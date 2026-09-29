param([string]$Attempt = '02')
$ErrorActionPreference = 'Stop'
$taskEvidence = Join-Path (Get-Location) 'docs/evidence/T-020'
$classes = Join-Path $taskEvidence 'test-classes'
New-Item -ItemType Directory -Force $classes | Out-Null
$dependencies = @(Get-Content -Encoding utf8 docs/evidence/T-008/compile-classpath.txt | Where-Object { $_.Trim() })
$classpath = (@((Join-Path (Get-Location) 'build/libs/simplerail-1.0.0.jar')) + $dependencies) -join ';'
$records = [Collections.Generic.List[object]]::new()
function Invoke-Recorded([string]$command, [scriptblock]$action, [string]$log) {
    $started = [DateTime]::UtcNow.ToString('o')
    $ErrorActionPreference = 'Continue'
    & $action *> (Join-Path $taskEvidence $log)
    $code = $LASTEXITCODE
    $ErrorActionPreference = 'Stop'
    $records.Add([ordered]@{command = $command; startedUtc = $started; finishedUtc = [DateTime]::UtcNow.ToString('o'); exitCode = $code; log = $log; logEncoding = 'UTF-16LE'})
    $records | ConvertTo-Json -Depth 5 | Set-Content -Encoding utf8 (Join-Path $taskEvidence ('test-commands-' + $Attempt + '.json'))
    Get-Content (Join-Path $taskEvidence $log)
    if ($code -ne 0) { exit $code }
}
$classpath | Set-Content -Encoding utf8 (Join-Path $taskEvidence 'test-classpath.txt')
@($dependencies | ForEach-Object { [ordered]@{path = $_; sha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $_).Hash} }) | ConvertTo-Json -Depth 5 | Set-Content -Encoding utf8 (Join-Path $taskEvidence 'test-classpath-manifest.json')
Invoke-Recorded 'javac --release 21 -proc:none -Xlint:deprecation -Werror -cp <test-classpath.txt> -d docs/evidence/T-020/test-classes docs/evidence/T-020/test/ConfigContractTest.java' {
    javac --release 21 -proc:none -Xlint:deprecation -Werror -cp $classpath -d $classes docs/evidence/T-020/test/ConfigContractTest.java
} ('test-compile-' + $Attempt + '.log')
Invoke-Recorded 'java -ea -cp <test-classes;test-classpath.txt> com.ericchiu.simplerail.config.ConfigContractTest docs/evidence/T-020' {
    java -ea -cp ($classes + ';' + $classpath) com.ericchiu.simplerail.config.ConfigContractTest $taskEvidence
} ('test-run-' + $Attempt + '.log')
