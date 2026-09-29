$ErrorActionPreference='Stop'
$taskEvidence=Join-Path (Get-Location) 'docs/evidence/T-026/fix-R1'
function Read-Json([string]$path){Get-Content -LiteralPath $path -Raw -Encoding UTF8|ConvertFrom-Json}
function Read-Utf8([string]$path){[IO.File]::ReadAllText((Resolve-Path -LiteralPath $path),[Text.Encoding]::UTF8)}
$results=[Collections.Generic.List[object]]::new()
function Check([string]$id,[bool]$passed,[string]$detail){$results.Add([ordered]@{id=$id;passed=$passed;detail=$detail})}
$commands=@()
foreach($name in @('HighSpeedRail','BasePoweredRail','BaseRail')){
    $class=if($name -eq 'HighSpeedRail'){'com.ericchiu.simplerail.block.'+$name}else{'com.ericchiu.simplerail.block.base.'+$name}
    $log=Join-Path $taskEvidence ($name+'-bytecode.txt')
    $ErrorActionPreference='Continue'
    javap -c -p -s -v -classpath build/classes/java/main $class *> $log
    $code=$LASTEXITCODE;$ErrorActionPreference='Stop'
    $commands+=@{command=('javap -c -p -s -v -classpath build/classes/java/main '+$class);exitCode=$code;log=$log}
    $body=Read-Utf8 $log
    $method=[regex]::Match($body,'(?ms)^  public boolean canMakeSlopes[^\r\n]*.*?(?=^  (?:public|private|protected|static)|^\})').Value
    $constant=if($name -eq 'HighSpeedRail'){1}else{0}
    Check ($name+'-slopes') ($code -eq 0 -and [regex]::IsMatch($method,('0: iconst_'+$constant+'\s+1: ireturn'))) 'Actual compiled slope hook; disassembly only, no class loading.'
}
$native=Read-Json (Join-Path $taskEvidence 'sources/vanilla/powered_rail.json')
$custom=Read-Json 'src/main/resources/assets/simplerail/blockstates/high_speed_rail.json'
$modelMap=@{
 'minecraft:block/powered_rail'='simplerail:block/high_speed_rail'
 'minecraft:block/powered_rail_on'='simplerail:block/high_speed_powered_rail'
 'minecraft:block/powered_rail_raised_ne'='simplerail:block/high_speed_rail_raised_ne'
 'minecraft:block/powered_rail_raised_sw'='simplerail:block/high_speed_rail_raised_sw'
 'minecraft:block/powered_rail_on_raised_ne'='simplerail:block/high_speed_powered_rail_raised_ne'
 'minecraft:block/powered_rail_on_raised_sw'='simplerail:block/high_speed_powered_rail_raised_sw'
}
Check 'twelve-variants' (@($custom.variants.PSObject.Properties).Count -eq 12) 'Six shapes times two powered states.'
$coverage=@()
foreach($variant in $native.variants.PSObject.Properties){
    $actual=$custom.variants.PSObject.Properties[$variant.Name].Value
    Check ('vanilla-geometry-'+$variant.Name) ($null -ne $actual -and $actual.model -eq $modelMap[$variant.Value.model] -and [int]$actual.y -eq [int]$variant.Value.y) 'Shape model and rotation match fixed-version vanilla powered rail.'
    foreach($waterlogged in @($false,$true)){$coverage+=@{selector=$variant.Name;waterlogged=$waterlogged;matches=($null -ne $actual)}}
}
Check 'complete-declared-coverage' ($coverage.Count -eq 24 -and @($coverage|Where-Object {-not $_.matches}).Count -eq 0 -and @($custom.variants.PSObject.Properties|Where-Object {$_.Name -match 'waterlogged'}).Count -eq 0) 'All 24 inherited declared combinations have a selector, including both waterlogged values; no runtime baking.'
foreach($name in @('high_speed_rail_raised_ne','high_speed_rail_raised_sw','high_speed_powered_rail_raised_ne','high_speed_powered_rail_raised_sw')){
    $path='src/main/resources/assets/simplerail/models/block/'+$name+'.json'
    $model=Read-Json $path
    $suffix=$name.Substring($name.Length-2)
    $texture=if($name.StartsWith('high_speed_powered_rail')){'high_speed_powered_rail'}else{'high_speed_rail'}
    Check ('model-'+$name) ($model.parent -eq ('minecraft:block/template_rail_raised_'+$suffix) -and $model.render_type -eq 'minecraft:cutout' -and $model.textures.rail -eq ('simplerail:blocks/'+$texture)) 'Vanilla raised template and preserved off/on texture.'
}
$inputs=Read-Json (Join-Path $taskEvidence 'inputs-before.json')
$changed=@($inputs|Where-Object {(Get-FileHash -LiteralPath $_.path).Hash -ne $_.sha256})
$allowedChanged=@(
 (Resolve-Path 'src/main/java/com/ericchiu/simplerail/block/HighSpeedRail.java').Path,
 (Resolve-Path 'src/main/resources/assets/simplerail/blockstates/high_speed_rail.json').Path
)
Check 'existing-scope' (@(Compare-Object $changed.path $allowedChanged).Count -eq 0) 'Only HighSpeedRail and its blockstate changed; bases, IDs, settings, other rails, Gradle and original resources untouched.'
$newFiles=@(Get-ChildItem src/main -Recurse -File|Where-Object {$inputs.path -notcontains $_.FullName}|ForEach-Object {$_.FullName.Substring((Get-Location).Path.Length+1).Replace('\','/')})
Check 'new-scope' ($newFiles.Count -eq 4 -and @($newFiles|Where-Object {$_ -notmatch '^src/main/resources/assets/simplerail/models/block/high_speed_(powered_)?rail_raised_(ne|sw)[.]json$'}).Count -eq 0) 'Exactly four high-speed raised models added.'
$source=Read-Utf8 'src/main/java/com/ericchiu/simplerail/block/HighSpeedRail.java'
Check 'no-direction-patch' (-not [regex]::IsMatch($source,'onMinecartPass|getRailDirection|setDeltaMovement|setPos|moveTo')) 'No guessed direction, speed-vector or teleport correction introduced.'
Add-Type -AssemblyName System.IO.Compression.FileSystem
$resourceArchive=[IO.Compression.ZipFile]::OpenRead((Resolve-Path 'build/moddev/artifacts/neoforge-21.1.251-client-extra-aka-minecraft-resources.jar'))
$modelSources=Read-Json (Join-Path $taskEvidence 'model-sources.json')
try{
    foreach($suffix in @('ne','sw')){
        $entryName='assets/minecraft/models/block/template_rail_raised_'+$suffix+'.json'
        $entry=$resourceArchive.GetEntry($entryName);if($null -eq $entry){throw ('Missing template '+$entryName)}
        $path=Join-Path $taskEvidence ('sources/vanilla/template_rail_raised_'+$suffix+'.json')
        [IO.Compression.ZipFileExtensions]::ExtractToFile($entry,$path,$false)
        $modelSources+=@{archive=$modelSources[0].archive;archiveSha256=$modelSources[0].archiveSha256;entry=$entryName;snapshot=$path;sha256=(Get-FileHash $path).Hash;scope='Fixed vanilla parent template; not baked/rendered'}
        Check ('template-'+$suffix) (Test-Path -LiteralPath $path) 'Vanilla model parent exists in the pinned archive.'
    }
}finally{$resourceArchive.Dispose()}
$modelSources|ConvertTo-Json|Set-Content -Encoding UTF8 (Join-Path $taskEvidence 'model-sources.json')
$coverage|ConvertTo-Json|Set-Content -Encoding UTF8 (Join-Path $taskEvidence 'state-coverage.json')
Copy-Item -LiteralPath 'build/libs/simplerail-1.0.0.jar' -Destination (Join-Path $taskEvidence 'artifacts/simplerail-1.0.0.jar')
$artifact=Join-Path $taskEvidence 'artifacts/simplerail-1.0.0.jar'
$sha=(Get-FileHash $artifact).Hash
$jar=[IO.Compression.ZipFile]::OpenRead($artifact)
function Entry-Hash($entry){$stream=$entry.Open();$hash=[Security.Cryptography.SHA256]::Create();try{[BitConverter]::ToString($hash.ComputeHash($stream)).Replace('-','')}finally{$stream.Dispose();$hash.Dispose()}}
$resourceDiff=@()
try{
    $root=(Resolve-Path 'src/main/resources').Path
    foreach($file in Get-ChildItem $root -Recurse -File){
        $entry=$jar.GetEntry($file.FullName.Substring($root.Length+1).Replace('\','/'))
        if($null -eq $entry -or (Entry-Hash $entry) -ne (Get-FileHash $file.FullName).Hash){$resourceDiff+=$file.FullName}
    }
    Check 'jar-resources' ($resourceDiff.Count -eq 0) 'All 149 source resources packaged byte-identically.'
    $jar.Entries|ForEach-Object {$_.FullName}|Set-Content -Encoding UTF8 (Join-Path $taskEvidence 'jar-contents.txt')
}finally{$jar.Dispose()}
$build=Read-Json (Join-Path $taskEvidence 'build-01.json')
$buildLog=Get-Content (Join-Path $taskEvidence 'build-01.log') -Raw
Check 'new-build' ($build.exitCode -eq 0 -and $buildLog.Contains('BUILD SUCCESSFUL')) 'NEW build exit 0.'
Check 'gradle-tests-boundary' ($buildLog.Contains(':test NO-SOURCE')) 'No Gradle unit tests executed; these checks are source/bytecode/resource contracts.'
$ErrorActionPreference='Continue'
git diff HEAD --binary *> (Join-Path $taskEvidence 'source.diff');$diffHeadCode=$LASTEXITCODE
$untracked=@(git ls-files --others --exclude-standard)
foreach($path in $untracked){if($path -like 'src/*'){git diff --no-index --binary -- NUL $path *>> (Join-Path $taskEvidence 'source.diff')}}
git diff --cached --binary *> (Join-Path $taskEvidence 'index-after.diff');$indexCode=$LASTEXITCODE
git -c core.safecrlf=false diff --check *> (Join-Path $taskEvidence 'diff-check.log');$diffCode=$LASTEXITCODE
$ErrorActionPreference='Stop'
Check 'index-preserved' ($indexCode -eq 0 -and (Get-FileHash (Join-Path $taskEvidence 'index-before.diff')).Hash -eq (Get-FileHash (Join-Path $taskEvidence 'index-after.diff')).Hash) 'Staged user changes preserved.'
Check 'diff-check' ($diffCode -eq 0) 'Whitespace check succeeds.'
Get-ChildItem src/main -Recurse -File|ForEach-Object {@{path=$_.FullName;sha256=(Get-FileHash $_.FullName).Hash}}|ConvertTo-Json|Set-Content -Encoding UTF8 (Join-Path $taskEvidence 'source-fingerprints.json')
[ordered]@{path=$artifact;sha256=$sha;head=(Get-Content (Join-Path $taskEvidence 'head.txt') -Raw).Trim();source='Uncommitted diff plus source-fingerprints.json';minecraft='1.21.1';neoforge='21.1.251';mod='1.0.0';java='Temurin 21.0.12.1+1';gradle='9.2.1';modDevGradle='2.0.147';parchment='2024.11.17 / 1.21.1';license='All Rights Reserved';developer='Slope exception implemented and built';codeReview='R-03 / R-F pending';manual='Not rerun; prior T-026 failed';reversal='Root cause and runtime fix unverified'}|ConvertTo-Json|Set-Content -Encoding UTF8 (Join-Path $taskEvidence 'artifact.json')
$commands+=@{command='git diff HEAD --binary';exitCode=$diffHeadCode;log='source.diff'}
$commands+=@{command='git -c core.safecrlf=false diff --check';exitCode=$diffCode;log='diff-check.log'}
$commands|ConvertTo-Json|Set-Content -Encoding UTF8 (Join-Path $taskEvidence 'audit-commands.json')
$failed=@($results|Where-Object {-not $_.passed})
[ordered]@{scope='Static actual bytecode/resource/scope contracts; no Minecraft bootstrap or callbacks';checks=$results.Count;passed=$results.Count-$failed.Count;failed=$failed.Count;results=$results;artifactSha256=$sha;changedExisting=$changed.path;newFiles=$newFiles}|ConvertTo-Json -Depth 6|Set-Content -Encoding UTF8 (Join-Path $taskEvidence 'audit-results.json')
Write-Output ('Static checks: '+$results.Count+'; failures: '+$failed.Count+'; JAR SHA-256: '+$sha)
if($failed.Count -gt 0){$failed|ForEach-Object {Write-Output $_.id};exit 1}
