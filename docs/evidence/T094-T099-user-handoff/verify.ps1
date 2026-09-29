$ErrorActionPreference='Stop'
$e=Join-Path (Get-Location) 'docs/evidence/T094-T099-user-handoff'
function Read([string]$p){[IO.File]::ReadAllText((Resolve-Path $p),[Text.Encoding]::UTF8)}
function Norm([string]$s){$s.Replace([string][char]13,'').Trim()}
$checks=@();function Check([string]$name,[bool]$pass){$script:checks += [ordered]@{name=$name;pass=$pass}}
$task=Read 'TASK.md';$old=Read ($e+'/before/TASK.md')
$pattern='(?ms)^### (T-\d{3})[^\r\n]*\r?\n(.*?)(?=^### T-|^## |\z)'
$blocks=@([regex]::Matches($task,$pattern));$before=@([regex]::Matches($old,$pattern));$ids=@($blocks|ForEach-Object {$_.Groups[1].Value})
Check '126 unique task IDs/order preserved' ($ids.Count -eq 126 -and @($ids|Select-Object -Unique).Count -eq 126 -and ($ids -join ',') -eq (($before|ForEach-Object {$_.Groups[1].Value}) -join ','))
$definition='(?m)^### T-\d{3}[^\r\n]*|^- 前置任務[^\r\n]*'
Check 'Titles and dependency numbers preserved' (([regex]::Matches($task,$definition).Value -join ',') -eq ([regex]::Matches($old,$definition).Value -join ','))
$deps=@{};$missing=@();$statuses=@{};$statusChanges=@();$otherChanges=@()
$allowed=@('T-025','T-027','T-029','T-031','T-033','T-035','T-026','T-028','T-030','T-032','T-034','T-036','T-094','T-095','T-096','T-097','T-098','T-099')
foreach($block in $blocks){$id=$block.Groups[1].Value;$body=$block.Groups[2].Value;$prior=($before|Where-Object {$_.Groups[1].Value -eq $id}).Groups[2].Value;$deps[$id]=@([regex]::Matches([regex]::Match($body,'(?m)^- 前置任務[^\r\n]*').Value,'T-\d{3}')|ForEach-Object {$_.Value});foreach($d in $deps[$id]){if($ids -notcontains $d){$missing+=($id+' -> '+$d)}};$statuses[$id]=[regex]::Match($body,'(?m)^- 狀態：([^\r\n]*)').Groups[1].Value;$priorStatus=[regex]::Match($prior,'(?m)^- 狀態：([^\r\n]*)').Groups[1].Value;if($statuses[$id] -ne $priorStatus){$statusChanges+=$id};if($allowed -notcontains $id -and (Norm $body) -ne (Norm $prior)){$otherChanges+=$id}}
Check 'Only six package statuses changed' (($statusChanges|Sort-Object) -join ',' -eq 'T-094,T-095,T-096,T-097,T-098,T-099')
Check 'Only six packages and their implementation/manual references changed' ($otherChanges.Count -eq 0)
Check 'Six tasks administratively closed by user handoff' (@($statuses.Values|Where-Object {$_.StartsWith('已結案（使用者接手')}).Count -eq 6)
Check '23 development complete, 86 pending, three manual passes' (@($statuses.Values|Where-Object {$_.StartsWith('開發完成')}).Count -eq 23 -and @($statuses.Values|Where-Object {$_ -eq '待執行'}).Count -eq 86 -and @($statuses.Values|Where-Object {$_.StartsWith('人工測試通過')}).Count -eq 3)
Check 'Manual five pending; T-026 remains user passed' (@(@('T-028','T-030','T-032','T-034','T-036')|Where-Object {$statuses[$_] -ne '待執行'}).Count -eq 0 -and $statuses['T-026'].StartsWith('人工測試通過'))
Check 'T-037 not executed' ($statuses['T-037'] -eq '待執行')
Check 'No missing dependencies' ($missing.Count -eq 0)
$resolved=[Collections.Generic.HashSet[string]]::new();do{$progress=$false;foreach($id in $ids){if(-not $resolved.Contains($id) -and @($deps[$id]|Where-Object {-not $resolved.Contains($_)}).Count -eq 0){[void]$resolved.Add($id);$progress=$true}}}while($progress)
Check 'No dependency cycles' ($resolved.Count -eq 126)
$phases=@([regex]::Matches($task,'(?m)^## 階段 ([0-8])[^\r\n]*'));$counts=@();for($i=0;$i -lt $phases.Count;$i++){$end=if($i+1 -lt $phases.Count){$phases[$i+1].Index}else{$task.Length};$counts+=[regex]::Matches($task.Substring($phases[$i].Index,$end-$phases[$i].Index),'(?m)^### T-\d{3}').Count}
Check 'Nine phases/counts preserved' ($phases.Count -eq 9 -and ($counts -join ',') -eq '4,17,8,18,16,26,23,8,6')
$coverage='(?ms)^## 覆蓋檢查表.*?(?=^## |\z)'
$a=[regex]::Match($old,$coverage).Value;$b=[regex]::Match($task,$coverage).Value
Check 'Coverage table rows preserved' (([regex]::Matches($a,'(?m)^\|[^\r\n]*').Value -join ',') -eq ([regex]::Matches($b,'(?m)^\|[^\r\n]*').Value -join ','))
$history='## T-026 使用者回報與來源調查';$newHistory='## T-094～T-099 使用者接手與製包結案'
Check 'Task history retained' ((Norm $old.Substring($old.IndexOf($history))) -eq (Norm $task.Substring($task.IndexOf($history),$task.IndexOf($newHistory)-$task.IndexOf($history))))
$review=Read 'REVIEW.md';$oldReview=Read ($e+'/before/REVIEW.md')
Check 'Review sections 8-40 retained' ((Norm $oldReview.Substring($oldReview.IndexOf('## 8. '))) -eq (Norm $review.Substring($review.IndexOf('## 8. '),$review.IndexOf('## 41. ')-$review.IndexOf('## 8. '))))
$migration=Read 'MIGRATION.md';$oldMigration=Read ($e+'/before/MIGRATION.md');$same=$true
foreach($n in 1..8){$p='(?m)^[|] D'+$n+' [|][^\r\n]*';if([regex]::Match($oldMigration,$p).Value -ne [regex]::Match($migration,$p).Value){$same=$false}}
Check 'D1-D8 unchanged' $same
$product=Get-Content -Raw -Encoding UTF8 ($e+'/product-before.json')|ConvertFrom-Json
Check 'Product/resources/Gradle unchanged' (@($product|Where-Object {(Get-FileHash -LiteralPath $_.path).Hash -ne $_.sha256}).Count -eq 0)
$links=@();$mdProblems=@()
foreach($path in @('MIGRATION.md','TASK.md','REVIEW.md','docs/evidence/T094-T099-user-handoff/README.md')){
 $content=Read $path;$dir=Split-Path (Resolve-Path $path).Path
 foreach($m in [regex]::Matches($content,'\[[^\]]*\]\(([^)]+)\)')){$target=$m.Groups[1].Value;if($target -match '^(https?://|#)' -or $target -match '[<>]'){continue};if(-not(Test-Path -LiteralPath ([IO.Path]::GetFullPath((Join-Path $dir ($target -split '#')[0]))))){$links+=($path+' -> '+$target)}}
 if([regex]::Matches($content,('(?m)^'+(([string][char]96)*3))).Count % 2 -ne 0){$mdProblems+=($path+': unbalanced fence')}
 $columns=0;foreach($line in ($content -split '\r?\n')){if($line -match '^[|]'){$c=[regex]::Matches($line,'(?<!\\)[|]').Count;if($columns -gt 0 -and $c -ne $columns){$mdProblems+=($path+': inconsistent table')};$columns=$c}else{$columns=0}}
}
Check 'Local links resolve' ($links.Count -eq 0)
Check 'Markdown tables/fences consistent' ($mdProblems.Count -eq 0)
$ErrorActionPreference='Continue';git -c core.safecrlf=false diff --check *> ($e+'/diff-check.log');$diffCode=$LASTEXITCODE;git diff --cached --binary|Out-File -Encoding UTF8 ($e+'/index-after.diff');$indexCode=$LASTEXITCODE;$ErrorActionPreference='Stop'
Check 'git diff --check exit 0' ($diffCode -eq 0)
Check 'Index unchanged' ($indexCode -eq 0 -and (Get-FileHash ($e+'/index-before.diff')).Hash -eq (Get-FileHash ($e+'/index-after.diff')).Hash)
$failed=@($checks|Where-Object {-not $_.pass})
[ordered]@{command='powershell -NoProfile -ExecutionPolicy Bypass -File docs/evidence/T094-T099-user-handoff/verify.ps1';count=$checks.Count;checks=$checks;failed=$failed;exitCode=$(if($failed.Count){1}else{0});taskCount=126;phaseCounts=$counts;statusChanges=$statusChanges;closedByUserHandoff=6;pending=86;manualPasses=3;developmentComplete=23;missingDependencies=$missing;missingLinks=$links;markdownProblems=$mdProblems;productChanged=$false;buildExecuted=$false;packageProduced=$false;gameExecuted=$false;reviewExecuted=$false}|ConvertTo-Json -Depth 5|Set-Content -Encoding UTF8 ($e+'/verification.json')
Write-Output ('Checks='+$checks.Count+'; failed='+$failed.Count)
if($failed.Count){$failed|ConvertTo-Json;exit 1}
