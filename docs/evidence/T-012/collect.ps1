$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem
$root='D:\workspace\java\simple-rail-1.21.1'
$ev=Join-Path $root 'docs/evidence/T-012'
$jar=Join-Path $root 'build/moddev/artifacts/neoforge-21.1.251-sources.jar'
$names=@(
 'net/minecraft/world/Container.java',
 'net/minecraft/world/ContainerHelper.java',
 'net/minecraft/world/SimpleContainer.java',
 'net/minecraft/world/MenuProvider.java',
 'net/minecraft/world/SimpleMenuProvider.java',
 'net/minecraft/world/inventory/ChestMenu.java',
 'net/minecraft/world/inventory/AbstractContainerMenu.java',
 'net/minecraft/world/inventory/MenuType.java',
 'net/minecraft/world/level/block/DispenserBlock.java',
 'net/minecraft/world/level/block/entity/DispenserBlockEntity.java',
 'net/minecraft/world/level/block/entity/ChestBlockEntity.java',
 'net/minecraft/world/level/block/entity/BaseContainerBlockEntity.java',
 'net/minecraft/world/level/block/entity/RandomizableContainerBlockEntity.java',
 'net/minecraft/world/level/block/entity/BlockEntity.java',
 'net/minecraft/world/level/block/entity/BlockEntityType.java',
 'net/minecraft/world/level/chunk/LevelChunk.java',
 'net/minecraft/world/item/ItemStack.java',
 'net/minecraft/core/NonNullList.java',
 'net/minecraft/server/level/ServerPlayer.java',
 'net/minecraft/client/gui/screens/inventory/ContainerScreen.java',
 'net/minecraft/client/gui/screens/MenuScreens.java',
 'net/neoforged/neoforge/items/ItemStackHandler.java',
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
$origin=Join-Path $old 'block/TrainDispenserBlock.java';$dest=Join-Path $ev 'sources/old/block/TrainDispenserBlock.java'
New-Item -ItemType Directory -Force (Split-Path $dest)|Out-Null
Copy-Item -LiteralPath $origin -Destination $dest
$records += [ordered]@{origin=$origin;snapshot=$dest.Substring($ev.Length+1);sha256=(Get-FileHash -LiteralPath $dest -Algorithm SHA256).Hash}
$records|ConvertTo-Json -Depth 5|Set-Content -Encoding UTF8 (Join-Path $ev 'source-manifest.json')
[ordered]@{command='& ([scriptblock]::Create((Get-Content -Raw -Encoding UTF8 docs/evidence/T-012/collect.ps1)))';exitCode=0;utc=[DateTime]::UtcNow.ToString('o');targetSources=$names.Count;oldSources=1;archiveSha256=$hash}|ConvertTo-Json|Set-Content -Encoding UTF8 (Join-Path $ev 'collection.json')
"Snapshots: $($records.Count)"
