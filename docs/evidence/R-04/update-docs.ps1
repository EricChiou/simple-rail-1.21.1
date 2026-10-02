$ErrorActionPreference='Stop'
$root=(Get-Location).Path
$utf8=[Text.UTF8Encoding]::new($false)
$task=[IO.File]::ReadAllText((Join-Path $root 'docs/evidence/R-04/before/TASK.md'))
$split=$task.IndexOf('## 執行規則與範圍')
$head=$task.Substring(0,$split).Replace('八項 R-04 待審','八項 R-04 指定範圍通過').Replace('R-04 獨立程式審查仍待執行，不從人工通過推定已審。','R-04 指定開發範圍及 T-040 R1 的 R-F 已獨立審查通過，見 [報告](docs/evidence/R-04/README.md)；沒有新增缺陷，不從人工通過推定程式結論。')
$task=$head+$task.Substring($split)
$task=$task.Replace('八項開發完成、R-04 待審','八項開發完成、R-04 指定範圍通過').Replace('T-082／T-083 及 R-04 仍各自待辦','T-040 R1 的 R-F 通過；T-082／T-083 仍各自待辦')
$task=$task.Replace('正式註冊仍待實作，不替換舊方塊或物品 ID。','T-044 已正式註冊，R-04 已核對，不替換舊方塊或物品 ID。')
$task=$task.Replace('## 階段 4：方塊實體、計時與容器',"## 階段 4：方塊實體、計時與容器`r`n`r`n> 2026-10-01：[R-04 指定開發範圍及 T-040 R1 複查通過](docs/evidence/R-04/README.md)，無新增缺陷。下列帶交付日期的證據段落保留當時狀態；現況以各項狀態／分項狀態及本報告為準。使用者人工與製包結案不變。")
foreach($id in @('037','038','039','041','043','044','045','046')){
    $pattern='(?ms)^### T-'+$id+'\b.*?(?=^### T-|^## 階段|\z)'
    $match=[regex]::Match($task,$pattern)
    if(!$match.Success){throw ('Missing task '+$id)}
    $block=$match.Value
    $state=if($id -in @('039','046')){'開發完成／條件式無需新增補丁；R-04 指定範圍通過（2026-10-01）'}else{'開發完成；R-04 指定範圍通過（2026-10-01）'}
    $block=[regex]::Replace($block,'(?m)^- 狀態：[^\r\n]*',('- 狀態：'+$state))
    $scope=switch($id){
        '037' {'T-119 維持使用者人工完成結案；診斷 fixture 不等於正式 D5 礦車驗收。'}
        '038' {'T-040／T-100 維持使用者確認結案；T-083 整合與 M-01 待辦，不補填量測資料。'}
        '039' {'五項保存疑點由 T-038 避開的判定通過；T-119／T-040 與 T-100 結案保留，T-083 另驗。'}
        '041' {'T-042 人工通過與 T-101 使用者完成結案保留；極大設定的產品期望與未提供的逐例相位數值不補定。'}
        '043' {'T-120 人工完成且未發現異常；診斷爐車／link_plan 不等於正式車頭／編組已驗收。'}
        '044' {'T-047 人工通過、T-102 使用者完成結案保留；T-082 專用 BE 存讀整合另驗。'}
        '045' {'原版生成／不消耗／來源觸發規格通過；T-120／T-047 人工結案保留，車頭／編組留 T-048／T-059／T-060。'}
        '046' {'T-120 無異常確認與現行來源支持條件式無需新增補丁；T-047 人工通過保留，不倒填受測 JAR。'}
    }
    $block=[regex]::Replace($block,'(?m)^- 分項狀態：[^\r\n]*',('- 分項狀態：[R-04 指定範圍通過](docs/evidence/R-04/README.md)。'+$scope))
    $task=$task.Substring(0,$match.Index)+$block+$task.Substring($match.Index+$match.Length)
}
foreach($id in @('040','042','047','100','101','102','119','120')){
    $pattern='(?ms)^### T-'+$id+'\b.*?(?=^### T-|^## 階段|\z)'
    $match=[regex]::Match($task,$pattern)
    if(!$match.Success){throw ('Missing task '+$id)}
    $block=$match.Value
    $block=$block.Replace('R-04／R-F 獨立程式審查另待執行','R-04／T-040 R1 的 R-F 已通過').Replace('R-04 獨立程式審查另待執行','R-04 指定程式範圍已通過').Replace('R-04／R-F 程式審查待審','R-04／T-040 R1 的 R-F 已通過').Replace('R-04 獨立程式審查仍待審','R-04 指定程式範圍已通過').Replace('R-04 仍待審','R-04 指定程式範圍已通過')
    $block=$block.Replace('R-04 程式審查仍待審','R-04 指定程式範圍已通過').Replace('R-04 程式審查待審','R-04 指定程式範圍已通過')
    $task=$task.Substring(0,$match.Index)+$block+$task.Substring($match.Index+$match.Length)
}
[IO.File]::WriteAllText((Join-Path $root 'TASK.md'),$task,$utf8)
foreach($name in @('REVIEW.md','MIGRATION.md')){
    $path=Join-Path $root $name;$text=[IO.File]::ReadAllText((Join-Path $root ('docs/evidence/R-04/before/'+$name)));$pos=$text.IndexOf("`n")+1
    $note="`r`n> 最新獨立審查（2026-10-01）：[R-04 報告](docs/evidence/R-04/README.md)，T-037～T-039／T-041／T-043～T-046 八項指定開發範圍及 T-040 R1 的 R-F 通過，無新增 S0–S3 缺陷。8 組非遊戲測試共 255,454 判定、28 份產品 Java 固定 API 編譯及 177 項靜態核對通過；現行 JAR 的 34 個 class 與重新編譯來源反組譯一致。既有五項人工、T-100／T-101／T-102 製包確認結案保留；不補造受測版本或 Agent 製包驗證。M-01、U-07／其他 U-09、T-060／T-082～T-084 及後續候選範圍保留。以下先前進度均為歷史快照，以本段／TASK 現況為準。`r`n"
    $text=$text.Insert($pos,$note)
    if($name -eq 'REVIEW.md'){
        $text+="`r`n## 61. R-04 與 T-040 R1 獨立程式複查通過（2026-10-01）`r`n`r`n指定開發範圍 T-037～T-039、T-041、T-043～T-046 通過；本次 R-F 僅含 T-040 R1 扳手累積狀態修正。沒有新增 S0–S3 發現。完整逐項結論、固定輸入、API／JVM 驗證及保留限制見 [R-04 報告](docs/evidence/R-04/README.md)。`r`n`r`n固定現行產品採 T-045 JAR，SHA-256 ``61B933A80F9B984E9AF35D7E55713803DF36328371D6B08CC02A63ADCEDA6C1E``；HEAD ``11916b69c3549504928f7cfa6790d59a2717b4b6`` 加審查前已暫存差異。全部產品未修改，Git index 保留，沒有啟動 Minecraft／GameTest／OLD build。獨立重跑 8 組非遊戲測試及真實 API 編譯通過，固定包／bytecode／資源與 API 順序核對通過。`r`n`r`nT-119／T-040／T-042／T-120／T-047 保持使用者人工結案；T-100／T-101／T-102 保持使用者完成確認，不冒充 Agent 已核對其包。T-037／T-043 診斷包與 T-040 R1 固定重測包按保存產物審查，未將其雜湊倒填為人工受測版本。M-01、訊號極大設定期望、其他 U-09 與後續整合仍依原範圍處理；不撤銷既有人工通過。`r`n"
    }
    [IO.File]::WriteAllText($path,$text,$utf8)
}
Write-Output 'Updated TASK, REVIEW, MIGRATION only.'
