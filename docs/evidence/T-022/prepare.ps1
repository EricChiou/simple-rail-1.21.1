$ErrorActionPreference = 'Stop'
$evidence = Join-Path (Get-Location) 'docs/evidence/T-022'
New-Item -ItemType Directory -Force (Join-Path $evidence 'before'), (Join-Path $evidence 'audit'), (Join-Path $evidence 'sources'), (Join-Path $evidence 'artifacts') | Out-Null
foreach ($name in @('TASK.md','REVIEW.md','MIGRATION.md')) { Copy-Item -LiteralPath $name -Destination (Join-Path $evidence ('before/' + $name)) }
git diff --cached --binary *> (Join-Path $evidence 'index-before.diff')
if ($LASTEXITCODE -ne 0) { throw 'Index capture failed' }
git status --short *> (Join-Path $evidence 'git-status-before.txt')
if ($LASTEXITCODE -ne 0) { throw 'Status capture failed' }
$paths = @('build.gradle','settings.gradle','gradle.properties','gradle/wrapper/gradle-wrapper.properties','.gitignore') + @(rg --files src/main | Where-Object { $_ -notmatch 'registry[/\\]ModTags.java$' })
@($paths | ForEach-Object { [ordered]@{path = $_; sha256 = (Get-FileHash -LiteralPath $_).Hash} }) | ConvertTo-Json -Depth 4 | Set-Content -Encoding utf8 (Join-Path $evidence 'inputs-before.json')
$sourcePaths = @(
    'docs/evidence/T-009/sources/target/net/minecraft/core/registries/Registries.java',
    'docs/evidence/T-009/sources/target/net/minecraft/world/item/crafting/ShapedRecipe.java',
    'docs/evidence/T-009/sources/target/net/minecraft/world/item/crafting/ShapedRecipePattern.java',
    'docs/evidence/T-009/sources/target/net/minecraft/world/item/crafting/Ingredient.java',
    'docs/evidence/T-009/sources/target/net/minecraft/world/item/ItemStack.java',
    'docs/evidence/T-009/sources/target/net/minecraft/world/level/storage/loot/LootTable.java',
    'docs/evidence/T-009/sources/target/net/minecraft/world/level/storage/loot/LootPool.java',
    'docs/evidence/T-009/sources/target/net/minecraft/world/level/storage/loot/predicates/ExplosionCondition.java',
    'docs/evidence/T-009/sources/target/net/minecraft/world/level/storage/loot/parameters/LootContextParamSets.java',
    'docs/evidence/T-009/sources/target/net/minecraft/world/level/storage/loot/parameters/LootContextParamSet.java',
    'docs/evidence/T-009/sources/target/net/minecraft/server/ReloadableServerRegistries.java',
    'docs/evidence/T-009/sources/target/net/minecraft/tags/TagFile.java',
    'docs/evidence/T-009/sources/target/net/minecraft/tags/TagManager.java',
    'docs/evidence/T-010/probe/T010Probe.java',
    'D:/workspace/java/simple-rail/src/main/java/ericchiu/simplerail/setup/SimpleRailTags.java',
    'D:/workspace/java/simple-rail/src/main/java/ericchiu/simplerail/entity/LocomotiveCartEntity.java'
)
$references = @($sourcePaths | ForEach-Object { [ordered]@{path = $_; sha256 = (Get-FileHash -LiteralPath $_).Hash; scope = 'Fixed target version source or OLD source reference; no runtime verification'} })
Add-Type -AssemblyName System.IO.Compression.FileSystem
$sourceArchive = (Resolve-Path 'build/moddev/artifacts/neoforge-21.1.251-sources.jar').Path
$archive = [IO.Compression.ZipFile]::OpenRead($sourceArchive)
try {
    $entry = $archive.GetEntry('net/minecraft/tags/TagKey.java')
    if ($null -eq $entry) { throw 'TagKey source missing' }
    $target = Join-Path $evidence 'sources/TagKey.java'
    [IO.Compression.ZipFileExtensions]::ExtractToFile($entry, $target, $true)
    $references += [ordered]@{path = 'docs/evidence/T-022/sources/TagKey.java'; sha256 = (Get-FileHash $target).Hash; archive = $sourceArchive; archiveSha256 = (Get-FileHash $sourceArchive).Hash; entry = $entry.FullName}
} finally { $archive.Dispose() }
$references | ConvertTo-Json -Depth 5 | Set-Content -Encoding utf8 (Join-Path $evidence 'source-references.json')
Copy-Item -LiteralPath 'docs/evidence/T-021/audit/gson-2.10.1.jar' -Destination (Join-Path $evidence 'audit/gson-2.10.1.jar')
Write-Output 'T-022 preparation: documents/index/product inputs captured; 17 source references fixed'
