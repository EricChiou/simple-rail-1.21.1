$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem
$root='D:\workspace\java\simple-rail-1.21.1'
$ev=Join-Path $root 'docs/evidence/T-011'
$jar=Join-Path $root 'build/moddev/artifacts/neoforge-21.1.251-sources.jar'
$names=@(
 'net/minecraft/world/level/block/entity/BlockEntity.java',
 'net/minecraft/world/level/block/entity/BlockEntityType.java',
 'net/minecraft/world/level/block/entity/BlockEntityTicker.java',
 'net/minecraft/world/level/block/EntityBlock.java',
 'net/minecraft/world/level/block/BaseEntityBlock.java',
 'net/minecraft/world/level/block/BaseRailBlock.java',
 'net/minecraft/world/level/block/PoweredRailBlock.java',
 'net/minecraft/world/level/block/state/BlockBehaviour.java',
 'net/minecraft/world/level/Level.java',
 'net/minecraft/world/level/LevelAccessor.java',
 'net/minecraft/world/level/LevelWriter.java',
 'net/minecraft/server/level/ServerLevel.java',
 'net/minecraft/server/level/ServerChunkCache.java',
 'net/minecraft/server/level/ChunkMap.java',
 'net/minecraft/world/level/chunk/LevelChunk.java',
 'net/minecraft/world/level/chunk/storage/ChunkSerializer.java',
 'net/minecraft/world/ticks/LevelTicks.java',
 'net/minecraft/world/ticks/LevelChunkTicks.java',
 'net/minecraft/world/ticks/LevelTickAccess.java',
 'net/minecraft/world/ticks/ScheduledTick.java',
 'net/minecraft/world/ticks/TickPriority.java',
 'net/minecraft/nbt/CompoundTag.java',
 'net/minecraft/nbt/Tag.java',
 'net/minecraft/core/HolderLookup.java',
 'net/neoforged/neoforge/registries/DeferredRegister.java',
 'net/neoforged/neoforge/common/extensions/IBlockEntityExtension.java',
 'net/neoforged/neoforge/event/level/ChunkEvent.java',
 'net/neoforged/neoforge/event/level/ChunkDataEvent.java'
)
$records=@();$hash=(Get-FileHash -LiteralPath $jar -Algorithm SHA256).Hash
$z=[IO.Compression.ZipFile]::OpenRead($jar)
try{
 foreach($n in $names){
  $e=$z.GetEntry($n);if(-not $e){throw "Missing $n"}
  $dest=Join-Path $ev ('sources/target/'+$n)
  New-Item -ItemType Directory -Force (Split-Path $dest)|Out-Null
  [IO.Compression.ZipFileExtensions]::ExtractToFile($e,$dest,$true)
  $records += [ordered]@{archive=$jar;archiveSha256=$hash;entry=$n;snapshot=$dest.Substring($ev.Length+1);sha256=(Get-FileHash -LiteralPath $dest -Algorithm SHA256).Hash}
 }
}finally{$z.Dispose()}
$old='D:\workspace\java\simple-rail\src\main\java\ericchiu\simplerail'
foreach($n in @('tileentity/TimerHoldingRailTileEntity.java','tileentity/SignalTimerTileEntity.java','block/TimerHoldingRail.java','block/SignalTimerBlock.java','registry/TileEntities.java','constants/Config.java')){
 $origin=Join-Path $old $n;$dest=Join-Path $ev ('sources/old/'+$n)
 New-Item -ItemType Directory -Force (Split-Path $dest)|Out-Null
 Copy-Item -LiteralPath $origin -Destination $dest
 $records += [ordered]@{origin=$origin;snapshot=$dest.Substring($ev.Length+1);sha256=(Get-FileHash -LiteralPath $dest -Algorithm SHA256).Hash}
}
$records | ConvertTo-Json -Depth 5 | Set-Content -Encoding UTF8 (Join-Path $ev 'source-manifest.json')
[ordered]@{command='& ([scriptblock]::Create((Get-Content -Raw -Encoding UTF8 docs/evidence/T-011/collect.ps1)))';exitCode=0;utc=[DateTime]::UtcNow.ToString('o');targetSources=$names.Count;oldSources=($records.Count-$names.Count);archiveSha256=$hash} | ConvertTo-Json | Set-Content -Encoding UTF8 (Join-Path $ev 'collection.json')
"Snapshots: $($records.Count)"
