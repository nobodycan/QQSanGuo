[CmdletBinding()]
param(
    [string]$ProjectRoot,
    [string]$GodotPath,
    [ValidateSet('all', 'unit', 'integration', 'resource', 'scene', 'e2e', 'soak')]
    [string]$Lane = 'all',
    [string]$ReportDirectory,
    [switch]$SelfTest
)

$ErrorActionPreference = 'Stop'
if ([string]::IsNullOrWhiteSpace($ProjectRoot)) {
    $ProjectRoot = Split-Path -Parent $PSScriptRoot
}
$ProjectRoot = [System.IO.Path]::GetFullPath($ProjectRoot)
if ([string]::IsNullOrWhiteSpace($ReportDirectory)) {
    $ReportDirectory = Join-Path $ProjectRoot 'artifacts\test-reports'
}
$ReportDirectory = [System.IO.Path]::GetFullPath($ReportDirectory)
[System.IO.Directory]::CreateDirectory($ReportDirectory) | Out-Null

function Write-Utf8([string]$Path, [string]$Content) {
    [System.IO.File]::WriteAllText($Path, $Content, (New-Object System.Text.UTF8Encoding($false)))
}

function Get-TestResult([string]$Output) {
    $line = @($Output -split "`r?`n" | Where-Object { $_ -like 'TEST_RESULT *' } | Select-Object -Last 1)
    if ($line.Count -ne 1) { return $null }
    try { return ($line[0].Substring('TEST_RESULT '.Length) | ConvertFrom-Json) } catch { return $null }
}

function Invoke-TestProcess($Test, [string]$Exe, [string[]]$ProcessArguments) {
    $stdout = Join-Path $ReportDirectory ($Test.id + '.stdout.log')
    $stderr = Join-Path $ReportDirectory ($Test.id + '.stderr.log')
    $isolatedHome = Join-Path ([System.IO.Path]::GetTempPath()) ('qqsanguo-test-' + $Test.id + '-' + [guid]::NewGuid().ToString('N'))
    [System.IO.Directory]::CreateDirectory($isolatedHome) | Out-Null
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $Exe
    $psi.Arguments = (($ProcessArguments | ForEach-Object { if ($_ -match '[\s"]') { '"' + ($_ -replace '"', '\"') + '"' } else { $_ } }) -join ' ')
    $psi.WorkingDirectory = $ProjectRoot
    $psi.UseShellExecute = $false
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.StandardOutputEncoding = [System.Text.Encoding]::UTF8
    $psi.StandardErrorEncoding = [System.Text.Encoding]::UTF8
    $psi.EnvironmentVariables['APPDATA'] = (Join-Path $isolatedHome 'AppData')
    $psi.EnvironmentVariables['LOCALAPPDATA'] = (Join-Path $isolatedHome 'LocalAppData')
    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $psi
    [void]$process.Start()
    $outTask = $process.StandardOutput.ReadToEndAsync()
    $errTask = $process.StandardError.ReadToEndAsync()
    $timedOut = -not $process.WaitForExit([int]$Test.timeout_seconds * 1000)
    if ($timedOut) { $process.Kill(); $process.WaitForExit() }
    $stdoutText = $outTask.GetAwaiter().GetResult()
    $stderrText = $errTask.GetAwaiter().GetResult()
    Write-Utf8 $stdout $stdoutText
    Write-Utf8 $stderr $stderrText
    $combined = $stdoutText + "`n" + $stderrText
    $terminal = Get-TestResult $combined
    $diagnosticOutput = $combined
    if ($Test.kind -eq 'godot_scene') {
        # Godot 3.5 reports these process-teardown lines after project Autoloads exit.
        # All runtime and script diagnostics remain strict for project scene tests.
        $diagnosticOutput = $diagnosticOutput -replace '(?m)^WARNING: ObjectDB instances leaked at exit \(run with --verbose for details\)\.\r?\n\s+at: cleanup \(core/object\.cpp:\d+\)\r?\n?', ''
        $diagnosticOutput = $diagnosticOutput -replace '(?m)^ERROR: Resources still in use at exit \(run with --verbose for details\)\.\r?\n\s+at: clear \(core/resource\.cpp:\d+\)\r?\n?', ''
    }
    $unexpectedError = $diagnosticOutput -match '(?m)^(ERROR:|SCRIPT ERROR:|Parser Error|.*missing resource.*)'
    $status = if ($timedOut) { 'timeout' } elseif ($unexpectedError) { 'log_error' } elseif ($null -eq $terminal) { 'protocol_error' } elseif ($process.ExitCode -ne 0 -or -not $terminal.ok) { 'failed' } else { 'passed' }
    Remove-Item -LiteralPath $isolatedHome -Recurse -Force -ErrorAction SilentlyContinue
    return [ordered]@{ id = $Test.id; lane = $Test.lane; status = $status; exit_code = if ($timedOut) { $null } else { $process.ExitCode }; timeout_seconds = $Test.timeout_seconds; result = $terminal; stdout = [System.IO.Path]::GetFileName($stdout); stderr = [System.IO.Path]::GetFileName($stderr) }
}

