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
    [IO.File]::WriteAllText((Join-Path $out 'artifact-commands.json'),($records|ConvertTo-Json -Depth 7),$utf8)
    Write-Output ($name+': '+$p.ExitCode)
    if($p.ExitCode -ne 0){throw ($name+' failed')}
}
function Inputs([string[]]$paths) { foreach($path in $paths){$inputs.Add([pscustomobject]@{path=$path;sha256=(Get-FileHash -LiteralPath $path).Hash})} }
Add-Type -AssemblyName System.IO.Compression.FileSystem
$checks=[Collections.Generic.List[object]]::new()
function Check([string]$name,[bool]$ok){$checks.Add([pscustomobject]@{name=$name;pass=$ok})}
function EntryHash($entry){$stream=$entry.Open();$sha=[Security.Cryptography.SHA256]::Create();try{return [BitConverter]::ToString($sha.ComputeHash($stream)).Replace('-','')}finally{$stream.Dispose();$sha.Dispose()}}
$artifacts=@(
    @('docs/evidence/T-037/artifacts/simplerail-1.0.0-T037-probe.jar','AAF9977E094981A481305DCDCF6C60694931FFD3483A29C9A6A5B31BB10415C7'),
    @('docs/evidence/T-038/artifacts/simplerail-1.0.0.jar','EABD253F9EA50B58B62A5311D2B7289F22AA1DEECADF9059FFF76A736DEAE21B'),
    @('docs/test-packages/T-040-R1/mods/simplerail-1.0.0.jar','E1C79C838055CEF0955E8B0CF46991DA51F24BBDDCA4FE2A1DA6C6891588EF39'),
    @('docs/test-packages/T-043-v1/mods/simplerail-1.0.0-T043-probe.jar','4026BB07B15FA97179ABADDB211CAADD20FC69B752ADCA9665D07CA91B07E41A'),
    @('docs/evidence/T-044/artifacts/simplerail-1.0.0.jar','9B0107CA2DA90AA98946E12DB51A6508E7A927479A6F50D6305B1BA2E288C35A'),
    @('docs/evidence/T-045/artifacts/simplerail-1.0.0.jar','61B933A80F9B984E9AF35D7E55713803DF36328371D6B08CC02A63ADCEDA6C1E')
)
foreach($a in $artifacts){Check ('fixed-artifact '+$a[0]) ((Get-FileHash -LiteralPath (Join-Path $root $a[0])).Hash -eq $a[1])}
$jar=Join-Path $root $artifacts[-1][0]
Check 'build/libs matches final archived product' ((Get-FileHash (Join-Path $root 'build/libs/simplerail-1.0.0.jar')).Hash -eq $artifacts[-1][1])
$zip=[IO.Compression.ZipFile]::OpenRead($jar)
try {
    $classes=@($zip.Entries | Where-Object {$_.FullName.EndsWith('.class')} | ForEach-Object {$_.FullName.Replace('/','.').Replace('.class','')} | Sort-Object)
    Check 'no diagnostic or test classes in final product' (@($classes | Where-Object {$_ -match '^evidence\.|Test|Probe'}).Count -eq 0)
    $compiled=Join-Path $out 'real-api/classes'
    Run 'source-bytecode' 'javap' (@('-p','-c','-classpath',$compiled)+$classes)
    Run 'jar-bytecode' 'javap' (@('-p','-c','-classpath',$jar)+$classes)
    $sourceCode=[IO.File]::ReadAllText((Join-Path $out 'source-bytecode.log'))
    $jarCode=[IO.File]::ReadAllText((Join-Path $out 'jar-bytecode.log'))
    Check 'all packaged class disassemblies match freshly compiled current sources' ($sourceCode -eq $jarCode)
    foreach($file in Get-ChildItem (Join-Path $root 'src/main/resources') -File -Recurse){
        $key=$file.FullName.Substring((Join-Path $root 'src/main/resources').Length+1).Replace('\','/')
        $entry=$zip.GetEntry($key)
        Check ('packaged resource '+$key) ($null -ne $entry -and (EntryHash $entry) -eq (Get-FileHash $file.FullName).Hash)
    }
} finally {$zip.Dispose()}
$apiPath=Join-Path $root 'build/moddev/artifacts/neoforge-21.1.251-sources.jar'
Check 'fixed API source archive' ((Get-FileHash $apiPath).Hash -eq '236151EDEC930A89E78054FCB5551323761F801778305F290D0B74238C33693E')
$api=[IO.Compression.ZipFile]::OpenRead($apiPath)
$apiEntries=[Collections.Generic.List[object]]::new()
try{
    $names=@('server/level/ChunkMap','server/level/ServerLevel','server/level/ServerPlayer','world/level/Level','world/level/block/DispenserBlock','world/level/block/entity/BaseContainerBlockEntity','world/level/block/entity/BlockEntity','world/inventory/ChestMenu','world/inventory/AbstractContainerMenu','client/gui/screens/MenuScreens','world/ContainerHelper','world/Containers','world/ticks/SavedTick','world/ticks/LevelChunkTicks','world/ticks/LevelTicks','world/level/chunk/storage/ChunkSerializer')
    foreach($name in $names){
        $key='net/minecraft/'+$name+'.java';$entry=$api.GetEntry($key)
        $dest=Join-Path $out ('api/'+$key);New-Item -ItemType Directory -Force (Split-Path $dest) | Out-Null
        $reader=[IO.StreamReader]::new($entry.Open());try{$content=$reader.ReadToEnd()}finally{$reader.Dispose()}
        [IO.File]::WriteAllText($dest,$content,$utf8)
        $apiEntries.Add([pscustomobject]@{entry=$key;sha256=(EntryHash $entry)})
    }
}finally{$api.Dispose()}
$chunk=[IO.File]::ReadAllText((Join-Path $out 'api/net/minecraft/server/level/ChunkMap.java'))
Check 'unload event precedes final chunk save' ($chunk -match '(?s)ChunkEvent\.Unload\(chunkaccess\).*?this\.save\(chunkaccess\);.*?this\.level\.unload\(levelchunk1\)')
Check 'chunk save skips clean chunks' ($chunk -match 'if \(!chunk.isUnsaved\(\)\)')
$reg=[IO.File]::ReadAllText((Join-Path $root 'src/main/java/com/ericchiu/simplerail/registry/ModBlockEntities.java'))
Check 'unload freezes every timer and dirties event chunk' ($reg -match 'changed \|= timer.pauseForUnload\(\)' -and $reg -match 'chunk.setUnsaved\(true\)' -and $reg -match 'event.getChunk\(\) instanceof LevelChunk chunk' -and $reg -notmatch '(level|Level\(\))\.getChunk\(')
foreach($id in @('timer_holding_rail','signal_timer','train_dispenser')){Check ('BE registry '+$id) ($reg -match ('TYPES.register\(\s*"'+$id+'"'))}
$variants=(Get-Content -Raw -Encoding UTF8 (Join-Path $root 'src/main/resources/assets/simplerail/blockstates/train_dispenser.json') | ConvertFrom-Json).variants
foreach($dir in @('north','south','east','west')){foreach($trigger in @('true','false')){Check ('dispenser model '+$dir+' '+$trigger) ($null -ne $variants.PSObject.Properties["facing=$dir,triggered=$trigger"])}}
foreach($task in @('T-037','T-043')){
    $results=Get-Content -Raw -Encoding UTF8 (Join-Path $root ('docs/test-packages/'+$task+'-v1/results.json')) | ConvertFrom-Json
    $raw=Get-Content -Raw -Encoding UTF8 (Join-Path $root ('docs/test-packages/'+$task+'-v1/results.json'))
    Check ('original diagnostic results remain blank '+$task) ($raw -match '"actual"\s*:\s*null' -and $raw -notmatch '"actual"\s*:\s*[^n\s]')
}
$commands=Get-Content -Raw -Encoding UTF8 (Join-Path $out 'commands.json') | ConvertFrom-Json
Check 'all independent compiles and JVM runs exit zero' (@($commands | Where-Object {$_.exitCode -ne 0}).Count -eq 0 -and $commands.Count -eq 16)
$result=[ordered]@{result=if(@($checks | Where-Object {!$_.pass}).Count){'FAIL'}else{'PASS'};checks=$checks;productClassCount=$classes.Count;sourceCount=@(Get-ChildItem (Join-Path $root 'src/main/java') -Recurse -Filter '*.java').Count;apiArchive=$apiPath;apiEntries=$apiEntries;artifacts=$artifacts;gameExecuted=$false}
[IO.File]::WriteAllText((Join-Path $out 'checks.json'),($result | ConvertTo-Json -Depth 8),$utf8)
Write-Output ('Checks='+$checks.Count+' result='+$result.result+' productClasses='+$classes.Count)
if($result.result -eq 'FAIL'){$checks | Where-Object {!$_.pass};exit 1}
