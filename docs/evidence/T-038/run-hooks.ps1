param([int]$Attempt=1)
$ErrorActionPreference='Stop'
$root=(Get-Location).Path
$ev=Join-Path $root 'docs/evidence/T-038'
$jdk='C:/Program Files/Eclipse Adoptium/jdk-21.0.12.101-hotspot/bin'
$out=Join-Path $ev ('isolated-tests/classes-{0:D2}' -f $Attempt)
[IO.Directory]::CreateDirectory($out)|Out-Null
$cp=(Get-Content (Join-Path $ev 'compile-classpath.txt')|Where-Object{$_}) -join ';'
$sources=@(Get-ChildItem (Join-Path $ev 'isolated-tests/stubs') -Recurse -File -Filter '*.java'|ForEach-Object{$_.FullName})
$stubCount=$sources.Count
$sources+=(Join-Path $ev 'isolated-tests/TimerRailHooksTest.java')
$sources+=@('src/main/java/com/ericchiu/simplerail/block/TimerHoldingRail.java','src/main/java/com/ericchiu/simplerail/blockentity/TimerHoldingRailBlockEntity.java','src/main/java/com/ericchiu/simplerail/blockentity/HoldingTimer.java','src/main/java/com/ericchiu/simplerail/blockentity/HoldingTimerData.java')|ForEach-Object{Join-Path $root $_}
$argsList=@('-encoding','UTF-8','-proc:none','-Xlint:deprecation','-Werror','--release','21','-classpath',$cp,'-d',$out)+$sources
$argPath=Join-Path $ev ('hooks-compile-{0:D2}.args' -f $Attempt)
$argsList | ForEach-Object {'"'+$_.Replace('\','/').Replace('"','\"')+'"'} | Set-Content $argPath -Encoding UTF8
# Java argfiles do not accept an initial UTF-8 BOM.
$text=[IO.File]::ReadAllText($argPath,[Text.Encoding]::UTF8)
[IO.File]::WriteAllText($argPath,$text,[Text.UTF8Encoding]::new($false))
$ErrorActionPreference='Continue'
& "$jdk/javac.exe" "@$argPath" *> (Join-Path $ev ('hooks-compile-{0:D2}.log' -f $Attempt))
$compile=$LASTEXITCODE
$run=$null
if($compile -eq 0) {
 Push-Location $ev
 try { & "$jdk/java.exe" -cp ($out+';'+$cp) com.ericchiu.simplerail.blockentity.TimerRailHooksTest *> ('hooks-test-{0:D2}.log' -f $Attempt);$run=$LASTEXITCODE }finally{Pop-Location}
}
$ErrorActionPreference='Stop'
[ordered]@{compileCommand="$jdk/javac.exe @$argPath";compileExitCode=$compile;runCommand="$jdk/java.exe -cp <isolated classes first; fixed NEW dependencies> com.ericchiu.simplerail.blockentity.TimerRailHooksTest";runExitCode=$run;stubCount=$stubCount;actualProductionSourceCount=4;actualNewNbt=$false;gameRuntime=$false;scope='Isolated rail/BE call-flow with labelled Minecraft/NBT doubles; actual NEW NBT is independently covered by Gradle testT038'}|ConvertTo-Json|Set-Content (Join-Path $ev ('hooks-{0:D2}.json' -f $Attempt)) -Encoding UTF8
if($compile -ne 0){Get-Content (Join-Path $ev ('hooks-compile-{0:D2}.log' -f $Attempt));exit $compile}
Get-Content (Join-Path $ev ('hooks-test-{0:D2}.log' -f $Attempt))
exit $run
