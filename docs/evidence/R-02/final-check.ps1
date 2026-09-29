$ErrorActionPreference='Stop'
$OutputEncoding=[Console]::OutputEncoding=[Text.UTF8Encoding]::new()
$root=(Get-Location).Path
$out=Join-Path $root 'docs/evidence/R-02'
$checks=[Collections.Generic.List[object]]::new()
function Check([string]$name,[bool]$ok,$detail) { $checks.Add([pscustomobject]@{name=$name;passed=$ok;detail=$detail}) }
$inputs=Get-Content -Raw -Encoding UTF8 (Join-Path $out 'reviewed-inputs.json')|ConvertFrom-Json
$changed=@($inputs|Where-Object {(Get-FileHash -LiteralPath $_.path).Hash -ne $_.sha256})
Check 'reviewed product, sources, fixed artifacts and packages remain unchanged' ($changed.Count -eq 0) $changed
$readme=Get-Content -Raw -Encoding UTF8 (Join-Path $out 'README.md')
$missing=@()
foreach($match in [regex]::Matches($readme,'\]\(([^)]+)\)')) {
    $path=($match.Groups[1].Value -split '#')[0]
    if ($path -and !(Test-Path -LiteralPath (Join-Path $out $path))) { $missing+=$path }
}
Check 'report local links resolve' ($missing.Count -eq 0) $missing
$before=(& git show HEAD:TASK.md) -join "`n"
$after=Get-Content -Raw -Encoding UTF8 TASK.md
$beforeIds=@([regex]::Matches($before,'(?m)^### (T-\d{3}) ')|ForEach-Object {$_.Groups[1].Value})
$afterIds=@([regex]::Matches($after,'(?m)^### (T-\d{3}) ')|ForEach-Object {$_.Groups[1].Value})
Check '126 task IDs and order unchanged' ($afterIds.Count -eq 126 -and ($beforeIds -join ',') -eq ($afterIds -join ',')) $afterIds.Count
$dependencyPattern='(?m)^- '+[regex]::Escape(([string][char]0x524D+[char]0x7F6E+[char]0x4EFB+[char]0x52D9))+':?.*$'
# Match the full existing dependency lines, including full-width colon.
$beforeDependencies=@([regex]::Matches($before,$dependencyPattern)|ForEach-Object {$_.Value.Trim()})
$afterDependencies=@([regex]::Matches($after,$dependencyPattern)|ForEach-Object {$_.Value.Trim()})
Check 'all 126 direct dependency lines unchanged' ($beforeDependencies.Count -eq 126 -and ($beforeDependencies -join "`n") -eq ($afterDependencies -join "`n")) $afterDependencies.Count
$stagePattern='(?m)^## '+[regex]::Escape(([string][char]0x968E+[char]0x6BB5))+' \d'
Check 'nine stages retained' ([regex]::Matches($after,$stagePattern).Count -eq 9) $null
$stage3='## '+[char]0x968E+[char]0x6BB5+' 3'
$originalTail=$before.Substring($before.IndexOf($stage3)).Trim()
$afterTail=$after.Substring($after.IndexOf($stage3)).Split(@('## R-02 '),[StringSplitOptions]::None)[0].Trim().Replace("`r`n","`n")
Check 'later tasks and historical TASK sections unchanged' ($originalTail -eq $afterTail) $null
$beforeReview=(& git show HEAD:REVIEW.md) -join "`n"
$afterReview=Get-Content -Raw -Encoding UTF8 REVIEW.md
$oldSections=$beforeReview.Substring($beforeReview.IndexOf('## 1.')).Trim()
$newSections=$afterReview.Substring($afterReview.IndexOf('## 1.')).Split(@('## 46.'),[StringSplitOptions]::None)[0].Trim().Replace("`r`n","`n")
Check 'REVIEW sections 1-45 unchanged' ($oldSections -eq $newSections) $null
& git diff --check
Check 'git diff whitespace check' ($LASTEXITCODE -eq 0) $null
$indexDiff=@(& git diff --cached --name-only)
Check 'index has no changes from this review' ($indexDiff.Count -eq 0) $indexDiff
$report=[ordered]@{utc=[DateTime]::UtcNow.ToString('o');head=(& git rev-parse HEAD);passed=@($checks|Where-Object {$_.passed}).Count;failed=@($checks|Where-Object {!$_.passed}).Count;checks=$checks}
[IO.File]::WriteAllText((Join-Path $out 'final-check.json'),($report|ConvertTo-Json -Depth 8),[Text.UTF8Encoding]::new($false))
$report|ConvertTo-Json -Depth 8
if ($report.failed -gt 0) { exit 1 }
