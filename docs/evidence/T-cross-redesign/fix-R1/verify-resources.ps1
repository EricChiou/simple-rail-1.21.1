$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '../../../..')).Path
Set-Location $root
$script:checks = 0
function Assert([bool] $ok, [string] $message) {
    if (!$ok) { throw $message }
    $script:checks++
}
function Json([string] $p) { Get-Content -Raw -Encoding UTF8 -LiteralPath $p | ConvertFrom-Json }
$assets = 'src/main/resources/assets/simplerail'
$states = (Json "$assets/blockstates/t_cross_rail.json").variants
Assert (@($states.PSObject.Properties).Count -eq 8) 'Expected exactly 4 directions x 2 power states'
$rotations = @{ north = 0; east = 90; south = 180; west = 270 }
foreach($dir in @('north','east','south','west')) {
    foreach($power in @('false','true')) {
        $variant = $states."direction=$dir,powered=$power"
        $turn = if($power -eq 'false'){'right'}else{'left'}
        Assert ($variant.model -eq "simplerail:block/t_cross_${turn}_rail") "Texture state mismatch $dir/$power"
        Assert ([int]$variant.y -eq $rotations[$dir]) "Wrong model rotation $dir/$power"
        $model = Json "$assets/models/block/t_cross_${turn}_rail.json"
        Assert ($model.render_type -eq 'minecraft:cutout') 'Missing cutout'
        $expectedTexture = 'simplerail:blocks/cross_rail'
        Assert ($model.textures.rail -eq $expectedTexture) 'Wrong turn texture'
        Assert (Test-Path "$assets/textures/$($model.textures.rail.Split(':')[1]).png") 'Missing turn PNG'
    }
}
Assert ((Json "$assets/models/item/t_cross_rail.json").parent -eq 'simplerail:block/t_cross_right_rail') 'Item must show default fixed T and right bend'
foreach($lang in @('en_us','zh_tw')) {
    $json=Json "$assets/lang/$lang.json"
    Assert (![string]::IsNullOrEmpty($json.'block.simplerail.t_cross_rail')) 'Missing T translation'
    Assert ($null -eq $json.'block.simplerail.y_cross_rail' -and $null -eq $json.'block.simplerail.y_cross_right_rail') 'Old translations remain'
}
foreach($p in @('src/main/resources/data/minecraft/tags/block/rails.json','src/main/resources/data/simplerail/tags/block/rails.json')) {
    $values=(Json $p).values
    Assert ($values.Count -eq 8 -and @($values | Where-Object {$_ -eq 'simplerail:t_cross_rail'}).Count -eq 1) 'Rails tag must contain 8 unique current rails'
    Assert ($values -notcontains 'simplerail:y_cross_rail' -and $values -notcontains 'simplerail:y_cross_right_rail') 'Old registry in tag'
}
$recipe = Json 'src/main/resources/data/simplerail/recipe/t_cross_rail.json'
Assert ($recipe.result.id -eq 'simplerail:t_cross_rail' -and $recipe.result.count -eq 1) 'Wrong recipe result'
$loot = Json 'src/main/resources/data/simplerail/loot_table/blocks/t_cross_rail.json'
Assert ($loot.pools[0].entries[0].name -eq 'simplerail:t_cross_rail') 'Wrong loot result'
$blocks=Get-Content -Raw src/main/java/com/ericchiu/simplerail/registry/ModBlocks.java
$items=Get-Content -Raw src/main/java/com/ericchiu/simplerail/registry/ModItems.java
Assert ([regex]::Matches($blocks,'BLOCKS\.registerBlock\(').Count -eq 10) 'Expected 10 block registrations'
Assert ([regex]::Matches($items,'ITEMS\.register(SimpleBlockItem|Item)\(').Count -eq 12) 'Expected 12 item registrations'
Assert (@(Get-ChildItem src/main/resources/data/simplerail/recipe -File).Count -eq 12) 'Expected 12 recipes'
Add-Type -AssemblyName System.IO.Compression.FileSystem
$jar=[IO.Compression.ZipFile]::OpenRead((Join-Path $root 'build/libs/simplerail-1.0.0.jar'))
try {
    foreach($path in @('com/ericchiu/simplerail/block/TCrossRail.class','assets/simplerail/blockstates/t_cross_rail.json','assets/simplerail/models/item/t_cross_rail.json','assets/simplerail/models/block/t_cross_left_rail.json','assets/simplerail/models/block/t_cross_right_rail.json','data/simplerail/recipe/t_cross_rail.json','data/simplerail/loot_table/blocks/t_cross_rail.json')) {
        $entry=$jar.GetEntry($path)
        Assert ($null -ne $entry) "JAR missing $path"
        if($path.EndsWith('.json')) {
            $stream=$entry.Open()
            $sha=[Security.Cryptography.SHA256]::Create()
            try { $hash=([BitConverter]::ToString($sha.ComputeHash($stream))).Replace('-','') }
            finally { $stream.Dispose(); $sha.Dispose() }
            Assert ($hash -eq (Get-FileHash -Algorithm SHA256 "src/main/resources/$path").Hash) "JAR stale $path"
        }
    }
    foreach($old in @('YCrossRail','YCrossRightRail','AbstractYCrossRail')) {
        Assert ($null -eq $jar.GetEntry("com/ericchiu/simplerail/block/$old.class")) 'JAR contains obsolete Y class'
    }
    foreach($old in @('y_cross_rail','y_cross_right_rail')) {
        foreach($path in @("assets/simplerail/blockstates/$old.json","assets/simplerail/models/item/$old.json","data/simplerail/recipe/$old.json","data/simplerail/loot_table/blocks/$old.json")) {
            Assert ($null -eq $jar.GetEntry($path)) "JAR contains obsolete $path"
        }
    }
} finally { $jar.Dispose() }

