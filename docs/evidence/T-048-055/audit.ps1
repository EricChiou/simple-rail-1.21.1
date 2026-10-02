$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem
$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
$product = Join-Path $root 'build\libs\simplerail-1.0.0.jar'
$probe = Join-Path $root 'build\t054\artifacts\simplerail-1.0.0-T054-probe.jar'
$source = @(
    'src/main/java/com/ericchiu/simplerail/SimpleRail.java',
    'src/main/java/com/ericchiu/simplerail/SimpleRailClient.java',
    'src/main/java/com/ericchiu/simplerail/registry/ModEntities.java',
    'src/main/java/com/ericchiu/simplerail/registry/ModItems.java',
    'src/main/java/com/ericchiu/simplerail/entity/Facing8.java',
    'src/main/java/com/ericchiu/simplerail/entity/LocomotiveCartEntity.java',
    'src/main/java/com/ericchiu/simplerail/entity/TrainFormation.java',
    'src/main/java/com/ericchiu/simplerail/entity/TrainOwnershipData.java',
    'src/main/java/com/ericchiu/simplerail/item/LocomotiveCartItem.java',
    'src/main/java/com/ericchiu/simplerail/client/LocomotiveCartModel.java',
    'src/main/java/com/ericchiu/simplerail/client/LocomotiveCartRenderer.java'
)
$sourceHashes = foreach ($relative in $source) {
    $h = Get-FileHash -LiteralPath (Join-Path $root $relative) -Algorithm SHA256
    [ordered]@{ path = $relative; sha256 = $h.Hash }
}
$railModels = Get-ChildItem -LiteralPath (Join-Path $root 'src\main\resources\assets\simplerail\models\block') -Filter '*.json' |
    Where-Object { $_.Name -match '(rail|cross)' }
$cutout = @($railModels | Where-Object { (Get-Content -LiteralPath $_.FullName -Raw -Encoding UTF8) -match '"render_type"\s*:\s*"minecraft:cutout"' })
if ($cutout.Count -lt 29) { throw "Only $($cutout.Count) cutout rail models" }
$productZip = [IO.Compression.ZipFile]::OpenRead($product)
$probeZip = [IO.Compression.ZipFile]::OpenRead($probe)
try {
    $productNames = @($productZip.Entries | ForEach-Object FullName)
    $probeNames = @($probeZip.Entries | ForEach-Object FullName)
    $required = @(
        'com/ericchiu/simplerail/entity/LocomotiveCartEntity.class',
        'com/ericchiu/simplerail/entity/TrainOwnershipData.class',
        'com/ericchiu/simplerail/client/LocomotiveCartRenderer.class',
        'assets/simplerail/textures/entity/locomotive_cart.png'
    )
    foreach ($entry in $required) { if ($entry -notin $productNames) { throw "Product JAR missing $entry" } }
    if ('evidence/t054/TrainProbe.class' -in $productNames) { throw 'Probe leaked into product JAR' }
    if ('evidence/t054/TrainProbe.class' -notin $probeNames) { throw 'Probe missing from diagnostic JAR' }
    $metadataEntry = $probeZip.GetEntry('META-INF/neoforge.mods.toml')
    $reader = [IO.StreamReader]::new($metadataEntry.Open())
    try { $metadata = $reader.ReadToEnd() } finally { $reader.Dispose() }
    if ($metadata -notmatch '\[T054 diagnostic\]') { throw 'Diagnostic metadata marker missing' }
} finally {
    $productZip.Dispose()
    $probeZip.Dispose()
}
$result = [ordered]@{
    command = 'powershell -NoProfile -ExecutionPolicy Bypass -File docs/evidence/T-048-055/audit.ps1'
    head = (git -C $root rev-parse HEAD).Trim()
    source = $sourceHashes
    productJar = [ordered]@{ path = 'build/libs/simplerail-1.0.0.jar'; sha256 = (Get-FileHash $product -Algorithm SHA256).Hash }
    diagnosticJar = [ordered]@{ path = 'build/t054/artifacts/simplerail-1.0.0-T054-probe.jar'; sha256 = (Get-FileHash $probe -Algorithm SHA256).Hash }
    cutoutRailModels = $cutout.Count
    requiredJarEntries = $required
    diagnosticOnlyClassIsolated = $true
    diagnosticMetadataMarked = $true
    result = 'PASS'
}
$result | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $PSScriptRoot 'audit.json') -Encoding UTF8
Write-Output "PASS: $($cutout.Count) cutout rail models; product/probe isolation; source and JAR hashes saved"
