$ErrorActionPreference = 'Stop'
$root = (Resolve-Path '.').Path
$evidence = Join-Path $root 'docs/evidence/T-040/fix-R1'
$classes = Join-Path $evidence 'tests/classes'
New-Item -ItemType Directory -Path $classes -Force | Out-Null
$doubles = @(Get-ChildItem (Join-Path $root 'docs/evidence/T-035/isolated-tests/stubs') -Recurse -Filter '*.java' |
        ForEach-Object { $_.FullName })
$inputs = $doubles + @(
    (Join-Path $evidence 'tests/stubs/com/ericchiu/simplerail/block/TimerHoldingRail.java'),
    (Join-Path $root 'src/main/java/com/ericchiu/simplerail/item/Wrench.java'),
    (Join-Path $root 'docs/evidence/T-035/WrenchHooksTest.java'),
    (Join-Path $evidence 'tests/TimerWrenchRegressionTest.java')
)
& javac --release 21 -encoding UTF-8 -Xlint:unchecked -Werror -d $classes @inputs *> (Join-Path $evidence 'compile.log')
$compileExit = $LASTEXITCODE
if ($compileExit -eq 0) {
    & java -cp $classes com.ericchiu.simplerail.item.WrenchHooksTest *> (Join-Path $evidence 'historical-regression.log')
    $historicalExit = $LASTEXITCODE
    & java -cp $classes com.ericchiu.simplerail.item.TimerWrenchRegressionTest *> (Join-Path $evidence 'timer-regression.log')
    $timerExit = $LASTEXITCODE
} else {
    $historicalExit = $null
    $timerExit = $null
}
[ordered]@{
    command = 'powershell -NoProfile -ExecutionPolicy Bypass -File docs/evidence/T-040/fix-R1/run-isolated-test.ps1'
    test_double_count = $doubles.Count + 1
    actual_product_source = 'src/main/java/com/ericchiu/simplerail/item/Wrench.java'
    compile_exit = $compileExit
    historical_exit = $historicalExit
    timer_regression_exit = $timerExit
    minecraft_executed = $false
} | ConvertTo-Json | Set-Content -Encoding UTF8 (Join-Path $evidence 'results.json')
if ($compileExit -ne 0) { exit $compileExit }
if ($historicalExit -ne 0) { exit $historicalExit }
exit $timerExit
