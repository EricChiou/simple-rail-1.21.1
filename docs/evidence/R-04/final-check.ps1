$ErrorActionPreference='Stop'
$root=(Get-Location).Path
$out=Join-Path $root 'docs/evidence/R-04'
$checks=[Collections.Generic.List[object]]::new()
function Check([string]$name,[bool]$ok,$detail=$null){$checks.Add([pscustomobject]@{name=$name;passed=$ok;detail=$detail})}
$inputs=Get-Content -Raw -Encoding UTF8 (Join-Path $out 'reviewed-inputs.json') | ConvertFrom-Json
$changed=@($inputs | Where-Object {(Get-FileHash -LiteralPath (Join-Path $root $_.path)).Hash -ne $_.sha256})
Check '431 reviewed product and historical inputs unchanged' ($inputs.Count -eq 431 -and $changed.Count -eq 0) $changed
$before=[IO.File]::ReadAllText((Join-Path $out 'before/TASK.md'))
$after=[IO.File]::ReadAllText((Join-Path $root 'TASK.md'))
function Lines([string]$text,[string]$pattern){return @([regex]::Matches($text,$pattern) | ForEach-Object {$_.Value.Trim()})}
$idsBefore=Lines $before '(?m)^### T-\d{3} [^\r\n]*'
$idsAfter=Lines $after '(?m)^### T-\d{3} [^\r\n]*'
Check '126 task IDs, titles and order unchanged' ($idsBefore.Count -eq 126 -and ($idsBefore -join "`n") -eq ($idsAfter -join "`n"))
$depsBefore=Lines $before '(?m)^- 前置任務：[^\r\n]*'
$depsAfter=Lines $after '(?m)^- 前置任務：[^\r\n]*'
Check '126 direct dependency lines unchanged' ($depsBefore.Count -eq 126 -and ($depsBefore -join "`n") -eq ($depsAfter -join "`n"))
Check 'nine stages unchanged' ((Lines $after '(?m)^## 階段 \d').Count -eq 9)
$dBefore=Lines $before '(?m)^- D[1-8]：[^\r\n]*'
$dAfter=Lines $after '(?m)^- D[1-8]：[^\r\n]*'
# D2 now records completed BE registration; its ID and all other decisions stay intact.
Check 'D1-D8 retain scope (D2 progress only)' ($dBefore.Count -eq 8 -and ($dBefore -join "`n").Replace('正式註冊仍待實作，不替換舊方塊或物品 ID。','T-044 已正式註冊，R-04 已核對，不替換舊方塊或物品 ID。') -eq ($dAfter -join "`n"))
foreach($id in @('037','038','039','041','043','044','045','046')){
    $block=[regex]::Match($after,('(?ms)^### T-'+$id+'\b.*?(?=^### T-|^## 階段|\z)')).Value
    Check ('current reviewed status T-'+$id) ($block -match '(?m)^- 狀態：[^\r\n]*R-04 指定範圍通過' -and $block -match '(?m)^- 分項狀態：\[R-04 指定範圍通過\]')
}
$reviewBefore=[IO.File]::ReadAllText((Join-Path $out 'before/REVIEW.md'))
$reviewAfter=[IO.File]::ReadAllText((Join-Path $root 'REVIEW.md'))
Check 'REVIEW historical sections 1-60 unchanged' ($reviewBefore.Substring($reviewBefore.IndexOf('## 1.')).Trim() -eq $reviewAfter.Substring($reviewAfter.IndexOf('## 1.'),$reviewAfter.IndexOf('## 61.')-$reviewAfter.IndexOf('## 1.')).Trim())
$migrationBefore=[IO.File]::ReadAllText((Join-Path $out 'before/MIGRATION.md'))
$migrationAfter=[IO.File]::ReadAllText((Join-Path $root 'MIGRATION.md'))
Check 'MIGRATION historical progress and requirements unchanged' ($migrationAfter.EndsWith($migrationBefore.Substring($migrationBefore.IndexOf("`n")+1)))
$index=(& git ls-files --stage) -join "`n"
$indexBefore=(Get-Content -Encoding UTF8 (Join-Path $out 'before/index.txt')) -join "`n"
$indexDelta=@(Compare-Object ($indexBefore -split "`n") ($index -split "`n"))
$removed=@($indexDelta | Where-Object {$_.SideIndicator -eq '<='})
$added=@($indexDelta | Where-Object {$_.SideIndicator -eq '=>'})
$unexpected=@($added | Where-Object {$_.InputObject -notmatch "`tdocs/evidence/R-04/"})
Check 'pre-existing staged entries unchanged; observed additions confined to R-04' ($removed.Count -eq 0 -and $unexpected.Count -eq 0)
$observation=[ordered]@{utc=[DateTime]::UtcNow.ToString('o');agentRanStageResetCommit=$false;cause='Not determined; no index mutations requested by reviewer';removedOrReplacedBaselineEntries=$removed;addedEntries=$added}
[IO.File]::WriteAllText((Join-Path $out 'index-observation.json'),($observation | ConvertTo-Json -Depth 5),[Text.UTF8Encoding]::new($false))
Check 'HEAD unchanged' ((& git rev-parse HEAD) -eq (Get-Content (Join-Path $out 'before/head.txt')))
& git -c core.safecrlf=false diff --check
Check 'git diff whitespace' ($LASTEXITCODE -eq 0)
$diff=@(& git diff --name-only)
Check 'tracked edits confined to three progress documents and R-04 evidence' (@($diff | Where-Object {$_ -notin @('TASK.md','REVIEW.md','MIGRATION.md') -and $_ -notmatch '^docs/evidence/R-04/'}).Count -eq 0)
$verification=Get-Content -Raw -Encoding UTF8 (Join-Path $out 'checks.json') | ConvertFrom-Json
Check '177 artifact/API checks passed' ($verification.result -eq 'PASS' -and $verification.checks.Count -eq 177)
$commands=Get-Content -Raw -Encoding UTF8 (Join-Path $out 'commands.json') | ConvertFrom-Json
Check '8 compiles and 8 non-game runs passed' ($commands.Count -eq 16 -and @($commands | Where-Object {$_.exitCode -ne 0}).Count -eq 0)
# Create the result path before resolving its link in README.
$finalPath=Join-Path $out 'final-check.json'
if(!(Test-Path $finalPath)){[IO.File]::WriteAllText($finalPath,'{}')}
$missing=@()
foreach($m in [regex]::Matches([IO.File]::ReadAllText((Join-Path $out 'README.md')),'\]\(([^)]+)\)')){
    $path=($m.Groups[1].Value -split '#')[0]
    if($path -and !(Test-Path -LiteralPath (Join-Path $out $path))){$missing+=$path}
}
Check 'report local links resolve' ($missing.Count -eq 0) $missing
$result=[ordered]@{utc=[DateTime]::UtcNow.ToString('o');passed=@($checks | Where-Object {$_.passed}).Count;failed=@($checks | Where-Object {!$_.passed}).Count;checks=$checks}
[IO.File]::WriteAllText($finalPath,($result | ConvertTo-Json -Depth 6),[Text.UTF8Encoding]::new($false))
Write-Output ('Final checks: '+$result.passed+' passed, '+$result.failed+' failed')
if($result.failed){$checks | Where-Object {!$_.passed} | ConvertTo-Json -Depth 5;exit 1}
