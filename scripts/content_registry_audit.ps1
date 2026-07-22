$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$contentRoot = Join-Path $root 'content\v1'
$manifest = Get-Content (Join-Path $contentRoot 'manifest.json') -Raw | ConvertFrom-Json
$ids = @{}
$failures = @()
foreach ($pack in $manifest.packs) {
    $path = Join-Path $contentRoot $pack
    if (-not (Test-Path $path)) { $failures += "missing_pack:$pack"; continue }
    $data = Get-Content $path -Raw | ConvertFrom-Json
    foreach ($entry in $data.entries) {
        if ($entry.id -notmatch '^[a-z]+\.[a-z0-9_]+$') { $failures += "invalid_id:$($entry.id)" }
        elseif ($ids.ContainsKey($entry.id)) { $failures += "duplicate_id:$($entry.id)" }
        else { $ids[$entry.id] = $true }
        foreach ($field in @('icon', 'scene')) {
            if ($entry.PSObject.Properties.Name -contains $field) {
                $relative = $entry.$field -replace '^res://', ''
                if (-not (Test-Path (Join-Path $root $relative))) { $failures += "missing_resource:$($entry.$field)" }
            }
        }
    }
}
$result = [ordered]@{ ok = ($failures.Count -eq 0); test_id = 'content_registry_audit'; failures = $failures }
'TEST_RESULT ' + ($result | ConvertTo-Json -Compress)
if ($result.ok) { exit 0 }
exit 1
