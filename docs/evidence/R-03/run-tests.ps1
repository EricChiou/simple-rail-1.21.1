$ErrorActionPreference='Stop'
$root=(Get-Location).Path
$out=Join-Path $root 'docs/evidence/R-03'
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
$jobs=@(
    @{id='holding';task='T-027';product='block/HoldingRail.java';tests=@('HoldingRailHooksTest');package='block'},
    @{id='oneway';task='T-030/fix-R1';product='block/OnewayRail.java';tests=@('OnewayRailHooksTest','CoastingRegressionTest');package='block'},
    @{id='eject';task='T-031';product='block/EjectRail.java';tests=@('EjectRailHooksTest');package='block'},
    @{id='destory';task='T-033';product='block/DestoryRail.java';tests=@('DestoryRailHooksTest');package='block'},
    @{id='wrench';task='T-035';product='item/Wrench.java';tests=@('WrenchHooksTest');package='item'}
)
$mixin=Join-Path $root 'docs/evidence/T-030/fix-R1/isolated-tests/lib/mixin.jar'
foreach($job in $jobs){
    $e=Join-Path $root ('docs/evidence/'+$job.task)
    $classes=Join-Path $out ($job.id+'/classes')
    New-Item -ItemType Directory -Force $classes|Out-Null
    $files=@(Get-ChildItem -File -Recurse ($e+'/isolated-tests/stubs') -Filter '*.java'|ForEach-Object {$_.FullName})
    $files+=Join-Path $root ('src/main/java/com/ericchiu/simplerail/'+$job.product)
    $classpath=$classes
    if($job.id -eq 'oneway'){$files+=Join-Path $root 'src/main/java/com/ericchiu/simplerail/mixin/AbstractMinecartMixin.java';$classpath+=';'+$mixin}
    foreach($test in $job.tests){$files+=$e+'/'+$test+'.java'}
    Inputs $files
    Run ($job.id+'-compile') 'javac' (@('--release','21','-proc:none','-encoding','UTF-8','-Xlint:unchecked','-Werror','-cp',$classpath,'-d',$classes)+$files)
    foreach($test in $job.tests){Run ($job.id+'-'+$test) 'java' @('-ea','-cp',$classpath,('com.ericchiu.simplerail.'+$job.package+'.'+$test))}
}
$numeric=Join-Path $out 'numeric/classes'
New-Item -ItemType Directory -Force $numeric|Out-Null
$numericFiles=@((Join-Path $root 'src/main/java/com/ericchiu/simplerail/block/RailAscentMovementLimit.java'),(Join-Path $root 'docs/evidence/T-026/fix-R2/AscentBoundaryTest.java'))
Inputs $numericFiles
Run 'numeric-compile' 'javac' (@('--release','21','-proc:none','-encoding','UTF-8','-d',$numeric)+$numericFiles)
Run 'numeric-run' 'java' @('-ea','-cp',$numeric,'com.ericchiu.simplerail.block.AscentBoundaryTest')
$audit=Join-Path $out 'audit/classes'
New-Item -ItemType Directory -Force $audit|Out-Null
$asm=@((Join-Path $root 'docs/evidence/T-030/fix-R1/isolated-tests/lib/asm.jar'),(Join-Path $root 'docs/evidence/T-030/fix-R1/isolated-tests/lib/asm-tree.jar'))
$auditSource=Join-Path $root 'docs/evidence/T-030/fix-R1/InjectionTargetAudit.java'
$target=Join-Path $root 'build/moddev/artifacts/neoforge-21.1.251.jar'
$product=Join-Path $root 'docs/evidence/T-030/fix-R1/artifacts/simplerail-1.0.0.jar'
Inputs ($asm+@($auditSource,$target,$product,$mixin))
Run 'mixin-audit-compile' 'javac' @('--release','21','-proc:none','-encoding','UTF-8','-cp',($asm -join ';'),'-d',$audit,$auditSource)
Run 'mixin-audit-run' 'java' @('-cp',((@($audit)+$asm) -join ';'),'InjectionTargetAudit',$target,$product)
# Compile all current product sources against the real fixed API; never execute those classes.
$real=Join-Path $out 'real-api/classes'
New-Item -ItemType Directory -Force $real|Out-Null
$dependencies=@(Get-Content -Encoding UTF8 (Join-Path $root 'docs/evidence/T-008/compile-classpath.txt')|Where-Object {$_.Trim()})+@($mixin)
$sources=@(Get-ChildItem -Recurse -File (Join-Path $root 'src/main/java') -Filter '*.java'|ForEach-Object {$_.FullName})
Inputs ($dependencies+$sources)
Run 'real-api-compile' 'javac' (@('--release','21','-proc:none','-encoding','UTF-8','-cp',($dependencies -join ';'),'-d',$real)+$sources)
[IO.File]::WriteAllText((Join-Path $out 'test-inputs.json'),($inputs|Sort-Object path -Unique|ConvertTo-Json -Depth 5),$utf8)
