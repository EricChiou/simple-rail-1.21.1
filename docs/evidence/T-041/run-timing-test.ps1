$ErrorActionPreference = 'Stop'
$root = (Resolve-Path '.').Path
$evidence = Join-Path $root 'docs/evidence/T-041'
$classes = Join-Path $evidence 'tests/classes'
New-Item -ItemType Directory -Path $classes -Force | Out-Null
$sources = @(
    (Join-Path $root 'src/main/java/com/ericchiu/simplerail/blockentity/SignalTimerTiming.java'),
    (Join-Path $evidence 'tests/com/ericchiu/simplerail/config/CommonConfig.java'),
    (Join-Path $evidence 'tests/com/ericchiu/simplerail/blockentity/SignalTimerTimingTest.java')
)
& javac --release 21 -d $classes @sources *> (Join-Path $evidence 'timing-compile.log')
$compileExit = $LASTEXITCODE
if ($compileExit -eq 0) {
    & java -cp $classes com.ericchiu.simplerail.blockentity.SignalTimerTimingTest *> (Join-Path $evidence 'timing-test.log')
    $testExit = $LASTEXITCODE
} else {
    $testExit = $null
}
[ordered]@{
    command = 'powershell -NoProfile -ExecutionPolicy Bypass -File docs/evidence/T-041/run-timing-test.ps1'
    javac = 'javac --release 21 -d docs/evidence/T-041/tests/classes [production SignalTimerTiming.java and two test sources]'
    compile_exit = $compileExit
    java = 'java -cp docs/evidence/T-041/tests/classes com.ericchiu.simplerail.blockentity.SignalTimerTimingTest'
    test_exit = $testExit
} | ConvertTo-Json | Set-Content -Encoding UTF8 (Join-Path $evidence 'timing-results.json')
if ($compileExit -ne 0) { exit $compileExit }
exit $testExit
