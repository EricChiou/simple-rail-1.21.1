$ErrorActionPreference='Stop'
$evidence=Join-Path (Get-Location) 'docs/evidence/T-027'
function Read([string]$p){[IO.File]::ReadAllText((Resolve-Path -LiteralPath $p),[Text.Encoding]::UTF8)}
function Norm([string]$s){$s.Replace([string][char]13,'').Trim()}
$checks=@();function Check([string]$n,[bool]$p){$script:checks += [ordered]@{name=$n;pass=$p}}
$task=Read 'TASK.md';$old=Read ($evidence+'/before/TASK.md')
$pattern='(?ms)^### (T-\d{3})[^\r\n]*\r?\n(.*?)(?=^### T-|^## |\z)'
$blocks=@([regex]::Matches($task,$pattern));$before=@([regex]::Matches($old,$pattern));$ids=@($blocks|ForEach-Object {$_.Groups[1].Value})
Check '126 task IDs preserved' ($ids.Count -eq 126 -and @($ids|Select-Object -Unique).Count -eq 126 -and ($ids -join ',') -eq (($before|ForEach-Object {$_.Groups[1].Value}) -join ','))
$definition='(?m)^### T-\d{3}[^\r\n]*|^- 前置任務[^\r\n]*'
Check 'Titles/dependencies preserved' (([regex]::Matches($task,$definition).Value -join ',') -eq ([regex]::Matches($old,$definition).Value -join ','))
$deps=@{};$missing=@();$other=@();$statuses=@{}
foreach($block in $blocks){$id=$block.Groups[1].Value;$body=$block.Groups[2].Value;$deps[$id]=@([regex]::Matches([regex]::Match($body,'(?m)^- 前置任務[^\r\n]*').Value,'T-\d{3}')|ForEach-Object {$_.Value});foreach($d in $deps[$id]){if($ids -notcontains $d){$missing+=($id+' -> '+$d)}};$statuses[$id]=[regex]::Match($body,'(?m)^- 狀態：([^\r\n]*)').Groups[1].Value;if($id -notin @('T-027')){$oldBody=($before|Where-Object {$_.Groups[1].Value -eq $id}).Groups[2].Value;if((Norm $body) -ne (Norm $oldBody)){$other+=$id}}}
Check 'Only T-027 task description updated' ($other.Count -eq 0)
Check 'No missing dependencies' ($missing.Count -eq 0)
$resolved=[Collections.Generic.HashSet[string]]::new();do{$progress=$false;foreach($id in $ids){if(-not $resolved.Contains($id) -and @($deps[$id]|Where-Object {-not $resolved.Contains($_)}).Count -eq 0){[void]$resolved.Add($id);$progress=$true}}}while($progress)
Check 'No dependency cycles' ($resolved.Count -eq 126)
Check 'T-026 user confirmed passed' ($statuses['T-026'] -eq '人工測試通過（2026-09-29 使用者確認，已結案）')
Check 'Three manual passes, zero failures, 96 pending' (@($statuses.Values|Where-Object {$_.StartsWith('人工測試通過')}).Count -eq 3 -and @($statuses.Values|Where-Object {$_.StartsWith('人工測試不通過')}).Count -eq 0 -and @($statuses.Values|Where-Object {$_ -eq '待執行'}).Count -eq 96)
Check 'T-029 and T-095 not executed' ($statuses['T-029'] -eq '待執行' -and $statuses['T-095'] -eq '待執行')
$phases=@([regex]::Matches($task,'(?m)^## 階段 ([0-8])[^\r\n]*'));$phaseCounts=@();for($i=0;$i -lt $phases.Count;$i++){$end=if($i+1 -lt $phases.Count){$phases[$i+1].Index}else{$task.Length};$phaseCounts+=[regex]::Matches($task.Substring($phases[$i].Index,$end-$phases[$i].Index),'(?m)^### T-\d{3}').Count}
Check 'Nine phases/counts preserved' ($phases.Count -eq 9 -and ($phaseCounts -join ',') -eq '4,17,8,18,16,26,23,8,6')
$cp='(?ms)^## [^\r\n]*覆蓋[^\r\n]*\r?\n.*?(?=^## |\z)'
Check 'Coverage unchanged' ((Norm ([regex]::Match($task,$cp).Value)) -eq (Norm ([regex]::Match($old,$cp).Value)))
$history='## T-026 使用者回報與來源調查';$endHistory='## T-027 holding_rail 開發交付'
Check 'Task failure/correction history unchanged' ((Norm $old.Substring($old.IndexOf($history))) -eq (Norm $task.Substring($task.IndexOf($history),$task.IndexOf($endHistory)-$task.IndexOf($history))))
$review=Read 'REVIEW.md';$oldReview=Read ($evidence+'/before/REVIEW.md')
Check 'Review sections 8-35 unchanged' ((Norm $oldReview.Substring($oldReview.IndexOf('## 8. '))) -eq (Norm $review.Substring($review.IndexOf('## 8. '),$review.IndexOf('## 36. ')-$review.IndexOf('## 8. '))))
$migration=Read 'MIGRATION.md';$oldMigration=Read ($evidence+'/before/MIGRATION.md');$decisions=$true
foreach($n in 1..8){$p='(?m)^[|] D'+$n+' [|][^\r\n]*';$a=[regex]::Match($oldMigration,$p).Value;$b=[regex]::Match($migration,$p).Value;if($n -eq 6){$a=($a -split '[|]')[2];$b=($b -split '[|]')[2]};if(-not $a -or $a -ne $b){$decisions=$false}}
Check 'D1-D8 decisions preserved' $decisions
$product=Get-Content -Raw -Encoding UTF8 ($evidence+'/source-fingerprints.json')|ConvertFrom-Json
Check 'Source/resources/Gradle unchanged' (@($product|Where-Object {(Get-FileHash -LiteralPath $_.path).Hash -ne $_.sha256}).Count -eq 0)
$links=@();$mdProblems=@()
foreach($path in @('MIGRATION.md','TASK.md','REVIEW.md','docs/evidence/T-026/REPORT-003.md','docs/evidence/T-027/README.md','docs/evidence/T-027/RAIL_CONTRACT.md')){$content=Read $path;$dir=Split-Path (Resolve-Path -LiteralPath $path).Path;foreach($m in [regex]::Matches($content,'\[[^\]]*\]\(([^)]+)\)')){$target=$m.Groups[1].Value;if($target -match '^(https?://|#)' -or $target -match '[<>]'){continue};if(-not(Test-Path -LiteralPath ([IO.Path]::GetFullPath((Join-Path $dir ($target -split '#')[0]))))){$links+=($path+' -> '+$target)}};if([regex]::Matches($content,('(?m)^'+(([string][char]96)*3))).Count % 2 -ne 0){$mdProblems+=($path+': unbalanced fence')};$columns=0;foreach($line in ($content -split '\r?\n')){if($line -match '^[|]'){$c=[regex]::Matches($line,'(?<!\\)[|]').Count;if($columns -gt 0 -and $c -ne $columns){$mdProblems+=($path+': inconsistent table')};$columns=$c}else{$columns=0}}}
Check 'Links resolve' ($links.Count -eq 0);Check 'Tables/fences valid' ($mdProblems.Count -eq 0)
$ErrorActionPreference='Continue'
git -c core.safecrlf=false diff --check *> ($evidence+'/diff-check.log');$diffCode=$LASTEXITCODE
git diff --cached --binary | Out-File -Encoding UTF8 ($evidence+'/index-after.diff');$indexCode=$LASTEXITCODE
$ErrorActionPreference='Stop'
Check 'git diff --check exit 0' ($diffCode -eq 0)
Check 'Index unchanged' ($indexCode -eq 0 -and (Get-FileHash ($evidence+'/index-before.diff')).Hash -eq (Get-FileHash ($evidence+'/index-after.diff')).Hash)
$failed=@($checks|Where-Object {-not $_.pass})
[ordered]@{command='powershell -NoProfile -ExecutionPolicy Bypass -File docs/evidence/T-027/doc-check.ps1';exitCode=$(if($failed.Count){1}else{0});checks=$checks;count=$checks.Count;failed=$failed;missingDependencies=$missing;phaseCounts=$phaseCounts;manualPasses=3;manualFailures=0;pending=96;productChanged=$false;gameExecuted=$false;buildExecuted=$false;review='R-03 / R-F pending';missingLinks=$links;markdownProblems=$mdProblems}|ConvertTo-Json -Depth 5|Set-Content -Encoding UTF8 ($evidence+'/doc-check.json')
Write-Output ('Checks='+$checks.Count+'; failed='+$failed.Count)
if($failed.Count){$failed|ConvertTo-Json;exit 1}
