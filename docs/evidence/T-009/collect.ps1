$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem
$root='D:\workspace\java\simple-rail-1.21.1'
$old='D:\workspace\java\simple-rail'
$ev=Join-Path $root 'docs/evidence/T-009'
$jar=Join-Path $root 'build/moddev/artifacts/neoforge-21.1.251-sources.jar'
$names=@(
 'net/minecraft/SharedConstants.java','net/minecraft/DetectedVersion.java',
 'net/minecraft/core/registries/Registries.java','net/minecraft/resources/FileToIdConverter.java',
 'net/minecraft/server/packs/PackType.java','net/minecraft/server/packs/metadata/pack/PackMetadataSection.java',
 'net/minecraft/world/item/crafting/RecipeManager.java','net/minecraft/world/item/crafting/ShapedRecipe.java',
 'net/minecraft/world/item/crafting/ShapedRecipePattern.java','net/minecraft/world/item/crafting/Ingredient.java',
 'net/minecraft/world/item/ItemStack.java','net/minecraft/world/level/storage/loot/LootTable.java',
 'net/minecraft/world/level/storage/loot/LootPool.java','net/minecraft/world/level/storage/loot/LootDataType.java',
 'net/minecraft/world/level/storage/loot/entries/LootItem.java','net/minecraft/world/level/storage/loot/predicates/ExplosionCondition.java',
 'net/minecraft/tags/TagFile.java','net/minecraft/tags/TagEntry.java','net/minecraft/tags/TagManager.java',
 'net/minecraft/client/renderer/block/model/BlockModel.java','net/minecraft/client/renderer/block/model/BlockElement.java',
 'net/minecraft/client/renderer/block/model/BlockModelDefinition.java','net/minecraft/client/renderer/block/model/Variant.java',
 'net/minecraft/client/resources/model/BlockStateModelLoader.java','net/minecraft/client/resources/model/ModelBakery.java',
 'net/minecraft/client/renderer/texture/atlas/SpriteSourceList.java','net/minecraft/client/renderer/texture/atlas/sources/DirectoryLister.java',
 'net/minecraft/locale/Language.java','net/minecraft/client/resources/language/ClientLanguage.java',
 'net/neoforged/neoforge/resource/ResourcePackLoader.java','net/neoforged/neoforge/common/data/ExistingFileHelper.java',
 'net/minecraft/world/entity/vehicle/AbstractMinecart.java','net/minecraft/world/entity/EntityType.java',
 'net/minecraft/world/level/block/state/BlockBehaviour.java'
)
$records=@()
$hash=(Get-FileHash -LiteralPath $jar -Algorithm SHA256).Hash
$zip=[IO.Compression.ZipFile]::OpenRead($jar)
try{
 foreach($name in $names){
  $entry=$zip.GetEntry($name)
  if(-not $entry){throw "Missing entry: $name"}
  $dest=Join-Path $ev ('sources/target/'+$name)
  New-Item -ItemType Directory -Force (Split-Path $dest) | Out-Null
  [IO.Compression.ZipFileExtensions]::ExtractToFile($entry,$dest,$true)
  $records += [ordered]@{archive=$jar;archiveSha256=$hash;entry=$name;snapshot=$dest.Substring($ev.Length+1);sha256=(Get-FileHash -LiteralPath $dest -Algorithm SHA256).Hash}
 }
}finally{$zip.Dispose()}
foreach($base in @('src/main/resources','src/main/java')){
 foreach($file in Get-ChildItem -LiteralPath (Join-Path $old $base) -File -Recurse){
  $rel=$file.FullName.Substring($old.Length+1)
  $dest=Join-Path $ev ('sources/old/'+$rel)
  New-Item -ItemType Directory -Force (Split-Path $dest) | Out-Null
  Copy-Item -LiteralPath $file.FullName -Destination $dest
  $records += [ordered]@{origin=$file.FullName;snapshot=$dest.Substring($ev.Length+1);sha256=(Get-FileHash -LiteralPath $dest -Algorithm SHA256).Hash}
 }
}
$records | ConvertTo-Json -Depth 5 | Set-Content -Encoding UTF8 (Join-Path $ev 'source-manifest.json')
$head=& git -C $root rev-parse HEAD
$newStatus=@(& git -C $root status --short)
$oldHead=& git -C $old rev-parse HEAD
$oldStatus=@(& git -C $old status --short)
[ordered]@{command='& ([scriptblock]::Create((Get-Content -Raw -Encoding UTF8 docs/evidence/T-009/collect.ps1)))';exitCode=0;utc=[DateTime]::UtcNow.ToString('o');newHead=$head;newStatus=$newStatus;oldHead=$oldHead;oldStatus=$oldStatus;targetSources=$names.Count;snapshots=$records.Count} | ConvertTo-Json -Depth 4 | Set-Content -Encoding UTF8 (Join-Path $ev 'collection.json')
"Collected $($names.Count) target sources and $($records.Count-$names.Count) OLD files. No game/build execution."
