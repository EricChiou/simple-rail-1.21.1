$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '../../..')).Path
Set-Location $root
$utf8 = [System.Text.UTF8Encoding]::new($false)
$results = @()
foreach ($n in @(8,10,11,12,13,14,15,16,17)) {
    $task = 'T-{0:D3}' -f $n
    $evidenceTask = if ($n -eq 17) { 'T-016' } else { $task }
    $compiler = (Get-Content "docs/evidence/$evidenceTask/compiler.txt" | Select-Object -Last 1).Trim()
    $classpath = ((Get-Content "docs/evidence/$evidenceTask/compile-classpath.txt") | Where-Object { $_.Trim() }) -join ';'
    $sources = if ($n -eq 17) { @(Get-ChildItem src/main/java -Recurse -Filter *.java) } else { @(Get-ChildItem "docs/evidence/$task/probe" -Filter *.java) }
    $outputDir = Join-Path $PSScriptRoot "compiled/$task"
    New-Item -ItemType Directory -Force -Path $outputDir | Out-Null
    $arguments = @('--release','21','-encoding','UTF-8','-Xlint:deprecation','-Werror','-proc:none','-classpath',$classpath,'-d',$outputDir) + @($sources.FullName)
    $argfile = Join-Path $PSScriptRoot "$task-javac.args"
    [IO.File]::WriteAllLines($argfile, @($arguments | ForEach-Object { '"' + $_.Replace('\','/') + '"' }), $utf8)
    $start = [DateTime]::UtcNow.ToString('o')
    $log = Join-Path $PSScriptRoot "$task-javac.log"
    $info = [Diagnostics.ProcessStartInfo]::new()
    $info.FileName = $compiler
    $info.Arguments = '@"' + $argfile + '"'
    $info.UseShellExecute = $false
    $info.CreateNoWindow = $true
    $info.RedirectStandardOutput = $true
    $info.RedirectStandardError = $true
    $process = [Diagnostics.Process]::Start($info)
    $stdout = $process.StandardOutput.ReadToEndAsync()
    $stderr = $process.StandardError.ReadToEndAsync()
    $process.WaitForExit()
    $code = $process.ExitCode
    [IO.File]::WriteAllText($log, $stdout.Result + $stderr.Result, $utf8)
    $process.Dispose()
    $results += [ordered]@{ task = $task; compiler = $compiler; argumentsFile = $argfile; startedUtc = $start; exitCode = $code; classCount = @(Get-ChildItem $outputDir -Recurse -Filter *.class).Count; log = $log }
    Write-Output "$task javac exit=$code"
}
[IO.File]::WriteAllText((Join-Path $PSScriptRoot 'compile-results.json'), ($results | ConvertTo-Json -Depth 6), $utf8)
if (@($results | Where-Object exitCode -ne 0).Count) { exit 1 }
