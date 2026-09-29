$ErrorActionPreference='Stop'
$root='D:\workspace\java\simple-rail-1.21.1'
Set-Location $root
$source=Get-Content -Raw -Encoding UTF8 docs/evidence/T-005/source-manifest.json | ConvertFrom-Json
$checked=@($source | ForEach-Object {
 $actual=(Get-FileHash -Algorithm SHA256 -LiteralPath $_.path).Hash
 [ordered]@{path=$_.path;baselineSha256=$_.sha256;actualSha256=$actual;equal=($actual -eq $_.sha256)}
})
if(@($checked | Where-Object {-not $_.equal}).Count){throw 'Product source differs from T-005 baseline'}
$head=& git rev-parse HEAD
$headExit=$LASTEXITCODE
$diff=@(& git diff HEAD -- src build.gradle settings.gradle gradle.properties gradle gradlew gradlew.bat)
$diffExit=$LASTEXITCODE
$status=@(& git status --short)
$statusExit=$LASTEXITCODE
foreach($id in 'T-006','T-007') {
 $ev=Join-Path $root "docs\evidence\$id"
 $run=Join-Path $root "run\$id"
 $launch=Get-Content -Raw -Encoding UTF8 (Join-Path $ev 'launch.json') | ConvertFrom-Json
 if($null -eq $launch.exitCode){throw "$id has not exited"}
 New-Item -ItemType Directory -Force (Join-Path $ev 'logs'),(Join-Path $ev 'config') | Out-Null
 Get-ChildItem (Join-Path $run 'logs') -File | Copy-Item -Destination (Join-Path $ev 'logs')
 Get-ChildItem (Join-Path $run 'config') -File | Copy-Item -Destination (Join-Path $ev 'config')
 foreach($name in 'options.txt','server.properties','eula.txt') {
  $file=Join-Path $run $name
  if(Test-Path $file){Copy-Item $file (Join-Path $ev "config\$name")}
 }
 $world=if($id -eq 'T-006'){Join-Path $run 'saves\T006-new-world'}else{Join-Path $run 'T007-new-world'}
 $zip=Join-Path $ev "$id-world.zip"
 if(-not(Test-Path $zip)){Compress-Archive -LiteralPath $world -DestinationPath $zip}
 $inventory=@(Get-ChildItem $world -Recurse -File | ForEach-Object {
  [ordered]@{path=$_.FullName.Substring($world.Length+1);bytes=$_.Length;sha256=(Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash}
 })
 $inventory | ConvertTo-Json -Depth 5 | Set-Content -Encoding UTF8 (Join-Path $ev 'world-manifest.json')
 $checked | ConvertTo-Json -Depth 5 | Set-Content -Encoding UTF8 (Join-Path $ev 'source-check.json')
 [ordered]@{checkedUtc=[DateTime]::UtcNow.ToString('o');newPath=$root;newHead=$head;headExitCode=$headExit;oldPath='D:\workspace\java\simple-rail';oldHeadReference='6698b1c5f494095a15b055c10045293e91540012 (T-003 reference; OLD not run)';sourceDiff=$diff;diffExitCode=$diffExit;gitStatus=$status;statusExitCode=$statusExit;launchExitCode=$launch.exitCode;world=$world;worldZipSha256=(Get-FileHash $zip -Algorithm SHA256).Hash} | ConvertTo-Json -Depth 5 | Set-Content -Encoding UTF8 (Join-Path $ev 'verification.json')
 $log=Join-Path $ev 'logs\debug.log'
 $lines=Get-Content -Encoding UTF8 $log
 $lines | Select-String -Pattern 'Mod List:' -Context 0,5 | Out-String -Width 250 | Set-Content -Encoding UTF8 (Join-Path $ev 'mod-list.txt')
 $lines | Select-String -Pattern 'ModLauncher.*java version|Found valid mod file.*simplerail|Starting integrated minecraft server|logged in with entity|Done \(|Saved the game|Stopping server|All dimensions are saved|Stopping!' | Out-String -Width 250 | Set-Content -Encoding UTF8 (Join-Path $ev 'key-events.txt')
 $lines | Select-String -Pattern '/WARN\]|/ERROR\]|/FATAL\]' | Out-String -Width 300 | Set-Content -Encoding UTF8 (Join-Path $ev 'warnings-errors.txt')
}
'Evidence copied, worlds archived, product source hashes match T-005.'
