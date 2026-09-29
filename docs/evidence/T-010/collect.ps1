$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem
$root='D:\workspace\java\simple-rail-1.21.1'
$ev=Join-Path $root 'docs/evidence/T-010'
$jar=Join-Path $root 'build/moddev/artifacts/neoforge-21.1.251-sources.jar'
$names=@(
'net/minecraft/world/level/block/BaseRailBlock.java','net/minecraft/world/level/block/RailBlock.java','net/minecraft/world/level/block/PoweredRailBlock.java','net/minecraft/world/level/block/RailState.java',
'net/minecraft/world/level/block/Block.java','net/minecraft/world/level/block/state/BlockBehaviour.java','net/minecraft/world/level/block/DispenserBlock.java','net/minecraft/world/level/block/PoweredBlock.java',
'net/minecraft/world/level/block/state/StateDefinition.java','net/minecraft/world/level/block/state/StateHolder.java','net/minecraft/world/level/block/state/properties/BlockStateProperties.java','net/minecraft/world/level/block/state/properties/EnumProperty.java','net/minecraft/world/level/block/state/properties/BooleanProperty.java','net/minecraft/world/level/block/state/properties/IntegerProperty.java','net/minecraft/world/level/block/state/properties/RailShape.java','net/minecraft/world/level/block/state/properties/DirectionProperty.java',
'net/minecraft/world/entity/vehicle/AbstractMinecart.java','net/minecraft/world/entity/Entity.java','net/minecraft/world/level/Level.java','net/minecraft/core/Direction.java',
'net/minecraft/world/InteractionResult.java','net/minecraft/world/ItemInteractionResult.java','net/minecraft/world/item/Item.java','net/minecraft/world/item/ItemStack.java','net/minecraft/world/item/context/UseOnContext.java','net/minecraft/world/item/context/BlockPlaceContext.java',
'net/minecraft/server/level/ServerPlayerGameMode.java','net/minecraft/client/multiplayer/MultiPlayerGameMode.java',
'net/neoforged/neoforge/common/extensions/IBaseRailBlockExtension.java','net/neoforged/neoforge/common/extensions/IBlockExtension.java','net/neoforged/neoforge/common/extensions/IAbstractMinecartExtension.java','net/neoforged/neoforge/common/extensions/IItemExtension.java','net/neoforged/neoforge/common/ItemAbilities.java','net/neoforged/neoforge/common/ItemAbility.java','net/neoforged/neoforge/common/CommonHooks.java'
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
foreach($f in Get-ChildItem -LiteralPath $old -File -Recurse){
 $dest=Join-Path $ev ('sources/old/'+$f.FullName.Substring($old.Length+1))
 New-Item -ItemType Directory -Force (Split-Path $dest)|Out-Null
 Copy-Item -LiteralPath $f.FullName -Destination $dest
 $records += [ordered]@{origin=$f.FullName;snapshot=$dest.Substring($ev.Length+1);sha256=(Get-FileHash -LiteralPath $dest -Algorithm SHA256).Hash}
}
$records | ConvertTo-Json -Depth 5 | Set-Content -Encoding UTF8 (Join-Path $ev 'source-manifest.json')
[ordered]@{command='& ([scriptblock]::Create((Get-Content -Raw -Encoding UTF8 docs/evidence/T-010/collect.ps1)))';exitCode=0;utc=[DateTime]::UtcNow.ToString('o');targetSources=$names.Count;oldSources=($records.Count-$names.Count);archiveSha256=$hash} | ConvertTo-Json | Set-Content -Encoding UTF8 (Join-Path $ev 'collection.json')
"Snapshots: $($records.Count)"
