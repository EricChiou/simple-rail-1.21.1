$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem
$root='D:\workspace\java\simple-rail-1.21.1'
$ev=Join-Path $root 'docs/evidence/T-015'
$jar=Join-Path $root 'build/moddev/artifacts/neoforge-21.1.251-sources.jar'
$names=@(
 'net/minecraft/client/model/MinecartModel.java',
 'net/minecraft/client/model/geom/ModelLayerLocation.java',
 'net/minecraft/client/model/geom/ModelPart.java',
 'net/minecraft/client/model/geom/builders/CubeDeformation.java',
 'net/minecraft/client/model/geom/builders/CubeListBuilder.java',
 'net/minecraft/client/model/geom/builders/LayerDefinition.java',
 'net/minecraft/client/model/geom/builders/MeshDefinition.java',
 'net/minecraft/client/model/geom/builders/PartDefinition.java',
 'net/minecraft/client/renderer/entity/EntityRendererProvider.java',
 'net/minecraft/client/renderer/entity/MinecartRenderer.java',
 'net/minecraft/client/renderer/ItemBlockRenderTypes.java',
 'net/minecraft/client/renderer/RenderType.java',
 'net/minecraft/client/renderer/MultiBufferSource.java',
 'net/neoforged/neoforge/client/event/EntityRenderersEvent.java',
 'net/neoforged/neoforge/client/event/RegisterNamedRenderTypesEvent.java',
 'net/minecraft/resources/ResourceLocation.java'
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
$oldNames=@('setup/Render.java','render/model/LocomotiveCartModel.java','render/LocomotiveCartRender.java','constants/Texture.java','registry/Blocks.java')
foreach($n in $oldNames){
 $origin=Join-Path $old $n;$dest=Join-Path $ev ('sources/old/'+$n)
 New-Item -ItemType Directory -Force (Split-Path $dest)|Out-Null
 Copy-Item -LiteralPath $origin -Destination $dest
 $records += [ordered]@{origin=$origin;snapshot=$dest.Substring($ev.Length+1);sha256=(Get-FileHash -LiteralPath $dest -Algorithm SHA256).Hash}
}
$records|ConvertTo-Json -Depth 5|Set-Content -Encoding UTF8 (Join-Path $ev 'source-manifest.json')
[ordered]@{command='& ([scriptblock]::Create((Get-Content -Raw -Encoding UTF8 docs/evidence/T-015/collect.ps1)))';exitCode=0;utc=[DateTime]::UtcNow.ToString('o');targetSources=$names.Count;oldSources=$oldNames.Count;archiveSha256=$hash}|ConvertTo-Json|Set-Content -Encoding UTF8 (Join-Path $ev 'collection.json')
"Snapshots: $($records.Count)"
