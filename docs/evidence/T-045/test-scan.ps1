$ErrorActionPreference = 'Stop'
$evidence = 'docs/evidence/T-045'
$outputDir = Join-Path $evidence 'classes'
New-Item -ItemType Directory -Force $outputDir | Out-Null
$started = (Get-Date).ToUniversalTime().ToString('o')
$log = Join-Path $evidence 'test-scan.log'
& javac --release 21 -d $outputDir 'src/main/java/com/ericchiu/simplerail/block/TrainDispenserScan.java' (Join-Path $evidence 'tests/TrainDispenserScanTest.java') *> $log
$compileExit = $LASTEXITCODE
if ($compileExit -eq 0) {
    & java -cp $outputDir evidence.t045.TrainDispenserScanTest *>> $log
    $testExit = $LASTEXITCODE
} else {
    $testExit = $null
}
[ordered]@{
    compile_command = 'javac --release 21 -d docs/evidence/T-045/classes src/main/java/com/ericchiu/simplerail/block/TrainDispenserScan.java docs/evidence/T-045/tests/TrainDispenserScanTest.java'
    test_command = 'java -cp docs/evidence/T-045/classes evidence.t045.TrainDispenserScanTest'
    started_utc = $started
    finished_utc = (Get-Date).ToUniversalTime().ToString('o')
    compile_exit_code = $compileExit
    test_exit_code = $testExit
    scope = 'Production scanner plain-JVM geometry/iteration only; no Minecraft runtime'
} | ConvertTo-Json | Set-Content -Encoding UTF8 (Join-Path $evidence 'test-scan.json')
Get-Content $log -Tail 20
if ($compileExit -ne 0) { exit $compileExit }
exit $testExit
