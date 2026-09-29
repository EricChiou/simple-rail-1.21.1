$ErrorActionPreference='Stop'
$root=(Get-Location).Path
$e=Join-Path $root 'docs/evidence/T094-T099-user-handoff'
New-Item -ItemType Directory -Force ($e+'/before')|Out-Null
foreach($file in @('TASK.md','MIGRATION.md','REVIEW.md')){Copy-Item -LiteralPath $file -Destination ($e+'/before/'+$file)}
git diff --cached --binary|Out-File -Encoding UTF8 ($e+'/index-before.diff')
@(Get-ChildItem src -Recurse -File;Get-Item build.gradle,gradle.properties,settings.gradle;Get-ChildItem gradle -Recurse -File)|ForEach-Object {[ordered]@{path=$_.FullName;sha256=(Get-FileHash $_.FullName).Hash}}|ConvertTo-Json|Set-Content -Encoding UTF8 ($e+'/product-before.json')
function Read([string]$p){[IO.File]::ReadAllText((Join-Path $root $p),[Text.Encoding]::UTF8)}
function SaveDocument([string]$p,[string]$s){[IO.File]::WriteAllText((Join-Path $root $p),$s,[Text.UTF8Encoding]::new($false))}
$task=Read 'TASK.md'
$pairs=@{'T-094'='T-026';'T-095'='T-028';'T-096'='T-030';'T-097'='T-032';'T-098'='T-034';'T-099'='T-036'}
$developers=@{'T-025'='T-094';'T-027'='T-095';'T-029'='T-096';'T-031'='T-097';'T-033'='T-098';'T-035'='T-099'}
$blocks=[regex]::Matches($task,'(?ms)^### (T-\d{3})[^\r\n]*\r?\n.*?(?=^### T-|^## |\z)')
for($i=$blocks.Count-1;$i -ge 0;$i--){
 $m=$blocks[$i];$id=$m.Groups[1].Value;$s=$m.Value
 if($pairs.ContainsKey($id)){
  $manual=$pairs[$id]
  $s=[regex]::Replace($s,'(?m)^- 狀態：[^\r\n]*','- 狀態：已結案（使用者接手；2026-09-29）')
  $s=[regex]::Replace($s,'(?m)^- 責任：[^\r\n]*','- 責任：使用者自行準備本項包；Agent 製包工作依使用者指示結案。獨立 Review Agent 仍按 R-03 審功能程式／資源與測例覆蓋，不由本次接手推定審查通過。')
  $s=[regex]::Replace($s,'(?m)^- 分項狀態：[^\r\n]*',('- 分項狀態：Agent 製包已結案、使用者接手自行處理；不是已製包／開發完成或人工通過。'+$manual+' 原人工狀態另列，R-03 待審。'))
  $s=[regex]::Replace($s,'(?m)^- 具體工作與交付成果：[^\r\n]*',('- 具體工作與交付成果：使用者自行準備 '+$manual+' 所需測試包及操作；Agent 記錄接手與製包任務結案。原功能、測例與未知項要求保留，Agent 不再製作本項包或要求使用者提交製包證據。'))
  $s=[regex]::Replace($s,'(?m)^- 完成條件：[^\r\n]*','- 完成條件：已記錄使用者接手／結案指示，固定編號及對應人工任務保留，Agent 製包閘門解除；不要求以實際包證據證明此行政結案，不虛構實際包完成或人工結果。')
  $s=[regex]::Replace($s,'(?m)^- 驗證方式與需保存的證據：[^\r\n]*','- 驗證方式與需保存的證據：保存使用者指示及本次日期，僅核對文件／編號／依賴；不製包、不重跑 build／遊戲、不補造 JAR 雜湊／log。人工完成仍由使用者另行確認。')
  $s=$s.TrimEnd()+[Environment]::NewLine+'- 結案依據：[使用者接手紀錄](docs/evidence/T094-T099-user-handoff/README.md)。'+[Environment]::NewLine+[Environment]::NewLine
 }elseif($developers.ContainsKey($id)){
  $pkg=$developers[$id]
  foreach($old in @($pkg+' 全量包待執行',$pkg+' 包仍待執行',$pkg+' 包未執行',$pkg+' 包待執行',$pkg+' 全量包待執行')){$s=$s.Replace($old,$pkg+' 製包已結案（使用者接手）')}
  $s=$s.TrimEnd()+[Environment]::NewLine+('- 使用者接手更新（2026-09-29）：'+$pkg+' 製包已結案，由使用者自行處理；本項其餘「包未執行」描述保留 Agent 歷史範圍，以本行取代其製包待辦。原 API／build／審查／人工／未決要求不變。')+[Environment]::NewLine+[Environment]::NewLine
 }elseif($pairs.Values -contains $id){
  $pkg=($pairs.GetEnumerator()|Where-Object {$_.Value -eq $id}).Key
  if($id -ne 'T-026'){
   $s=[regex]::Replace($s,'(?m)^- 分項狀態：[^\r\n]*',('- 分項狀態：人工測試待執行；'+$pkg+' 製包已結案（使用者接手），不再等待 Agent 製包。R-03 待審；原功能／其他前置／未决預期保留，收到使用者確認即可人工結案，毋須提交證據；未確認不填通過。'))
   $s=[regex]::Replace($s,'(?m)^- 責任：[^\r\n]*',('- 責任：使用者自行準備 '+$pkg+' 的包並親自執行本項遊戲回報；開發 Agent 負責程式／build／分析修正，不再製作此包。獨立 Review Agent 僅按 R-03 審程式／覆蓋，不代跑或簽人工通過。'))
  }
  $s=$s.TrimEnd()+[Environment]::NewLine+('- 使用者接手更新（2026-09-29）：'+$pkg+' 製包已結案；前置編號保留追溯，此 Agent 製包閘門視為已解除。本項人工結果不由接手推定，原功能與其他必要前置保留。')+[Environment]::NewLine+[Environment]::NewLine
 }
 $task=$task.Remove($m.Index,$m.Length).Insert($m.Index,$s)
}
$task=$task.Replace('92 項待執行**','六項製包已結案（使用者接手）；86 項待執行**')
$task=$task.Replace('11 項待執行，U-07／U-09','六項製包已結案（使用者接手）／5 項人工待執行，U-07／U-09')
$task=$task.Replace('T-036／T-099 未執行。level','T-036 人工未執行；T-094～T-099 製包已結案（使用者接手）。level')
$exception='**製包接手例外（2026-09-29 使用者決策）：** T-094～T-099 標「已結案（使用者接手）」，僅表示 Agent 製包工作結案，由使用者自行處理；不是實際包已完成／開發完成／程式審查通過／人工通過。編號／前置保留追溯，其對應 Agent 製包閘門視為解除，Agent 不再製包或要求製包證據。其他功能／人工／Review 前置與 U-07／U-09 待確認保留；T-026 原已通過、T-028／T-030／T-032／T-034／T-036 仍待使用者確認。此例外優先於本文件與歷史模板對六包的 Agent 交付／證據要求，其餘包分工不變。'
$task=$task.Replace('### 共用測試包與回報格式',$exception+[Environment]::NewLine+[Environment]::NewLine+'### 共用測試包與回報格式')
$task=$task.Replace('| 使用者決定免執行 | 僅 T-002；','| 已結案（使用者接手） | 僅 T-094～T-099 的 Agent 製包行政結案；使用者自行處理，不代表實際製包／人工或審查通過；不要求製包證據 |'+[Environment]::NewLine+'| 使用者決定免執行 | 僅 T-002；')
$task=$task.Replace('開發 Agent 在 T-090–T-118 提供各驗收包；','開發 Agent 在 T-090–T-118 提供各驗收包，但 T-094～T-099 由使用者接手並已結案；')
$task=$task.Replace('測試包對照另列於下表。','測試包對照另列於下表；T-094～T-099 現由使用者接手、Agent 已結案，對照保留追溯，不代表人工已通過。')
$task += [Environment]::NewLine+'## T-094～T-099 使用者接手與製包結案（2026-09-29）'+[Environment]::NewLine+[Environment]::NewLine+'依[使用者原文指示](docs/evidence/T094-T099-user-handoff/README.md)，六包改由使用者自行處理、Agent 製包已結案；不將未來意圖寫成已完成實際包或遊戲結果。前置編號／九階段／功能覆蓋保留，六包對应 Agent 製包閘門解除，其他功能／審查／人工／未知前置不改。T-026 原通過結案保留，其餘五項人工仍待確認；U-07／U-09 未獲新決策。'+[Environment]::NewLine+[Environment]::NewLine+'最新 126 項：六歷史、一免執行、二十三開發、一受阻、三人工通過、六使用者接手製包結案、86 待執行；階段 3 為六開發、一人工通過、六製包結案、五人工待執行。先前各數量與製包未執行文字保留歷史，最新以本次接手例外為準。下一可獨立開發 T-037 未開始；本輪只有文件變更，未改產品／Gradle／資源，未 build／製包／啟動 Minecraft。'+[Environment]::NewLine
SaveDocument 'TASK.md' $task
$migration=Read 'MIGRATION.md'
$migration=$migration.Replace('最新交付：2026-09-29。狀態：','最新交付／分工調整：2026-09-29。狀態：')
$migration=$migration.Replace('；歷史保留**','；T-094～T-099 製包已結案（使用者接手，取代下列製包未執行待辦）；歷史保留**')
$migration=$migration.Replace('以下完整功能及驗收要求不刪減；','T-094～T-099 Agent 製包已由使用者接手結案，不再阻擋對應人工；未決意圖／功能 owner 與其他前置保留。以下完整功能及驗收要求不刪減；')
$marker='- 待技術驗證：'
$update='- 製包分工更新：[T-094～T-099 使用者接手指示](docs/evidence/T094-T099-user-handoff/README.md)，六項 Agent 製包已結案、由使用者自行處理；原開發交付列的包未執行為 Agent 歷史，以本次例外取代待辦。不是實際包／新 JAR／審查或遊戲已通過，不要求使用者製包證據。T-026 原已通過、其餘五項人工仍待確認；U-07／U-09 待確認、D1–D8 與全部功能驗收不變。'
$migration=$migration.Replace($marker,$update+[Environment]::NewLine+$marker)
$migration += [Environment]::NewLine+'本次 T-094～T-099 由使用者接手、Agent 製包工作已結案；上述包未執行文字僅保留歷史，不再視為 Agent 待辦或人工的製包阻擋。其餘人工與程式審查仍分開記錄，不推定通過；沒有開始新任務。'+[Environment]::NewLine
SaveDocument 'MIGRATION.md' $migration
$review=Read 'REVIEW.md'
$review=$review.Replace('，不倒填其他任務或審查通過。','，不倒填其他任務或審查通過。T-094～T-099 Agent 製包最新已結案（使用者接手），舊製包待辦由 §41 取代。')
$review=$review.Replace('## 2.',$exception+[Environment]::NewLine+[Environment]::NewLine+'## 2.')
$review += [Environment]::NewLine+'## 41. T-094～T-099 使用者接手／Agent 製包結案（2026-09-29）'+[Environment]::NewLine+[Environment]::NewLine+'依[使用者指示](docs/evidence/T094-T099-user-handoff/README.md)將六包標「已結案（使用者接手）」，不記「開發完成」或「人工通過」。Agent 不再製作／審核這六包的交付證據，使用者自行處理；Review 仍只審功能程式／資源、邏輯、測例覆蓋、保存與同步設計／D1–D8，不由接手推定 R-03／R-F 通過，不啟動遊戲。'+[Environment]::NewLine+[Environment]::NewLine+'固定編號／前置／測例與功能保留；六包的 Agent 製包閘門解除，未實作 owner／U-07／U-09 預期與其他前置不改。T-026 原已通過結案，T-028／T-030／T-032／T-034／T-036 未收到新人工確認，仍待執行；確認即可結案、附件選用。§8–40 舊包待辦／數量為歷史，不改原 API／build／固定 JAR／使用者結果。'+[Environment]::NewLine+[Environment]::NewLine+'最新 126 項：六歷史、一免執行、二十三開發、一受阻、三人工通過、六製包接手結案、86 待執行。只編修文件，產品／Gradle／資源不改，未執行 build／製包／遊戲／獨立審查／其他任務。下一可獨立開發 T-037 尚未開始。'+[Environment]::NewLine
SaveDocument 'REVIEW.md' $review
Write-Output 'Updated three planning files; six package tasks administratively closed by user handoff.'
