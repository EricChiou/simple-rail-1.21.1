$ErrorActionPreference='Stop'
$root=(Get-Location).Path
$out=Join-Path $root 'docs/evidence/T-057/performance-review-2026-10-03'
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
$classes=Join-Path $out 'classes'
New-Item -ItemType Directory -Force $classes | Out-Null
$files=@(
    (Join-Path $root 'src/main/java/com/ericchiu/simplerail/entity/TrainFormation.java'),
    (Join-Path $root 'src/main/java/com/ericchiu/simplerail/entity/TrainBlockRoute.java'),
    (Join-Path $root 'src/main/java/com/ericchiu/simplerail/entity/Facing8.java'),
    (Join-Path $root 'docs/evidence/T-048-055/TrainFormationTest.java'),
    (Join-Path $root 'docs/evidence/T-058/fix-R7/BlockRouteSpacingTest.java'),
    (Join-Path $out 'PerformanceProbe.java')
)
Inputs $files
Run 'compile' 'javac' (@('--release','21','-proc:none','-encoding','UTF-8','-d',$classes)+$files)
Run 'formation-regression' 'java' @('-ea','-cp',$classes,'TrainFormationTest')
Run 'route-regression' 'java' @('-ea','-cp',$classes,'BlockRouteSpacingTest')
Run 'deterministic' 'java' @('-ea','-cp',$classes,'PerformanceProbe')
foreach($fork in 1..3){Run ('timing-fork-'+$fork) 'java' @('-Xms256m','-Xmx256m','-ea','-cp',$classes,'PerformanceProbe','timing')}
[IO.File]::WriteAllText((Join-Path $out 'test-inputs.json'),($inputs | ConvertTo-Json -Depth 5),$utf8)
