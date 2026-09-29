$ErrorActionPreference = 'Stop'
$taskEvidence = Join-Path (Get-Location) 'docs/evidence/T-025'
function Read-Utf8([string]$path) { [IO.File]::ReadAllText((Resolve-Path -LiteralPath $path), [Text.Encoding]::UTF8) }
function Read-Json([string]$path) { Read-Utf8 $path | ConvertFrom-Json }
$checks = [Collections.Generic.List[object]]::new()
function Check([string]$id, [bool]$passed, [string]$detail) {
    $checks.Add([ordered]@{id=$id;passed=$passed;detail=$detail})
}
$classes = @(
    'com.ericchiu.simplerail.block.base.BaseRail',
    'com.ericchiu.simplerail.block.base.BasePoweredRail',
    'com.ericchiu.simplerail.block.HighSpeedRail',
    'com.ericchiu.simplerail.registry.ModBlocks'
)
$commands = [Collections.Generic.List[object]]::new()
$bytecode = @{}
foreach ($className in $classes) {
    $log = Join-Path $taskEvidence (($className.Split('.')[-1]) + '-bytecode.txt')
    $ErrorActionPreference = 'Continue'
    & javap -c -p -s -v -classpath build/classes/java/main $className *> $log
    $code = $LASTEXITCODE
    $ErrorActionPreference = 'Stop'
    $commands.Add([ordered]@{command=('javap -c -p -s -v -classpath build/classes/java/main ' + $className);exitCode=$code;log=$log;scope='Disassembly only, no class loading or Minecraft bootstrap'})
    $bytecode[$className.Split('.')[-1]] = Get-Content -LiteralPath $log -Raw
    Check ('javap-' + $className.Split('.')[-1]) ($code -eq 0) 'Compiled product class disassembled without loading it.'
}
function Method-Body([string]$text,[string]$name) {
    [regex]::Match($text, ('(?ms)^  public [^\r\n]* ' + $name + '\([^\r\n]*\);.*?(?=^  (?:public|protected|private|static)|^\})')).Value
}
foreach ($base in @('BaseRail','BasePoweredRail')) {
    $text=$bytecode[$base]
    $speed=Method-Body $text 'getRailMaxSpeed'
    Check ($base+'-speed-snapshot') ([regex]::Matches($speed,'CommonConfig[.]current:').Count -eq 1 -and $speed.Contains('Snapshot.railMaxSpeed:()D') -and $speed.Contains('d2f') -and $speed.Contains('freturn')) 'Every speed query reads exactly one current config snapshot and returns its double value as float.'
    Check ($base+'-no-speed-field') (-not [regex]::IsMatch($text,'(?m)^  (?:public|private|protected)[^\r\n]*(?:float|double|Snapshot) [^(\r\n]*;')) 'No cached speed or snapshot field in the base.'
    Check ($base+'-no-early-config') (-not [regex]::Match($text,'(?ms)^  static \{\};.*?(?=^\})').Value.Contains('CommonConfig')) 'Codec static initialization does not read unloaded config.'
    foreach ($hook in @('canMakeSlopes','canEntityDestroy')) {
        $body=Method-Body $text $hook
        Check ($base+'-'+$hook) ([regex]::IsMatch($body,'0: iconst_0\s+1: ireturn')) 'Compiled hook returns false; not a game behavior test.'
    }
    Check ($base+'-parent-state') (-not [regex]::IsMatch($text,'(?m)^  (?:public|protected) [^\r\n]* (?:createBlockStateDefinition|registerDefaultState|updateState|getStateForPlacement|isFlexibleRail|isValidRailShape|onMinecartPass)\(')) 'Vanilla shape domain, defaults, waterlogging, redstone and flexibility remain inherited.'
    Check ($base+'-java21') ($text.Contains('major version: 65')) 'Java 21 class file.'
}
Check 'powered-parent-true' ([regex]::IsMatch($bytecode.BasePoweredRail,'(?s)iconst_1\s+3: invokespecial[^\r\n]*PoweredRailBlock[.]"<init>":[^\r\n]*Properties;Z')) 'The two-argument powered constructor receives true, preserving OLD powered rather than activator behavior.'
Check 'highspeed-parent' ($bytecode.HighSpeedRail.Contains('extends com.ericchiu.simplerail.block.base.BasePoweredRail')) 'HighSpeedRail inherits all OLD behavior from the powered base.'
Check 'highspeed-no-special-hooks' (-not [regex]::IsMatch($bytecode.HighSpeedRail,'(?m)^  public [^\r\n]* (?:getRailMaxSpeed|canMakeSlopes|canEntityDestroy|onMinecartPass)\(')) 'No separate acceleration or callback policy added.'
Check 'highspeed-own-codec' ($bytecode.HighSpeedRail.Contains('REF_newInvokeSpecial com/ericchiu/simplerail/block/HighSpeedRail."<init>"') -and (Method-Body $bytecode.HighSpeedRail 'codec').Contains('Field CODEC:')) 'Subclass codec constructs HighSpeedRail rather than the shared base; codec not executed.'
$blocks=Read-Utf8 'src/main/java/com/ericchiu/simplerail/registry/ModBlocks.java'
$before=Read-Utf8 (Join-Path $taskEvidence 'before/ModBlocks.java')
$ids=@([regex]::Matches($blocks,'BLOCKS[.]register(?:SimpleBlock|Block)\("([^"]+)"')|ForEach-Object {$_.Groups[1].Value})
$oldIds=@([regex]::Matches($before,'BLOCKS[.]register(?:SimpleBlock|Block)\("([^"]+)"')|ForEach-Object {$_.Groups[1].Value})
Check 'block-ids' ($ids.Count -eq 11 -and ($ids -join ',') -eq ($oldIds -join ',')) 'All eleven block IDs and ordering preserved, including destory_rail.'
$otherLines=@($blocks -split '\r?\n'|Where-Object {$_ -match 'public static final DeferredBlock' -and $_ -notmatch 'HIGH_SPEED_RAIL'})
$oldOtherLines=@($before -split '\r?\n'|Where-Object {$_ -match 'public static final DeferredBlock' -and $_ -notmatch 'HIGH_SPEED_RAIL'})
Check 'other-blocks-untouched' ($otherLines.Count -eq 10 -and ($otherLines -join [Environment]::NewLine) -eq ($oldOtherLines -join [Environment]::NewLine)) 'Only high_speed_rail registration changed.'
Check 'highspeed-lazy-factory' ($blocks.Contains('BLOCKS.registerBlock("high_speed_rail", HighSpeedRail::new, railProperties())') -and -not $blocks.Contains('CommonConfig')) 'Deferred factory; registration does not read config.'
Check 'physical-properties' ($blocks.Contains('Properties.of().noCollission().strength(0.7F).sound(SoundType.METAL)') -and -not $blocks.Contains('requiresCorrectToolForDrops')) 'OLD collision/strength/sound retained; no new tool drop requirement.'
$tag=Read-Json 'src/main/resources/data/minecraft/tags/block/mineable/pickaxe.json'
Check 'pickaxe-tag' ($tag.replace -eq $false -and @($tag.values).Count -eq 1 -and $tag.values[0] -eq 'simplerail:high_speed_rail') 'Only the implemented high-speed rail appends to vanilla pickaxe classification.'
$inputs=Read-Json (Join-Path $taskEvidence 'inputs-before.json')
$changed=@($inputs|Where-Object {(Get-FileHash -LiteralPath $_.path -Algorithm SHA256).Hash -ne $_.sha256})
Check 'bounded-product-changes' ($changed.Count -eq 1 -and $changed[0].path.EndsWith('\registry\ModBlocks.java')) 'All pre-existing product/settings/resource files except ModBlocks are byte-identical.'
$allowedNew=@(
 'src/main/java/com/ericchiu/simplerail/block/base/BaseRail.java',
 'src/main/java/com/ericchiu/simplerail/block/base/BasePoweredRail.java',
 'src/main/java/com/ericchiu/simplerail/block/HighSpeedRail.java',
 'src/main/resources/data/minecraft/tags/block/mineable/pickaxe.json'
)
$newFiles=@(Get-ChildItem src/main -Recurse -File|Where-Object {$inputs.path -notcontains $_.FullName}|ForEach-Object {$_.FullName.Substring((Get-Location).Path.Length+1).Replace('\','/')})
Check 'bounded-new-files' (@(Compare-Object $newFiles $allowedNew).Count -eq 0) 'Exactly three rail classes and one scoped pickaxe tag were added.'
Add-Type -AssemblyName System.IO.Compression.FileSystem
$sourceJar=(Resolve-Path 'build/moddev/artifacts/neoforge-21.1.251-sources.jar').Path
$sourceArchive=[IO.Compression.ZipFile]::OpenRead($sourceJar)
$references=[Collections.Generic.List[object]]::new()
$sourceEntries=@(
 'net/minecraft/world/level/block/BaseRailBlock.java',
 'net/minecraft/world/level/block/RailBlock.java',
 'net/minecraft/world/level/block/PoweredRailBlock.java',
 'net/minecraft/world/level/block/RailState.java',
 'net/minecraft/world/level/block/state/properties/BlockStateProperties.java',
 'net/minecraft/world/entity/vehicle/AbstractMinecart.java',
 'net/neoforged/neoforge/common/extensions/IBaseRailBlockExtension.java',
 'net/neoforged/neoforge/common/extensions/IBlockExtension.java',
 'net/minecraft/world/item/PickaxeItem.java',
 'net/minecraft/world/item/DiggerItem.java'
)
try {
    foreach($entryName in $sourceEntries) {
        $entry=$sourceArchive.GetEntry($entryName)
        if($null -eq $entry){throw "Missing fixed-version source entry: $entryName"}
        $path=Join-Path $taskEvidence ('sources/target/'+$entryName)
        New-Item -ItemType Directory -Force -Path (Split-Path $path)|Out-Null
        [IO.Compression.ZipFileExtensions]::ExtractToFile($entry,$path,$true)
        $references.Add([ordered]@{origin=$sourceJar;originSha256=(Get-FileHash $sourceJar).Hash;entry=$entryName;snapshot=$path;sha256=(Get-FileHash $path).Hash;scope='Fixed 21.1.251 primary source; no runtime verification'})
    }
} finally {$sourceArchive.Dispose()}
foreach($name in @('block/base/BaseRail.java','block/base/BasePoweredRail.java','block/HighSpeedRail.java')) {
    $path=Join-Path 'D:/workspace/java/simple-rail/src/main/java/ericchiu/simplerail' $name
    $snapshot=Join-Path $taskEvidence ('sources/old/'+$name)
    New-Item -ItemType Directory -Force -Path (Split-Path $snapshot)|Out-Null
    Copy-Item -LiteralPath $path -Destination $snapshot
    $references.Add([ordered]@{origin=$path;snapshot=$snapshot;sha256=(Get-FileHash $snapshot).Hash;scope='OLD source inference only; OLD not run or rebuilt'})
}
$references|ConvertTo-Json -Depth 5|Set-Content -Encoding UTF8 (Join-Path $taskEvidence 'source-references.json')
$pickaxeSource=Read-Utf8 (Join-Path $taskEvidence 'sources/target/net/minecraft/world/item/PickaxeItem.java')
Check 'pickaxe-primary-source' ($pickaxeSource.Contains('BlockTags.MINEABLE_WITH_PICKAXE')) 'Fixed-version PickaxeItem selects the tag; actual mining performance remains untested.'
Copy-Item -LiteralPath 'build/libs/simplerail-1.0.0.jar' -Destination (Join-Path $taskEvidence 'artifacts/simplerail-1.0.0.jar')
$artifactPath=Join-Path $taskEvidence 'artifacts/simplerail-1.0.0.jar'
$artifactHash=(Get-FileHash $artifactPath -Algorithm SHA256).Hash
[ordered]@{path=$artifactPath;sha256=$artifactHash;head=(Get-Content (Join-Path $taskEvidence 'head.txt') -Raw).Trim();commitScope='Existing HEAD plus uncommitted source diff/fingerprints';minecraft='1.21.1';neoforge='21.1.251';mod='1.0.0';license='All Rights Reserved';java='Temurin 21.0.12.1+1';gradle='9.2.1';modDevGradle='2.0.147';parchment='2024.11.17 / 1.21.1';build='build-01.json';scope='T-025 build artifact; not a T-094 test package or runtime-approved release'}|ConvertTo-Json|Set-Content -Encoding UTF8 (Join-Path $taskEvidence 'artifact.json')
$jar=[IO.Compression.ZipFile]::OpenRead($artifactPath)
function Entry-Hash($entry) {
    $stream=$entry.Open();$sha=[Security.Cryptography.SHA256]::Create()
    try {[BitConverter]::ToString($sha.ComputeHash($stream)).Replace('-','')} finally {$stream.Dispose();$sha.Dispose()}
}
$resourceDifferences=@()
try {
    $root=(Resolve-Path 'src/main/resources').Path
    foreach($file in Get-ChildItem $root -Recurse -File) {
        $entryName=$file.FullName.Substring($root.Length+1).Replace('\','/')
        $entry=$jar.GetEntry($entryName)
        if($null -eq $entry -or (Entry-Hash $entry) -ne (Get-FileHash $file.FullName).Hash){$resourceDifferences+=$entryName}
    }
    $entries=@($jar.Entries|ForEach-Object {$_.FullName})
    $entries|Set-Content -Encoding UTF8 (Join-Path $taskEvidence 'jar-contents.txt')
    Check 'jar-resources' ($resourceDifferences.Count -eq 0) 'All 145 source resource files included byte-identically.'
    foreach($name in $classes) {Check ('jar-'+$name.Split('.')[-1]) ($entries -contains ($name.Replace('.','/')+'.class')) 'Compiled class is present in the frozen JAR.'}
    $reader=[IO.StreamReader]::new($jar.GetEntry('META-INF/neoforge.mods.toml').Open())
    try {$metadata=$reader.ReadToEnd()} finally {$reader.Dispose()}
    $metadata|Set-Content -Encoding UTF8 (Join-Path $taskEvidence 'neoforge.mods.toml')
    Check 'jar-metadata' ($metadata.Contains('modId="simplerail"') -and $metadata.Contains('version="1.0.0"') -and $metadata.Contains('license="All Rights Reserved"') -and $metadata.Contains('21.1.251') -and $metadata.Contains('[1.21.1]')) 'D8 metadata retained.'
} finally {$jar.Dispose()}
Get-ChildItem src/main -Recurse -File|ForEach-Object {[ordered]@{path=$_.FullName;sha256=(Get-FileHash $_.FullName).Hash}}|ConvertTo-Json|Set-Content -Encoding UTF8 (Join-Path $taskEvidence 'source-fingerprints.json')
$build=Read-Json (Join-Path $taskEvidence 'build-01.json')
$buildLog=Get-Content (Join-Path $taskEvidence 'build-01.log') -Raw
Check 'new-build' ($build.exitCode -eq 0 -and $buildLog.Contains('BUILD SUCCESSFUL')) 'Actual NEW build exit 0.'
Check 'no-gradle-tests' ($buildLog.Contains(':test NO-SOURCE')) 'No Gradle unit tests were run; do not report test coverage.'
$ErrorActionPreference='Continue'
git -c core.safecrlf=false diff --check *> (Join-Path $taskEvidence 'diff-check.log');$diffCode=$LASTEXITCODE
git diff --cached --binary *> (Join-Path $taskEvidence 'index-after.diff');$indexCode=$LASTEXITCODE
git diff HEAD --binary *> (Join-Path $taskEvidence 'source.diff');$diffHeadCode=$LASTEXITCODE
$untracked=@(git ls-files --others --exclude-standard)
foreach($path in $untracked) {if($path -like 'src/*'){git diff --no-index --binary -- NUL $path *>> (Join-Path $taskEvidence 'source.diff')}}
git diff --no-index -- (Join-Path $taskEvidence 'before/ModBlocks.java') 'src/main/java/com/ericchiu/simplerail/registry/ModBlocks.java' *> (Join-Path $taskEvidence 'T-025-registration.diff');$scopeDiffCode=$LASTEXITCODE
$ErrorActionPreference='Stop'
$commands.Add([ordered]@{command='git diff HEAD --binary (then append git diff --no-index --binary -- NUL <untracked source> per file)';exitCode=$diffHeadCode;untrackedDiffExitCode='1 means differences, expected';log='source.diff'})
$commands.Add([ordered]@{command='git diff --no-index -- before/ModBlocks.java src/main/java/com/ericchiu/simplerail/registry/ModBlocks.java';exitCode=$scopeDiffCode;meaning='1 means the expected T-025 registration difference';log='T-025-registration.diff'})
$commands.Add([ordered]@{command='git -c core.safecrlf=false diff --check';exitCode=$diffCode;log='diff-check.log'})
Check 'diff-check' ($diffCode -eq 0) 'Git reports no whitespace errors in tracked changes.'
Check 'index-unchanged' ($indexCode -eq 0 -and (Get-FileHash (Join-Path $taskEvidence 'index-before.diff')).Hash -eq (Get-FileHash (Join-Path $taskEvidence 'index-after.diff')).Hash) 'Existing staged changes were not altered.'
$commands|ConvertTo-Json -Depth 5|Set-Content -Encoding UTF8 (Join-Path $taskEvidence 'audit-commands-01.json')
$failed=@($checks|Where-Object {-not $_.passed})
[ordered]@{scope='Product bytecode/source/JAR static contracts only; no callbacks, codec, game or OLD runtime executed';checks=$checks.Count;passed=$checks.Count-$failed.Count;failed=$failed.Count;results=$checks;artifactSha256=$artifactHash;newProductFiles=$newFiles;changedExistingProductFiles=$changed.path;resourceDifferences=$resourceDifferences}|ConvertTo-Json -Depth 7|Set-Content -Encoding UTF8 (Join-Path $taskEvidence 'audit-results-01.json')
Write-Output ('Static contracts: '+$checks.Count+'; failed: '+$failed.Count+'; JAR SHA-256: '+$artifactHash)
foreach($item in $failed){Write-Output ($item.id+': '+$item.detail)}
if($failed.Count -gt 0){exit 1}
