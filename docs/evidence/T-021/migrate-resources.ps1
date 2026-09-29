$ErrorActionPreference = 'Stop'
$taskRoot = (Get-Location).Path
$oldResources = 'D:\workspace\java\simple-rail\src\main\resources'
$targetResources = Join-Path $taskRoot 'src/main/resources'
$evidence = Join-Path $taskRoot 'docs/evidence/T-021'
$oldManifest = Get-Content docs/evidence/T-009/source-manifest.json -Raw -Encoding utf8 | ConvertFrom-Json
$oldResourceManifest = @($oldManifest | Where-Object { $_.origin -and $_.origin.StartsWith($oldResources + '\') })
if ($oldResourceManifest.Count -ne 144) { throw 'Expected 144 fixed OLD resource references' }
foreach ($reference in $oldResourceManifest) {
    if ((Get-FileHash -LiteralPath $reference.origin -Algorithm SHA256).Hash -ne $reference.sha256) { throw ('OLD source changed: ' + $reference.origin) }
}
$mappings = Get-Content docs/evidence/T-009/resource-map.json -Raw -Encoding utf8 | ConvertFrom-Json
$migrated = @($mappings | Where-Object { $_.oldPath.StartsWith('assets/simplerail/') -or $_.oldPath -in @('logo.png','pack.mcmeta') })
if ($migrated.Count -ne 114) { throw 'Expected 114 T-021 source files' }
foreach ($mapping in $migrated) {
    if ($mapping.oldPath -eq 'pack.mcmeta') { continue }
    $destination = [IO.Path]::GetFullPath((Join-Path $targetResources $mapping.oldPath))
    if (-not $destination.StartsWith($targetResources + '\')) { throw 'Resource destination outside expected root' }
    New-Item -ItemType Directory -Force (Split-Path $destination) | Out-Null
    Copy-Item -LiteralPath (Join-Path $oldResources $mapping.oldPath) -Destination $destination
}
$railResources = Get-Content docs/evidence/T-015/resources.json -Raw -Encoding utf8 | ConvertFrom-Json
$railModels = @($railResources.railBlocks | ForEach-Object { $_.models } | Sort-Object -Unique)
if ($railModels.Count -ne 29) { throw 'Expected 29 rail models for cutout' }
foreach ($modelName in $railModels) {
    $modelPath = Join-Path $targetResources ('assets/simplerail/models/block/' + $modelName + '.json')
    $content = [IO.File]::ReadAllText($modelPath, [Text.Encoding]::UTF8)
    if ($content -match '"render_type"') { throw 'Unexpected existing render_type; inspect before rewriting' }
    $firstBrace = $content.IndexOf('{')
    if ($firstBrace -lt 0) { throw 'Missing model JSON object' }
    $updated = $content.Insert($firstBrace + 1, "`n  `"render_type`": `"minecraft:cutout`",")
    [IO.File]::WriteAllText($modelPath, $updated, [Text.UTF8Encoding]::new($false))
}
[ordered]@{task='T-021'; timestampUtc=[DateTime]::UtcNow.ToString('o'); fixedOldResourceCount=$oldResourceManifest.Count; selectedSourceCount=$migrated.Count; cutoutModels=$railModels; scope='copy preserved resources and add cutout; no Java, data recipes/loot/tags, OLD build or Minecraft'} | ConvertTo-Json -Depth 5 | Set-Content -Encoding utf8 (Join-Path $evidence 'migration-command.json')
Write-Output 'Copied 113 files; pack metadata handled separately. Added cutout to 29 rail models.'
