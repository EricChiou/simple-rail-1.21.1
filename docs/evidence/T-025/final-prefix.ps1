$ErrorActionPreference = 'Stop'
$taskEvidence = Join-Path (Get-Location) 'docs/evidence/T-025'
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
$documentPaths = @('TASK.md','MIGRATION.md','REVIEW.md','docs/evidence/T-025/README.md','docs/evidence/T-025/RAIL_CONTRACT.md')
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
$reviewHistoryStable = $oldReview.Substring($oldReview.IndexOf('## 8. ')).Trim().Replace("`r`n","`n") -eq $reviewText.Substring($reviewText.IndexOf('## 8. '), $reviewText.IndexOf('## 31. ') - $reviewText.IndexOf('## 8. ')).Trim().Replace("`r`n","`n")
