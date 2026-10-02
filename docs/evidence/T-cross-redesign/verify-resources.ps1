$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '../../..')).Path
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
        $expectedTexture = if($turn -eq 'right'){'simplerail:blocks/y_cross_right_turn_rail'}else{'simplerail:blocks/y_cross_turn_rail'}
        Assert ($model.textures.rail -eq $expectedTexture) 'Wrong turn texture'
        Assert (Test-Path "$assets/textures/$($model.textures.rail.Split(':')[1]).png") 'Missing turn PNG'
    }
}
Assert ((Json "$assets/models/item/t_cross_rail.json").textures.layer0 -eq 'simplerail:blocks/y_cross_right_turn_rail') 'Item must show default right turn'
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
Write-Output "PASS $script:checks resource/registry/JAR static checks (not runtime registration or rendering)"
