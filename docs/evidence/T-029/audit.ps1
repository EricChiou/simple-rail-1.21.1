$ErrorActionPreference='Stop'
$e=Join-Path (Get-Location) 'docs/evidence/T-029'
$checks=@();function Check([string]$name,[bool]$pass){$script:checks += [ordered]@{name=$name;pass=$pass}}
$before=Get-Content -Raw -Encoding UTF8 ($e+'/inputs-before.json')|ConvertFrom-Json
$changed=@($before|Where-Object {(Get-FileHash -LiteralPath $_.path).Hash -ne $_.sha256})
$allowed=@('src/main/java/com/ericchiu/simplerail/registry/ModBlocks.java','src/main/resources/data/minecraft/tags/block/mineable/pickaxe.json')|ForEach-Object {(Join-Path (Get-Location) $_).Replace('/','\')}
Check 'Exactly registry and pickaxe tag changed' ($changed.Count -eq 2 -and @($changed|Where-Object {$allowed -notcontains $_.path}).Count -eq 0)
$new=@(Get-ChildItem src -Recurse -File|Where-Object {$before.path -notcontains $_.FullName})
Check 'Only OnewayRail production file added' ($new.Count -eq 1 -and $new[0].Name -eq 'OnewayRail.java')
$rail=Get-Content -Raw -Encoding UTF8 src/main/java/com/ericchiu/simplerail/block/OnewayRail.java
foreach($name in @('reverse','need_power','use_power')){Check ('Boolean state name '+$name) ($rail.Contains('BooleanProperty.create("'+$name+'")'))}
$constructor=[regex]::Match($rail,'(?s)public OnewayRail\(.*?\n    }').Value
Check 'Constructor/defaults never read config' ($constructor -notmatch 'CommonConfig.current|Config\.get' -and $constructor.Contains('.setValue(NEED_POWER, true).setValue(USE_POWER, false)'))
Check 'Inherited default state retained' ($constructor.Contains('defaultBlockState().setValue(REVERSE, false)'))
Check 'Server guard before callback config read' ($rail.IndexOf('if (level.isClientSide)') -lt $rail.IndexOf('CommonConfig.Snapshot config = CommonConfig.current()'))
Check 'Source-compatible active condition' ($rail.Contains('config.onewayUsePowerChangeDirection()') -and $rail.Contains('|| state.getValue(POWERED) || !config.onewayNeedPower()'))
Check 'Pass uses config snapshot, not stored display flags' ([regex]::Match($rail,'(?s)public void onMinecartPass.*?(?=    @Override)').Value -notmatch 'getValue\(NEED_POWER\)|getValue\(USE_POWER\)')
Check 'Passive branch multiplies all axes by 1.2' ($rail.Contains('multiply(1.2D, 1.2D, 1.2D)'))
Check 'Placement projects only newly placed server block' ($rail.Contains('if (!level.isClientSide && !oldState.is(this))') -and $rail.Contains('super.onPlace(state, level, pos, oldState, moving)'))
Check 'No cache/BE/NBT/event/mixin/teleport added' ($rail -notmatch 'Map<|BlockEntity|CompoundTag|SubscribeEvent|Mixin|moveTo\(|setPos\(')
$reg=Get-Content -Raw -Encoding UTF8 src/main/java/com/ericchiu/simplerail/registry/ModBlocks.java
$oldReg=Get-Content -Raw -Encoding UTF8 ($e+'/before/ModBlocks.java')
$a=([regex]::Matches($reg,'register(?:Simple)?Block\("([^"]+)"')|ForEach-Object {$_.Groups[1].Value}) -join ','
$b=([regex]::Matches($oldReg,'register(?:Simple)?Block\("([^"]+)"')|ForEach-Object {$_.Groups[1].Value}) -join ','
Check 'All 11 registry IDs unchanged' ($a -eq $b -and ([regex]::Matches($reg,'register(?:Simple)?Block\("([^"]+)"')).Count -eq 11)
Check 'Same ID uses OnewayRail factory' ($reg.Contains('BLOCKS.registerBlock("oneway_rail", OnewayRail::new, railProperties())'))
$tag=Get-Content -Raw -Encoding UTF8 src/main/resources/data/minecraft/tags/block/mineable/pickaxe.json|ConvertFrom-Json
Check 'Pickaxe append only' (-not $tag.replace -and ($tag.values -join ',') -eq 'simplerail:high_speed_rail,simplerail:holding_rail,simplerail:oneway_rail')
$variants=(Get-Content -Raw -Encoding UTF8 src/main/resources/assets/simplerail/blockstates/oneway_rail.json|ConvertFrom-Json).variants
$coverage=@()
foreach($shape in @('north_south','east_west','ascending_east','ascending_west','ascending_north','ascending_south')){foreach($reverse in @('false','true')){foreach($powered in @('false','true')){foreach($need in @('false','true')){foreach($use in @('false','true')){foreach($water in @('false','true')){
    $state=@{shape=$shape;reverse=$reverse;powered=$powered;need_power=$need;use_power=$use;waterlogged=$water};$matches=@()
    foreach($variant in $variants.PSObject.Properties){$match=$true;foreach($part in ($variant.Name -split ',')){$pieces=$part -split '=';if($state[$pieces[0]] -ne $pieces[1]){$match=$false;break}};if($match){$matches+=$variant}}
    $coverage+=[ordered]@{shape=$shape;reverse=$reverse;powered=$powered;need_power=$need;use_power=$use;waterlogged=$water;naturalFlat=($shape -in @('north_south','east_west'));selectorCount=$matches.Count;model=$(if($matches.Count -eq 1){$matches[0].Value.model}else{$null})}
}}}}}}
$coverage|ConvertTo-Json -Depth 4|Set-Content -Encoding UTF8 ($e+'/state-coverage.json')
Check 'All 64 flat states select exactly one existing model' (@($coverage|Where-Object {$_.naturalFlat -and $_.selectorCount -eq 1}).Count -eq 64)
Check '192 declared states include 128 non-natural unmapped slopes' ($coverage.Count -eq 192 -and @($coverage|Where-Object {-not $_.naturalFlat -and $_.selectorCount -eq 0}).Count -eq 128)
$usePowerModels=@($coverage|Where-Object {$_.naturalFlat -and $_.use_power -eq 'true'}|ForEach-Object {[ordered]@{reverse=$_.reverse;powered=$_.powered;model=$_.model}})
Check 'U-07 model power flips preserved rather than silently corrected' (@($usePowerModels|Where-Object {$_.powered -eq 'true' -and $_.model -ne 'simplerail:block/oneway_reverse_powered_rail'}).Count -eq 0 -and @($usePowerModels|Where-Object {$_.powered -eq 'false' -and $_.model -ne 'simplerail:block/oneway_powered_rail'}).Count -eq 0)
$matrix=@();foreach($shape in @('north_south','east_west')){foreach($reverse in @($false,$true)){foreach($powered in @($false,$true)){foreach($need in @($false,$true)){foreach($use in @($false,$true)){
    $active=$use -or $powered -or -not $need
    $matrix+=[ordered]@{shape=$shape;reverse=$reverse;powered=$powered;needPower=$need;usePowerChangeDirection=$use;active=$active;callbackVector=$(if(-not $active){'nonzero input times 1.2 (all axes)'}elseif($shape -eq 'north_south'){if($reverse){'0,0,+0.4'}else{'0,0,-0.4'}}else{if($reverse){'-0.4,0,0'}else{'+0.4,0,0'}});oldReference='Source-inferred / untested';userIntent='U-07 pending';gameResult=$null}
}}}}}
$matrix|ConvertTo-Json -Depth 4|Set-Content -Encoding UTF8 ($e+'/behavior-matrix.json')
Check '32 source-inferred behavior rows; user results null' ($matrix.Count -eq 32 -and @($matrix|Where-Object {$null -ne $_.gameResult}).Count -eq 0)
$jdk='C:/Program Files/Eclipse Adoptium/jdk-21.0.12.101-hotspot/bin'
& ($jdk+'/javap.exe') -c -p -s -v -classpath build/classes/java/main com.ericchiu.simplerail.block.OnewayRail *> ($e+'/OnewayRail-bytecode.txt');Check 'Real API bytecode readable' ($LASTEXITCODE -eq 0)
$bytecode=Get-Content -Raw ($e+'/OnewayRail-bytecode.txt')
Check 'Java major 65/codec/onPlace/onMinecartPass compiled' ($bytecode.Contains('major version: 65') -and $bytecode.Contains('MapCodec') -and $bytecode.Contains('onPlace') -and $bytecode.Contains('onMinecartPass'))
Check 'Base speed/no slopes inherited unchanged' ($bytecode -notmatch 'public float getRailMaxSpeed|public boolean canMakeSlopes')
$build=Get-Content -Raw -Encoding UTF8 ($e+'/build-01.json')|ConvertFrom-Json;$test=Get-Content -Raw -Encoding UTF8 ($e+'/hooks-test.json')|ConvertFrom-Json
Check 'NEW build exit 0' ($build.exitCode -eq 0);Check 'Actual hooks isolated compile/run pass without game' ($test.compileExitCode -eq 0 -and $test.runExitCode -eq 0 -and -not $test.gameExecuted)
$jar=$e+'/artifacts/simplerail-1.0.0.jar';Copy-Item -LiteralPath build/libs/simplerail-1.0.0.jar -Destination $jar
Add-Type -AssemblyName System.IO.Compression.FileSystem;$archive=[IO.Compression.ZipFile]::OpenRead($jar)
Check 'JAR has OnewayRail' ($null -ne $archive.GetEntry('com/ericchiu/simplerail/block/OnewayRail.class'))
Check 'No test doubles packaged' (@($archive.Entries|Where-Object {$_.FullName -match 'HooksTest|isolated-tests|net/minecraft/'}).Count -eq 0)
$resources=Get-ChildItem src/main/resources -Recurse -File
foreach($f in $resources){$path=$f.FullName.Substring((Resolve-Path src/main/resources).Path.Length+1).Replace('\','/');$entry=$archive.GetEntry($path);$pass=$false;if($entry){$stream=$entry.Open();$sha=[Security.Cryptography.SHA256]::Create();$hash=[BitConverter]::ToString($sha.ComputeHash($stream)).Replace('-','');$stream.Dispose();$sha.Dispose();$pass=$hash -eq (Get-FileHash -LiteralPath $f.FullName).Hash};Check ('JAR resource '+$path) $pass}
@(@(Get-ChildItem src -Recurse -File)|ForEach-Object {[ordered]@{path=$_.FullName;sha256=(Get-FileHash -LiteralPath $_.FullName).Hash}})|ConvertTo-Json -Depth 4|Set-Content -Encoding UTF8 ($e+'/source-fingerprints.json')
@(@(Get-ChildItem ($e+'/isolated-tests/stubs') -Recurse -File)|ForEach-Object {[ordered]@{path=$_.FullName;sha256=(Get-FileHash -LiteralPath $_.FullName).Hash}})|ConvertTo-Json -Depth 4|Set-Content -Encoding UTF8 ($e+'/test-double-fingerprints.json')
$archive.Dispose();$ErrorActionPreference='Continue'
git -c core.safecrlf=false diff --check *> ($e+'/diff-check.log');$diffCode=$LASTEXITCODE
git diff --cached --binary|Out-File -Encoding UTF8 ($e+'/index-after.diff');$indexCode=$LASTEXITCODE
git diff HEAD --binary|Out-File -Encoding UTF8 ($e+'/source.diff');$sourceCode=$LASTEXITCODE
foreach($file in @('src/main/java/com/ericchiu/simplerail/block/HoldingRail.java','src/main/java/com/ericchiu/simplerail/block/OnewayRail.java')){git diff --no-index --binary -- NUL $file|Out-File -Append -Encoding UTF8 ($e+'/source.diff');if($LASTEXITCODE -ne 1){throw 'Expected new-file diff exit 1'}}
$ErrorActionPreference='Stop'
Check 'git diff --check/source exit 0' ($diffCode -eq 0 -and $sourceCode -eq 0)
Check 'Index unchanged' ($indexCode -eq 0 -and (Get-FileHash ($e+'/index-before.diff')).Hash -eq (Get-FileHash ($e+'/index-after.diff')).Hash)
[ordered]@{path=$jar;sha256=(Get-FileHash -LiteralPath $jar).Hash;head=(Get-Content ($e+'/head.txt')).Trim();source='Uncommitted full source.diff and source-fingerprints.json';minecraft='1.21.1';neoforge='21.1.251';mod='1.0.0';javaToolchain='21';isolatedTestJdk='Temurin 21.0.12.1+1';gradle='9.2.1';modDevGradle='2.0.147';parchment='2024.11.17';license='All Rights Reserved';development='T-029 source-compatible implementation complete';review='R-03 pending';manual='T-030 pending';package='T-096 pending';ambiguity='U-07 intent/model mismatch pending; not resolved by test doubles';gameExecuted=$false}|ConvertTo-Json|Set-Content -Encoding UTF8 ($e+'/artifact.json')
$failed=@($checks|Where-Object {-not $_.pass})
[ordered]@{command='powershell -NoProfile -ExecutionPolicy Bypass -File docs/evidence/T-029/audit.ps1';checks=$checks;count=$checks.Count;failed=$failed;changedExisting=@($changed.path);added=@($new.FullName);resourceCount=$resources.Count;declaredStates=192;naturalFlatStatesMapped=64;nonNaturalSlopesUnmapped=128;behaviorRows=32;gameExecuted=$false}|ConvertTo-Json -Depth 5|Set-Content -Encoding UTF8 ($e+'/audit-results-01.json')
Write-Output ('Checks='+$checks.Count+'; failed='+$failed.Count)
if($failed.Count){$failed|ConvertTo-Json;exit 1}
