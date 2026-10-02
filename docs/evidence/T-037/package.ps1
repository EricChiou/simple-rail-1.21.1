$ErrorActionPreference='Stop'
$root=(Get-Location).Path
$ev=Join-Path $root 'docs/evidence/T-037'
$pkg=Join-Path $root 'docs/test-packages/T-037-v1'
$zip=Join-Path $root 'docs/test-packages/T-037-v1.zip'
if(Test-Path -LiteralPath $zip) { throw 'Fixed package already sealed; do not overwrite.' }
New-Item -ItemType Directory -Path (Join-Path $pkg 'mods'),(Join-Path $pkg 'evidence') -Force | Out-Null
Copy-Item -LiteralPath (Join-Path $ev 'artifacts/simplerail-1.0.0-T037-probe.jar') -Destination (Join-Path $pkg 'mods')
$inputPaths=@(Get-ChildItem (Join-Path $ev 'sources'),(Join-Path $ev 'fixture'),(Join-Path $ev 'tests') -File -Recurse)
$inputPaths+=Get-Item (Join-Path $ev 'probe.init.gradle'),(Join-Path $ev 'build.ps1'),'build/moddev/artifacts/neoforge-21.1.251-sources.jar'
$inputPaths | ForEach-Object { [ordered]@{path=$_.FullName.Substring($root.Length+1).Replace('\','/');sha256=(Get-FileHash -LiteralPath $_.FullName).Hash} } | ConvertTo-Json -Depth 4 | Set-Content (Join-Path $ev 'input-fingerprints.json') -Encoding UTF8
foreach($folder in @('fixture','tests','sources')) {
 foreach($file in (Get-ChildItem -LiteralPath (Join-Path $ev $folder) -File -Recurse)) {
  $dest=Join-Path (Join-Path $pkg 'evidence') $file.FullName.Substring($ev.Length+1)
  [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($dest)) | Out-Null
  Copy-Item -LiteralPath $file.FullName -Destination $dest -Force
 }
}
foreach($file in @('probe.init.gradle','build.ps1','build-01.log','build-01.json','build-02.log','build-02.json','build-03.log','build-03.json','compiler.txt','java-version.log','collection.json','old-head.json','input-fingerprints.json','product-before.json','overlay-entry.diff','overlay-registry.diff','INVESTIGATION.md')) {
 Copy-Item -LiteralPath (Join-Path $ev $file) -Destination (Join-Path $pkg 'evidence')
}
$cases=@()
foreach($n in 1..7) {
 $modes=if($n -eq 3){@('DS')}else{@('SP','DS')}
 foreach($mode in $modes) {$cases += ('T119-{0:D2}-{1}' -f $n,$mode)}
}
$jar=Get-Item (Join-Path $pkg 'mods/simplerail-1.0.0-T037-probe.jar')
$manifest=[ordered]@{
 packageId='T-037-v1';createdDate='2026-09-30';developerTask='T-037';manualTask='T-119';caseIds=$cases
 head=(Get-Content (Join-Path $ev 'head.txt') -Raw).Trim();workingTreeScope='Production unchanged; evidence-only fixture and documentation are uncommitted.'
 minecraft='1.21.1';neoForge='21.1.251';modId='simplerail';modVersion='1.0.0';license='All Rights Reserved'
 javaBuild='Temurin 21.0.12.1+1';javaRuntimeMajor=21;gradle='9.2.1';modDevGradle='2.0.147';parchment='1.21.1 / 2024.11.17'
 jar='mods/'+$jar.Name;jarSha256=(Get-FileHash -LiteralPath $jar.FullName).Hash
 normalProductionJarSha256=(Get-FileHash -LiteralPath (Join-Path $ev 'artifacts/simplerail-1.0.0.jar')).Hash
 review='R-04 pending';manualResult=$null;gameExecutedByAgent=$false;oldBuildExecuted=$false
 buildCommand='.\gradlew.bat build t037Jar testT037 --offline --console=plain --no-configuration-cache -I docs/evidence/T-037/probe.init.gradle';buildExitCode=0
 nonGameChecks=1049;gradleTest='NO-SOURCE';limits=@('Synthetic timer only; no minecart holding or release.','Controlled save/unload arm is instrumentation, not a production policy.','M-01 formal gameplay tolerance remains undefined.','No OLD world or NBT conversion.','No user results recorded.')
}
$manifest | ConvertTo-Json -Depth 6 | Set-Content (Join-Path $pkg 'manifest.json') -Encoding UTF8
[ordered]@{task='T-119';packageId='T-037-v1';userConfirmation=$null;recordedDate=$null;cases=@($cases | ForEach-Object {[ordered]@{id=$_;expected='See CASES.md';actual=$null;result=$null;notes=$null}});attachmentsOptional=$true} | ConvertTo-Json -Depth 6 | Set-Content (Join-Path $pkg 'results.json') -Encoding UTF8
Get-ChildItem -LiteralPath $pkg -File -Recurse | Where-Object {$_.Name -ne 'files-manifest.json'} | ForEach-Object { [ordered]@{path=$_.FullName.Substring($pkg.Length+1).Replace('\','/');sha256=(Get-FileHash -LiteralPath $_.FullName).Hash} } | ConvertTo-Json -Depth 4 | Set-Content (Join-Path $pkg 'files-manifest.json') -Encoding UTF8
Add-Type -AssemblyName System.IO.Compression.FileSystem
Add-Type -AssemblyName System.IO.Compression
$out=[IO.Compression.ZipFile]::Open($zip,[IO.Compression.ZipArchiveMode]::Create)
try {
 foreach($file in (Get-ChildItem -LiteralPath $pkg -File -Recurse)) {
  $entry=$file.FullName.Substring($pkg.Length+1).Replace('\','/')
  [IO.Compression.ZipFileExtensions]::CreateEntryFromFile($out,$file.FullName,$entry,[IO.Compression.CompressionLevel]::Optimal) | Out-Null
 }
} finally { $out.Dispose() }
[ordered]@{command='powershell -NoProfile -ExecutionPolicy Bypass -File docs/evidence/T-037/package.ps1';exitCode=0;package=$pkg;zip=$zip;zipSha256=(Get-FileHash -LiteralPath $zip).Hash;jarSha256=$manifest.jarSha256;caseVariantCount=$cases.Count} | ConvertTo-Json | Set-Content (Join-Path $ev 'package.json') -Encoding UTF8
Write-Output ('Sealed T-037-v1; case variants='+$cases.Count+'; diagnostic JAR SHA256='+$manifest.jarSha256)
