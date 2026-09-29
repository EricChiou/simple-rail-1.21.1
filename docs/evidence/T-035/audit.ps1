$ErrorActionPreference='Stop'
$e=Join-Path (Get-Location) 'docs/evidence/T-035'
$checks=@();function Check([string]$name,[bool]$pass){$script:checks += [ordered]@{name=$name;pass=$pass}}
$before=Get-Content -Raw -Encoding UTF8 ($e+'/inputs-before.json')|ConvertFrom-Json
$changed=@($before|Where-Object {(Get-FileHash -LiteralPath $_.path).Hash -ne $_.sha256})
$allowed=(Join-Path (Get-Location) 'src/main/java/com/ericchiu/simplerail/registry/ModItems.java').Replace('/','\')
Check 'Only ModItems changed among prior product/Gradle/resource inputs' ($changed.Count -eq 1 -and $changed[0].path -eq $allowed)
$new=@(Get-ChildItem src -Recurse -File|Where-Object {$before.path -notcontains $_.FullName})
Check 'Only Wrench production file added' ($new.Count -eq 1 -and $new[0].Name -eq 'Wrench.java')
$wrench=Get-Content -Raw -Encoding UTF8 src/main/java/com/ericchiu/simplerail/item/Wrench.java
Check 'Client success before server access; non-server safe pass' ($wrench.IndexOf('if (level.isClientSide)') -lt $wrench.IndexOf('server.getBlockState(pos)') -and $wrench.Contains('return InteractionResult.SUCCESS') -and $wrench.Contains('return InteractionResult.PASS'))
Check 'Server consumes action without item mutation' ($wrench.Contains('return InteractionResult.CONSUME') -and $wrench -notmatch '\.shrink\(|hurtAndBreak|setCount|setDamage')
Check 'Rail gate uses clicked-cell AABB and no cart' ($wrench.Contains('state.is(ModTags.RAILS)') -and $wrench.Contains('getEntitiesOfClass(AbstractMinecart.class, new AABB(pos)).isEmpty()'))
Check 'Machines are independent of rail occupancy gate' ($wrench.Contains('if (state.is(ModTags.MACHINES))') -and $wrench.IndexOf('if (state.is(ModTags.MACHINES))') -gt $wrench.IndexOf('rotate(state, "direction")'))
Check 'Actual property instances resolved by StateDefinition name' ($wrench.Contains('getStateDefinition().getProperty("reverse")') -and $wrench.Contains('getStateDefinition().getProperty("level")') -and $wrench.Contains('getStateDefinition().getProperty(name)') -and $wrench -notmatch 'BooleanProperty.create|IntegerProperty.create|EnumProperty.create')
Check 'Boolean reverse type guard' ($wrench.Contains('property instanceof BooleanProperty reverse'))
Check 'Level range 0-9 and wrap 9 to 0' ($wrench.Contains('property instanceof IntegerProperty level') -and $wrench.Contains('getPossibleValues().size() == 10') -and $wrench.Contains('getPossibleValues().contains(0)') -and $wrench.Contains('getPossibleValues().contains(9)') -and $wrench.Contains('current >= 9 ? 0 : current + 1'))
Check 'Direction/facing type, horizontal and possible-value guards' ($wrench.Contains('enumeration.getValueClass() == Direction.class') -and $wrench.Contains('current.getAxis().isHorizontal()') -and $wrench.Contains('current.getClockWise()') -and $wrench.Contains('direction.getPossibleValues().contains(next)'))
Check 'Source-compatible U-09 same-initial-state writes explicitly retained' ($wrench.Contains('writeChange(server, pos, state, toggleReverse(state))') -and $wrench.Contains('writeChange(server, pos, state, cycleLevel(state))') -and $wrench.Contains('writeChange(server, pos, state, rotate(state, "direction"))') -and $wrench.Contains('writeChange(server, pos, state, rotate(state, "facing"))'))
Check 'No-op skips write; updates use flag 3' ($wrench.Contains('if (changed != initial)') -and $wrench.Contains('level.setBlock(pos, changed, Block.UPDATE_ALL)'))
Check 'HOE abilities retained without implementing tilling' ($wrench.Contains('ItemAbilities.DEFAULT_HOE_ACTIONS.contains(ability)') -and $wrench -notmatch 'extends HoeItem')
Check 'No config/BE/NBT/network/linking/neighbor-cell/sound implementation' ($wrench -notmatch 'CommonConfig|CompoundTag|BlockEntity|LinkageManager|linkNewCart|getSecondPos|sendParticles|playSound|SubscribeEvent|Mixin')
$reg=Get-Content -Raw -Encoding UTF8 src/main/java/com/ericchiu/simplerail/registry/ModItems.java
$oldReg=Get-Content -Raw -Encoding UTF8 ($e+'/before/ModItems.java')
$pattern='register(?:SimpleItem|Item|SimpleBlockItem)\("([^"]+)"'
$a=([regex]::Matches($reg,$pattern)|ForEach-Object {$_.Groups[1].Value}) -join ','
$b=([regex]::Matches($oldReg,$pattern)|ForEach-Object {$_.Groups[1].Value}) -join ','
Check 'All 13 item IDs and order preserved' ($a -eq $b -and ([regex]::Matches($reg,$pattern)).Count -eq 13)
Check 'Same wrench ID uses typed Wrench factory' ($reg.Contains('ITEMS.registerItem("wrench", Wrench::new,'))
Check 'Wrench stack 1/common/fire resistant properties unchanged' ($reg.Contains('new Item.Properties().stacksTo(1).rarity(Rarity.COMMON).fireResistant()'))
$rails=Get-Content -Raw -Encoding UTF8 src/main/resources/data/simplerail/tags/block/rails.json|ConvertFrom-Json
$machines=Get-Content -Raw -Encoding UTF8 src/main/resources/data/simplerail/tags/block/machines.json|ConvertFrom-Json
Check 'Unchanged rails nine/machines two block tags, replace false' ($rails.values.Count -eq 9 -and $machines.values.Count -eq 2 -and -not $rails.replace -and -not $machines.replace)
$matrix=@();foreach($reverse in @($false,$true)){$matrix+=[ordered]@{property='reverse';initial=$reverse;isolatedNext=(-not $reverse);gate='rails and clicked cell empty';gameResult=$null}}
foreach($n in 0..9){$matrix+=[ordered]@{property='level';initial=$n;isolatedNext=(($n+1)%10);gate='rails empty, or machines regardless of cart';gameResult=$null}}
foreach($property in @('direction','facing')){foreach($d in @('north','east','south','west','up','down')){$next=switch($d){north{'east'}east{'south'}south{'west'}west{'north'}default{$d}};$matrix+=[ordered]@{property=$property;initial=$d;isolatedNext=$next;gate=$(if($property -eq 'direction'){'rails and clicked cell empty'}else{'machines regardless of cart'});gameResult=$null}}}
$matrix|ConvertTo-Json -Depth 4|Set-Content -Encoding UTF8 ($e+'/operation-matrix.json')
Check '24 isolated property rows, no fabricated game result' ($matrix.Count -eq 24 -and @($matrix|Where-Object {$null -ne $_.gameResult}).Count -eq 0)
@([ordered]@{case='U09-rail';initial='reverse=false,level=9,direction=north';sourceCompatibleFinal='reverse=false,level=9,direction=east';writes=3;decision='Pending user decision; not fixed';oldStatus='Source-inferred / untested';gameResult=$null},[ordered]@{case='U09-machine';initial='facing=north,level=9';sourceCompatibleFinal='facing=north,level=0';writes=2;decision='Pending user decision; not fixed';oldStatus='Source-inferred / untested';gameResult=$null})|ConvertTo-Json|Set-Content -Encoding UTF8 ($e+'/U09-source-reproduction.json')
$contracts=@(
 @('high_speed_rail','none','implemented rail'),@('holding_rail','direction','implemented rail'),@('oneway_rail','reverse','implemented rail'),@('eject_rail','reverse','implemented rail'),@('destory_rail','none','implemented rail'),
 @('timer_holding_rail','level,direction','placeholder; T-038 pending'),@('cross_rail','none','placeholder; T-066 pending'),@('y_cross_rail','direction','placeholder; T-068 pending'),@('y_cross_right_rail','direction','placeholder; T-070 pending'),@('train_dispenser','facing','placeholder; T-044 pending'),@('signal_timer','level','placeholder; T-041 pending'))
$contracts|ForEach-Object {[ordered]@{id=('simplerail:'+$_[0]);requiredWrenchProperties=$_[1];currentScope=$_[2];gameResult=$null}}|ConvertTo-Json|Set-Content -Encoding UTF8 ($e+'/property-tag-map.json')
Check 'All 11 blocks mapped, future owners explicitly pending' ($contracts.Count -eq 11)

$jdk='C:/Program Files/Eclipse Adoptium/jdk-21.0.12.101-hotspot/bin'
& ($jdk+'/javap.exe') -c -p -s -v -classpath build/classes/java/main com.ericchiu.simplerail.item.Wrench *> ($e+'/Wrench-bytecode.txt');Check 'Real API bytecode readable' ($LASTEXITCODE -eq 0)
$bytecode=Get-Content -Raw ($e+'/Wrench-bytecode.txt')
Check 'Java major 65/useOn/abilities/actual property lookup compiled' ($bytecode.Contains('major version: 65') -and $bytecode.Contains('useOn') -and $bytecode.Contains('canPerformAction') -and $bytecode.Contains('StateDefinition.getProperty'))
Check 'Wrench adds no rail movement overrides' ($bytecode -notmatch 'public float getRailMaxSpeed|public boolean canMakeSlopes')
$build=Get-Content -Raw -Encoding UTF8 ($e+'/build-01.json')|ConvertFrom-Json;$test=Get-Content -Raw -Encoding UTF8 ($e+'/hooks-test.json')|ConvertFrom-Json
Check 'NEW build exit 0' ($build.exitCode -eq 0)
Check 'Actual hook isolated compile/run exit 0, no game' ($test.compileExitCode -eq 0 -and $test.runExitCode -eq 0 -and -not $test.gameExecuted)
Add-Type -AssemblyName System.IO.Compression.FileSystem
$sourceJar='build/moddev/artifacts/neoforge-21.1.251-sources.jar';$sourceArchive=[IO.Compression.ZipFile]::OpenRead((Resolve-Path $sourceJar));$manifest=@()
foreach($f in (Get-ChildItem ($e+'/sources/target') -Recurse -File)){
 $path=$f.FullName.Substring((Resolve-Path ($e+'/sources/target')).Path.Length+1).Replace('\','/');$stream=$sourceArchive.GetEntry($path).Open();$sha=[Security.Cryptography.SHA256]::Create();$hash=[BitConverter]::ToString($sha.ComputeHash($stream)).Replace('-','');$stream.Dispose();$sha.Dispose()
 $manifest+=[ordered]@{path=$path;sha256=$hash};Check ('Pinned source snapshot '+$path) ($hash -eq (Get-FileHash -LiteralPath $f.FullName).Hash)
}
$sourceArchive.Dispose()
[ordered]@{archive=$sourceJar;archiveSha256=(Get-FileHash $sourceJar).Hash;minecraft='1.21.1';neoforge='21.1.251';target=$manifest;old=@(Get-ChildItem ($e+'/sources/old') -File|ForEach-Object {[ordered]@{path=$_.Name;sha256=(Get-FileHash $_.FullName).Hash}});oldStatus='Source reference only; OLD build not executed; U09 intent pending; OLD not executed'}|ConvertTo-Json -Depth 5|Set-Content -Encoding UTF8 ($e+'/source-manifest.json')
$jar=$e+'/artifacts/simplerail-1.0.0.jar';Copy-Item -LiteralPath build/libs/simplerail-1.0.0.jar -Destination $jar
$archive=[IO.Compression.ZipFile]::OpenRead($jar)
Check 'JAR contains Wrench' ($null -ne $archive.GetEntry('com/ericchiu/simplerail/item/Wrench.class'))
Check 'No test doubles packaged' (@($archive.Entries|Where-Object {$_.FullName -match 'HooksTest|isolated-tests|net/minecraft/'}).Count -eq 0)
$resources=Get-ChildItem src/main/resources -Recurse -File
foreach($f in $resources){$path=$f.FullName.Substring((Resolve-Path src/main/resources).Path.Length+1).Replace('\','/');$entry=$archive.GetEntry($path);$pass=$false;if($entry){$stream=$entry.Open();$sha=[Security.Cryptography.SHA256]::Create();$hash=[BitConverter]::ToString($sha.ComputeHash($stream)).Replace('-','');$stream.Dispose();$sha.Dispose();$pass=$hash -eq (Get-FileHash -LiteralPath $f.FullName).Hash};Check ('JAR resource '+$path) $pass}
$archive.Dispose()
foreach($prior in @(@('T-027','DE13BF73E4A79E32A656CEEBD052C61E042B342D8886050AC71330E6EDF78D35'),@('T-029','7EE7F6853662572F1D1D073F72EE49E4F44413B2D6CEBB839D5BDFAF36941A7C'),@('T-031','D0ECA101CA8A9B72173E9B340206B1DDB7FCB3FE1B7834DDD2F5BA56E3E19B7E'),@('T-033','336FAFDF1237127E613E3B300BCD9263191A377284A8EB7B7BA77DE124A24473'))){Check ('Earlier frozen JAR retained '+$prior[0]) ((Get-FileHash ('docs/evidence/'+$prior[0]+'/artifacts/simplerail-1.0.0.jar')).Hash -eq $prior[1])}
@(Get-ChildItem src -Recurse -File; Get-Item build.gradle,gradle.properties,settings.gradle; Get-ChildItem gradle -Recurse -File)|ForEach-Object {[ordered]@{path=$_.FullName;sha256=(Get-FileHash -LiteralPath $_.FullName).Hash}}|ConvertTo-Json -Depth 4|Set-Content -Encoding UTF8 ($e+'/source-fingerprints.json')
@(Get-ChildItem ($e+'/isolated-tests/stubs') -Recurse -File)|ForEach-Object {[ordered]@{path=$_.FullName;sha256=(Get-FileHash -LiteralPath $_.FullName).Hash}}|ConvertTo-Json -Depth 4|Set-Content -Encoding UTF8 ($e+'/test-double-fingerprints.json')
$ErrorActionPreference='Continue'
git -c core.safecrlf=false diff --check *> ($e+'/diff-check.log');$diffCode=$LASTEXITCODE
git diff --cached --binary|Out-File -Encoding UTF8 ($e+'/index-after.diff');$indexCode=$LASTEXITCODE
git diff HEAD --binary|Out-File -Encoding UTF8 ($e+'/source.diff');$sourceCode=$LASTEXITCODE
foreach($file in @('src/main/java/com/ericchiu/simplerail/block/HoldingRail.java','src/main/java/com/ericchiu/simplerail/block/OnewayRail.java','src/main/java/com/ericchiu/simplerail/block/EjectRail.java','src/main/java/com/ericchiu/simplerail/block/DestoryRail.java','src/main/java/com/ericchiu/simplerail/item/Wrench.java')){git diff --no-index --binary -- NUL $file|Out-File -Append -Encoding UTF8 ($e+'/source.diff');if($LASTEXITCODE -ne 1){throw 'Expected new-file diff exit 1'}}
$ErrorActionPreference='Stop'
Check 'git diff --check/source exit 0' ($diffCode -eq 0 -and $sourceCode -eq 0)
Check 'Index unchanged' ($indexCode -eq 0 -and (Get-FileHash ($e+'/index-before.diff')).Hash -eq (Get-FileHash ($e+'/index-after.diff')).Hash)
[ordered]@{path=$jar;sha256=(Get-FileHash -LiteralPath $jar).Hash;head=(Get-Content ($e+'/head.txt')).Trim();source='Uncommitted full source.diff and source-fingerprints.json';minecraft='1.21.1';neoforge='21.1.251';mod='1.0.0';javaToolchain='21';isolatedTestJdk='Temurin 21.0.12.1+1';gradle='9.2.1';modDevGradle='2.0.147';parchment='2024.11.17';license='All Rights Reserved';development='T-035 source-compatible wrench development complete; U09 intent pending';review='R-03 pending';manual='T-036 pending';package='T-099 pending';linking='T-057 not implemented';gameExecuted=$false}|ConvertTo-Json|Set-Content -Encoding UTF8 ($e+'/artifact.json')
$failed=@($checks|Where-Object {-not $_.pass})
[ordered]@{command='powershell -NoProfile -ExecutionPolicy Bypass -File docs/evidence/T-035/audit.ps1';checks=$checks;count=$checks.Count;failed=$failed;changedExisting=@($changed|ForEach-Object {$_.path});added=@($new|ForEach-Object {$_.FullName});resourceCount=$resources.Count;operationRows=24;U09Intent='pending';gameCasesNotRun='T-036';gameExecuted=$false}|ConvertTo-Json -Depth 5|Set-Content -Encoding UTF8 ($e+'/audit-results-02.json')
Write-Output ('Checks='+$checks.Count+'; failed='+$failed.Count)
if($failed.Count){$failed|ConvertTo-Json;exit 1}
