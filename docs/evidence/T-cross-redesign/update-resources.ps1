$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '../../..')).Path
$utf8 = New-Object System.Text.UTF8Encoding($false)
function Read-Resource([string] $path) { [IO.File]::ReadAllText((Join-Path $root $path)) }
function Write-Resource([string] $path, [string] $text) { [IO.File]::WriteAllText((Join-Path $root $path), $text, $utf8) }

foreach ($path in @('src/main/resources/data/minecraft/tags/block/rails.json', 'src/main/resources/data/simplerail/tags/block/rails.json')) {
    $text = Read-Resource $path
    $text = $text.Replace('"simplerail:y_cross_rail",', '"simplerail:t_cross_rail"')
    $text = $text -replace '(?m)^\s*"simplerail:y_cross_right_rail"\r?\n', ''
    Write-Resource $path $text
}
foreach ($lang in @('en_us', 'zh_tw')) {
    $path = "src/main/resources/assets/simplerail/lang/$lang.json"
    $text = Read-Resource $path
    $name = if ($lang -eq 'en_us') { 'T-Cross Rail' } else { 'T型交叉鐵軌' }
    $text = $text -replace '"block.simplerail.y_cross_rail": "[^"]*"', ('"block.simplerail.t_cross_rail": "' + $name + '"')
    $text = $text -replace '(?m)^\s*"block.simplerail.y_cross_right_rail": [^\r\n]*\r?\n', ''
    Write-Resource $path $text
}
$assets = 'src/main/resources/assets/simplerail'
$data = 'src/main/resources/data/simplerail'
$state = Read-Resource "$assets/blockstates/y_cross_rail.json"
$state = $state.Replace('y_cross_straight_rail', 't_cross_right_rail').Replace('y_cross_turn_rail', 't_cross_left_rail').Replace('"y": -90', '"y": 270')
Write-Resource "$assets/blockstates/t_cross_rail.json" $state
Write-Resource "$assets/models/block/t_cross_left_rail.json" (Read-Resource "$assets/models/block/y_cross_turn_rail.json")
Write-Resource "$assets/models/block/t_cross_right_rail.json" (Read-Resource "$assets/models/block/y_cross_right_turn_rail.json")
Write-Resource "$assets/models/item/t_cross_rail.json" (Read-Resource "$assets/models/item/y_cross_right_rail.json")
Write-Resource "$data/recipe/t_cross_rail.json" ((Read-Resource "$data/recipe/y_cross_rail.json").Replace('y_cross_rail', 't_cross_rail'))
Write-Resource "$data/loot_table/blocks/t_cross_rail.json" ((Read-Resource "$data/loot_table/blocks/y_cross_rail.json").Replace('y_cross_rail', 't_cross_rail'))
foreach ($old in @('y_cross_rail', 'y_cross_right_rail')) {
    foreach ($path in @("$assets/blockstates/$old.json", "$assets/models/item/$old.json", "$data/recipe/$old.json", "$data/loot_table/blocks/$old.json")) {
        Remove-Item -LiteralPath (Join-Path $root $path)
    }
}
Write-Output 'Updated T-cross resource references; original turn textures are reused unchanged.'
