$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$contentRoot = Join-Path $root 'content\v1'
$manifest = Get-Content (Join-Path $contentRoot 'manifest.json') -Raw | ConvertFrom-Json
$ids = @{}
$maps = @{}
$entries = @{}
$failures = @()
if (-not ($manifest.PSObject.Properties.Name -contains 'content_revision') -or [string]$manifest.content_revision -notmatch '^v\S+$') { $failures += 'invalid_content_revision' }
foreach ($pack in $manifest.packs) {
    $path = Join-Path $contentRoot $pack
    if (-not (Test-Path $path)) { $failures += "missing_pack:$pack"; continue }
    $data = Get-Content $path -Raw | ConvertFrom-Json
    foreach ($entry in $data.entries) {
        if ($entry.id -notmatch '^[a-z]+\.[a-z0-9_]+$') { $failures += "invalid_id:$($entry.id)" }
        elseif ($ids.ContainsKey($entry.id)) { $failures += "duplicate_id:$($entry.id)" }
		else { $ids[$entry.id] = $true; $entries[$entry.id] = $entry }
		if ($entry.kind -eq 'map') { $maps[$entry.id] = $entry }
		$properties = @($entry.PSObject.Properties.Name)
		if ($entry.kind -eq 'map' -and ((-not ($properties -contains 'scene')) -or (-not ($properties -contains 'default_spawn_id')) -or (-not ($properties -contains 'spawns')))) { $failures += "invalid_map_schema:$($entry.id)" }
		if ($entry.kind -eq 'skill' -and ((-not ($properties -contains 'unlock_level')) -or [int]$entry.unlock_level -lt 1 -or (-not ($properties -contains 'magic_cost')) -or [int]$entry.magic_cost -lt 0 -or (-not ($properties -contains 'cooldown_ticks')) -or [int]$entry.cooldown_ticks -lt 0 -or (-not ($properties -contains 'damage')) -or [int]$entry.damage -lt 0)) { $failures += "invalid_skill_schema:$($entry.id)" }
		if (@('equipment', 'material', 'consumable') -contains $entry.kind -and ((-not ($properties -contains 'stack_limit')) -or [int]$entry.stack_limit -lt 1 -or (-not ($properties -contains 'quest')))) { $failures += "invalid_item_schema:$($entry.id)" }
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
$aliasesPath = Join-Path $contentRoot 'legacy_aliases.json'
if (-not (Test-Path $aliasesPath)) { $failures += 'missing_legacy_aliases' }
else {
	$aliases = Get-Content $aliasesPath -Raw | ConvertFrom-Json
	foreach ($category in @('items', 'skills')) {
		if (-not ($aliases.PSObject.Properties.Name -contains $category)) { $failures += "missing_alias_category:$category"; continue }
		foreach ($property in $aliases.$category.PSObject.Properties) {
			$targetId = [string]$property.Value
			if (-not $entries.ContainsKey($targetId)) { $failures += "unknown_alias_target:${category}:$($property.Name)" }
			elseif ($category -eq 'skills' -and $entries[$targetId].kind -ne 'skill') { $failures += "wrong_alias_kind:${category}:$($property.Name)" }
			elseif ($category -eq 'items' -and @('equipment', 'material', 'consumable') -notcontains $entries[$targetId].kind) { $failures += "wrong_alias_kind:${category}:$($property.Name)" }
		}
	}
	if (-not ($aliases.PSObject.Properties.Name -contains 'maps')) { $failures += 'missing_alias_category:maps' }
	else {
		foreach ($property in $aliases.maps.PSObject.Properties) {
			$location = $property.Value
			$mapId = [string]$location.map_id
			$spawnId = [string]$location.spawn_id
			if (-not $maps.ContainsKey($mapId)) { $failures += "unknown_map_alias:$($property.Name)" }
			elseif ($spawnId -notin @($maps[$mapId].spawns | ForEach-Object { $_.id })) { $failures += "unknown_map_alias_spawn:$($property.Name)" }
		}
	}
}
$result = [ordered]@{ ok = ($failures.Count -eq 0); test_id = 'content_registry_audit'; failures = $failures }
'TEST_RESULT ' + ($result | ConvertTo-Json -Compress)
if ($result.ok) { exit 0 }
exit 1
