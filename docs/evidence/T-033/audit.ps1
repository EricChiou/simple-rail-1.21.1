$ErrorActionPreference='Stop'
$e=Join-Path (Get-Location) 'docs/evidence/T-033'
$checks=@();function Check([string]$name,[bool]$pass){$script:checks += [ordered]@{name=$name;pass=$pass}}
$before=Get-Content -Raw -Encoding UTF8 ($e+'/inputs-before.json')|ConvertFrom-Json
$changed=@($before|Where-Object {(Get-FileHash -LiteralPath $_.path).Hash -ne $_.sha256})
$allowed=@('src/main/java/com/ericchiu/simplerail/registry/ModBlocks.java','src/main/resources/data/minecraft/tags/block/mineable/pickaxe.json')|ForEach-Object {(Join-Path (Get-Location) $_).Replace('/','\')}
Check 'Only registry and pickaxe tag changed among prior product/Gradle inputs' ($changed.Count -eq 2 -and @($changed|Where-Object {$allowed -notcontains $_.path}).Count -eq 0)
$new=@(Get-ChildItem src -Recurse -File|Where-Object {$before.path -notcontains $_.FullName})
Check 'Only DestoryRail production file added' ($new.Count -eq 1 -and $new[0].Name -eq 'DestoryRail.java')
$rail=Get-Content -Raw -Encoding UTF8 src/main/java/com/ericchiu/simplerail/block/DestoryRail.java
Check 'Historical need_power property name' ($rail.Contains('BooleanProperty.create("need_power")'))
$constructor=[regex]::Match($rail,'(?s)public DestoryRail\(.*?\n    }').Value
Check 'Constructor no config read; OLD false needPower default with inherited defaults' ($constructor -notmatch 'CommonConfig.current|Config\.get' -and $constructor.Contains('defaultBlockState().setValue(NEED_POWER, false)'))
$hook=[regex]::Match($rail,'(?s)public void onMinecartPass.*?(?=    @Override)').Value
Check 'ServerLevel and removed-cart guard before config read' ($hook.Contains('!(level instanceof ServerLevel serverLevel) || cart.isRemoved()') -and $hook.IndexOf('cart.isRemoved()') -lt $hook.IndexOf('CommonConfig.current()'))
Check 'One config snapshot; current config gate, not display state' ([regex]::Matches($hook,'CommonConfig.current\(').Count -eq 1 -and $hook.Contains('config.destoryNeedPower() && !state.getValue(POWERED)') -and $hook -notmatch 'getValue\(NEED_POWER\)')
Check 'Discard exactly once; not damage, kill or direct setRemoved' ([regex]::Matches($hook,'cart.discard\(').Count -eq 1 -and $hook -notmatch 'cart.kill|cart.hurt|cart.destroy|cart.setRemoved|cart.remove\(')
Check 'Effects after removal at OLD rail coordinates' ($hook.IndexOf('cart.discard()') -lt $hook.IndexOf('serverLevel.sendParticles') -and $hook.Contains('pos.getX() + 0.5D') -and $hook.Contains('pos.getY() + 0.75D') -and $hook.Contains('pos.getZ() + 0.5D'))
Check 'One smoke with zero spread and speed through server API' ($hook.Contains('sendParticles(ParticleTypes.LARGE_SMOKE, x, y, z, 1, 0.0D, 0.0D, 0.0D, 0.0D)'))
Check 'Server sound, no excluded player; OLD burn blocks volume/pitch 4' ($hook.Contains('playSound(null, x, y, z, SoundEvents.GENERIC_BURN, SoundSource.BLOCKS, 4.0F, 4.0F)') -and $hook -notmatch 'playLocalSound|\.addParticle\(')
Check 'No direction/cart velocity/neighbor scanning logic' ($hook -notmatch 'getMotionDirection|SHAPE|getDeltaMovement|setDeltaMovement|moveTo|teleportTo|getEntities')
Check 'No custom drops, inventory bypass or consist implementation' ($hook -notmatch 'spawnAtLocation|dropContents|clearContent|deleteTrain|LinkageManager|LocomotiveCart')
Check 'Placement projects only new server block and delegates parent' ($rail.Contains('if (!level.isClientSide && !oldState.is(this))') -and $rail.Contains('super.onPlace(state, level, pos, oldState, moving)'))
Check 'No custom BE/NBT/network/ticket/event/mixin added' ($rail -notmatch 'CompoundTag|BlockEntity|SubscribeEvent|Mixin|Ticket|addRegionTicket')
$reg=Get-Content -Raw -Encoding UTF8 src/main/java/com/ericchiu/simplerail/registry/ModBlocks.java
$oldReg=Get-Content -Raw -Encoding UTF8 ($e+'/before/ModBlocks.java')
$a=([regex]::Matches($reg,'register(?:Simple)?Block\("([^"]+)"')|ForEach-Object {$_.Groups[1].Value}) -join ','
$b=([regex]::Matches($oldReg,'register(?:Simple)?Block\("([^"]+)"')|ForEach-Object {$_.Groups[1].Value}) -join ','
Check 'All 11 registry IDs unchanged including destory_rail' ($a -eq $b -and ([regex]::Matches($reg,'register(?:Simple)?Block\("([^"]+)"')).Count -eq 11 -and $a.Contains('destory_rail'))
Check 'Same destory_rail ID uses actual factory' ($reg.Contains('BLOCKS.registerBlock("destory_rail", DestoryRail::new, railProperties())'))
$tag=Get-Content -Raw -Encoding UTF8 src/main/resources/data/minecraft/tags/block/mineable/pickaxe.json|ConvertFrom-Json
Check 'Pickaxe append only, replace false' (-not $tag.replace -and ($tag.values -join ',') -eq 'simplerail:high_speed_rail,simplerail:holding_rail,simplerail:oneway_rail,simplerail:eject_rail,simplerail:destory_rail')
$variants=(Get-Content -Raw -Encoding UTF8 src/main/resources/assets/simplerail/blockstates/destory_rail.json|ConvertFrom-Json).variants
$coverage=@()
foreach($shape in @('north_south','east_west','ascending_east','ascending_west','ascending_north','ascending_south')){foreach($powered in @('false','true')){foreach($need in @('false','true')){foreach($water in @('false','true')){
 $state=@{shape=$shape;powered=$powered;need_power=$need;waterlogged=$water};$matches=@()
 foreach($variant in $variants.PSObject.Properties){$match=$true;foreach($part in ($variant.Name -split ',')){$pieces=$part -split '=';if($state[$pieces[0]] -ne $pieces[1]){$match=$false;break}};if($match){$matches+=$variant}}
 $coverage+=[ordered]@{shape=$shape;powered=$powered;need_power=$need;waterlogged=$water;naturalFlat=($shape -in @('north_south','east_west'));selectorCount=$matches.Count;model=$(if($matches.Count -eq 1){$matches[0].Value.model}else{$null})}
}}}}
$coverage|ConvertTo-Json -Depth 4|Set-Content -Encoding UTF8 ($e+'/state-coverage.json')
Check 'All 16 flat states select exactly one unchanged model' (@($coverage|Where-Object {$_.naturalFlat -and $_.selectorCount -eq 1}).Count -eq 16)
Check '48 declared states include 32 non-natural unmapped slopes' ($coverage.Count -eq 48 -and @($coverage|Where-Object {-not $_.naturalFlat -and $_.selectorCount -eq 0}).Count -eq 32)
$matrix=@();foreach($need in @($false,$true)){foreach($powered in @($false,$true)){
 $matrix+=[ordered]@{id=('C-011-B'+($matrix.Count+1).ToString('D2'));needPower=$need;powered=$powered;active=($powered -or -not $need);target='Only the callback cart, when not already removed';removalReason=$(if($powered -or -not $need){'DISCARDED'}else{$null});effects=$(if($powered -or -not $need){'One LARGE_SMOKE (zero offset/speed) and GENERIC_BURN/BLOCKS volume=4 pitch=4 at rail+(.5,.75,.5)'}else{'None'});ordinaryVehicleItem='No rail-added item; no destroy damage path';containerContents='Target source invokes vanilla container removal hook; actual game pending';passengers='Target source invokes stopRiding; actual game pending';oldReference='Source-inferred / untested; OLD superclass side effects not verified';manualCase='C-011 / T-034';gameResult=$null}
}}
$matrix|ConvertTo-Json -Depth 4|Set-Content -Encoding UTF8 ($e+'/behavior-matrix.json')
Check 'Four complete power rows and no fabricated game results' ($matrix.Count -eq 4 -and @($matrix|Where-Object {$null -ne $_.gameResult}).Count -eq 0)
$jdk='C:/Program Files/Eclipse Adoptium/jdk-21.0.12.101-hotspot/bin'
& ($jdk+'/javap.exe') -c -p -s -v -classpath build/classes/java/main com.ericchiu.simplerail.block.DestoryRail *> ($e+'/DestoryRail-bytecode.txt');Check 'Real API bytecode readable' ($LASTEXITCODE -eq 0)
$bytecode=Get-Content -Raw ($e+'/DestoryRail-bytecode.txt')
Check 'Java major 65/codec/placement/pass/discard/broadcast compiled' ($bytecode.Contains('major version: 65') -and $bytecode.Contains('MapCodec') -and $bytecode.Contains('onPlace') -and $bytecode.Contains('onMinecartPass') -and $bytecode.Contains('discard') -and $bytecode.Contains('sendParticles') -and $bytecode.Contains('playSound'))
Check 'Base speed/no slopes inherited unchanged' ($bytecode -notmatch 'public float getRailMaxSpeed|public boolean canMakeSlopes')
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
[ordered]@{archive=$sourceJar;archiveSha256=(Get-FileHash $sourceJar).Hash;minecraft='1.21.1';neoforge='21.1.251';target=$manifest;old=@(Get-ChildItem ($e+'/sources/old') -File|ForEach-Object {[ordered]@{path=$_.Name;sha256=(Get-FileHash $_.FullName).Hash}});oldStatus='Source reference only; OLD build not executed; OLD superclass removal not inspected'}|ConvertTo-Json -Depth 5|Set-Content -Encoding UTF8 ($e+'/source-manifest.json')
$jar=$e+'/artifacts/simplerail-1.0.0.jar';Copy-Item -LiteralPath build/libs/simplerail-1.0.0.jar -Destination $jar
$archive=[IO.Compression.ZipFile]::OpenRead($jar)
Check 'JAR contains DestoryRail' ($null -ne $archive.GetEntry('com/ericchiu/simplerail/block/DestoryRail.class'))
Check 'No test doubles packaged' (@($archive.Entries|Where-Object {$_.FullName -match 'HooksTest|isolated-tests|net/minecraft/'}).Count -eq 0)
$resources=Get-ChildItem src/main/resources -Recurse -File
foreach($f in $resources){$path=$f.FullName.Substring((Resolve-Path src/main/resources).Path.Length+1).Replace('\','/');$entry=$archive.GetEntry($path);$pass=$false;if($entry){$stream=$entry.Open();$sha=[Security.Cryptography.SHA256]::Create();$hash=[BitConverter]::ToString($sha.ComputeHash($stream)).Replace('-','');$stream.Dispose();$sha.Dispose();$pass=$hash -eq (Get-FileHash -LiteralPath $f.FullName).Hash};Check ('JAR resource '+$path) $pass}
$archive.Dispose()
foreach($prior in @(@('T-027','DE13BF73E4A79E32A656CEEBD052C61E042B342D8886050AC71330E6EDF78D35'),@('T-029','7EE7F6853662572F1D1D073F72EE49E4F44413B2D6CEBB839D5BDFAF36941A7C'),@('T-031','D0ECA101CA8A9B72173E9B340206B1DDB7FCB3FE1B7834DDD2F5BA56E3E19B7E'))){Check ('Earlier frozen JAR retained '+$prior[0]) ((Get-FileHash ('docs/evidence/'+$prior[0]+'/artifacts/simplerail-1.0.0.jar')).Hash -eq $prior[1])}
@(Get-ChildItem src -Recurse -File; Get-Item build.gradle,gradle.properties,settings.gradle; Get-ChildItem gradle -Recurse -File)|ForEach-Object {[ordered]@{path=$_.FullName;sha256=(Get-FileHash -LiteralPath $_.FullName).Hash}}|ConvertTo-Json -Depth 4|Set-Content -Encoding UTF8 ($e+'/source-fingerprints.json')
@(Get-ChildItem ($e+'/isolated-tests/stubs') -Recurse -File)|ForEach-Object {[ordered]@{path=$_.FullName;sha256=(Get-FileHash -LiteralPath $_.FullName).Hash}}|ConvertTo-Json -Depth 4|Set-Content -Encoding UTF8 ($e+'/test-double-fingerprints.json')
$ErrorActionPreference='Continue'
git -c core.safecrlf=false diff --check *> ($e+'/diff-check.log');$diffCode=$LASTEXITCODE
git diff --cached --binary|Out-File -Encoding UTF8 ($e+'/index-after.diff');$indexCode=$LASTEXITCODE
git diff HEAD --binary|Out-File -Encoding UTF8 ($e+'/source.diff');$sourceCode=$LASTEXITCODE
foreach($name in @('HoldingRail','OnewayRail','EjectRail','DestoryRail')){git diff --no-index --binary -- NUL ('src/main/java/com/ericchiu/simplerail/block/'+$name+'.java')|Out-File -Append -Encoding UTF8 ($e+'/source.diff');if($LASTEXITCODE -ne 1){throw 'Expected new-file diff exit 1'}}
$ErrorActionPreference='Stop'
Check 'git diff --check/source exit 0' ($diffCode -eq 0 -and $sourceCode -eq 0)
Check 'Index unchanged' ($indexCode -eq 0 -and (Get-FileHash ($e+'/index-before.diff')).Hash -eq (Get-FileHash ($e+'/index-after.diff')).Hash)
[ordered]@{path=$jar;sha256=(Get-FileHash -LiteralPath $jar).Hash;head=(Get-Content ($e+'/head.txt')).Trim();source='Uncommitted full source.diff and source-fingerprints.json';minecraft='1.21.1';neoforge='21.1.251';mod='1.0.0';javaToolchain='21';isolatedTestJdk='Temurin 21.0.12.1+1';gradle='9.2.1';modDevGradle='2.0.147';parchment='2024.11.17';license='All Rights Reserved';development='T-033 ordinary minecart implementation complete';review='R-03 pending';manual='T-034 pending';package='T-098 pending';consist='T-061 not implemented';gameExecuted=$false}|ConvertTo-Json|Set-Content -Encoding UTF8 ($e+'/artifact.json')
$failed=@($checks|Where-Object {-not $_.pass})
[ordered]@{command='powershell -NoProfile -ExecutionPolicy Bypass -File docs/evidence/T-033/audit.ps1';checks=$checks;count=$checks.Count;failed=$failed;changedExisting=@($changed|ForEach-Object {$_.path});added=@($new|ForEach-Object {$_.FullName});resourceCount=$resources.Count;declaredStates=48;naturalFlatStatesMapped=16;nonNaturalSlopesUnmapped=32;behaviorRows=4;gameExecuted=$false}|ConvertTo-Json -Depth 5|Set-Content -Encoding UTF8 ($e+'/audit-results-01.json')
Write-Output ('Checks='+$checks.Count+'; failed='+$failed.Count)
if($failed.Count){$failed|ConvertTo-Json;exit 1}
