$ErrorActionPreference = 'Stop'
$taskEvidence = Join-Path (Get-Location) 'docs/evidence/T-022'
function Read-Utf8([string]$path) { [IO.File]::ReadAllText((Resolve-Path -LiteralPath $path), [Text.Encoding]::UTF8) }
function Read-Json([string]$path) { Get-Content -LiteralPath $path -Raw -Encoding utf8 | ConvertFrom-Json }
function Matching-Lines([string]$content, [string]$pattern) { @([regex]::Matches($content, $pattern) | ForEach-Object { $_.Value }) }
$taskText = Read-Utf8 'TASK.md'
$oldTask = Read-Utf8 (Join-Path $taskEvidence 'before/TASK.md')
$taskBlocks = @([regex]::Matches($taskText, '(?ms)^### (T-\d{3})[^\r\n]*\r?\n(.*?)(?=^### T-|^## |\z)'))
$taskIds = @($taskBlocks | ForEach-Object { $_.Groups[1].Value })
$expectedIds = @(1..126 | ForEach-Object { 'T-{0:D3}' -f $_ })
$definitionStable = @(Compare-Object (Matching-Lines $oldTask '(?m)^### T-\d{3}[^\r\n]*') (Matching-Lines $taskText '(?m)^### T-\d{3}[^\r\n]*')).Count -eq 0 -and @(Compare-Object (Matching-Lines $oldTask '(?m)^- 前置任務[^\r\n]*') (Matching-Lines $taskText '(?m)^- 前置任務[^\r\n]*')).Count -eq 0
$dependencies = @{}; $missingDependencies = @(); $statusCounts = @{}
foreach ($block in $taskBlocks) {
    $id = $block.Groups[1].Value; $body = $block.Groups[2].Value
    $dependencies[$id] = @([regex]::Matches([regex]::Match($body, '(?m)^- 前置任務[^\r\n]*').Value, 'T-\d{3}') | ForEach-Object { $_.Value } | Select-Object -Unique)
    foreach ($dep in $dependencies[$id]) { if ($taskIds -notcontains $dep) { $missingDependencies += "$id -> $dep" } }
    $status = [regex]::Match($body, '(?m)^- 狀態：([^\r\n]+)').Groups[1].Value.Trim()
    if (-not $statusCounts.ContainsKey($status)) { $statusCounts[$status] = 0 }; $statusCounts[$status]++
}
$resolved = [Collections.Generic.HashSet[string]]::new()
do {
    $advanced = $false
    foreach ($id in $taskIds) {
        if ($resolved.Contains($id)) { continue }
        if (@($dependencies[$id] | Where-Object { -not $resolved.Contains($_) }).Count -eq 0) { [void]$resolved.Add($id); $advanced = $true }
    }
} while ($advanced)
$unresolved = @($taskIds | Where-Object { -not $resolved.Contains($_) })
$stages = @([regex]::Matches($taskText, '(?m)^## 階段 ([0-8])[^\r\n]*')); $stageCounts = @()
for ($i = 0; $i -lt $stages.Count; $i++) {
    $end = if ($i + 1 -lt $stages.Count) { $stages[$i+1].Index } else { $taskText.Length }
    $count = [regex]::Matches($taskText.Substring($stages[$i].Index, $end - $stages[$i].Index), '(?m)^### T-\d{3}').Count
    $phase = [int]$stages[$i].Groups[1].Value
    $overviewCount = [int](([regex]::Match($taskText, ('(?m)^\| ' + $phase + '\. [^\r\n]+')).Value -split '\|')[3].Trim())
    $stageCounts += [ordered]@{stage = $phase; count = $count; overviewCount = $overviewCount; matches = $count -eq $overviewCount}
}
$coveragePattern = '(?ms)^## [^\r\n]*覆蓋[^\r\n]*\r?\n.*?(?=^## |\z)'
$coverageStable = [regex]::Match($taskText, $coveragePattern).Value.Trim().Replace("`r`n","`n") -eq [regex]::Match($oldTask, $coveragePattern).Value.Trim().Replace("`r`n","`n")
$documentPaths = @('TASK.md','MIGRATION.md','REVIEW.md','docs/evidence/T-022/README.md','docs/evidence/T-022/DATA_CONTRACT.md')
$missingLinks = @(); $selfReport = Join-Path $taskEvidence 'final-check.json'
foreach ($path in $documentPaths) {
    $full = (Resolve-Path -LiteralPath $path).Path
    foreach ($link in [regex]::Matches((Read-Utf8 $path), '\[[^\]]*\]\(([^)]+)\)')) {
        $target = $link.Groups[1].Value
        if ($target -match '^(https?://|#)' -or $target -match '[<>]') { continue }
        $targetPath = [IO.Path]::GetFullPath((Join-Path (Split-Path $full) ($target -split '#')[0]))
        if ($targetPath -eq $selfReport) { continue } # Produced by this check, not a pre-existing result.
        if (-not (Test-Path -LiteralPath $targetPath)) { $missingLinks += "$path -> $target" }
    }
}
$reviewText = Read-Utf8 'REVIEW.md'; $oldReview = Read-Utf8 (Join-Path $taskEvidence 'before/REVIEW.md')
$reviewHistoryStable = $oldReview.Substring($oldReview.IndexOf('## 8. ')).Trim().Replace("`r`n","`n") -eq $reviewText.Substring($reviewText.IndexOf('## 8. '), $reviewText.IndexOf('## 29. ') - $reviewText.IndexOf('## 8. ')).Trim().Replace("`r`n","`n")
$reviewedInputs = Read-Json 'docs/evidence/R-01/reviewed-inputs.json'
$changedHistory = @($reviewedInputs | Where-Object { -not (Test-Path -LiteralPath $_.path) -or (Get-FileHash -LiteralPath $_.path).Hash -ne $_.sha256 })
$priorSources = Read-Json 'docs/evidence/T-021/source-fingerprints.json'
$changedProductInputs = @($priorSources | Where-Object { (Get-FileHash -LiteralPath $_.path).Hash -ne $_.sha256 })
$unauthorizedInputChanges = $changedProductInputs
$templateBefore = Read-Utf8 'src/main/templates/META-INF/neoforge.mods.toml'
$templateAfter = Read-Utf8 'src/main/templates/META-INF/neoforge.mods.toml'
$templateOnlyLogo = (Get-FileHash 'src/main/templates/META-INF/neoforge.mods.toml').Hash -eq ($priorSources | Where-Object { $_.path -like '*\META-INF\neoforge.mods.toml' }).sha256
$audit = Read-Json (Join-Path $taskEvidence 'audit-results.json')
$auditCommands = Read-Json (Join-Path $taskEvidence 'audit-commands-01.json')
$build = Read-Json (Join-Path $taskEvidence 'build-01.json'); $buildLog = Get-Content (Join-Path $taskEvidence 'build-01.log') -Raw
$artifact = Read-Json (Join-Path $taskEvidence 'artifact.json')
$mapping = Read-Json (Join-Path $taskEvidence 'data-map.json')
$coverage = Read-Json 'docs/evidence/T-021/state-coverage.json'
$productFiles = @(Get-ChildItem -LiteralPath 'src/main/resources' -Recurse -File)
$mappedByteChanges = @($mapping | Where-Object { $_.targetSha256 -and (Get-FileHash -LiteralPath (Join-Path 'src/main/resources' $_.targetPath)).Hash -ne $_.targetSha256 })
Add-Type -AssemblyName System.IO.Compression.FileSystem
$jar = [IO.Compression.ZipFile]::OpenRead((Resolve-Path (Join-Path $taskEvidence 'artifacts/simplerail-1.0.0.jar')))
$oldJar = [IO.Compression.ZipFile]::OpenRead((Resolve-Path 'docs/evidence/T-021/artifacts/simplerail-1.0.0.jar'))
function Entry-Hash($entry) {
    $stream = $entry.Open(); $sha = [Security.Cryptography.SHA256]::Create()
    try { [BitConverter]::ToString($sha.ComputeHash($stream)).Replace('-', '') } finally { $stream.Dispose(); $sha.Dispose() }
}
$jarResourceDifferences = @(); $classDifferences = @()
try {
    $jarEntries = @($jar.Entries | ForEach-Object { $_.FullName })
    $resourceRoot = (Resolve-Path 'src/main/resources').Path
    foreach ($file in $productFiles) {
        $path = $file.FullName.Substring($resourceRoot.Length + 1).Replace('\','/')
        $entry = $jar.GetEntry($path)
        if ($null -eq $entry -or (Entry-Hash $entry) -ne (Get-FileHash -LiteralPath $file.FullName).Hash) { $jarResourceDifferences += $path }
    }
    foreach ($entry in $oldJar.Entries | Where-Object { $_.FullName.EndsWith('.class') }) {
        $newEntry = $jar.GetEntry($entry.FullName)
        if ($null -eq $newEntry -or (Entry-Hash $entry) -ne (Entry-Hash $newEntry)) { $classDifferences += $entry.FullName }
    }
    $classCountsEqual = @($jar.Entries | Where-Object { $_.FullName.EndsWith('.class') }).Count -eq (@($oldJar.Entries | Where-Object { $_.FullName.EndsWith('.class') }).Count + 1)
    $reader = [IO.StreamReader]::new($jar.GetEntry('META-INF/neoforge.mods.toml').Open())
    try { $metadata = $reader.ReadToEnd() } finally { $reader.Dispose() }
} finally { $jar.Dispose(); $oldJar.Dispose() }
$metadata | Set-Content -Encoding utf8 (Join-Path $taskEvidence 'neoforge.mods.toml')
$jarEntries | Set-Content -Encoding utf8 (Join-Path $taskEvidence 'jar-contents.txt')
$ErrorActionPreference = 'Continue'
git -c core.safecrlf=false diff --check *> (Join-Path $taskEvidence 'diff-check.log'); $diffCode = $LASTEXITCODE
git diff --cached --binary *> (Join-Path $taskEvidence 'index-after.diff'); $indexCode = $LASTEXITCODE
git status --short *> (Join-Path $taskEvidence 'git-status-after.txt'); $statusCode = $LASTEXITCODE
$ErrorActionPreference = 'Stop'
$devCount = ($statusCounts.Keys | Where-Object { $_.StartsWith('開發完成') } | ForEach-Object { $statusCounts[$_] } | Measure-Object -Sum).Sum
$checks = [ordered]@{
    taskIds126UniqueContinuous = $taskIds.Count -eq 126 -and @($taskIds | Select-Object -Unique).Count -eq 126 -and @(Compare-Object @($taskIds | Sort-Object) @($expectedIds | Sort-Object)).Count -eq 0
    taskHeadersAndDependenciesUnchanged = $definitionStable
    dependenciesExistAndAcyclic = $missingDependencies.Count -eq 0 -and $unresolved.Count -eq 0
    nineStageOverviewCountsMatch = $stages.Count -eq 9 -and @($stageCounts | Where-Object { -not $_.matches }).Count -eq 0
    coverageTableUnchanged = $coverageStable
    localLinksResolve = $missingLinks.Count -eq 0
    historicalReviewSections8To28Unchanged = $reviewHistoryStable
    R01ReviewedInputsUnchanged = $changedHistory.Count -eq 0
    stagedIndexUnchanged = $indexCode -eq 0 -and (Get-FileHash (Join-Path $taskEvidence 'index-after.diff')).Hash -eq (Get-FileHash (Join-Path $taskEvidence 'index-before.diff')).Hash
    trackedWhitespaceCheckPassed = $diffCode -eq 0
    allPriorProductInputsUnchanged = $unauthorizedInputChanges.Count -eq 0
    productTemplateUnchanged = $templateOnlyLogo
    priorClassBytesUnchangedOnlyOneNewClass = $classCountsEqual -and $classDifferences.Count -eq 0
    T022DevCompleteT025Pending = (($taskBlocks | Where-Object { $_.Groups[1].Value -eq 'T-022' }).Groups[2].Value -match '- 狀態：開發完成；R-02 程式審查待審') -and (($taskBlocks | Where-Object { $_.Groups[1].Value -eq 'T-025' }).Groups[2].Value -match '- 狀態：待執行')
    sixteenDevCompleted101Pending = $devCount -eq 16 -and $statusCounts['待執行'] -eq 101
    all29DataSourcesMapped = $mapping.Count -eq 29 -and $audit.dataFiles -eq 29
    resourceTree144Files99Json45Png = $productFiles.Count -eq 144 -and @($productFiles | Where-Object { $_.Extension -in @('.json','.mcmeta') }).Count -eq 99 -and @($productFiles | Where-Object { $_.Extension -eq '.png' }).Count -eq 45
    auditedProductResourceHashesStable = $mappedByteChanges.Count -eq 0
    audit393PassedWithZeroFailures = $audit.passed -eq 393 -and $audit.failed -eq 0 -and $audit.checks.Count -eq 393 -and $audit.references -eq 85 -and @($audit.checks | Where-Object { -not $_.passed }).Count -eq 0
    standaloneAuditCommandsBothExitZero = $auditCommands.Count -eq 2 -and @($auditCommands | Where-Object { $_.exitCode -ne 0 }).Count -eq 0
    buildSucceededNoGameTasksAndTestNoSource = $build.exitCode -eq 0 -and $buildLog -match 'BUILD SUCCESSFUL' -and $buildLog -match ':test NO-SOURCE' -and $buildLog -notmatch '> Task :.*(runClient|runServer|GameTest|runData)'
    jarExactlyContainsEveryProductResource = $jarResourceDifferences.Count -eq 0
    savedAndLiveJarHashesMatchArtifact = (Get-FileHash (Join-Path $taskEvidence 'artifacts/simplerail-1.0.0.jar')).Hash -eq $artifact.jarSha256 -and (Get-FileHash 'build/libs/simplerail-1.0.0.jar').Hash -eq $artifact.jarSha256
    jarMetadataKeepsD8AndLogo = $metadata -match 'modId="simplerail"' -and $metadata -match 'version="1\.0\.0"' -and $metadata -match 'license="All Rights Reserved"' -and $metadata -match 'versionRange="\[21\.1\.251,\)"' -and $metadata -match 'versionRange="\[1\.21\.1\]"' -and $metadata -match 'logoFile="logo\.png"'
    jarContains29DataJsonNoOldForgeOrPluralDirs = $jarEntries -notcontains 'META-INF/mods.toml' -and @($jarEntries | Where-Object { $_ -match '^data/.*\.json$' }).Count -eq 29 -and @($jarEntries | Where-Object { $_ -match '^data/.*/(recipes|loot_tables|tags/blocks|tags/items)/' }).Count -eq 0
    preservedT019AndT021JarsUnchanged = (Get-FileHash 'docs/evidence/T-019/artifacts/simplerail-1.0.0.jar').Hash -eq (Read-Json 'docs/evidence/T-019/checks.json').jarSha256 -and (Get-FileHash 'docs/evidence/T-021/artifacts/simplerail-1.0.0.jar').Hash -eq (Read-Json 'docs/evidence/T-021/artifact.json').jarSha256
    integrationFindingRecordedWithoutClaimOfGamePass = $coverage.Count -eq 11 -and @($coverage | Where-Object { -not $_.plainT019SkeletonHasRequiredProperties }).Count -eq 10 -and @($coverage | Where-Object { $_.uncovered -gt 0 }).Count -eq 9 -and $taskText.Contains('I-021-01') -and $reviewText.Contains('I-021-01') -and (Read-Utf8 'MIGRATION.md').Contains('I-021-01')
}
$oldBlocks = @([regex]::Matches($oldTask, '(?ms)^### (T-\d{3})[^\r\n]*\r?\n(.*?)(?=^### T-|^## |\z)'))
$otherStatusChanges = @()
foreach ($block in $taskBlocks) {
    $id = $block.Groups[1].Value
    if ($id -eq 'T-022') { continue }
    $oldBlock = $oldBlocks | Where-Object { $_.Groups[1].Value -eq $id }
    if ([regex]::Match($oldBlock.Groups[2].Value, '(?m)^- 狀態：[^\r\n]*').Value -ne [regex]::Match($block.Groups[2].Value, '(?m)^- 狀態：[^\r\n]*').Value) { $otherStatusChanges += $id }
}
$baseline = Read-Json (Join-Path $taskEvidence 'inputs-before.json')
$priorPaths = @($baseline | ForEach-Object { [IO.Path]::GetFullPath((Join-Path (Get-Location) $_.path)) })
$newFiles = @(rg --files src/main | ForEach-Object { [IO.Path]::GetFullPath((Join-Path (Get-Location) $_)) } | Where-Object { $priorPaths -notcontains $_ })
$expectedNewFiles = @($mapping | ForEach-Object { [IO.Path]::GetFullPath((Join-Path (Get-Location) ('src/main/resources/' + $_.targetPath))) }) + @([IO.Path]::GetFullPath((Join-Path (Get-Location) 'src/main/java/com/ericchiu/simplerail/registry/ModTags.java')))
$newFileDelta = @(Compare-Object ($newFiles | Sort-Object) ($expectedNewFiles | Sort-Object))
$referenceSources = Read-Json (Join-Path $taskEvidence 'source-references.json')
$changedSources = @($referenceSources | Where-Object { (Get-FileHash -LiteralPath $_.path).Hash -ne $_.sha256 })
$oldData = Read-Json 'docs/evidence/T-009/source-manifest.json'
$oldDataChanges = @($oldData | Where-Object { $_.origin -like '*src\main\resources\data\*' } | Where-Object { (Get-FileHash -LiteralPath $_.origin).Hash -ne $_.sha256 })
$bytecode = Read-Utf8 (Join-Path $taskEvidence 'tags-bytecode.txt')
$checks.onlyT022StatusChanged = $otherStatusChanges.Count -eq 0
$checks.only30AuthorizedNewProductFiles = $newFiles.Count -eq 30 -and $newFileDelta.Count -eq 0
$checks.fixed17ReferenceSourcesAnd29OldDataUnchanged = $referenceSources.Count -eq 17 -and $changedSources.Count -eq 0 -and $oldDataChanges.Count -eq 0
$checks.newModTagsClassAndTypedDeclarationsVerified = $jarEntries -contains 'com/ericchiu/simplerail/registry/ModTags.class' -and $bytecode -match 'TagKey<net.minecraft.world.item.Item> WRENCH' -and $bytecode -match 'TagKey<net.minecraft.world.level.block.Block> RAILS' -and $bytecode -match 'TagKey<net.minecraft.world.level.block.Block> MACHINES'
$checks.preservedT020JarUnchanged = (Get-FileHash 'docs/evidence/T-020/artifacts/simplerail-1.0.0.jar').Hash -eq (Read-Json 'docs/evidence/T-020/artifact.json').sha256
$failed = @($checks.Keys | Where-Object { -not $checks[$_] })
$report = [ordered]@{task = 'T-022'; timestampUtc = [DateTime]::UtcNow.ToString('o'); checks = $checks; failed = $failed; statuses = $statusCounts; stageCounts = $stageCounts; missingLinks = $missingLinks; missingDependencies = $missingDependencies; unresolvedTasks = $unresolved; changedHistory = $changedHistory; R01ReviewedInputsCount = $reviewedInputs.Count; changedProductInputs = $changedProductInputs; unauthorizedInputChanges = $unauthorizedInputChanges; jarResourceDifferences = $jarResourceDifferences; classDifferences = $classDifferences; mappedByteChanges = $mappedByteChanges; diffCheckExitCode = $diffCode; indexExitCode = $indexCode; gitStatusExitCode = $statusCode; nextPriorityDevelopment = 'T-025 (not started)'; nextManual = 'T-023 (not ready: I-021-01, T-092, R-02)'; documentationFingerprints = @($documentPaths | ForEach-Object { [ordered]@{path = $_; sha256 = (Get-FileHash -LiteralPath $_).Hash} })}
$report | ConvertTo-Json -Depth 8 | Set-Content -Encoding utf8 (Join-Path $taskEvidence 'final-check.json')
Write-Output ("Final document/JAR/scope checks: {0} passed, {1} failed; 126 tasks, 9 stages" -f ($checks.Count - $failed.Count), $failed.Count)
if ($failed.Count -gt 0) { throw ($failed -join ', ') }
