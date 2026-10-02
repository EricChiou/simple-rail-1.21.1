$ErrorActionPreference='Stop'
$root=(Get-Location).Path
$out=Join-Path $root 'docs/evidence/R-04'
$utf8=[Text.UTF8Encoding]::new($false)
$records=[Collections.Generic.List[object]]::new()
$inputs=[Collections.Generic.List[object]]::new()
function Run([string]$name,[string]$exe,[string[]]$arguments) {
    $info=[Diagnostics.ProcessStartInfo]::new()
    $info.FileName=(Get-Command $exe).Source
    $info.Arguments=($arguments|ForEach-Object {'"'+$_+'"'}) -join ' '
    $info.WorkingDirectory=$out
    $info.UseShellExecute=$false; $info.CreateNoWindow=$true
    $info.RedirectStandardOutput=$true; $info.RedirectStandardError=$true
    $started=[DateTime]::UtcNow.ToString('o')
    $p=[Diagnostics.Process]::Start($info)
    $stdout=$p.StandardOutput.ReadToEndAsync(); $stderr=$p.StandardError.ReadToEndAsync()
    $p.WaitForExit()
    [IO.File]::WriteAllText((Join-Path $out ($name+'.log')),$stdout.Result+$stderr.Result,$utf8)
    $records.Add([pscustomobject]@{name=$name;executable=$info.FileName;arguments=$arguments;cwd=$out;startedUtc=$started;finishedUtc=[DateTime]::UtcNow.ToString('o');exitCode=$p.ExitCode})
    [IO.File]::WriteAllText((Join-Path $out 'commands.json'),($records|ConvertTo-Json -Depth 7),$utf8)
    Write-Output ($name+': '+$p.ExitCode+' '+$stdout.Result.Trim())
    if($p.ExitCode -ne 0){throw ($name+' failed')}
}
function Inputs([string[]]$paths) { foreach($path in $paths){$inputs.Add([pscustomobject]@{path=$path;sha256=(Get-FileHash -LiteralPath $path).Hash})} }
$cp=@(Get-Content -Encoding UTF8 (Join-Path $root 'docs/evidence/T-038/compile-classpath.txt') | Where-Object {$_.Trim()})
$product=Join-Path $root 'src/main/java/com/ericchiu/simplerail'
function Suite([string]$id,[string[]]$files,[string[]]$tests,[string[]]$dependencies=@()) {
    $classes=Join-Path $out ($id+'/classes')
    New-Item -ItemType Directory -Force $classes | Out-Null
    $classpath=(@($classes)+$dependencies) -join ';'
    Inputs ($files+$dependencies)
    Run ($id+'-compile') 'javac' (@('--release','21','-proc:none','-encoding','UTF-8','-cp',$classpath,'-d',$classes)+$files)
    foreach($test in $tests){Run ($id+'-'+($test.Split('.')[-1])) 'java' @('-ea','-cp',$classpath,$test)}
}
$e=Join-Path $root 'docs/evidence'
Suite 'timer-investigation' @("$e/T-037/fixture/evidence/t037/TimerState.java","$e/T-037/fixture/evidence/t037/TimerRecordCodec.java","$e/T-037/tests/evidence/t037/TimerInvestigationTest.java") @('evidence.t037.TimerInvestigationTest') $cp
Suite 'holding-nbt' @("$product/blockentity/HoldingTimer.java","$product/blockentity/HoldingTimerData.java","$e/T-038/tests/com/ericchiu/simplerail/blockentity/HoldingTimerTest.java") @('com.ericchiu.simplerail.blockentity.HoldingTimerTest') $cp
$stubs=@(Get-ChildItem "$e/T-038/isolated-tests/stubs" -Recurse -File -Filter '*.java' | ForEach-Object {$_.FullName})
Suite 'holding-hooks' ($stubs+@("$product/block/TimerHoldingRail.java","$product/blockentity/TimerHoldingRailBlockEntity.java","$product/blockentity/HoldingTimer.java","$product/blockentity/HoldingTimerData.java","$e/T-038/isolated-tests/TimerRailHooksTest.java")) @('com.ericchiu.simplerail.blockentity.TimerRailHooksTest') $cp
Suite 'signal-timing' @("$product/blockentity/SignalTimerTiming.java","$e/T-041/tests/com/ericchiu/simplerail/config/CommonConfig.java","$e/T-041/tests/com/ericchiu/simplerail/blockentity/SignalTimerTimingTest.java") @('com.ericchiu.simplerail.blockentity.SignalTimerTimingTest')
$stubs=@(Get-ChildItem "$e/T-035/isolated-tests/stubs" -Recurse -File -Filter '*.java' | ForEach-Object {$_.FullName})
Suite 'wrench' ($stubs+@("$e/T-040/fix-R1/tests/stubs/com/ericchiu/simplerail/block/TimerHoldingRail.java","$product/item/Wrench.java","$e/T-035/WrenchHooksTest.java","$e/T-040/fix-R1/tests/TimerWrenchRegressionTest.java")) @('com.ericchiu.simplerail.item.WrenchHooksTest','com.ericchiu.simplerail.item.TimerWrenchRegressionTest')
Suite 'dispenser-investigation' @("$e/T-043/fixture/evidence/t043/DispenserSourceModel.java","$e/T-043/tests/evidence/t043/DispenserSourceModelTest.java") @('evidence.t043.DispenserSourceModelTest')
Suite 'dispenser-scan' @("$product/block/TrainDispenserScan.java","$e/T-045/tests/TrainDispenserScanTest.java") @('evidence.t045.TrainDispenserScanTest')
# Compile all production Java against the fixed real API; do not execute it.
$sources=@(Get-ChildItem (Join-Path $root 'src/main/java') -Recurse -File -Filter '*.java' | ForEach-Object {$_.FullName})
$mixin=Join-Path $root 'docs/evidence/T-030/fix-R1/isolated-tests/lib/mixin.jar'
Suite 'real-api' $sources @() ($cp+@($mixin))
[IO.File]::WriteAllText((Join-Path $out 'test-inputs.json'),($inputs | Sort-Object path -Unique | ConvertTo-Json -Depth 5),$utf8)
