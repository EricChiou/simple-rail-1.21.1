$ErrorActionPreference='Stop'
$root=(Resolve-Path (Join-Path $PSScriptRoot '../../../..')).Path
$assets=Join-Path $root 'src/main/resources/assets/simplerail'
# Native Minecraft model geometry; the existing PNG is only sampled, never edited.
# Coordinates are model units (16 per block), north at z=0, stem at z=16.
$frame=@{}
function Fill($mask,$x0,$z0,$x1,$z1) {
    for($z=$z0;$z -lt $z1;$z++){for($x=$x0;$x -lt $x1;$x++){ $mask["$x,$z"]=$true }}
}
Fill $frame 0 2 16 4
Fill $frame 0 12 4 14
Fill $frame 12 12 16 14
Fill $frame 2 12 4 16
Fill $frame 12 12 14 16
$bend=@{}
Fill $bend 2 9 4 12
Fill $bend 3 7 5 9
Fill $bend 4 6 6 7
Fill $bend 5 5 7 6
Fill $bend 6 4 9 5
Fill $bend 8 3 12 4
Fill $bend 10 2 12 3
function Plane($name,$x0,$z0,$x1,$z1,$height,$uv) {
    [ordered]@{ name=$name; from=@($x0,$height,$z0); to=@($x1,$height,$z1); shade=$false
        faces=[ordered]@{ up=[ordered]@{texture='#rail';uv=$uv}; down=[ordered]@{texture='#rail';uv=$uv} } }
}
function Metal($mask,$label) {
    for($z=0;$z -lt 16;$z++){for($x=0;$x -lt 16;$x++){
        if(!$mask.ContainsKey("$x,$z")){continue}
        # Read light/dark opaque steel texels from the original 32px cross texture.
        $bright=(!$mask.ContainsKey("$x,$($z-1)") -or !$mask.ContainsKey("$($x-1),$z"))
        $uv=if($bright){ @(2,0,3,1) }else{ @(3,0,4,1) }
        $end=$x+1
        while($end -lt 16 -and $mask.ContainsKey("$end,$z")){
            $nextBright=(!$mask.ContainsKey("$end,$($z-1)") -or !$mask.ContainsKey("$($end-1),$z"))
            if($nextBright -ne $bright){break}; $end++
        }
        Plane "$label-$x-$z" $x $z $end ($z+1) 0.125 $uv
        $x=$end-1
    }}
}
$common=@()
foreach($x in @(0,3,6,9,12,15)){ $common+=Plane "tie-horizontal-$x" $x 1 ($x+1) 15 0.0625 @(4,1,12,2) }
foreach($z in @(12,15)){ $common+=Plane "tie-stem-$z" 1 $z 15 ($z+1) 0.0625 @(4,1,12,2) }
# Remove the two exterior bottom corners from the sleepers: only T openings remain.
foreach($element in $common){if($element.name -like 'tie-horizontal-*'){ $element.to[2]=if($element.from[0] -ge 4 -and $element.from[0] -lt 12){15}else{14} }}
$common+=@(Metal $frame 'frame')
$models=@{}
foreach($turn in @('right','left')){
    $selected=@{}
    foreach($key in $bend.Keys){ $xz=$key.Split(','); $x=[int]$xz[0]; $z=[int]$xz[1]; if($turn -eq 'left'){$x=15-$x}; if(!$frame.ContainsKey("$x,$z")){$selected["$x,$z"]=$true} }
    $model=[ordered]@{ parent='minecraft:block/block'; render_type='minecraft:cutout'; ambientocclusion=$false
        textures=[ordered]@{particle='simplerail:blocks/cross_rail';rail='simplerail:blocks/cross_rail'}
        elements=@($common)+@(Metal $selected 'switch') }
    $models[$turn]=$model
    $model | ConvertTo-Json -Depth 12 | Set-Content -Encoding UTF8 "$assets/models/block/t_cross_${turn}_rail.json"
}
[ordered]@{ parent='simplerail:block/t_cross_right_rail'; display=[ordered]@{
    gui=[ordered]@{rotation=@(90,0,0);translation=@(0,0,0);scale=@(0.9,0.9,0.9)}
} } | ConvertTo-Json -Depth 6 | Set-Content -Encoding UTF8 "$assets/models/item/t_cross_rail.json"
# Reviewable vector top view of the actual model planes; not an in-game render.
$svg=@('<svg xmlns="http://www.w3.org/2000/svg" width="740" height="390" viewBox="0 0 740 390">','<rect width="740" height="390" fill="#282c30"/>')
$offset=20
foreach($turn in @('right','left')){
    $label=if($turn -eq 'right'){'OFF: south &lt;-&gt; east'}else{'ON: south &lt;-&gt; west'}
    $svg+="<text x='$offset' y='24' fill='white' font-family='sans-serif' font-size='18'>$label</text>"
    foreach($e in $models[$turn].elements){
        $color=if($e.name -like 'tie-*'){'#947340'}elseif($e.faces.up.uv[0] -eq 2){'#a9aaa9'}else{'#676767'}
        $x=$offset+$e.from[0]*20; $z=40+$e.from[2]*20; $w=($e.to[0]-$e.from[0])*20; $h=($e.to[2]-$e.from[2])*20
        $svg+="<rect x='$x' y='$z' width='$w' height='$h' fill='$color'/>"
    }
    $offset+=370
}
$svg+='</svg>'
$svg | Set-Content -Encoding UTF8 (Join-Path $PSScriptRoot 'model-preview.svg')
Write-Output "Generated fixed T frame + switch-only mirrored geometry; common planes=$($common.Count). PNG unchanged."
