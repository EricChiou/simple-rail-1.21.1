param([ValidateSet('client','server')][string]$Mode)
$ErrorActionPreference = 'Stop'
$root = 'D:\workspace\java\simple-rail-1.21.1'
$taskId = if ($Mode -eq 'client') { 'T-006' } else { 'T-007' }
$ev = Join-Path $root "docs\evidence\$taskId"
$task = if ($Mode -eq 'client') { 'runClient' } else { 'runServer' }
$argsText = "/d /c gradlew.bat $task --console=plain --info --no-configuration-cache -I docs/evidence/T-006/runtime.init.gradle"
$info = New-Object System.Diagnostics.ProcessStartInfo
$info.FileName = $env:ComSpec
$info.Arguments = $argsText
$info.WorkingDirectory = $root
$info.UseShellExecute = $false
$info.CreateNoWindow = $true
$info.RedirectStandardOutput = $true
$info.RedirectStandardError = $true
$info.RedirectStandardInput = $true
$process = New-Object System.Diagnostics.Process
$process.StartInfo = $info
$started = [DateTime]::UtcNow.ToString('o')
$outStream = [IO.File]::Open((Join-Path $ev 'stdout.log'), [IO.FileMode]::Create, [IO.FileAccess]::Write, [IO.FileShare]::ReadWrite)
$errStream = [IO.File]::Open((Join-Path $ev 'stderr.log'), [IO.FileMode]::Create, [IO.FileAccess]::Write, [IO.FileShare]::ReadWrite)
[void]$process.Start()
$outCopy = $process.StandardOutput.BaseStream.CopyToAsync($outStream)
$errCopy = $process.StandardError.BaseStream.CopyToAsync($errStream)
$meta = [ordered]@{ task=$taskId; command="$($info.FileName) $argsText"; cwd=$root; startedUtc=$started; launcherPid=$process.Id; exitCode=$null }
$meta | ConvertTo-Json | Set-Content -Encoding UTF8 (Join-Path $ev 'launch.json')
$sent = 0
while (-not $process.WaitForExit(250)) {
    $control = Join-Path $ev 'stdin.txt'
    if (Test-Path -LiteralPath $control) {
        $lines = @(Get-Content -LiteralPath $control -Encoding UTF8)
        while ($sent -lt $lines.Count) {
            $line = $lines[$sent]
            $process.StandardInput.WriteLine($line)
            $process.StandardInput.Flush()
            "$( [DateTime]::UtcNow.ToString('o') ) $line" | Add-Content -Encoding UTF8 (Join-Path $ev 'stdin-sent.log')
            $sent++
        }
    }
}
$outCopy.GetAwaiter().GetResult()
$errCopy.GetAwaiter().GetResult()
$outStream.Dispose()
$errStream.Dispose()
$meta.endedUtc = [DateTime]::UtcNow.ToString('o')
$meta.exitCode = $process.ExitCode
$meta | ConvertTo-Json | Set-Content -Encoding UTF8 (Join-Path $ev 'launch.json')
exit $process.ExitCode
