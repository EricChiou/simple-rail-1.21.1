$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem
$ev=Join-Path $PWD 'docs/evidence/T-009'
$records=@()
$sets=@(
 @{name='target';jar=(Join-Path $PWD 'build/moddev/artifacts/neoforge-21.1.251-sources.jar');entries=@('net/minecraft/world/level/storage/loot/parameters/LootContextParamSets.java','net/minecraft/world/level/storage/loot/ValidationContext.java','net/neoforged/neoforge/common/crafting/CraftingHelper.java','net/neoforged/neoforge/client/textures/NamespacedDirectoryLister.java','net/minecraft/client/renderer/texture/atlas/SpriteSources.java','net/minecraft/server/ReloadableServerRegistries.java','net/minecraft/client/resources/model/BlockModelRotation.java','net/minecraft/world/level/storage/loot/parameters/LootContextParamSet.java','net/neoforged/neoforge/client/ClientHooks.java','net/neoforged/neoforge/client/ClientNeoForgeMod.java')},
 @{name='vanilla';jar='C:\Users\Kinoko\.gradle\caches\neoformruntime\artifacts\minecraft_1.21.1_client.jar';entries=@('version.json','assets/minecraft/atlases/blocks.json','assets/minecraft/models/block/rail_flat.json','assets/minecraft/models/block/rail_raised_ne.json','assets/minecraft/models/block/cube_all.json','assets/minecraft/models/item/generated.json','assets/minecraft/models/item/handheld.json','data/minecraft/recipe/rail.json','data/minecraft/recipe/powered_rail.json','data/minecraft/loot_table/blocks/rail.json','data/minecraft/tags/block/rails.json')}
)
foreach($set in $sets){
 $hash=(Get-FileHash -LiteralPath $set.jar -Algorithm SHA256).Hash
 $z=[IO.Compression.ZipFile]::OpenRead($set.jar)
 try{
  foreach($name in $set.entries){
   $e=$z.GetEntry($name)
   if(-not $e){throw "Missing $name"}
   $dest=Join-Path $ev ('sources/'+$set.name+'/'+$name)
   New-Item -ItemType Directory -Force (Split-Path $dest) | Out-Null
   [IO.Compression.ZipFileExtensions]::ExtractToFile($e,$dest,$true)
   $records += [ordered]@{archive=$set.jar;archiveSha256=$hash;entry=$name;snapshot=$dest.Substring($ev.Length+1);sha256=(Get-FileHash -LiteralPath $dest -Algorithm SHA256).Hash}
  }
 }finally{$z.Dispose()}
}
$records | ConvertTo-Json -Depth 5 | Set-Content -Encoding UTF8 (Join-Path $ev 'extra-source-manifest.json')
"Extra source/resource snapshots: $($records.Count)"