function Invoke-SelfTests {
    $tests = @(
        @{ id='self_pass'; timeout_seconds=5; code='Write-Output ''TEST_RESULT {"ok":true,"test_id":"self_pass"}''; exit 0'; expected='passed' },
        @{ id='self_fail'; timeout_seconds=5; code='Write-Output ''TEST_RESULT {"ok":false,"test_id":"self_fail"}''; exit 1'; expected='failed' },
        @{ id='self_timeout'; timeout_seconds=1; code='Start-Sleep -Seconds 5'; expected='timeout' },
        @{ id='self_log_error'; timeout_seconds=5; code='Write-Output ''ERROR: synthetic diagnostic''; Write-Output ''TEST_RESULT {"ok":true,"test_id":"self_log_error"}''; exit 0'; expected='log_error' }
    )
    $results = @()
    foreach ($fixture in $tests) {
        $test = [pscustomobject]@{ id=$fixture.id; lane='unit'; timeout_seconds=$fixture.timeout_seconds }
        $fixturePath = Join-Path $ReportDirectory ($fixture.id + '.fixture.ps1')
        Write-Utf8 $fixturePath $fixture.code
        $result = Invoke-TestProcess $test 'powershell.exe' @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $fixturePath)
        Remove-Item -LiteralPath $fixturePath -Force -ErrorAction SilentlyContinue
        $result.self_test_expected = $fixture.expected
        $result.self_test_ok = ($result.status -eq $fixture.expected)
        $results += [pscustomobject]$result
    }
    return $results
}

if ($SelfTest) {
    $results = Invoke-SelfTests
} else {
    $manifestPath = Join-Path $ProjectRoot 'tests\test_manifest.json'
    $manifest = Get-Content -Raw -Encoding UTF8 $manifestPath | ConvertFrom-Json
    if ($manifest.schema_version -ne 1) { throw 'Unsupported test manifest schema.' }
    if ([string]::IsNullOrWhiteSpace($GodotPath)) { $GodotPath = $env:GODOT_BIN }
    $results = @()
    foreach ($test in $manifest.tests | Where-Object { $Lane -eq 'all' -or $_.lane -eq $Lane }) {
        if ($test.kind -eq 'powershell') {
            $results += [pscustomobject](Invoke-TestProcess $test 'powershell.exe' @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', (Join-Path $ProjectRoot $test.script)))
        } elseif ($test.kind -eq 'godot') {
            if ([string]::IsNullOrWhiteSpace($GodotPath) -or -not (Test-Path -LiteralPath $GodotPath)) {
                $results += [pscustomobject]@{ id=$test.id; lane=$test.lane; status='blocked_tool_missing'; exit_code=$null; timeout_seconds=$test.timeout_seconds; result=$null; stdout=$null; stderr=$null }
            } else {
                $results += [pscustomobject](Invoke-TestProcess $test $GodotPath @('--path', $ProjectRoot, '--no-window', '--audio-driver', 'Dummy', '--fixed-fps', '60', '-s', ('res://' + ($test.script -replace '\\', '/'))))
            }
        } elseif ($test.kind -eq 'godot_scene') {
            if ([string]::IsNullOrWhiteSpace($GodotPath) -or -not (Test-Path -LiteralPath $GodotPath)) {
                $results += [pscustomobject]@{ id=$test.id; lane=$test.lane; status='blocked_tool_missing'; exit_code=$null; timeout_seconds=$test.timeout_seconds; result=$null; stdout=$null; stderr=$null }
            } else {
                $results += [pscustomobject](Invoke-TestProcess $test $GodotPath @('--path', $ProjectRoot, '--no-window', '--audio-driver', 'Dummy', '--fixed-fps', '60', ('res://' + ($test.scene -replace '\\', '/'))))
            }
        } else { throw "Unsupported test kind: $($test.kind)" }
    }
}

$summary = [ordered]@{ schema_version=1; lane=$Lane; generated_at=(Get-Date).ToUniversalTime().ToString('o'); ok=(@($results | Where-Object { $_.status -ne 'passed' -and -not $_.self_test_ok }).Count -eq 0); tests=@($results) }
$jsonPath = Join-Path $ReportDirectory 'test-report.json'
Write-Utf8 $jsonPath ($summary | ConvertTo-Json -Depth 8)
$suite = New-Object System.Xml.XmlDocument
$decl = $suite.CreateXmlDeclaration('1.0', 'UTF-8', $null); [void]$suite.AppendChild($decl)
$root = $suite.CreateElement('testsuite'); $root.SetAttribute('name', 'QQSanGuo'); $root.SetAttribute('tests', [string]$results.Count); $root.SetAttribute('failures', [string](@($results | Where-Object { $_.status -ne 'passed' }).Count)); [void]$suite.AppendChild($root)
foreach ($result in $results) { $case = $suite.CreateElement('testcase'); $case.SetAttribute('name', $result.id); $case.SetAttribute('classname', $result.lane); if ($result.status -ne 'passed') { $failure=$suite.CreateElement('failure'); $failure.SetAttribute('message', $result.status); [void]$case.AppendChild($failure) }; [void]$root.AppendChild($case) }
$suite.Save((Join-Path $ReportDirectory 'junit.xml'))
Write-Output ('TEST_RUNNER_RESULT ' + ($summary | ConvertTo-Json -Depth 8 -Compress))
if (-not $summary.ok) { exit 1 }
