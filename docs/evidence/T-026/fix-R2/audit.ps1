$ErrorActionPreference='Stop'
$taskEvidence=Join-Path (Get-Location) 'docs/evidence/T-026/fix-R2'
$taskJdk='C:/Program Files/Eclipse Adoptium/jdk-21.0.12.101-hotspot/bin'
$checks=@()
function Check([string]$name,[bool]$pass){$script:checks += [ordered]@{name=$name;pass=$pass}}
$before=Get-Content -Raw -Encoding UTF8 (Join-Path $taskEvidence 'inputs-before.json')|ConvertFrom-Json
$changed=@($before|Where-Object {(Get-FileHash -LiteralPath $_.path).Hash -ne $_.sha256})
Check 'Only existing HighSpeedRail Java changed; no resources, base classes or Gradle changes' ($changed.Count -eq 1 -and $changed[0].path.EndsWith('\block\HighSpeedRail.java'))
$newFiles=@(Get-ChildItem src -Recurse -File|Where-Object {$before.path -notcontains $_.FullName})
Check 'Only one new production file: scalar geometry helper' ($newFiles.Count -eq 1 -and $newFiles[0].Name -eq 'RailAscentMovementLimit.java')
$source=Get-Content -Raw -Encoding UTF8 src/main/java/com/ericchiu/simplerail/block/HighSpeedRail.java
Check 'High-speed slope exception retained' ($source -match '(?s)canMakeSlopes.*?return true;')
Check 'No direction, position, velocity, passenger or ticket mutation introduced' ($source -notmatch 'setDeltaMovement|setPos\(|teleport|setCurrentCartSpeedCap|setNoGravity|startRiding|forceChunk')
Check 'No event/mixin or new state fields introduced' ($source -notmatch 'SubscribeEvent|Mixin|static.*Map<|private.*AbstractMinecart')
Check 'Per-call configured maximum still obtained from shared base' ($source -match 'super.getRailMaxSpeed\(state, level, pos, cart\)')
Check 'Next rail uses actual direction callback; all rail types accepted' ($source -match 'BaseRailBlock.isRail\(next\)' -and $source -match 'getRailDirection\(next, level, nextPos, cart\)')
Check 'Already elevated cart excluded' ($source -match 'cart.getY\(\) >= nextPos.getY\(\) \+ 1.0')
foreach($name in @('HighSpeedRail','RailAscentMovementLimit')){
    & ($taskJdk+'/javap.exe') -c -p -s -classpath build/classes/java/main ('com.ericchiu.simplerail.block.'+$name) *> (Join-Path $taskEvidence ($name+'-bytecode.txt'))
    Check ($name+' compiled bytecode exit 0') ($LASTEXITCODE -eq 0)
}
$bytecode=Get-Content -Raw (Join-Path $taskEvidence 'HighSpeedRail-bytecode.txt')
Check 'Compiled speed hook invokes geometry helper' ($bytecode -match 'RailAscentMovementLimit.limit')
$numeric=Get-Content -Raw -Encoding UTF8 (Join-Path $taskEvidence 'numeric-test.json')|ConvertFrom-Json
Check 'Standalone numeric compile/test succeeded; no game' ($numeric.compileExitCode -eq 0 -and $numeric.testExitCode -eq 0 -and -not $numeric.minecraftStarted)
$build=Get-Content -Raw -Encoding UTF8 (Join-Path $taskEvidence 'build-01.json')|ConvertFrom-Json
Check 'NEW build exit 0' ($build.exitCode -eq 0)
$artifact=Join-Path $taskEvidence 'artifacts/simplerail-1.0.0.jar'
Copy-Item -LiteralPath build/libs/simplerail-1.0.0.jar -Destination $artifact
Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip=[IO.Compression.ZipFile]::OpenRead($artifact)
$resources=Get-ChildItem src/main/resources -Recurse -File
foreach($file in $resources){
    $relative=$file.FullName.Substring((Resolve-Path src/main/resources).Path.Length+1).Replace('\','/')
    $entry=$zip.GetEntry($relative)
    $pass=$false
    if($entry){$stream=$entry.Open();$sha=[Security.Cryptography.SHA256]::Create();$hash=[BitConverter]::ToString($sha.ComputeHash($stream)).Replace('-','');$stream.Dispose();$sha.Dispose();$pass=$hash -eq (Get-FileHash -LiteralPath $file.FullName).Hash}
    Check ('JAR resource: '+$relative) $pass
}
foreach($name in @('HighSpeedRail','RailAscentMovementLimit')){Check ('JAR class '+$name) ($null -ne $zip.GetEntry('com/ericchiu/simplerail/block/'+$name+'.class'))}
$zip.Dispose()
$ErrorActionPreference='Continue'
git diff --cached --binary | Out-File -Encoding UTF8 (Join-Path $taskEvidence 'index-after-02.diff');$indexCode=$LASTEXITCODE
git -c core.safecrlf=false diff --check *> (Join-Path $taskEvidence 'diff-check.log');$diffCode=$LASTEXITCODE
$ErrorActionPreference='Stop'
Check 'git diff --check exit 0' ($diffCode -eq 0)
Check 'Index text unchanged since R2 snapshot (explicit same encoding)' ($indexCode -eq 0 -and (Get-FileHash (Join-Path $taskEvidence 'index-before.diff')).Hash -eq (Get-FileHash (Join-Path $taskEvidence 'index-after-02.diff')).Hash)
$fingerprints=@(Get-ChildItem src -Recurse -File|ForEach-Object {[ordered]@{path=$_.FullName;sha256=(Get-FileHash -LiteralPath $_.FullName).Hash}})
$fingerprints|ConvertTo-Json -Depth 5|Set-Content -Encoding UTF8 (Join-Path $taskEvidence 'source-fingerprints.json')
$sources=@('docs/evidence/T-025/sources/target/net/minecraft/world/entity/vehicle/AbstractMinecart.java','docs/evidence/T-010/sources/target/net/minecraft/world/entity/Entity.java','docs/evidence/T-010/sources/target/net/neoforged/neoforge/common/extensions/IBaseRailBlockExtension.java','docs/evidence/T-026/fix-R2/EntityType.java','build/moddev/artifacts/neoforge-21.1.251-sources.jar')
@($sources|ForEach-Object {[ordered]@{path=$_;sha256=(Get-FileHash -LiteralPath $_).Hash}})|ConvertTo-Json|Set-Content -Encoding UTF8 (Join-Path $taskEvidence 'primary-sources.json')
[ordered]@{jar=$artifact;sha256=(Get-FileHash $artifact).Hash;head=(Get-Content (Join-Path $taskEvidence 'head.txt')).Trim();source='Uncommitted changes, source-fingerprints.json and source.diff';minecraft='1.21.1';neoforge='21.1.251';mod='1.0.0';java='Temurin 21.0.12.1+1';gradle='9.2.1';license='All Rights Reserved';review='R-03 / R-F pending';manual='I-026-01 user confirmed; I-026-02 R2 not tested';gameStartedByAgent=$false}|ConvertTo-Json|Set-Content -Encoding UTF8 (Join-Path $taskEvidence 'artifact.json')
$failed=@($checks|Where-Object {-not $_.pass})
[ordered]@{checks=$checks;count=$checks.Count;failed=$failed;changedExistingFiles=$changed;newFiles=@($newFiles.FullName);resources=$resources.Count;gameExecuted=$false}|ConvertTo-Json -Depth 7|Set-Content -Encoding UTF8 (Join-Path $taskEvidence 'audit-results-02.json')
Write-Output ('Checks='+$checks.Count+'; failed='+$failed.Count)
if($failed.Count){$failed|ConvertTo-Json;exit 1}
