$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$root='D:\workspace\java\simple-rail\src\main\resources\assets\simplerail'
$ev='D:\workspace\java\simple-rail-1.21.1\docs\evidence\T-015'
$rails=@('high_speed_rail','holding_rail','oneway_rail','eject_rail','destory_rail','timer_holding_rail','cross_rail','y_cross_rail','y_cross_right_rail')
$records=@();$models=@{};$textures=@{}
foreach($id in $rails){
 $path=Join-Path $root ("blockstates/$id.json")
 $raw=Get-Content -Raw -Encoding UTF8 -LiteralPath $path
 $modelMatches=@([regex]::Matches($raw,'"model"\s*:\s*"simplerail:block/([^"]+)"'))
 $refs=@($modelMatches|ForEach-Object {$_.Groups[1].Value}|Sort-Object -Unique)
 foreach($m in $refs){
  $modelPath=Join-Path $root ("models/block/$m.json")
  if(-not (Test-Path -LiteralPath $modelPath)){throw "Missing model $m"}
  $model=Get-Content -Raw -Encoding UTF8 -LiteralPath $modelPath|ConvertFrom-Json
  $modelTextures=@($model.textures.PSObject.Properties|ForEach-Object {$_.Value}|Where-Object {$_ -like 'simplerail:blocks/*'})
  foreach($t in $modelTextures){
   $name=$t.Substring('simplerail:blocks/'.Length)
   $texturePath=Join-Path $root ("textures/blocks/$name.png")
   if(-not (Test-Path -LiteralPath $texturePath)){throw "Missing texture $t"}
   if(-not $textures.ContainsKey($name)){
    $bitmap=[Drawing.Bitmap]::FromFile($texturePath)
    try{$w=$bitmap.Width;$h=$bitmap.Height;$transparent=0;for($y=0;$y -lt $h;$y++){for($x=0;$x -lt $w;$x++){if($bitmap.GetPixel($x,$y).A -eq 0){$transparent++}}}}
    finally{$bitmap.Dispose()}
    $textures[$name]=[ordered]@{id=$t;path=$texturePath;sha256=(Get-FileHash -LiteralPath $texturePath -Algorithm SHA256).Hash;width=$w;height=$h;fullyTransparentPixels=$transparent}
   }
  }
  $models[$m]=[ordered]@{id="simplerail:block/$m";path=$modelPath;sha256=(Get-FileHash -LiteralPath $modelPath -Algorithm SHA256).Hash;parent=$model.parent;hasRenderType=($null -ne $model.render_type);textures=$modelTextures}
 }
 $records += [ordered]@{id="simplerail:$id";blockstate=$path;sha256=(Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash;modelReferenceCount=$modelMatches.Count;models=$refs}
}
$entityTexture=Join-Path $root 'textures/entity/locomotive_cart.png'
$bitmap=[Drawing.Bitmap]::FromFile($entityTexture)
try{$width=$bitmap.Width;$height=$bitmap.Height;$format=[string]$bitmap.PixelFormat}finally{$bitmap.Dispose()}
$result=[ordered]@{command='& ([scriptblock]::Create((Get-Content -Raw -Encoding UTF8 docs/evidence/T-015/inspect-resources.ps1)))';exitCode=0;utc=[DateTime]::UtcNow.ToString('o');railBlocks=$records;blockModels=@($models.Values|Sort-Object id);blockTextures=@($textures.Values|Sort-Object id);entityTexture=[ordered]@{path=$entityTexture;sha256=(Get-FileHash -LiteralPath $entityTexture -Algorithm SHA256).Hash;width=$width;height=$height;pixelFormat=$format}}
$result|ConvertTo-Json -Depth 8|Set-Content -Encoding UTF8 (Join-Path $ev 'resources.json')
"Rail blocks: $($records.Count); referenced block models: $($models.Count); textures: $($textures.Count); entity texture ${width}x${height}"
