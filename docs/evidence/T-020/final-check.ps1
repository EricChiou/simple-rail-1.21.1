$ErrorActionPreference = 'Stop'
$taskEvidence = Join-Path (Get-Location) 'docs/evidence/T-020'
$taskText = [IO.File]::ReadAllText((Resolve-Path 'TASK.md'), [Text.Encoding]::UTF8)
$oldTask = [IO.File]::ReadAllText((Join-Path $taskEvidence 'TASK-before.md'), [Text.Encoding]::UTF8)
$taskBlocks = @([regex]::Matches($taskText, '(?ms)^### (T-\d{3})[^\r\n]*\r?\n(.*?)(?=^### T-|^## |\z)'))
$taskIds = @($taskBlocks | ForEach-Object { $_.Groups[1].Value })
$expectedIds = @(1..126 | ForEach-Object { 'T-{0:D3}' -f $_ })
$headerPattern = '(?m)^### T-\d{3}[^\r\n]*'
$dependencyPattern = '(?m)^- 前置任務[^\r\n]*'
function Lines-Matching([string]$content, [string]$pattern) { return @([regex]::Matches($content, $pattern) | ForEach-Object { $_.Value }) }
$definitionStable = @(Compare-Object (Lines-Matching $oldTask $headerPattern) (Lines-Matching $taskText $headerPattern)).Count -eq 0 -and @(Compare-Object (Lines-Matching $oldTask $dependencyPattern) (Lines-Matching $taskText $dependencyPattern)).Count -eq 0
$dependencies = @{}
$missingDependencies = @()
$statusCounts = @{}
foreach ($taskBlock in $taskBlocks) {
    $id = $taskBlock.Groups[1].Value
    $body = $taskBlock.Groups[2].Value
    $dependencyLine = [regex]::Match($body, '(?m)^- 前置任務[^\r\n]*').Value
    $dependencies[$id] = @([regex]::Matches($dependencyLine, 'T-\d{3}') | ForEach-Object { $_.Value } | Select-Object -Unique)
    foreach ($dependency in $dependencies[$id]) { if ($taskIds -notcontains $dependency) { $missingDependencies += "$id -> $dependency" } }
    $status = [regex]::Match($body, '(?m)^- 狀態：([^\r\n]+)').Groups[1].Value.Trim()
    if (-not $statusCounts.ContainsKey($status)) { $statusCounts[$status] = 0 }
    $statusCounts[$status]++
}
$resolvedTasks = [Collections.Generic.HashSet[string]]::new()
do {
    $advanced = $false
    foreach ($id in $taskIds) {
        if ($resolvedTasks.Contains($id)) { continue }
        if (@($dependencies[$id] | Where-Object { -not $resolvedTasks.Contains($_) }).Count -eq 0) { [void]$resolvedTasks.Add($id); $advanced = $true }
    }
} while ($advanced)
$unresolvedTasks = @($taskIds | Where-Object { -not $resolvedTasks.Contains($_) })
$stages = @([regex]::Matches($taskText, '(?m)^## 階段 ([0-8])[^\r\n]*'))
$stageCounts = @()
for ($i = 0; $i -lt $stages.Count; $i++) {
    $start = $stages[$i].Index
    $end = if ($i + 1 -lt $stages.Count) { $stages[$i+1].Index } else { $taskText.Length }
    $count = [regex]::Matches($taskText.Substring($start, $end - $start), '(?m)^### T-\d{3}').Count
    $phase = [int]$stages[$i].Groups[1].Value
    $overviewLine = [regex]::Match($taskText, ('(?m)^\| ' + $phase + '\. [^\r\n]+')).Value
    $overviewCount = [int](($overviewLine -split '\|')[3].Trim())
    $stageCounts += [ordered]@{ stage = $phase; count = $count; overviewCount = $overviewCount; matches = $count -eq $overviewCount }
}
$coveragePattern = '(?ms)^## [^\r\n]*覆蓋[^\r\n]*\r?\n.*?(?=^## |\z)'
$coverageStable = [regex]::Match($taskText, $coveragePattern).Value.Trim().Replace("`r`n","`n") -eq [regex]::Match($oldTask, $coveragePattern).Value.Trim().Replace("`r`n","`n")
$documentPaths = @('TASK.md','MIGRATION.md','REVIEW.md','docs/evidence/T-020/README.md','docs/evidence/T-020/config-contract.md')
$missingLinks = @()
foreach ($path in $documentPaths) {
    $full = (Resolve-Path $path).Path
    $content = [IO.File]::ReadAllText($full, [Text.Encoding]::UTF8)
    foreach ($linkMatch in [regex]::Matches($content, '\[[^\]]*\]\(([^)]+)\)')) {
        $target = $linkMatch.Groups[1].Value
        if ($target -match '^(https?://|#)' -or $target -match '[<>]') { continue }
        $target = ($target -split '#')[0]
        if ($target -eq 'docs/evidence/T-020/final-check.json') { continue }
        if (-not (Test-Path -LiteralPath (Join-Path (Split-Path $full) $target))) { $missingLinks += "$path -> $target" }
    }
}
$reviewText = [IO.File]::ReadAllText((Resolve-Path 'REVIEW.md'), [Text.Encoding]::UTF8)
$oldReview = [IO.File]::ReadAllText((Join-Path $taskEvidence 'REVIEW-before.md'), [Text.Encoding]::UTF8)
$historyStart = '## 8. '
$historyEnd = '## 27. '
$reviewHistoryStable = $oldReview.Substring($oldReview.IndexOf($historyStart)).Trim().Replace("`r`n","`n") -eq $reviewText.Substring($reviewText.IndexOf($historyStart), $reviewText.IndexOf($historyEnd) - $reviewText.IndexOf($historyStart)).Trim().Replace("`r`n","`n")
$reviewedInputs = Get-Content docs/evidence/R-01/reviewed-inputs.json -Raw -Encoding utf8 | ConvertFrom-Json
$changedHistoryFiles = @($reviewedInputs | Where-Object { -not (Test-Path -LiteralPath $_.path) -or (Get-FileHash -LiteralPath $_.path -Algorithm SHA256).Hash -ne $_.sha256 })
$sourcePaths = @('src/main/java/com/ericchiu/simplerail/config/CommonConfig.java')
$ErrorActionPreference = 'Continue'
git -c core.safecrlf=false diff --check *> (Join-Path $taskEvidence 'diff-check.log')
$diffCode = $LASTEXITCODE
$newSourceWhitespaceCodes = @()
foreach ($path in $sourcePaths) {
    git -c core.safecrlf=false diff --no-index --check -- NUL $path *> (Join-Path $taskEvidence ((Split-Path $path -Leaf) + '.whitespace.log'))
    $newSourceWhitespaceCodes += $LASTEXITCODE
}
git diff --cached --binary *> (Join-Path $taskEvidence 'index-after.diff')
$indexExit = $LASTEXITCODE
$protectedDelta = @(git -c core.safecrlf=false diff --name-only -- src/main/resources src/main/templates build.gradle gradle.properties settings.gradle gradle gradlew gradlew.bat .gitignore)
$ErrorActionPreference = 'Stop'
$indexStable = $indexExit -eq 0 -and (Get-FileHash (Join-Path $taskEvidence 'index-after.diff')).Hash -eq (Get-FileHash (Join-Path $taskEvidence 'index-before.diff')).Hash
$previousSources = Get-Content docs/evidence/T-019/source-fingerprints.json -Raw -Encoding utf8 | ConvertFrom-Json
$otherProductChanges = @($previousSources | Where-Object { -not $_.path.EndsWith('\SimpleRail.java') -and (Get-FileHash -LiteralPath $_.path -Algorithm SHA256).Hash -ne $_.sha256 })
$configSource = [IO.File]::ReadAllText((Resolve-Path 'src/main/java/com/ericchiu/simplerail/config/CommonConfig.java'), [Text.Encoding]::UTF8)
$mainSource = [IO.File]::ReadAllText((Resolve-Path 'src/main/java/com/ericchiu/simplerail/SimpleRail.java'), [Text.Encoding]::UTF8)
$bytecode = Get-Content (Join-Path $taskEvidence 'config-bytecode.txt') -Raw
$staticInitializer = [regex]::Match($bytecode, '(?ms)  static \{\};(.*?)(?=^\}|^Compiled from|\z)').Groups[1].Value
$testResults = Get-Content (Join-Path $taskEvidence 'test-results.json') -Raw -Encoding utf8 | ConvertFrom-Json
$testCommands = Get-Content (Join-Path $taskEvidence 'test-commands-02.json') -Raw -Encoding utf8 | ConvertFrom-Json
$artifact = Get-Content (Join-Path $taskEvidence 'artifact.json') -Raw -Encoding utf8 | ConvertFrom-Json
$build = Get-Content (Join-Path $taskEvidence 'build-01.json') -Raw -Encoding utf8 | ConvertFrom-Json
$buildLog = Get-Content (Join-Path $taskEvidence 'build-01.log') -Raw
$tomlPaths = @()
$group = ''
foreach ($line in Get-Content (Join-Path $taskEvidence 'simplerail-common.toml') -Encoding utf8) {
    $groupMatch = [regex]::Match($line, '^\s*\[([^\]]+)\]\s*$')
    if ($groupMatch.Success) { $group = $groupMatch.Groups[1].Value }
    $valueMatch = [regex]::Match($line, '^\s*(\w+)\s*=')
    if ($valueMatch.Success) { $tomlPaths += $group + '.' + $valueMatch.Groups[1].Value }
}
Add-Type -AssemblyName System.IO.Compression.FileSystem
$jar = [IO.Compression.ZipFile]::OpenRead((Resolve-Path (Join-Path $taskEvidence 'artifacts/simplerail-1.0.0.jar')))
try {
    $jarEntries = @($jar.Entries | ForEach-Object { $_.FullName })
    $reader = [IO.StreamReader]::new($jar.GetEntry('META-INF/neoforge.mods.toml').Open())
    try { $metadata = $reader.ReadToEnd() } finally { $reader.Dispose() }
} finally { $jar.Dispose() }
$metadata | Set-Content -Encoding utf8 (Join-Path $taskEvidence 'neoforge.mods.toml')
$jarEntries | Set-Content -Encoding utf8 (Join-Path $taskEvidence 'jar-contents.txt')
$devCount = ($statusCounts.Keys | Where-Object { $_.StartsWith('開發完成') } | ForEach-Object { $statusCounts[$_] } | Measure-Object -Sum).Sum
$checks = [ordered]@{
    taskIds126UniqueAndContinuous = $taskIds.Count -eq 126 -and @($taskIds | Select-Object -Unique).Count -eq 126 -and @(Compare-Object @($taskIds | Sort-Object) @($expectedIds | Sort-Object)).Count -eq 0
    taskHeadersAndDependenciesUnchanged = $definitionStable
    allDependenciesExistAndNoCycles = $missingDependencies.Count -eq 0 -and $unresolvedTasks.Count -eq 0
    nineStagesAndOverviewCountsMatch = $stages.Count -eq 9 -and @($stageCounts | Where-Object { -not $_.matches }).Count -eq 0
    coverageTableUnchanged = $coverageStable
    localLinksResolve = $missingLinks.Count -eq 0
    historicalReviewSectionsUnchanged = $reviewHistoryStable
    previousEvidenceFilesUnchanged = $changedHistoryFiles.Count -eq 0
    preexistingIndexUnchanged = $indexStable
    noGradleResourceOrIgnoreDelta = $protectedDelta.Count -eq 0
    trackedAndNewJavaWhitespaceChecksPass = $diffCode -eq 0 -and @($newSourceWhitespaceCodes | Where-Object { $_ -notin @(0,1) }).Count -eq 0 -and @($sourcePaths | Where-Object { (Get-Item (Join-Path $taskEvidence ((Split-Path $_ -Leaf) + '.whitespace.log'))).Length -ne 0 }).Count -eq 0
    T020DevCompleteAndT021StillPending = (($taskBlocks | Where-Object { $_.Groups[1].Value -eq 'T-020' }).Groups[2].Value -match '- 狀態：開發完成；R-02 程式審查待審') -and (($taskBlocks | Where-Object { $_.Groups[1].Value -eq 'T-021' }).Groups[2].Value -match '- 狀態：待執行')
    fourteenDevCompletedAnd103Pending = $devCount -eq 14 -and $statusCounts['待執行'] -eq 103
    otherT019ProductInputsUnchanged = $otherProductChanges.Count -eq 0
    commonConstructorInjectsAndRegistersConfig = $mainSource.Contains('SimpleRail(IEventBus modEventBus, ModContainer modContainer)') -and $mainSource.Contains('CommonConfig.register(modEventBus, modContainer);')
    commonSpecRegisteredAndAllLifecycleHandlersFiltered = $configSource.Contains('registerConfig(ModConfig.Type.COMMON, SPEC, FILE_NAME)') -and $configSource.Contains('event.getConfig().getSpec() == SPEC') -and $configSource.Contains('event.getConfig().getType() == ModConfig.Type.COMMON') -and $configSource.Contains('event.getConfig().getModId().equals(SimpleRail.MODID)') -and $configSource.Contains('addListener(CommonConfig::onLoading)') -and $configSource.Contains('addListener(CommonConfig::onReloading)') -and $configSource.Contains('addListener(CommonConfig::onUnloading)')
    noConfigGetInStaticInitializerOrEntry = $staticInitializer.Length -gt 0 -and $staticInitializer -notmatch 'getAs(Boolean|Int|Double)|publishLoadedValues|current:' -and $mainSource -notmatch 'CommonConfig\.current\(|\.getAs'
    configHasNoClientWorldNetworkingOrTicketReferences = $configSource -notmatch 'net\.minecraft\.(client|world)|net\.neoforged\.neoforge\.(network|common\.world)'
    immutableVolatileSnapshot = $configSource.Contains('private static volatile Snapshot active;') -and $configSource.Contains('holdingWaitSecondsByLevel = List.copyOf(holdingWaitSecondsByLevel);') -and $configSource.Contains('signalIntervalSecondsByLevel = List.copyOf(signalIntervalSecondsByLevel);')
    configContractTests159PassedWithExitZero = $testResults.passed -eq 159 -and $testResults.failed -eq 0 -and @($testResults.checks | Where-Object { -not $_.passed }).Count -eq 0 -and @($testCommands | Where-Object { $_.exitCode -ne 0 }).Count -eq 0 -and $testCommands.Count -eq 2
    generatedDefaultTomlHas25UniqueKeys = $tomlPaths.Count -eq 25 -and @($tomlPaths | Select-Object -Unique).Count -eq 25
    buildSucceededAndNoGameTask = $build.exitCode -eq 0 -and $buildLog -match 'BUILD SUCCESSFUL' -and $buildLog -match ':test NO-SOURCE' -and $buildLog -notmatch '> Task :.*(runClient|runServer|GameTest|runData)'
    savedJarFingerprintAndConfigClassesMatch = (Get-FileHash (Join-Path $taskEvidence 'artifacts/simplerail-1.0.0.jar')).Hash -eq $artifact.sha256 -and (Get-FileHash build/libs/simplerail-1.0.0.jar).Hash -eq $artifact.sha256 -and $jarEntries -contains 'com/ericchiu/simplerail/config/CommonConfig.class' -and $jarEntries -contains 'com/ericchiu/simplerail/config/CommonConfig$Snapshot.class'
    metadataKeepsD8 = $metadata -match 'modId="simplerail"' -and $metadata -match 'version="1\.0\.0"' -and $metadata -match 'license="All Rights Reserved"' -and $metadata -match 'versionRange="\[21\.1\.251,\)"' -and $metadata -match 'versionRange="\[1\.21\.1\]"'
    preservedT019JarUnchanged = (Get-FileHash docs/evidence/T-019/artifacts/simplerail-1.0.0.jar).Hash -eq (Get-Content docs/evidence/T-019/checks.json -Raw -Encoding utf8 | ConvertFrom-Json).jarSha256
}
$report = [ordered]@{ task = 'T-020'; timestampUtc = [DateTime]::UtcNow.ToString('o'); checks = $checks; statuses = $statusCounts; stageCounts = $stageCounts; missingLinks = $missingLinks; missingDependencies = $missingDependencies; unresolvedTasks = $unresolvedTasks; changedHistoryFiles = $changedHistoryFiles; reviewedEvidenceFilesCount = $reviewedInputs.Count; protectedDelta = $protectedDelta; diffCheckExitCode = $diffCode; newJavaWhitespaceExitCodes = $newSourceWhitespaceCodes; nextPriorityDevelopment = 'T-021'; nextManual = 'T-023 (not ready)'; documentationFingerprints = @($documentPaths | ForEach-Object { [ordered]@{path = $_; sha256 = (Get-FileHash -LiteralPath $_ -Algorithm SHA256).Hash} }) }
$report | ConvertTo-Json -Depth 9 | Set-Content -Encoding utf8 (Join-Path $taskEvidence 'final-check.json')
$failed = @($checks.Keys | Where-Object { -not $checks[$_] })
Write-Output ("Final document/scope checks: {0} passed, {1} failed; 126 tasks, 9 stages" -f ($checks.Count - $failed.Count), $failed.Count)
if ($failed.Count -gt 0) { throw ($failed -join ', ') }
