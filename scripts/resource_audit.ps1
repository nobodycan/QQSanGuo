param(
    [Parameter(Mandatory = $true)]
    [string]$ProjectRoot,
    [string]$ManifestPath
)

$ErrorActionPreference = 'Stop'
$root = [System.IO.Path]::GetFullPath($ProjectRoot)
if ([string]::IsNullOrWhiteSpace($ManifestPath)) {
    $ManifestPath = Join-Path $root 'Data\resource_manifest.json'
}

$missing = New-Object System.Collections.Generic.List[object]
$caseMismatch = New-Object System.Collections.Generic.List[object]
$invalidManifest = New-Object System.Collections.Generic.List[object]
$missingPlugin = New-Object System.Collections.Generic.List[object]
$references = New-Object System.Collections.Generic.List[string]
$directoryEntryCache = @{}
$manifestValues = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::Ordinal)

function Add-Issue([System.Collections.Generic.List[object]]$List, [string]$Code, [string]$Owner, [string]$Path) {
    $List.Add([pscustomobject]@{ code = $Code; owner = $Owner; path = $Path })
}

function Test-ResPath([string]$Path, [string]$Owner) {
    if ([string]::IsNullOrWhiteSpace($Path) -or -not $Path.StartsWith('res://', [System.StringComparison]::Ordinal)) {
        Add-Issue $invalidManifest 'invalid_manifest' $Owner $Path
        return
    }
    # Godot generates this cache during import; it is not a tracked runtime source.
    if ($Path.StartsWith('res://.import/', [System.StringComparison]::Ordinal)) { return }
    $relative = $Path.Substring(6)
    if ($relative.Contains('..') -or $relative.Contains(':') -or $relative.StartsWith('/')) {
        Add-Issue $invalidManifest 'invalid_manifest' $Owner $Path
        return
    }
    $relative = $relative.TrimEnd('/')
    if ([string]::IsNullOrWhiteSpace($relative)) { return }
    $cursor = $root
    foreach ($segment in ($relative -split '/')) {
        if ([string]::IsNullOrWhiteSpace($segment)) {
            Add-Issue $invalidManifest 'invalid_manifest' $Owner $Path
            return
        }
        if (-not $directoryEntryCache.ContainsKey($cursor)) {
            $directoryEntryCache[$cursor] = @(Get-ChildItem -LiteralPath $cursor -Force -ErrorAction SilentlyContinue)
        }
        $children = @($directoryEntryCache[$cursor])
        $exactChild = @($children | Where-Object { $_.Name -ceq $segment } | Select-Object -First 1)
        if ($exactChild.Count -eq 1) {
            $cursor = $exactChild[0].FullName
            continue
        }
        $candidate = @($children | Where-Object { $_.Name -ieq $segment } | Select-Object -First 1)
        if ($candidate.Count -eq 1) {
            Add-Issue $caseMismatch 'case_mismatch' $Owner $Path
        } else {
            Add-Issue $missing 'missing_resource' $Owner $Path
        }
        return
    }
}

function Test-ManifestValue([string]$Path, [string]$Owner) {
    if ($Path.EndsWith('/', [System.StringComparison]::Ordinal)) {
        Add-Issue $invalidManifest 'invalid_manifest' $Owner $Path
        return $false
    }
    if (-not $manifestValues.Add($Path)) {
        Add-Issue $invalidManifest 'invalid_manifest' $Owner $Path
        return $false
    }
    return $true
}

if (-not (Test-Path -LiteralPath (Join-Path $root 'project.godot'))) {
    Add-Issue $missing 'missing_resource' 'project' 'project.godot'
} else {
    $projectConfig = [System.IO.File]::ReadAllText((Join-Path $root 'project.godot'), [System.Text.Encoding]::UTF8)
    if ($projectConfig -match 'codeandweb\.texturepacker' -and -not (Test-Path -LiteralPath (Join-Path $root 'addons\codeandweb.texturepacker'))) {
        Add-Issue $missingPlugin 'missing_plugin' 'project.godot' 'codeandweb.texturepacker'
    }
}

if (-not (Test-Path -LiteralPath $ManifestPath)) {
    Add-Issue $invalidManifest 'invalid_manifest' 'manifest' $ManifestPath
} else {
    try {
        $manifest = [System.IO.File]::ReadAllText($ManifestPath, [System.Text.Encoding]::UTF8) | ConvertFrom-Json
        if ($manifest.schema_version -ne 1) { throw 'schema_version must be 1' }
        foreach ($field in @('images', 'audio', 'other')) {
            $values = $manifest.$field
            if ($null -eq $values -or $values -is [string] -or -not ($values -is [System.Collections.IEnumerable])) { throw "$field must be an array" }
            foreach ($value in @($values)) {
                if ($value -isnot [string]) { Add-Issue $invalidManifest 'invalid_manifest' "manifest.$field" ([string]$value); continue }
                $references.Add($value)
                if (Test-ManifestValue $value "manifest.$field") {
                    Test-ResPath $value "manifest.$field"
                }
            }
        }
    } catch {
        Add-Issue $invalidManifest 'invalid_manifest' 'manifest' $_.Exception.Message
    }
}

$sourceFiles = Get-ChildItem -LiteralPath $root -Recurse -File -ErrorAction SilentlyContinue |
    Where-Object {
        $relative = $_.FullName.Substring($root.Length).TrimStart([char[]]@('\', '/'))
        $_.Extension -in @('.gd', '.tscn', '.tres') -and
        $relative -notmatch '^(\.git|\.worktrees|\.import|tests|artifacts)(\\|/)'
    }
foreach ($file in $sourceFiles) {
    $content = [System.IO.File]::ReadAllText($file.FullName, [System.Text.Encoding]::UTF8)
    if ($file.Extension -eq '.gd') {
        $content = [regex]::Replace($content, '(?m)^\s*#.*$', '')
    }
    $pattern = if ($file.Extension -in @('.tscn', '.tres')) {
        'path="(?<path>res://[^"]+)"'
    } else {
        '["''](?<path>res://[^"'']+)["'']'
    }
    foreach ($match in [regex]::Matches($content, $pattern)) {
        $path = $match.Groups['path'].Value
        $references.Add($path)
        Test-ResPath $path $file.FullName.Substring($root.Length).TrimStart([char[]]@('\', '/'))
    }
}

$result = [ordered]@{
    ok = ($missing.Count -eq 0 -and $caseMismatch.Count -eq 0 -and $invalidManifest.Count -eq 0 -and $missingPlugin.Count -eq 0)
    scanned_files = @($sourceFiles).Count
    references = @($references | Sort-Object -Unique)
    missing = @($missing | Sort-Object owner, path)
    case_mismatch = @($caseMismatch | Sort-Object owner, path)
    invalid_manifest = @($invalidManifest | Sort-Object owner, path)
    missing_plugin = @($missingPlugin | Sort-Object owner, path)
}

'RESOURCE_AUDIT_RESULT ' + ($result | ConvertTo-Json -Depth 6 -Compress)
if ($result.ok) { exit 0 }
exit 1
