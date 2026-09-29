$ErrorActionPreference='Stop'
$e=Join-Path (Get-Location) 'docs/evidence/T-027'
$checks=@();function Check([string]$name,[bool]$pass){$script:checks += [ordered]@{name=$name;pass=$pass}}
$before=Get-Content -Raw -Encoding UTF8 ($e+'/inputs-before.json')|ConvertFrom-Json
$changed=@($before|Where-Object {(Get-FileHash -LiteralPath $_.path).Hash -ne $_.sha256})
$expected=@('src/main/java/com/ericchiu/simplerail/registry/ModBlocks.java','src/main/resources/data/minecraft/tags/block/mineable/pickaxe.json')|ForEach-Object {(Join-Path (Get-Location) $_).Replace('/','\')}
Check 'Exactly two existing production files changed' ($changed.Count -eq 2 -and @($changed|Where-Object {$expected -notcontains $_.path}).Count -eq 0)
$new=@(Get-ChildItem src -Recurse -File|Where-Object {$before.path -notcontains $_.FullName})
Check 'Only HoldingRail added to production' ($new.Count -eq 1 -and $new[0].Name -eq 'HoldingRail.java')
$rail=Get-Content -Raw -Encoding UTF8 src/main/java/com/ericchiu/simplerail/block/HoldingRail.java
Check 'Direction name/full domain retained' ($rail.Contains('EnumProperty.create("direction", Direction.class)'))
Check 'Default builds on parent state' ($rail.Contains('defaultBlockState().setValue(DIRECTION, Direction.NORTH)'))
Check 'Server-only mutations' ($rail.Contains('if (level.isClientSide || state.getValue(POWERED))') -and $rail.Contains('if (level.isClientSide)'))
Check 'Direction captured before zero velocity' ($rail.IndexOf('cart.getMotionDirection()') -lt $rail.IndexOf('cart.setDeltaMovement(Vec3.ZERO)'))
Check 'No new cache/NBT/BE/timer/foreign integration' ($rail -notmatch 'Map<|BlockEntity|CompoundTag|System.currentTimeMillis|SubscribeEvent|Mixin')
Check 'Stop remains OLD moveTo with rotation' ($rail.Contains('cart.moveTo(pos, cart.getYRot(), cart.getXRot())'))
Check 'Parent power update precedes read-back' ($rail.IndexOf('super.updateState(state, level, pos, neighborBlock)') -lt $rail.IndexOf('BlockState updated = level.getBlockState(pos)'))
Check 'Release only on real rising edge and matching block' ($rail.Contains('updated.is(this) && !wasPowered && updated.getValue(POWERED)'))
Check 'Release all carts in original block AABB' ($rail.Contains('level.getEntitiesOfClass(AbstractMinecart.class, new AABB(pos))'))
$reg=Get-Content -Raw -Encoding UTF8 src/main/java/com/ericchiu/simplerail/registry/ModBlocks.java
Check 'Holding ID uses dedicated class' ($reg.Contains('BLOCKS.registerBlock("holding_rail", HoldingRail::new, railProperties())'))
$oldReg=Get-Content -Raw -Encoding UTF8 ($e+'/before/ModBlocks.java')
$idsNow=([regex]::Matches($reg,'register(?:Simple)?Block\("([^"]+)"')|ForEach-Object {$_.Groups[1].Value}) -join ','
$idsBefore=([regex]::Matches($oldReg,'register(?:Simple)?Block\("([^"]+)"')|ForEach-Object {$_.Groups[1].Value}) -join ','
Check 'All registry IDs unchanged' ($idsNow -eq $idsBefore)
$tag=Get-Content -Raw -Encoding UTF8 src/main/resources/data/minecraft/tags/block/mineable/pickaxe.json|ConvertFrom-Json
Check 'Pickaxe classification append only' (-not $tag.replace -and ($tag.values -join ',') -eq 'simplerail:high_speed_rail,simplerail:holding_rail')
$models=Get-Content -Raw -Encoding UTF8 src/main/resources/assets/simplerail/blockstates/holding_rail.json|ConvertFrom-Json
$coverage=@()
foreach($shape in @('north_south','east_west','ascending_east','ascending_west','ascending_north','ascending_south')){foreach($powered in @('false','true')){foreach($waterlogged in @('false','true')){foreach($direction in @('north','east','south','west','up','down')){$selector='powered='+$powered+',shape='+$shape;$mapped=$null -ne $models.variants.PSObject.Properties[$selector];$coverage+=[ordered]@{shape=$shape;powered=$powered;waterlogged=$waterlogged;direction=$direction;naturalPlacement=($shape -in @('north_south','east_west'));mapped=$mapped}}}}}
$coverage|ConvertTo-Json -Depth 4|Set-Content -Encoding UTF8 ($e+'/state-coverage.json')
Check '48 flat states match existing models' (@($coverage|Where-Object {$_.naturalPlacement -and $_.mapped}).Count -eq 48)
Check 'Full 144 declared states distinguished from 96 unreachable unmapped slopes' ($coverage.Count -eq 144 -and @($coverage|Where-Object {-not $_.naturalPlacement -and -not $_.mapped}).Count -eq 96)
$jdk='C:/Program Files/Eclipse Adoptium/jdk-21.0.12.101-hotspot/bin'
& ($jdk+'/javap.exe') -c -p -s -v -classpath build/classes/java/main com.ericchiu.simplerail.block.HoldingRail *> ($e+'/HoldingRail-bytecode.txt');Check 'Real compiled API bytecode readable' ($LASTEXITCODE -eq 0)
$bytecode=Get-Content -Raw ($e+'/HoldingRail-bytecode.txt')
Check 'Actual artifact Java major 65 / codec / hooks' ($bytecode.Contains('major version: 65') -and $bytecode.Contains('onMinecartPass') -and $bytecode.Contains('updateState') -and $bytecode.Contains('MapCodec'))
Check 'Common speed and no slopes inherited unchanged' ($bytecode -notmatch 'public float getRailMaxSpeed|public boolean canMakeSlopes')
$build=Get-Content -Raw -Encoding UTF8 ($e+'/build-01.json')|ConvertFrom-Json
$test=Get-Content -Raw -Encoding UTF8 ($e+'/hooks-test.json')|ConvertFrom-Json
Check 'NEW build exit 0' ($build.exitCode -eq 0)
Check 'Actual hooks isolated tests compile and pass' ($test.compileExitCode -eq 0 -and $test.runExitCode -eq 0 -and -not $test.gameExecuted)
$jar=$e+'/artifacts/simplerail-1.0.0.jar';Copy-Item -LiteralPath build/libs/simplerail-1.0.0.jar -Destination $jar
Add-Type -AssemblyName System.IO.Compression.FileSystem
$archive=[IO.Compression.ZipFile]::OpenRead($jar)
Check 'JAR contains HoldingRail production class' ($null -ne $archive.GetEntry('com/ericchiu/simplerail/block/HoldingRail.class'))
Check 'Test doubles not packaged' (@($archive.Entries|Where-Object {$_.FullName -match 'HoldingRailHooksTest|isolated-tests|net/minecraft/'}).Count -eq 0)
$resources=Get-ChildItem src/main/resources -Recurse -File
foreach($file in $resources){$p=$file.FullName.Substring((Resolve-Path src/main/resources).Path.Length+1).Replace('\','/');$entry=$archive.GetEntry($p);$pass=$false;if($entry){$stream=$entry.Open();$sha=[Security.Cryptography.SHA256]::Create();$hash=[BitConverter]::ToString($sha.ComputeHash($stream)).Replace('-','');$stream.Dispose();$sha.Dispose();$pass=$hash -eq (Get-FileHash -LiteralPath $file.FullName).Hash};Check ('JAR resource '+$p) $pass}
$archive.Dispose()
@(@(Get-ChildItem src -Recurse -File)|ForEach-Object {[ordered]@{path=$_.FullName;sha256=(Get-FileHash -LiteralPath $_.FullName).Hash}})|ConvertTo-Json -Depth 4|Set-Content -Encoding UTF8 ($e+'/source-fingerprints.json')
@(@(Get-ChildItem ($e+'/isolated-tests/stubs') -Recurse -File)|ForEach-Object {[ordered]@{path=$_.FullName;sha256=(Get-FileHash -LiteralPath $_.FullName).Hash}})|ConvertTo-Json -Depth 4|Set-Content -Encoding UTF8 ($e+'/test-double-fingerprints.json')
$ErrorActionPreference='Continue'
git -c core.safecrlf=false diff --check *> ($e+'/diff-check.log');$diffCode=$LASTEXITCODE
git diff --cached --binary | Out-File -Encoding UTF8 ($e+'/index-after.diff');$indexCode=$LASTEXITCODE
git diff HEAD --binary | Out-File -Encoding UTF8 ($e+'/source.diff');$diffSourceCode=$LASTEXITCODE
git diff --no-index --binary -- NUL src/main/java/com/ericchiu/simplerail/block/HoldingRail.java | Out-File -Append -Encoding UTF8 ($e+'/source.diff');$newSourceCode=$LASTEXITCODE
$ErrorActionPreference='Stop'
Check 'git diff --check exit 0' ($diffCode -eq 0)
Check 'Index unchanged' ($indexCode -eq 0 -and (Get-FileHash ($e+'/index-before.diff')).Hash -eq (Get-FileHash ($e+'/index-after.diff')).Hash)
Check 'Source diff collected (new file no-index exit 1 expected)' ($diffSourceCode -eq 0 -and $newSourceCode -eq 1)
[ordered]@{path=$jar;sha256=(Get-FileHash -LiteralPath $jar).Hash;head=(Get-Content ($e+'/head.txt')).Trim();source='Uncommitted full source.diff / source-fingerprints.json';minecraft='1.21.1';neoforge='21.1.251';mod='1.0.0';javaToolchain='21';isolatedTestJdk='Temurin 21.0.12.1+1';gradle='9.2.1';modDevGradle='2.0.147';parchment='2024.11.17';license='All Rights Reserved';development='T-027 complete';review='R-03 pending';manual='T-028 pending';package='T-095 pending';gameExecuted=$false}|ConvertTo-Json|Set-Content -Encoding UTF8 ($e+'/artifact.json')
$failed=@($checks|Where-Object {-not $_.pass})
[ordered]@{command='powershell -NoProfile -ExecutionPolicy Bypass -File docs/evidence/T-027/audit.ps1';checks=$checks;count=$checks.Count;failed=$failed;changedExisting=@($changed.path);added=@($new.FullName);resourceCount=$resources.Count;declaredStates=144;naturalFlatMapped=48;unreachableSlopesUnmapped=96;gameExecuted=$false}|ConvertTo-Json -Depth 5|Set-Content -Encoding UTF8 ($e+'/audit-results-01.json')
Write-Output ('Checks='+$checks.Count+'; failed='+$failed.Count)
if($failed.Count){$failed|ConvertTo-Json;exit 1}
