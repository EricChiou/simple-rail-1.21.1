$ErrorActionPreference='Stop'
$taskEvidence=Join-Path (Get-Location) 'docs/evidence/T-026/fix-R2'
function Read([string]$path){[IO.File]::ReadAllText((Resolve-Path -LiteralPath $path),[Text.Encoding]::UTF8)}
function Normalize([string]$text){$text.Replace([string][char]13,'').Trim()}
$checks=@()
function Check([string]$name,[bool]$pass){$script:checks += [ordered]@{name=$name;pass=$pass}}
$task=Read 'TASK.md';$oldTask=Read (Join-Path $taskEvidence 'before/TASK.md')
$pattern='(?ms)^### (T-\d{3})[^\r\n]*\r?\n(.*?)(?=^### T-|^## |\z)'
$blocks=@([regex]::Matches($task,$pattern));$oldBlocks=@([regex]::Matches($oldTask,$pattern))
$ids=@($blocks|ForEach-Object {$_.Groups[1].Value})
Check '126 unique task IDs retained' ($ids.Count -eq 126 -and @($ids|Select-Object -Unique).Count -eq 126 -and ($ids -join ',') -eq (($oldBlocks|ForEach-Object {$_.Groups[1].Value}) -join ','))
$dependencies=@{};$missing=@();$changed=@()
foreach($block in $blocks){
    $id=$block.Groups[1].Value;$body=$block.Groups[2].Value
    $dependencies[$id]=@([regex]::Matches([regex]::Match($body,'(?m)^- 前置任務[^\r\n]*').Value,'T-\d{3}')|ForEach-Object {$_.Value})
    foreach($dep in $dependencies[$id]){if($ids -notcontains $dep){$missing+=($id+' -> '+$dep)}}
    if($id -notin @('T-025','T-026')){
        $oldBody=($oldBlocks|Where-Object {$_.Groups[1].Value -eq $id}).Groups[2].Value
        if((Normalize $body) -ne (Normalize $oldBody)){$changed+=$id}
    }
}
Check 'No other task bodies changed' ($changed.Count -eq 0)
Check 'No missing dependency IDs' ($missing.Count -eq 0)
$resolved=[Collections.Generic.HashSet[string]]::new()
do{$advanced=$false;foreach($id in $ids){if(-not $resolved.Contains($id) -and @($dependencies[$id]|Where-Object {-not $resolved.Contains($_)}).Count -eq 0){[void]$resolved.Add($id);$advanced=$true}}}while($advanced)
Check 'No dependency cycle' ($resolved.Count -eq $ids.Count)
$definitionPattern='(?m)^### T-\d{3}[^\r\n]*|^- 前置任務[^\r\n]*'
Check 'Task titles and formal dependencies unchanged' (([regex]::Matches($task,$definitionPattern).Value -join ',') -eq ([regex]::Matches($oldTask,$definitionPattern).Value -join ','))
$stages=@([regex]::Matches($task,'(?m)^## 階段 ([0-8])[^\r\n]*'));$stageCounts=@()
for($i=0;$i -lt $stages.Count;$i++){$end=if($i+1 -lt $stages.Count){$stages[$i+1].Index}else{$task.Length};$stageCounts+=[regex]::Matches($task.Substring($stages[$i].Index,$end-$stages[$i].Index),'(?m)^### T-\d{3}').Count}
Check 'Nine phases and counts retained' ($stages.Count -eq 9 -and ($stageCounts -join ',') -eq '4,17,8,18,16,26,23,8,6')
$coveragePattern='(?ms)^## [^\r\n]*覆蓋[^\r\n]*\r?\n.*?(?=^## |\z)'
Check 'Coverage task mapping unchanged' (([regex]::Matches([regex]::Match($task,$coveragePattern).Value,'T-\d{3}').Value -join ',') -eq ([regex]::Matches([regex]::Match($oldTask,$coveragePattern).Value,'T-\d{3}').Value -join ','))
$review=Read 'REVIEW.md';$oldReview=Read (Join-Path $taskEvidence 'before/REVIEW.md')
Check 'Review historical sections 8-33 untouched' ((Normalize $oldReview.Substring($oldReview.IndexOf('## 8. '))) -eq (Normalize $review.Substring($review.IndexOf('## 8. '),$review.IndexOf('## 34. ')-$review.IndexOf('## 8. '))))
$migration=Read 'MIGRATION.md';$oldMigration=Read (Join-Path $taskEvidence 'before/MIGRATION.md');$decisionsStable=$true
foreach($number in 1..8){$dp='(?m)^[|] D'+$number+' [|][^\r\n]*';$a=[regex]::Match($oldMigration,$dp).Value;$b=[regex]::Match($migration,$dp).Value;if($number -eq 6){$a=($a -split '[|]')[2];$b=($b -split '[|]')[2]};if(-not $a -or $a -ne $b){$decisionsStable=$false}}
Check 'D1-D8 decisions retained (only D6 progress cell updated)' $decisionsStable
$section4='(?ms)^## 4[.] [^\r\n]*\r?\n.*?(?=^## |\z)'
Check 'Compatibility requirements section retained' ((Normalize ([regex]::Match($oldMigration,$section4).Value)) -eq (Normalize ([regex]::Match($migration,$section4).Value)))
Check 'Manual partial pass and unresolved reversal explicitly recorded' ($task.Contains('I-026-01 已由使用者確認人工通過') -and $task.Contains('I-026-02 仍不通過') -and $task.Contains('約 10%'))
$missingLinks=@();$markdownProblems=@()
foreach($path in @('MIGRATION.md','TASK.md','REVIEW.md','docs/evidence/T-026/REPORT-002.md','docs/evidence/T-026/fix-R2/README.md')){
    $content=Read $path;$directory=Split-Path (Resolve-Path -LiteralPath $path).Path
    foreach($match in [regex]::Matches($content,'\[[^\]]*\]\(([^)]+)\)')){$target=$match.Groups[1].Value;if($target -match '^(https?://|#)' -or $target -match '[<>]'){continue};$full=[IO.Path]::GetFullPath((Join-Path $directory ($target -split '#')[0]));if($full -eq (Join-Path $taskEvidence 'final-check.json')){continue};if(-not(Test-Path -LiteralPath $full)){$missingLinks+=($path+' -> '+$target)}}
    if([regex]::Matches($content,('(?m)^'+(([string][char]96)*3))).Count % 2 -ne 0){$markdownProblems+=($path+': unbalanced fences')}
    $columns=0;foreach($row in ($content -split '\r?\n')){if($row -match '^[|]'){$current=[regex]::Matches($row,'(?<!\\)[|]').Count;if($columns -gt 0 -and $current -ne $columns){$markdownProblems+=($path+': inconsistent table')};$columns=$current}else{$columns=0}}
}
Check 'Markdown references resolve' ($missingLinks.Count -eq 0)
Check 'Markdown tables/fences structurally valid' ($markdownProblems.Count -eq 0)
$bundle='docs/test-packages/T-026-R2-v1';$manifest=Get-Content -Raw -Encoding UTF8 ($bundle+'/manifest.json')|ConvertFrom-Json
$results=Get-Content -Raw -Encoding UTF8 ($bundle+'/results.json')|ConvertFrom-Json
Check 'R2 user results remain null and code review pending' ($null -eq $results.manualOverall -and @($results.results|Where-Object {$null -ne $_.actual}).Count -eq 0 -and -not $manifest.manualHandoffReady -and -not $manifest.fullT094Completed -and -not $manifest.gameStartedByAgent)
Check 'R2 fixed JAR hash matches manifest' ((Get-FileHash ($bundle+'/mods/simplerail-1.0.0.jar')).Hash -eq $manifest.jarSha256)
Check 'Frozen R1 JAR unchanged' ((Get-FileHash docs/evidence/T-026/fix-R1/artifacts/simplerail-1.0.0.jar).Hash -eq '8455CC5DE6FE2C7E5953E6A8F0D4A4E419A40489B954C8B0B1216304C5CEA599')
Check 'Frozen R1 ZIP unchanged' ((Get-FileHash docs/test-packages/T-026-R1-v1.zip).Hash -eq 'AF444803264FDCAE8442ECE4DC97A265427579C853E40E892F0C065F4794FA73')
$files=Get-Content -Raw -Encoding UTF8 ($bundle+'/files-manifest.json')|ConvertFrom-Json
$mismatch=@($files|Where-Object {(Get-FileHash -LiteralPath (Join-Path $bundle $_.path)).Hash -ne $_.sha256})
Check 'R2 package file fingerprints match' ($mismatch.Count -eq 0)
$after=Get-Content -Raw -Encoding UTF8 (Join-Path $taskEvidence 'source-fingerprints.json')|ConvertFrom-Json
Check 'Production files unchanged since successful build/audit' (@($after|Where-Object {(Get-FileHash -LiteralPath $_.path).Hash -ne $_.sha256}).Count -eq 0)
$ErrorActionPreference='Continue'
git -c core.safecrlf=false diff --check *> (Join-Path $taskEvidence 'diff-check-final.log');$diffCode=$LASTEXITCODE
git diff --cached --binary | Out-File -Encoding UTF8 (Join-Path $taskEvidence 'index-final.diff');$indexCode=$LASTEXITCODE
$ErrorActionPreference='Stop'
Check 'Final git diff --check exit 0' ($diffCode -eq 0)
Check 'Final index unchanged' ($indexCode -eq 0 -and (Get-FileHash (Join-Path $taskEvidence 'index-before.diff')).Hash -eq (Get-FileHash (Join-Path $taskEvidence 'index-final.diff')).Hash)
$failed=@($checks|Where-Object {-not $_.pass})
[ordered]@{command='powershell -NoProfile -ExecutionPolicy Bypass -File docs/evidence/T-026/fix-R2/final-check.ps1';checks=$checks;count=$checks.Count;failed=$failed;taskCount=$ids.Count;phaseCounts=$stageCounts;missingDependencies=$missing;otherChangedTasks=$changed;missingLinks=$missingLinks;markdownProblems=$markdownProblems;gameExecuted=$false}|ConvertTo-Json -Depth 6|Set-Content -Encoding UTF8 (Join-Path $taskEvidence 'final-check.json')
Write-Output ('Final checks='+$checks.Count+'; failed='+$failed.Count)
if($failed.Count){$failed|ConvertTo-Json;exit 1}
