param([int]$Attempt=1)
$ErrorActionPreference='Stop'
$e=Join-Path (Get-Location) 'docs/evidence/T-030/fix-R1'
$root=$e+'/isolated-tests'
$jdk='C:/Program Files/Eclipse Adoptium/jdk-21.0.12.101-hotspot/bin'
$mixin=$root+'/lib/mixin.jar'
New-Item -ItemType Directory -Force ($root+'/classes')|Out-Null
$doubles=@(Get-ChildItem ($root+'/stubs') -Recurse -Filter '*.java'|ForEach-Object {$_.FullName})
$files=$doubles+@((Join-Path (Get-Location) 'src/main/java/com/ericchiu/simplerail/block/OnewayRail.java'),(Join-Path (Get-Location) 'src/main/java/com/ericchiu/simplerail/mixin/AbstractMinecartMixin.java'),($e+'/OnewayRailHooksTest.java'),($e+'/CoastingRegressionTest.java'))
$start=[DateTime]::UtcNow.ToString('o')
$ErrorActionPreference='Continue'
& ($jdk+'/javac.exe') --release 21 -proc:none -encoding UTF-8 -Xlint:unchecked -Werror -cp $mixin -d ($root+'/classes') $files *> ($e+('/hooks-compile-{0:d2}.log' -f $Attempt));$compileCode=$LASTEXITCODE
$runCodes=@();if($compileCode -eq 0){foreach($test in @('OnewayRailHooksTest','CoastingRegressionTest')){& ($jdk+'/java.exe') -cp (($root+'/classes')+';'+$mixin) ('com.ericchiu.simplerail.block.'+$test) *> ($e+'/'+$test+('-{0:d2}.log' -f $Attempt));$runCodes+=$LASTEXITCODE;Get-Content ($e+'/'+$test+('-{0:d2}.log' -f $Attempt))}}
$ErrorActionPreference='Stop'
[ordered]@{command='powershell -NoProfile -ExecutionPolicy Bypass -File docs/evidence/T-030/fix-R1/hooks-test.ps1';compileCommand='Temurin 21 javac --release 21 -proc:none -encoding UTF-8 -Xlint:unchecked -Werror -cp [existing Mixin 0.8.7 jar] -d [isolated classes] [explicit doubles + actual OnewayRail.java + actual AbstractMinecartMixin.java + two tests]';testDoubleCount=$doubles.Count;compileExitCode=$compileCode;runCommands=@('Temurin 21 java -cp [isolated classes;Mixin jar] com.ericchiu.simplerail.block.OnewayRailHooksTest','Temurin 21 java -cp [isolated classes;Mixin jar] com.ericchiu.simplerail.block.CoastingRegressionTest');runExitCodes=$runCodes;startedUtc=$start;finishedUtc=[DateTime]::UtcNow.ToString('o');scope='Real hook and redirect source against isolated doubles; no Minecraft runtime or Mixin weaving';gameExecuted=$false}|ConvertTo-Json -Depth 4|Set-Content -Encoding UTF8 ($e+'/hooks-test.json')
Get-Content ($e+('/hooks-compile-{0:d2}.log' -f $Attempt))
if($compileCode -ne 0 -or $runCodes.Count -ne 2 -or @($runCodes|Where-Object {$_ -ne 0}).Count){exit 1}
