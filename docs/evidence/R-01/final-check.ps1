$ErrorActionPreference = 'Stop'
$OutputEncoding = [Console]::OutputEncoding = [Text.UTF8Encoding]::new()
$root = (Resolve-Path (Join-Path $PSScriptRoot '../../..')).Path
Set-Location $root
$utf8 = [Text.UTF8Encoding]::new($false)
$before = (git show :TASK.md) -join "`n"
$after = [IO.File]::ReadAllText((Join-Path $root 'TASK.md'))
$headersPattern = '(?m)^### T-\d{3}[^\r\n]*'
$dependenciesPattern = '(?m)^- 前置任務[^\r\n]*'
$stagesPattern = '(?m)^## 階段 [0-8][^\r\n]*'
function Matches([string]$text, [string]$pattern) { @([regex]::Matches($text, $pattern) | ForEach-Object Value) }
$headers = Matches $after $headersPattern
$dependencies = Matches $after $dependenciesPattern
$stages = Matches $after $stagesPattern
$unchanged = !(Compare-Object (Matches $before $headersPattern) $headers) -and !(Compare-Object (Matches $before $dependenciesPattern) $dependencies) -and !(Compare-Object (Matches $before $stagesPattern) $stages)
$missingLinks = @()
$documentPaths = @('TASK.md','REVIEW.md','MIGRATION.md','docs/evidence/R-01/README.md')
foreach ($path in $documentPaths) {
    $full = Join-Path $root $path
    $text = [IO.File]::ReadAllText($full)
    foreach ($match in [regex]::Matches($text, '\[[^\]]*\]\(([^)]+)\)')) {
        $target = $match.Groups[1].Value
        if ($target -match '^(https?://|#)' -or $target -match '[<>]') { continue }
        $target = ($target -split '#')[0]
        if (!(Test-Path -LiteralPath (Join-Path (Split-Path $full) $target))) { $missingLinks += "$path -> $target" }
    }
}
$checks = Get-Content -Raw -Encoding UTF8 "$PSScriptRoot/checks.json" | ConvertFrom-Json
$compiles = Get-Content -Raw -Encoding UTF8 "$PSScriptRoot/compile-results.json" | ConvertFrom-Json
$productDelta = @(git -c core.safecrlf=false diff --name-only -- src build.gradle settings.gradle gradle.properties gradle gradlew gradlew.bat)
git -c core.safecrlf=false diff --check > "$PSScriptRoot/diff-check.log" 2>&1
$diffCode = $LASTEXITCODE
$reviewText = [IO.File]::ReadAllText((Join-Path $root 'REVIEW.md'))
$oldReview = (git show :REVIEW.md) -join "`n"
$historyMarker = '## 8. '
$historyUnchanged = $reviewText.Substring($reviewText.IndexOf($historyMarker)).Split(@('## 25. '), [StringSplitOptions]::None)[0].Trim().Replace("`r`n","`n") -eq $oldReview.Substring($oldReview.IndexOf($historyMarker)).Trim()
$passed = $unchanged -and $headers.Count -eq 126 -and $stages.Count -eq 9 -and $missingLinks.Count -eq 0 -and $productDelta.Count -eq 0 -and $diffCode -eq 0 -and $historyUnchanged -and @($checks.checks | Where-Object { !$_.passed }).Count -eq 0 -and @($compiles | Where-Object exitCode -ne 0).Count -eq 0
$result = [ordered]@{ dateUtc=[DateTime]::UtcNow.ToString('o'); passed=$passed; taskCount=$headers.Count; stageCount=$stages.Count; taskHeadersAndDependenciesUnchanged=$unchanged; reviewHistoryUnchanged=$historyUnchanged; missingLinks=$missingLinks; productDeltaFromIndex=$productDelta; diffCheckExitCode=$diffCode; staticCheckCount=$checks.checks.Count; javacRuns=$compiles.Count; compiledClasses=($compiles | Measure-Object classCount -Sum).Sum; files=@($documentPaths | ForEach-Object { [ordered]@{path=$_;sha256=(Get-FileHash -LiteralPath $_).Hash} }) }
[IO.File]::WriteAllText((Join-Path $PSScriptRoot 'final-check.json'), ($result | ConvertTo-Json -Depth 6), $utf8)
$inputs = @()
foreach ($task in @('T-005','T-006','T-007','T-008','T-009','T-010','T-011','T-012','T-013','T-014','T-015','T-016','T-017','T-018','T-089','T-090','T-091')) {
    $dir = Join-Path $root "docs/evidence/$task"
    $files = @(Get-ChildItem $dir -File | Where-Object { $_.Extension -in @('.md','.json','.diff') })
    if (Test-Path "$dir/probe") { $files += @(Get-ChildItem "$dir/probe" -Filter *.java) }
    if ($task -eq 'T-009') { $files += Get-Item "$dir/audit/ResourceAudit.java" }
    foreach ($file in $files) { $inputs += [ordered]@{ path=$file.FullName.Substring($root.Length+1).Replace('\','/'); sha256=(Get-FileHash -LiteralPath $file.FullName).Hash } }
}
[IO.File]::WriteAllText((Join-Path $PSScriptRoot 'reviewed-inputs.json'), ($inputs | ConvertTo-Json -Depth 5), $utf8)
$result | ConvertTo-Json -Depth 6
if (!$passed) { exit 1 }
