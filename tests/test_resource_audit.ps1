$ErrorActionPreference = 'Stop'

$script:Failures = @()
$projectRoot = Split-Path -Parent $PSScriptRoot
$auditScript = Join-Path $projectRoot 'scripts\resource_audit.ps1'
$fixtureRoot = Join-Path (Join-Path ([System.IO.Path]::GetTempPath()) ('qqsanguo-resource-audit-' + [guid]::NewGuid().ToString('N'))) '.worktrees'

function Add-Failure([string]$Message) {
    $script:Failures += $Message
}

function Write-Utf8File([string]$Path, [string]$Content) {
    $directory = Split-Path -Parent $Path
    [System.IO.Directory]::CreateDirectory($directory) | Out-Null
    [System.IO.File]::WriteAllText($Path, $Content, (New-Object System.Text.UTF8Encoding($false)))
}

function New-Fixture([string]$Name, [string]$PluginLine, [string]$Reference, [string]$Manifest) {
    $root = Join-Path $fixtureRoot $Name
    Write-Utf8File (Join-Path $root 'project.godot') ("[application]`nconfig/name=`"fixture`"`n[editor_plugins]`nenabled=PoolStringArray( $PluginLine )`n")
    Write-Utf8File (Join-Path $root 'scene.tscn') ("[gd_scene load_steps=1 format=2]`n[ext_resource path=`"$Reference`" type=`"Texture`" id=1]`n")
    Write-Utf8File (Join-Path $root 'assets\ok.png') 'fixture'
    Write-Utf8File (Join-Path $root 'assets\捕快\ok.png') 'fixture'
    Write-Utf8File (Join-Path $root 'Data\resource_manifest.json') $Manifest
    return $root
}

function Invoke-Audit([string]$Root) {
    $output = & powershell -NoProfile -ExecutionPolicy Bypass -File $auditScript -ProjectRoot $Root 2>&1
    return [pscustomobject]@{ ExitCode = $LASTEXITCODE; Output = @($output) }
}

try {
    if (-not (Test-Path -LiteralPath $auditScript)) {
        Add-Failure 'audit script is missing'
    } else {
        $closed = New-Fixture 'closed' '' 'res://assets/捕快/ok.png' '{"schema_version":1,"images":["res://assets/捕快/ok.png"],"audio":[],"other":[]}'
        $missingPlugin = New-Fixture 'missing-plugin' '"codeandweb.texturepacker"' 'res://assets/ok.png' '{"schema_version":1,"images":[],"audio":[],"other":[]}'
        $missingPath = New-Fixture 'missing-path' '' 'res://assets/missing.png' '{"schema_version":1,"images":[],"audio":[],"other":[]}'
        $caseMismatch = New-Fixture 'case-mismatch' '' 'res://Assets/ok.png' '{"schema_version":1,"images":[],"audio":[],"other":[]}'
        $invalidManifest = New-Fixture 'invalid-manifest' '' 'res://assets/ok.png' '{"schema_version":1,"images":["../escape.png"],"audio":[],"other":[]}'
        $utf8Manifest = New-Fixture 'utf8-manifest' '' 'res://assets/ok.png' '{"schema_version":1,"images":["res://assets/utf8-\u00e9.png"],"audio":[],"other":[]}'
        Write-Utf8File (Join-Path $utf8Manifest ('assets\utf8-' + [char]0x00E9 + '.png')) 'fixture'
        $duplicateManifest = New-Fixture 'duplicate-manifest' '' 'res://assets/ok.png' '{"schema_version":1,"images":["res://assets/ok.png"],"audio":["res://assets/ok.png"],"other":[]}'
        $trailingSlashManifest = New-Fixture 'trailing-slash-manifest' '' 'res://assets/ok.png' '{"schema_version":1,"images":["res://assets/ok.png/"],"audio":[],"other":[]}'
        $stringManifestField = New-Fixture 'string-manifest-field' '' 'res://assets/ok.png' '{"schema_version":1,"images":"res://assets/ok.png","audio":[],"other":[]}'
        $spaced = New-Fixture 'spaced' '' 'res://assets/Iron Sword.png' '{"schema_version":1,"images":[],"audio":[],"other":[]}'
        Write-Utf8File (Join-Path $spaced 'assets\Iron Sword.png') 'fixture'
        $directoryPrefix = New-Fixture 'directory-prefix' '' 'res://assets/ok.png' '{"schema_version":1,"images":[],"audio":[],"other":[]}'
        Write-Utf8File (Join-Path $directoryPrefix 'script.gd') 'var root = "res://assets/"'
        $commentOnly = New-Fixture 'comment-only' '' 'res://assets/ok.png' '{"schema_version":1,"images":[],"audio":[],"other":[]}'
        Write-Utf8File (Join-Path $commentOnly 'script.gd') '# var stale = "res://assets/does-not-exist.png"'

        $cases = @(
            @{ Name = 'closed'; Root = $closed; Exit = 0; Code = $null },
            @{ Name = 'missing-plugin'; Root = $missingPlugin; Exit = 1; Code = 'missing_plugin' },
            @{ Name = 'missing-path'; Root = $missingPath; Exit = 1; Code = 'missing_resource' },
            @{ Name = 'case-mismatch'; Root = $caseMismatch; Exit = 1; Code = 'case_mismatch' },
            @{ Name = 'invalid-manifest'; Root = $invalidManifest; Exit = 1; Code = 'invalid_manifest' },
            @{ Name = 'utf8-manifest'; Root = $utf8Manifest; Exit = 0; Code = $null },
            @{ Name = 'duplicate-manifest'; Root = $duplicateManifest; Exit = 1; Code = 'invalid_manifest' },
            @{ Name = 'trailing-slash-manifest'; Root = $trailingSlashManifest; Exit = 1; Code = 'invalid_manifest' },
            @{ Name = 'string-manifest-field'; Root = $stringManifestField; Exit = 1; Code = 'invalid_manifest' },
            @{ Name = 'spaced'; Root = $spaced; Exit = 0; Code = $null },
            @{ Name = 'directory-prefix'; Root = $directoryPrefix; Exit = 0; Code = $null },
            @{ Name = 'comment-only'; Root = $commentOnly; Exit = 0; Code = $null }
        )
        foreach ($case in $cases) {
            $result = Invoke-Audit $case.Root
            $line = @($result.Output | Where-Object { $_ -like 'RESOURCE_AUDIT_RESULT *' }) | Select-Object -Last 1
            if ($result.ExitCode -ne $case.Exit) { Add-Failure "$($case.Name): expected exit $($case.Exit), got $($result.ExitCode)"; continue }
            if ($null -eq $line) { Add-Failure "$($case.Name): missing terminal JSON"; continue }
            $json = ($line -replace '^RESOURCE_AUDIT_RESULT\s+', '') | ConvertFrom-Json
            if ($case.Exit -eq 0 -and -not $json.ok) { Add-Failure "$($case.Name): expected ok true" }
            if ($json.scanned_files -lt 1) { Add-Failure "$($case.Name): expected at least one scanned source file" }
            if ($null -ne $case.Code -and -not (($json.missing + $json.case_mismatch + $json.invalid_manifest + $json.missing_plugin | ConvertTo-Json -Compress) -match [regex]::Escape($case.Code))) { Add-Failure "$($case.Name): expected $($case.Code)" }
        }
        $projectAudit = Invoke-Audit $projectRoot
        if ($projectAudit.ExitCode -ne 0) { Add-Failure "project: expected closed audit, got exit $($projectAudit.ExitCode)" }
    }
} finally {
    if (Test-Path -LiteralPath $fixtureRoot) { Remove-Item -LiteralPath $fixtureRoot -Recurse -Force }
}

if ($script:Failures.Count -gt 0) {
    $script:Failures | ForEach-Object { "TEST_RESOURCE_AUDIT_FAIL $_" }
    exit 1
}

'TEST_RESOURCE_AUDIT_PASS'
exit 0
