$ErrorActionPreference = 'Stop'
$taskEvidence = Join-Path (Get-Location) 'docs/evidence/T-019'
$taskText = [IO.File]::ReadAllText((Resolve-Path 'TASK.md'), [Text.Encoding]::UTF8)
$oldTask = (git show :TASK.md) -join "`n"
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
$documentPaths = @('TASK.md','MIGRATION.md','REVIEW.md','docs/evidence/T-019/README.md','docs/evidence/T-019/state-contract.md')
$missingLinks = @()
foreach ($path in $documentPaths) {
    $full = (Resolve-Path $path).Path
    $content = [IO.File]::ReadAllText($full, [Text.Encoding]::UTF8)
    foreach ($linkMatch in [regex]::Matches($content, '\[[^\]]*\]\(([^)]+)\)')) {
        $target = $linkMatch.Groups[1].Value
        if ($target -match '^(https?://|#)' -or $target -match '[<>]') { continue }
        $target = ($target -split '#')[0]
        if ($target -eq 'docs/evidence/T-019/final-check.json') { continue }
        if (-not (Test-Path -LiteralPath (Join-Path (Split-Path $full) $target))) { $missingLinks += "$path -> $target" }
    }
}
$reviewText = [IO.File]::ReadAllText((Resolve-Path 'REVIEW.md'), [Text.Encoding]::UTF8)
$oldReview = (git show :REVIEW.md) -join "`n"
$historyStart = '## 8. '
$historyEnd = '## 26. '
$reviewHistoryStable = $oldReview.Substring($oldReview.IndexOf($historyStart)).Trim().Replace("`r`n","`n") -eq $reviewText.Substring($reviewText.IndexOf($historyStart), $reviewText.IndexOf($historyEnd) - $reviewText.IndexOf($historyStart)).Trim().Replace("`r`n","`n")
$reviewedInputs = Get-Content docs/evidence/R-01/reviewed-inputs.json -Raw -Encoding utf8 | ConvertFrom-Json
$changedHistoryFiles = @($reviewedInputs | Where-Object { -not (Test-Path -LiteralPath $_.path) -or (Get-FileHash -LiteralPath $_.path -Algorithm SHA256).Hash -ne $_.sha256 })
$sourcePaths = @('src/main/java/com/ericchiu/simplerail/registry/ModBlocks.java','src/main/java/com/ericchiu/simplerail/registry/ModItems.java','src/main/java/com/ericchiu/simplerail/registry/ModCreativeTabs.java')
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
$indexStable = $indexExit -eq 0 -and (Get-FileHash (Join-Path $taskEvidence 'index-after.diff')).Hash -eq (Get-FileHash (Join-Path $taskEvidence 'preexisting-index.diff')).Hash
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
    T019DevCompleteAndT020StillPending = [regex]::Match(($taskBlocks | Where-Object { $_.Groups[1].Value -eq 'T-019' }).Groups[2].Value, '(?m)^- 狀態：').Success -and (($taskBlocks | Where-Object { $_.Groups[1].Value -eq 'T-019' }).Groups[2].Value -match '- 狀態：開發完成；R-02 程式審查待審') -and (($taskBlocks | Where-Object { $_.Groups[1].Value -eq 'T-020' }).Groups[2].Value -match '- 狀態：待執行')
}
$report = [ordered]@{ task = 'T-019'; timestampUtc = [DateTime]::UtcNow.ToString('o'); checks = $checks; statuses = $statusCounts; stageCounts = $stageCounts; missingLinks = $missingLinks; missingDependencies = $missingDependencies; unresolvedTasks = $unresolvedTasks; changedHistoryFiles = $changedHistoryFiles; reviewedEvidenceFilesCount = $reviewedInputs.Count; protectedDelta = $protectedDelta; diffCheckExitCode = $diffCode; newJavaWhitespaceExitCodes = $newSourceWhitespaceCodes; nextPriorityDevelopment = 'T-020'; nextManual = 'T-023 (not ready)'; documentationFingerprints = @($documentPaths | ForEach-Object { [ordered]@{path = $_; sha256 = (Get-FileHash -LiteralPath $_ -Algorithm SHA256).Hash} }) }
$report | ConvertTo-Json -Depth 9 | Set-Content -Encoding utf8 (Join-Path $taskEvidence 'final-check.json')
$failed = @($checks.Keys | Where-Object { -not $checks[$_] })
Write-Output ("Final document/scope checks: {0} passed, {1} failed; 126 tasks, 9 stages" -f ($checks.Count - $failed.Count), $failed.Count)
if ($failed.Count -gt 0) { throw ($failed -join ', ') }
