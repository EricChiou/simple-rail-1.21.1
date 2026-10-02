$ErrorActionPreference = 'Stop'
$root = (Get-Location).Path
$ev = Join-Path $root 'docs/evidence/T-037'
Add-Type -AssemblyName System.IO.Compression.FileSystem
$archivePath = Join-Path $root 'build/moddev/artifacts/neoforge-21.1.251-sources.jar'
$archive = [IO.Compression.ZipFile]::OpenRead($archivePath)
$names = @(
 'net/minecraft/nbt/CompoundTag.java','net/minecraft/nbt/NbtUtils.java',
 'net/minecraft/world/level/block/entity/BlockEntity.java','net/minecraft/world/level/Level.java',
 'net/minecraft/world/level/chunk/LevelChunk.java','net/minecraft/server/level/ChunkMap.java',
 'net/minecraft/server/level/ServerLevel.java','net/minecraft/world/level/chunk/storage/ChunkSerializer.java',
 'net/neoforged/neoforge/common/extensions/IBlockEntityExtension.java',
 'net/neoforged/neoforge/event/level/ChunkDataEvent.java','net/neoforged/neoforge/event/level/ChunkEvent.java',
 'net/neoforged/neoforge/event/RegisterCommandsEvent.java','net/minecraft/commands/Commands.java',
 'net/minecraft/commands/arguments/coordinates/BlockPosArgument.java')
try {
 foreach ($name in $names) {
  $entry = $archive.GetEntry($name)
  if (!$entry) { throw "Missing source $name" }
  $dest = Join-Path $ev ('sources/target/' + $name)
  [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($dest)) | Out-Null
  [IO.Compression.ZipFileExtensions]::ExtractToFile($entry,$dest,$true)
 }
} finally { $archive.Dispose() }
$inputs = @(Get-ChildItem (Join-Path $ev 'sources'),(Join-Path $ev 'fixture'),(Join-Path $ev 'tests') -File -Recurse)
$inputs += Get-Item (Join-Path $ev 'probe.init.gradle'),(Join-Path $ev 'build.ps1'),$archivePath
$inputs | ForEach-Object { [ordered]@{path=$_.FullName.Substring($root.Length+1).Replace('\','/');sha256=(Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash} } | ConvertTo-Json -Depth 4 | Set-Content (Join-Path $ev 'input-fingerprints.json') -Encoding UTF8
Copy-Item -LiteralPath 'build/t037/artifacts/simplerail-1.0.0-T037-probe.jar' -Destination (Join-Path $ev 'artifacts')
Copy-Item -LiteralPath 'build/libs/simplerail-1.0.0.jar' -Destination (Join-Path $ev 'artifacts')
$ErrorActionPreference = 'Continue'
& 'C:/Program Files/Eclipse Adoptium/jdk-21.0.12.101-hotspot/bin/java.exe' -version *> (Join-Path $ev 'java-version.log')
$javaExit = $LASTEXITCODE
$oldHead = & git -C 'D:/workspace/java/simple-rail' rev-parse HEAD
$oldGitExit = $LASTEXITCODE
& git diff --no-index -- src/main/java/com/ericchiu/simplerail/SimpleRail.java docs/evidence/T-037/fixture/com/ericchiu/simplerail/SimpleRail.java 2>$null | Set-Content (Join-Path $ev 'overlay-entry.diff') -Encoding UTF8
$entryDiffExit = $LASTEXITCODE
& git diff --no-index -- src/main/java/com/ericchiu/simplerail/registry/ModBlocks.java docs/evidence/T-037/fixture/com/ericchiu/simplerail/registry/ModBlocks.java 2>$null | Set-Content (Join-Path $ev 'overlay-registry.diff') -Encoding UTF8
$registryDiffExit = $LASTEXITCODE
$ErrorActionPreference = 'Stop'
[ordered]@{javaCommand='C:/Program Files/Eclipse Adoptium/jdk-21.0.12.101-hotspot/bin/java.exe -version';javaExitCode=$javaExit;oldHeadCommand='git -C D:/workspace/java/simple-rail rev-parse HEAD';oldHead=$oldHead;oldHeadExitCode=$oldGitExit;overlayDiffCommand='git diff --no-index -- <production source> <evidence overlay>';entryDiffExitCode=$entryDiffExit;registryDiffExitCode=$registryDiffExit;diffExitOneMeans='differences present, not failure';sourceArchive=$archivePath;archiveSha256=(Get-FileHash $archivePath).Hash;extractedCount=$names.Count;gameExecuted=$false;oldBuildExecuted=$false} | ConvertTo-Json | Set-Content (Join-Path $ev 'collection.json') -Encoding UTF8
Write-Output 'Collected 14 fixed-version sources, fingerprints, overlay diffs and artifacts.'
