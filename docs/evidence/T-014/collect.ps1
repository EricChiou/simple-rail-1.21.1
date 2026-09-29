$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem
$root='D:\workspace\java\simple-rail-1.21.1'
$ev=Join-Path $root 'docs/evidence/T-014'
$jar=Join-Path $root 'build/moddev/artifacts/neoforge-21.1.251-sources.jar'
$names=@(
 'net/minecraft/network/syncher/EntityDataSerializers.java',
 'net/minecraft/network/syncher/EntityDataSerializer.java',
 'net/minecraft/network/syncher/EntityDataAccessor.java',
 'net/minecraft/network/syncher/SynchedEntityData.java',
 'net/minecraft/network/RegistryFriendlyByteBuf.java',
 'net/minecraft/network/FriendlyByteBuf.java',
 'net/minecraft/network/codec/ByteBufCodecs.java',
 'net/minecraft/network/codec/StreamCodec.java',
 'net/minecraft/network/protocol/game/ClientboundAddEntityPacket.java',
 'net/minecraft/network/protocol/game/ClientboundSetEntityDataPacket.java',
 'net/minecraft/server/level/ServerEntity.java',
 'net/minecraft/server/level/ChunkMap.java',
 'net/minecraft/server/level/ServerLevel.java',
 'net/minecraft/client/multiplayer/ClientPacketListener.java',
 'net/minecraft/client/multiplayer/ClientLevel.java',
 'net/minecraft/world/entity/Entity.java',
 'net/minecraft/world/entity/EntityType.java',
 'net/neoforged/neoforge/entity/IEntityWithComplexSpawn.java',
 'net/neoforged/neoforge/common/extensions/IEntityExtension.java',
 'net/neoforged/neoforge/registries/NeoForgeRegistries.java',
 'net/neoforged/neoforge/registries/DeferredRegister.java'
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
$oldNames=@('entity/LocomotiveCartEntity.java','setup/SimpleRailDataSerializers.java','registry/Entities.java','SimpleRail.java','render/LocomotiveCartRender.java')
foreach($n in $oldNames){
 $origin=Join-Path $old $n;$dest=Join-Path $ev ('sources/old/'+$n)
 New-Item -ItemType Directory -Force (Split-Path $dest)|Out-Null
 Copy-Item -LiteralPath $origin -Destination $dest
 $records += [ordered]@{origin=$origin;snapshot=$dest.Substring($ev.Length+1);sha256=(Get-FileHash -LiteralPath $dest -Algorithm SHA256).Hash}
}
$records|ConvertTo-Json -Depth 5|Set-Content -Encoding UTF8 (Join-Path $ev 'source-manifest.json')
[ordered]@{command='& ([scriptblock]::Create((Get-Content -Raw -Encoding UTF8 docs/evidence/T-014/collect.ps1)))';exitCode=0;utc=[DateTime]::UtcNow.ToString('o');targetSources=$names.Count;oldSources=$oldNames.Count;archiveSha256=$hash}|ConvertTo-Json|Set-Content -Encoding UTF8 (Join-Path $ev 'collection.json')
"Snapshots: $($records.Count)"
