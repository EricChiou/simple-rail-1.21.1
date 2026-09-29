$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem
$taskEvidence = Join-Path (Get-Location) 'docs/evidence/T-019'
$oldConstantsPath = 'docs/evidence/T-010/sources/old/constants/I18n.java'
$oldConstants = Get-Content $oldConstantsPath -Raw -Encoding utf8
$blockSource = Get-Content 'src/main/java/com/ericchiu/simplerail/registry/ModBlocks.java' -Raw -Encoding utf8
$itemSource = Get-Content 'src/main/java/com/ericchiu/simplerail/registry/ModItems.java' -Raw -Encoding utf8
$tabSource = Get-Content 'src/main/java/com/ericchiu/simplerail/registry/ModCreativeTabs.java' -Raw -Encoding utf8
$entrySource = Get-Content 'src/main/java/com/ericchiu/simplerail/SimpleRail.java' -Raw -Encoding utf8
$expectedBlocks = @([regex]::Matches($oldConstants, 'String BLOCK_\w+ = "([a-z_]+)"') | ForEach-Object { $_.Groups[1].Value })
$expectedTools = @([regex]::Matches($oldConstants, 'String ITEM_\w+ = "([a-z_]+)"') | ForEach-Object { $_.Groups[1].Value })
$declaredBlocks = @([regex]::Matches($blockSource, 'DeferredBlock<Block> (\w+) = BLOCKS\.registerSimpleBlock\("([a-z_]+)"') | ForEach-Object { [ordered]@{ field = $_.Groups[1].Value; id = $_.Groups[2].Value } })
$declaredBlockItems = @([regex]::Matches($itemSource, 'DeferredItem<BlockItem> (\w+) = ITEMS\.registerSimpleBlockItem\("([a-z_]+)", ModBlocks\.(\w+)\)') | ForEach-Object { [ordered]@{ field = $_.Groups[1].Value; id = $_.Groups[2].Value; blockField = $_.Groups[3].Value } })
$declaredTools = @([regex]::Matches($itemSource, 'DeferredItem<Item> (\w+) = ITEMS\.registerSimpleItem\("([a-z_]+)"') | ForEach-Object { [ordered]@{ field = $_.Groups[1].Value; id = $_.Groups[2].Value } })
$tabFields = @([regex]::Matches($tabSource, 'output\.accept\(ModItems\.(\w+)\.get\(\)\)') | ForEach-Object { $_.Groups[1].Value })
function Same-Set($left, $right) { return @((Compare-Object @($left | Sort-Object) @($right | Sort-Object))).Count -eq 0 }
$paired = $true
foreach ($blockItem in $declaredBlockItems) {
    $partner = @($declaredBlocks | Where-Object { $_.field -eq $blockItem.blockField })
    if ($partner.Count -ne 1 -or $partner[0].id -ne $blockItem.id) { $paired = $false }
}
$jarPath = 'build/libs/simplerail-1.0.0.jar'
if (-not (Test-Path $jarPath)) { throw 'Expected built JAR not found' }
$artifactDir = Join-Path $taskEvidence 'artifacts'
New-Item -ItemType Directory -Force $artifactDir | Out-Null
Copy-Item -LiteralPath $jarPath -Destination (Join-Path $artifactDir 'simplerail-1.0.0.jar')
$archive = [IO.Compression.ZipFile]::OpenRead((Resolve-Path $jarPath))
try {
    $jarEntries = @($archive.Entries | ForEach-Object { $_.FullName })
    $reader = [IO.StreamReader]::new($archive.GetEntry('META-INF/neoforge.mods.toml').Open())
    try { $metadata = $reader.ReadToEnd() } finally { $reader.Dispose() }
} finally { $archive.Dispose() }
$checks = [ordered]@{
    oldCatalogueHas11BlocksAnd2Tools = $expectedBlocks.Count -eq 11 -and $expectedTools.Count -eq 2
    blockIdsExactlyMatchOld = $declaredBlocks.Count -eq 11 -and (Same-Set @($declaredBlocks | ForEach-Object { $_.id }) $expectedBlocks)
    blockItemIdsExactlyMatchOld = $declaredBlockItems.Count -eq 11 -and (Same-Set @($declaredBlockItems | ForEach-Object { $_.id }) $expectedBlocks)
    blockItemsReferenceMatchingBlocks = $paired
    standaloneItemIdsExactlyMatchOld = $declaredTools.Count -eq 2 -and (Same-Set @($declaredTools | ForEach-Object { $_.id }) $expectedTools)
    creativeTabListsExactly13UniqueItems = $tabFields.Count -eq 13 -and (Same-Set $tabFields @(@($declaredTools | ForEach-Object { $_.field }) + @($declaredBlockItems | ForEach-Object { $_.field }))) -and @($tabFields | Select-Object -Unique).Count -eq 13
    creativeTabUsesHighSpeedIcon = $tabSource.Contains('.icon(() -> ModItems.HIGH_SPEED_RAIL.get().getDefaultInstance())')
    creativeTabKeepsTranslationAndDefinesOneKey = $tabSource.Contains('Component.translatable("itemGroup.simplerail.tab")') -and [regex]::Matches($tabSource, 'TABS\.register\("tab"').Count -eq 1
    destorySpellingPreservedAndNoReverseRegistration = @($declaredBlocks | Where-Object { $_.id -eq 'destory_rail' }).Count -eq 1 -and @($declaredBlocks + $declaredTools | Where-Object { $_.id -match 'reverse|destroy_rail' }).Count -eq 0
    commonConstructorRegistersAll3Registers = $entrySource.Contains('ModBlocks.register(modEventBus);') -and $entrySource.Contains('ModItems.register(modEventBus);') -and $entrySource.Contains('ModCreativeTabs.register(modEventBus);')
    commonRegistriesHaveNoClientDependencies = ($entrySource + $blockSource + $itemSource + $tabSource) -notmatch 'net\.minecraft\.client|net\.neoforged\.neoforge\.client'
    blockAndItemStaticDeclarationsDoNotResolveHoldersOrConfig = ($blockSource + $itemSource) -notmatch '\.get\(|ModConfig|Config\.'
    skeletonDoesNotRegisterEntitiesBEOrMenus = ($blockSource + $itemSource + $tabSource) -notmatch 'Registries\.(ENTITY_TYPE|BLOCK_ENTITY_TYPE|MENU)'
    wrenchStack1AndCartStack64 = $itemSource.Contains('stacksTo(1).rarity(Rarity.COMMON).fireResistant()') -and $itemSource.Contains('stacksTo(64).rarity(Rarity.UNCOMMON).fireResistant()')
    jarContainsAll3RegistryClasses = $jarEntries -contains 'com/ericchiu/simplerail/registry/ModBlocks.class' -and $jarEntries -contains 'com/ericchiu/simplerail/registry/ModItems.class' -and $jarEntries -contains 'com/ericchiu/simplerail/registry/ModCreativeTabs.class'
    metadataKeepsD8 = $metadata -match 'modId="simplerail"' -and $metadata -match 'version="1\.0\.0"' -and $metadata -match 'license="All Rights Reserved"' -and $metadata -match 'versionRange="\[21\.1\.251,\)"' -and $metadata -match 'versionRange="\[1\.21\.1\]"'
    buildExitZero = (Get-Content (Join-Path $taskEvidence 'build-01.json') -Raw -Encoding utf8 | ConvertFrom-Json).exitCode -eq 0
    buildSuccessfulNoGameTaskAndTestNoSource = (Get-Content (Join-Path $taskEvidence 'build-01.log') -Raw) -match 'BUILD SUCCESSFUL' -and (Get-Content (Join-Path $taskEvidence 'build-01.log') -Raw) -match ':test NO-SOURCE' -and (Get-Content (Join-Path $taskEvidence 'build-01.log') -Raw) -notmatch '> Task :.*(runClient|runServer|GameTest|runData)'
}
$manifest = [ordered]@{
    task = 'T-019'
    timestampUtc = [DateTime]::UtcNow.ToString('o')
    head = (git rev-parse HEAD).Trim()
    jar = $jarPath
    jarSha256 = (Get-FileHash -Algorithm SHA256 $jarPath).Hash
    oldConstantsSource = $oldConstantsPath
    oldConstantsSha256 = (Get-FileHash -Algorithm SHA256 $oldConstantsPath).Hash
    blocks = $declaredBlocks
    blockItems = $declaredBlockItems
    items = $declaredTools
    creativeTabId = 'simplerail:tab'
    creativeTabOrder = $tabFields
    checks = $checks
    limitation = 'Source and JAR structure only; no runtime registry dump, Minecraft execution, unit tests or independent review'
}
$manifest | ConvertTo-Json -Depth 10 | Set-Content -Encoding utf8 (Join-Path $taskEvidence 'checks.json')
$jarEntries | Set-Content -Encoding utf8 (Join-Path $taskEvidence 'jar-contents.txt')
$metadata | Set-Content -Encoding utf8 (Join-Path $taskEvidence 'neoforge.mods.toml')
$productPaths = @('build.gradle','gradle.properties','settings.gradle','gradle/wrapper/gradle-wrapper.properties') + @(Get-ChildItem src/main,src/main/templates -Recurse -File | ForEach-Object { $_.FullName } | Select-Object -Unique)
@($productPaths | ForEach-Object { $fingerprint = Get-FileHash -Algorithm SHA256 -LiteralPath $_; [ordered]@{ path = $fingerprint.Path; sha256 = $fingerprint.Hash } }) | ConvertTo-Json -Depth 4 | Set-Content -Encoding utf8 (Join-Path $taskEvidence 'source-fingerprints.json')
$failedChecks = @($checks.Keys | Where-Object { -not $checks[$_] })
Write-Output ("Static checks: {0} passed, {1} failed; JAR SHA-256 {2}" -f ($checks.Count - $failedChecks.Count), $failedChecks.Count, $manifest.jarSha256)
if ($failedChecks.Count -gt 0) { throw ($failedChecks -join ', ') }
