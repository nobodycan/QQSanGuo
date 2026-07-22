$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$baseline = Get-Content (Join-Path $root 'tests\phase03_legacy_baseline.json') -Raw | ConvertFrom-Json
$legacy = 'DataImport|PlayerInventory|FileManager|SkillsFactory|SkillsProperty|jsonData|SaveState|SceneChange|FreeNodes|PlayerStorage'
$current = @(rg -n --glob '*.gd' --glob '!tests/**' "\b($legacy)\b|change_scene\(" $root | ForEach-Object { $_.Substring($root.Length + 1) } | Sort-Object)
$failures = @($current | Where-Object { $_ -notin $baseline })
$unsafe = @(rg -n --glob '*.gd' --glob '!tests/**' 'OS\.(execute|shell_open)|HTTPClient|HTTPRequest|WebSocket|PacketPeerUDP|load\(.*user://' $root)
foreach ($entry in $unsafe) { $failures += "unsafe_runtime_api:$entry" }
$result = [ordered]@{ ok = ($failures.Count -eq 0); test_id = 'phase03_static_gate'; failures = $failures }
'TEST_RESULT ' + ($result | ConvertTo-Json -Compress)
if ($result.ok) { exit 0 }
exit 1
