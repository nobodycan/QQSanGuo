$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$source = Get-Content -Raw -Encoding UTF8 (Join-Path $projectRoot 'Data\SkillsFactory.gd')
$failures = @()

if ($source -match 'preload\("res://69896-1\.png"\)') {
    $failures += 'SkillsFactory preloads a generated texture before clean import completes.'
}

$result = [ordered]@{ ok = ($failures.Count -eq 0); test_id = 'startup_import_safety'; failures = $failures }
'TEST_RESULT ' + ($result | ConvertTo-Json -Compress)
if ($result.ok) { exit 0 }
exit 1
