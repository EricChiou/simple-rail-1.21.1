$ErrorActionPreference = 'Stop'
$root = (Get-Location).Path
$out = Join-Path $root 'docs/evidence/R-02'
$utf8 = [Text.UTF8Encoding]::new($false)
Add-Type -AssemblyName System.IO.Compression.FileSystem
$checks = [Collections.Generic.List[object]]::new()
$inputs = [Collections.Generic.List[object]]::new()
function ReadJson([string]$path) { Get-Content -Raw -Encoding UTF8 -LiteralPath $path | ConvertFrom-Json }
function Check([string]$name, [bool]$ok, $detail) {
    $checks.Add([pscustomobject]@{name=$name; passed=$ok; detail=$detail})
}
function Hash([string]$path) { (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash }
function BytesHash([byte[]]$bytes) {
    $sha = [Security.Cryptography.SHA256]::Create()
    try { ([BitConverter]::ToString($sha.ComputeHash($bytes))).Replace('-','') } finally { $sha.Dispose() }
}
function EntryHash($entry) {
    $stream=$entry.Open(); $memory=[IO.MemoryStream]::new()
    try { $stream.CopyTo($memory); BytesHash $memory.ToArray() } finally { $stream.Dispose(); $memory.Dispose() }
}
function Input([string]$path) { $inputs.Add([pscustomobject]@{path=$path;sha256=(Hash $path)}) }
$jars = @{
    'T-019'='7AEB033B7B5949E89005DC8B65DF73D93272BCCB430D81F80DE516248ECF9C9D'
    'T-020'='166E7B63AC9E56A83CEFD23448B458F0E221D7059825BDACFE9A541898A9C467'
    'T-021'='3FB257657741F7A0A50EE0879FC92C7F15EB51C1434F2FDBB1EE51AD0B5A96AD'
    'T-022'='3D4BFC8926509DCE28C6DE11E8198D3639EB288E1EB29FAD89D3AEC9C1C6BBD3'
}
foreach ($task in ($jars.Keys | Sort-Object)) {
    $path='docs/evidence/'+$task+'/artifacts/simplerail-1.0.0.jar'
    Check ($task+' fixed JAR hash') ((Hash $path) -eq $jars[$task]) $jars[$task]
    Input $path
    $build=ReadJson ('docs/evidence/'+$task+'/build-01.json')
    $log=Get-Content -Raw ('docs/evidence/'+$task+'/build-01.log')
    Check ($task+' historical NEW build evidence') ($build.exitCode -eq 0 -and $log.Contains('BUILD SUCCESSFUL') -and $log.Contains('test NO-SOURCE')) $build.command
}
foreach ($task in @('T-020','T-021','T-022')) {
    $references=ReadJson ('docs/evidence/'+$task+'/source-references.json')
    foreach ($reference in $references) {
        Check ($task+' source '+$reference.path) ((Hash $reference.path) -eq $reference.sha256) $reference.sha256
        Input $reference.path
    }
}
$baseline=ReadJson 'docs/evidence/T-022/source-fingerprints.json'
$deltas=@()
foreach ($row in $baseline) {
    if ((Hash $row.path) -ne $row.sha256) { $deltas += $row.path.Substring($root.Length+1).Replace('\','/') }
}
$expectedDeltas=@('src/main/templates/META-INF/neoforge.mods.toml','src/main/resources/assets/simplerail/blockstates/high_speed_rail.json','src/main/java/com/ericchiu/simplerail/registry/ModItems.java','src/main/java/com/ericchiu/simplerail/registry/ModBlocks.java')
Check 'T-022 existing inputs differ only in four documented R-03 paths' (@(Compare-Object ($deltas|Sort-Object) ($expectedDeltas|Sort-Object)).Count -eq 0) $deltas
foreach ($file in Get-ChildItem -Recurse -File src/main) { Input $file.FullName }
foreach ($path in @('build.gradle','settings.gradle','gradle.properties','gradle/wrapper/gradle-wrapper.properties')) { Input $path }
$registry='src/main/java/com/ericchiu/simplerail/registry/'
$blocks=[regex]::Matches([IO.File]::ReadAllText((Join-Path $root ($registry+'ModBlocks.java'))),'register(?:Simple)?Block\("([^"]+)"') | ForEach-Object { $_.Groups[1].Value }
$items=[regex]::Matches([IO.File]::ReadAllText((Join-Path $root ($registry+'ModItems.java'))),'register(?:Simple)?(?:Item|BlockItem)\("([^"]+)"') | ForEach-Object { $_.Groups[1].Value }
$catalogue=ReadJson 'docs/evidence/T-004/catalogue.json'
Check 'all eleven block IDs retained and unique' ($blocks.Count -eq 11 -and @($blocks|Sort-Object -Unique).Count -eq 11 -and @(Compare-Object ($blocks|ForEach-Object {'simplerail:'+$_}) $catalogue.blocks).Count -eq 0) $blocks
Check 'all thirteen item IDs retained and unique' ($items.Count -eq 13 -and @($items|Sort-Object -Unique).Count -eq 13 -and @(Compare-Object ($items|ForEach-Object {'simplerail:'+$_}) $catalogue.items).Count -eq 0) $items
$itemText=Get-Content -Raw -Encoding UTF8 ($registry+'ModItems.java')
foreach ($block in $blocks) { Check ('same-ID BlockItem '+$block) ($itemText.Contains('registerSimpleBlockItem("'+$block+'", ModBlocks.'+$block.ToUpper()+')')) $null }
$tabs=Get-Content -Raw -Encoding UTF8 ($registry+'ModCreativeTabs.java')
$order=@([regex]::Matches($tabs,'output.accept\(ModItems\.([A-Z_]+)\.get\(\)\)')|ForEach-Object {$_.Groups[1].Value.ToLower()})
Check 'creative contents include thirteen items exactly once' ($order.Count -eq 13 -and @(Compare-Object ($order|Sort-Object) ($items|Sort-Object)).Count -eq 0) $order
Check 'creative title and icon' ($tabs.Contains('itemGroup.simplerail.tab') -and $tabs.Contains('.icon(() -> ModItems.HIGH_SPEED_RAIL.get().getDefaultInstance())')) $null
$archive=[IO.Compression.ZipFile]::OpenRead((Join-Path $root 'docs/evidence/T-022/artifacts/simplerail-1.0.0.jar'))
try {
    $data=@($archive.Entries|Where-Object {$_.FullName.StartsWith('data/') -and !$_.FullName.EndsWith('/')})
    Check 'fixed data archive has 29 files' ($data.Count -eq 29) $data.Count
    foreach ($entry in $data) { Check ('current data equals fixed artifact '+$entry.FullName) ((EntryHash $entry) -eq (Hash ('src/main/resources/'+$entry.FullName))) $null }
} finally { $archive.Dispose() }
$pickaxe=ReadJson 'src/main/resources/data/minecraft/tags/block/mineable/pickaxe.json'
$expectedPickaxe=@('simplerail:high_speed_rail','simplerail:holding_rail','simplerail:oneway_rail','simplerail:eject_rail','simplerail:destory_rail')
Check 'separate R-03 pickaxe tag is additive and resolves five implemented rails' (!$pickaxe.replace -and @(Compare-Object ($pickaxe.values|Sort-Object) ($expectedPickaxe|Sort-Object)).Count -eq 0) $pickaxe
$packages=ReadJson 'docs/evidence/T-092/packages.json'
foreach ($package in $packages) {
    $base='docs/test-packages/'+$package.package
    Check ($package.package+' ZIP hash') ((Hash $package.zip) -eq $package.zipSha256) $package.zipSha256
    Input $package.zip
    $manifest=ReadJson ($base+'/files-manifest.json')
    $zip=[IO.Compression.ZipFile]::OpenRead((Join-Path $root $package.zip))
    try {
        $files=@(Get-ChildItem -File -Recurse $base)
        Check ($package.package+' file count and ZIP entries') ($files.Count -eq 31 -and @($zip.Entries|Where-Object {!$_.FullName.EndsWith('/')}).Count -eq 31) $files.Count
        foreach ($file in $files) {
            $relative=$file.FullName.Substring((Join-Path $root $base).Length+1).Replace('\','/')
            $entry=$zip.GetEntry($relative)
            Check ($package.package+' ZIP/file '+$relative) ($null -ne $entry -and (EntryHash $entry) -eq (Hash $file.FullName)) $null
            Input $file.FullName
        }
    } finally { $zip.Dispose() }
    foreach ($row in $manifest) { Check ($package.package+' manifest '+$row.path) ((Hash ($base+'/'+$row.path)) -eq $row.sha256) $null }
    $cases=ReadJson ($base+'/case-index.json'); $meta=ReadJson ($base+'/manifest.json')
    $caseIds=@($cases|ForEach-Object {$_.caseId})
    Check ($package.package+' unique cases and manifest') ($cases.Count -eq $package.cases -and @($caseIds|Sort-Object -Unique).Count -eq $cases.Count -and @(Compare-Object $caseIds $meta.cases).Count -eq 0) $cases.Count
    Check ($package.package+' no invented actual results') (@($cases|Where-Object {$null -ne $_.actualResult}).Count -eq 0) $null
    foreach ($envName in @('SP','DS')) {
        Check ($package.package+' '+$envName+' cases have actionable structure or explicit local issue') (@($cases|Where-Object {$_.environment -eq $envName -and (!$_.steps -or !$_.expected -or !$_.expectedSource)}).Count -eq 0) @($cases|Where-Object {$_.environment -eq $envName}).Count
        if ($package.task -eq 'T-093') {
            foreach ($id in $items) { foreach ($variant in @('original','offset','mirror')) { Check ('T093 '+$envName+' recipe '+$id+' '+$variant) ($caseIds -contains ('T024-C005-'+$envName+'-'+$id+'-'+$variant)) $null } }
            foreach ($id in $blocks) { foreach ($mode in @('iron_pickaxe','hand','loot-mine','explosion')) { Check ('T093 '+$envName+' loot '+$id+' '+$mode) ($caseIds -contains ('T024-C006-'+$envName+'-'+$id+'-'+$mode)) $null } }
        }
    }
    # A documented S3 finding, not silently changed in immutable archives.
    $table=Get-Content -Raw -Encoding UTF8 ($base+'/TABLES.md')
    $line=($table -split "`n" | Where-Object { $_.StartsWith([char]0x5206) -and $_.Contains('high_speed_rail') })
    [IO.File]::WriteAllText((Join-Path $out ($package.task+'-tab-order.txt')), ($line + "`nActual source order: " + ($order -join ', ')), $utf8)
}
$passed=@($checks|Where-Object {$_.passed}).Count
$report=[ordered]@{head=(& git rev-parse HEAD);scope='Independent static checks; archived inputs and bounded current integration; no game';passed=$passed;failed=$checks.Count-$passed;checks=$checks}
[IO.File]::WriteAllText((Join-Path $out 'checks.json'), ($report|ConvertTo-Json -Depth 12), $utf8)
[IO.File]::WriteAllText((Join-Path $out 'reviewed-inputs.json'), ($inputs|Sort-Object path -Unique|ConvertTo-Json -Depth 5), $utf8)
Write-Output ('Static checks: '+$passed+' passed; '+($checks.Count-$passed)+' failed')
$checks|Where-Object {!$_.passed}|ConvertTo-Json -Depth 5
if ($passed -ne $checks.Count) { exit 1 }