# The outline and ties must be identical in both power states; only the switch moves.
$right=Json "$assets/models/block/t_cross_right_rail.json"
$left=Json "$assets/models/block/t_cross_left_rail.json"
$rCommon=@($right.elements | Where-Object { $_.name -notlike 'switch-*' }) | ConvertTo-Json -Depth 12 -Compress
$lCommon=@($left.elements | Where-Object { $_.name -notlike 'switch-*' }) | ConvertTo-Json -Depth 12 -Compress
Assert ($rCommon -ceq $lCommon) 'Power changed fixed T outline or ties'
function Mask($model,[string]$pattern) {
    $cells=@{}
    foreach($e in $model.elements | Where-Object { $_.name -like $pattern }) {
        for($z=[int]$e.from[2];$z -lt $e.to[2];$z++){for($x=[int]$e.from[0];$x -lt $e.to[0];$x++){ $cells["$x,$z"]=$true }}
    }
    return $cells
}
$rs=Mask $right 'switch-*'; $ls=Mask $left 'switch-*'
Assert ($rs.Count -gt 0 -and $rs.Count -eq $ls.Count) 'Missing mirrored switch'
foreach($key in $rs.Keys){$xz=$key.Split(',');Assert ($ls.ContainsKey("$(15-[int]$xz[0]),$($xz[1])")) 'Bends must mirror within fixed frame'}
$frame=Mask $right 'frame-*'
foreach($key in @('0,2','15,2','0,12','15,12','2,15','13,15')){Assert ($frame.ContainsKey($key)) "Missing T frame $key"}
foreach($key in @('7,0','7,15','0,7','15,7')){Assert (!$frame.ContainsKey($key)) "Frame crossed entrance or added north spur $key"}
Add-Type -AssemblyName System.Drawing
$png=[Drawing.Bitmap]::new((Resolve-Path "$assets/textures/blocks/cross_rail.png").Path)
try {
    foreach($model in @($right,$left)){
        Assert ($model.parent -eq 'minecraft:block/block') 'Wrong native model parent'
        foreach($e in $model.elements){
            Assert ($e.from[0] -ge 0 -and $e.from[2] -ge 0 -and $e.to[0] -le 16 -and $e.to[2] -le 16 -and $e.from[0] -lt $e.to[0] -and $e.from[2] -lt $e.to[2]) 'Invalid plane bounds'
            Assert ($e.from[1] -eq $e.to[1] -and $e.from[1] -gt 0 -and $e.from[1] -lt 1) 'Rail must remain flat above support'
            foreach($face in @($e.faces.up,$e.faces.down)){
                Assert ($face.texture -eq '#rail') 'Unresolved face texture'
                $uv=$face.uv
                for($v=[int]($uv[1]*2);$v -lt $uv[3]*2;$v++){for($u=[int]($uv[0]*2);$u -lt $uv[2]*2;$u++){
                    Assert ($png.GetPixel($u,$v).A -eq 255) 'Sampled transparent texel'
                }}
            }
        }
    }
} finally {$png.Dispose()}
$previousInputs=Get-Content -Raw -Encoding UTF8 'docs/test-packages/T-cross-v1/source-inputs.json' | ConvertFrom-Json
$previousTexture=$previousInputs | Where-Object {$_.path -eq 'src/main/resources/assets/simplerail/textures/blocks/cross_rail.png'}
Assert ((Get-FileHash "$assets/textures/blocks/cross_rail.png").Hash -eq $previousTexture.sha256) 'Existing PNG was modified'
Write-Output "PASS $script:checks resource/model/registry/JAR static checks (not in-game rendering)"


