$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$contentRoot = Join-Path $root 'content\v1'
$manifest = Get-Content (Join-Path $contentRoot 'manifest.json') -Raw | ConvertFrom-Json
$ids = @{}
$maps = @{}
$failures = @()
foreach ($pack in $manifest.packs) {
    $path = Join-Path $contentRoot $pack
    if (-not (Test-Path $path)) { $failures += "missing_pack:$pack"; continue }
    $data = Get-Content $path -Raw | ConvertFrom-Json
    foreach ($entry in $data.entries) {
        if ($entry.id -notmatch '^[a-z]+\.[a-z0-9_]+$') { $failures += "invalid_id:$($entry.id)" }
        elseif ($ids.ContainsKey($entry.id)) { $failures += "duplicate_id:$($entry.id)" }
        else { $ids[$entry.id] = $true }
		if ($entry.kind -eq 'map') { $maps[$entry.id] = $entry }
        foreach ($field in @('icon', 'scene')) {
            if ($entry.PSObject.Properties.Name -contains $field) {
                $relative = $entry.$field -replace '^res://', ''
                if (-not (Test-Path (Join-Path $root $relative))) { $failures += "missing_resource:$($entry.$field)" }
            }
        }
    }
}
foreach ($map in $maps.Values) {
	$spawnIds = @($map.spawns | ForEach-Object { $_.id })
	if ($map.default_spawn_id -notin $spawnIds) { $failures += "missing_default_spawn:$($map.id)" }
	foreach ($portal in $map.portals) {
		if (-not $maps.ContainsKey($portal.target_map_id)) { $failures += "missing_portal_map:$($portal.id)"; continue }
		$targetSpawns = @($maps[$portal.target_map_id].spawns | ForEach-Object { $_.id })
		if ($portal.target_spawn_id -notin $targetSpawns) { $failures += "missing_portal_spawn:$($portal.id)" }
	}
}
$result = [ordered]@{ ok = ($failures.Count -eq 0); test_id = 'content_registry_audit'; failures = $failures }
'TEST_RESULT ' + ($result | ConvertTo-Json -Compress)
if ($result.ok) { exit 0 }
exit 1
