$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem
$root='D:\workspace\java\simple-rail-1.21.1'
$ev=Join-Path $root 'docs/evidence/T-013'
$jar=Join-Path $root 'build/moddev/artifacts/neoforge-21.1.251-sources.jar'
$names=@(
 'net/minecraft/world/entity/Entity.java',
 'net/minecraft/world/entity/EntityType.java',
 'net/minecraft/world/entity/vehicle/AbstractMinecart.java',
 'net/minecraft/world/entity/vehicle/VehicleEntity.java',
 'net/neoforged/neoforge/common/extensions/IAbstractMinecartExtension.java',
 'net/minecraft/world/entity/vehicle/MinecartFurnace.java',
 'net/minecraft/world/entity/vehicle/Minecart.java',
 'net/minecraft/world/entity/vehicle/AbstractMinecartContainer.java',
 'net/minecraft/world/item/MinecartItem.java',
 'net/minecraft/world/item/Item.java',
 'net/minecraft/world/item/ItemStack.java',
 'net/minecraft/world/item/context/UseOnContext.java',
 'net/minecraft/world/level/block/BaseRailBlock.java',
 'net/minecraft/world/level/block/state/properties/RailShape.java',
 'net/minecraft/server/level/ServerLevel.java',
 'net/minecraft/world/level/ServerLevelAccessor.java',
 'net/minecraft/world/level/entity/PersistentEntitySectionManager.java',
 'net/minecraft/world/level/entity/LevelEntityGetter.java',
 'net/minecraft/world/level/entity/EntityLookup.java',
 'net/minecraft/nbt/CompoundTag.java',
 'net/minecraft/nbt/ListTag.java',
 'net/minecraft/nbt/StringTag.java',
 'net/minecraft/core/component/DataComponents.java',
 'net/minecraft/world/damagesource/DamageSource.java',
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
$oldNames=@('entity/LocomotiveCartEntity.java','item/LocomotiveCart.java','link/LinkageManager.java','registry/Entities.java','constants/I18n.java','setup/SimpleRailDataSerializers.java')
foreach($n in $oldNames){
 $origin=Join-Path $old $n;$dest=Join-Path $ev ('sources/old/'+$n)
 New-Item -ItemType Directory -Force (Split-Path $dest)|Out-Null
 Copy-Item -LiteralPath $origin -Destination $dest
 $records += [ordered]@{origin=$origin;snapshot=$dest.Substring($ev.Length+1);sha256=(Get-FileHash -LiteralPath $dest -Algorithm SHA256).Hash}
}
$records|ConvertTo-Json -Depth 5|Set-Content -Encoding UTF8 (Join-Path $ev 'source-manifest.json')
[ordered]@{command='& ([scriptblock]::Create((Get-Content -Raw -Encoding UTF8 docs/evidence/T-013/collect.ps1)))';exitCode=0;utc=[DateTime]::UtcNow.ToString('o');targetSources=$names.Count;oldSources=$oldNames.Count;archiveSha256=$hash}|ConvertTo-Json|Set-Content -Encoding UTF8 (Join-Path $ev 'collection.json')
"Snapshots: $($records.Count)"
