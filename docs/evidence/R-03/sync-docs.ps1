$ErrorActionPreference='Stop'
$utf8=[Text.UTF8Encoding]::new($false)
$root=(Get-Location).Path
function Passed([string]$text){
 $text=$text.Replace('R-03／R-F 程式審查仍待審','R-03／本次列明 R-F 修正範圍已通過（見 [報告](docs/evidence/R-03/README.md)）')
 $text=$text.Replace('R-03／R-F 仍待審','R-03／本次列明 R-F 修正範圍已通過（見 [報告](docs/evidence/R-03/README.md)）')
 $text=$text.Replace('R-03／R-F 待審','R-03／本次列明 R-F 修正範圍通過')
 $text=$text.Replace('R-03 程式審查待審','R-03 指定範圍程式審查通過')
 $text=$text.Replace('R-03 待審','R-03 指定範圍通過')
 return $text
}
$path=Join-Path $root 'TASK.md';$text=[IO.File]::ReadAllText($path)
$stage1=$text.IndexOf('## 階段 1：');$stage3=$text.IndexOf('## 階段 3：');$stage4=$text.IndexOf('## 階段 4：')
if($stage1 -lt 0 -or $stage3 -lt $stage1 -or $stage4 -lt $stage3){throw 'Task boundaries missing'}
$prefix=Passed $text.Substring(0,$stage1)
$section=Passed $text.Substring($stage3,$stage4-$stage3)
$section=$section.Replace('T-094 全量交付待執行；','T-094 製包已結案（使用者接手）；')
$text=$prefix+$text.Substring($stage1,$stage3-$stage1)+$section+$text.Substring($stage4)
$text += @'

## R-03 與指定 R-F 修正獨立審查完成（2026-09-30）

[完整報告](docs/evidence/R-03/README.md)：**T-025／T-027／T-029／T-031／T-033／T-035 指定開發範圍通過，無新增審查缺陷**。R-F 一併通過 T-026 R1 高速升坡、R2 坡底移動保護及 T-030 R1 未供電滑行；不外推到未列明的新修正。T-029／T-035 的原碼相容界線及 U-07／U-09 意圖待確認保留，後續 state／模型／owner／GUI／整列／最終整合仍依原任務。

現行產品符合 T-030 R1 保存指紋，固定整合 JAR SHA-256 `3AB3E37EF4AA21342011332E9531088DB36D121A1F6C9C9823DD6B3259538594`；受審 HEAD `11916b69c3549504928f7cfa6790d59a2717b4b6`。全產品 Java 對真實固定 API 重編通過；五組功能隔離測試、高速幾何掃描、288 項新增高速回呼分支測試、11 項 Mixin class bytes 核對與 468 項靜態核對全部通過。替身／數值／class bytes 不冒充真實遊戲或 Mixin weaving；工具初次問題及修正紀錄保留，產品未改。

六項人工 T-026／T-028／T-030／T-032／T-034／T-036 通過結案與 T-094～T-099 製包接手結案保留，不重新製包／要求附件／代填任何遊戲結果。原所有開發與修正證據、人工確認及 R-01／R-02 紀錄不覆寫。

126 任務／九階段／正式前置不變：六歷史、一免執行、二十三開發（十二 R-01、五 R-02、六 R-03 指定範圍通過）、十人工通過、六製包接手結案、一製包依確認結案、79 待執行。本輪沒有執行 Gradle／OLD／Minecraft／GameTest，也未開始 T-037 或其他功能。原歷史章節中的待審狀態以本節更新目前結論，並非改寫當時結果。
'@
[IO.File]::WriteAllText($path,$text,$utf8)
$path=Join-Path $root 'REVIEW.md';$text=[IO.File]::ReadAllText($path)
$end=$text.IndexOf('## 2.');$prefix=Passed $text.Substring(0,$end)
$prefix=$prefix.Replace('> 最新獨立審查（2026-09-29）：[R-02','> 前次獨立審查（2026-09-29）：[R-02')
$text=$prefix+$text.Substring($end)
$text=$text.Insert($text.IndexOf("`n")+1,"`n> 最新獨立審查（2026-09-30）：[R-03 報告](docs/evidence/R-03/README.md)，六項開發指定範圍及 T-026 R1／R2、T-030 R1 的 R-F 通過，無新增缺陷；U-07／U-09 與後續整合保留。人工／製包接手結案不變。見 §47。`n")
$text += @'

## 47. R-03 與指定 R-F 修正獨立審查通過（2026-09-30）

[獨立報告](docs/evidence/R-03/README.md)簽核 T-025／T-027／T-029／T-031／T-033／T-035 指定開發範圍，**無新增 S0–S3**。R-F 通過僅限 T-026 R1 高速升坡與雙供電模型、R2 支撐碰撞前的局部移動限制、T-030 R1 未供電單向滑行與唯一 moveAlongTrack Mixin。U-07 電力翻向與 U-09 複合覆寫意圖仍未定案，原碼相容通過不表示疑點已修復或所有後續 owner／模型／GUI／保存整合完成。

受審 HEAD `11916b69c3549504928f7cfa6790d59a2717b4b6`；現行產品與 T-030 R1 保存指紋一致，整合 JAR SHA-256 `3AB3E37EF4AA21342011332E9531088DB36D121A1F6C9C9823DD6B3259538594`。九個固定 JAR／原 build、766 份輸入與來源／資源皆可追溯；468 項靜態核對通過。所有產品對真實固定 API 重新 javac 成功；功能替身、64,008 幾何判定、審查新增 288 高速 hook 判定及 11 Mixin class bytes 核對通過。原 Gradle test NO-SOURCE 保留，本次未執行 Gradle、OLD 或 Minecraft／GameTest／Mixin weaving。

審查者未實作受審產品變更，本輪不修改產品或固定包。六項使用者人工通過及六項製包接手結案保持，不要求附件或重新製包、不將人工確認綁定特定 JAR。§8–46 與原失敗／修正／證據保持歷史；R-F 不外推到新修正，D1–D8、編號／正式前置及其他任務不變。
'@
[IO.File]::WriteAllText($path,$text,$utf8)
$path=Join-Path $root 'MIGRATION.md';$text=[IO.File]::ReadAllText($path)
$end=$text.IndexOf('### 路徑與證據範圍');$text=(Passed $text.Substring(0,$end))+$text.Substring($end)
$text=$text.Replace('> 最新程式審查（2026-09-29）：','> 前次程式審查（2026-09-29）：')
$text=$text.Insert($text.IndexOf("`n")+1,"`n> 最新程式審查（2026-09-30）：[R-03](docs/evidence/R-03/README.md)六項開發指定範圍通過，並完成 T-026 R1／R2、T-030 R1 的 R-F；無新增缺陷。U-07／U-09 的意圖及後續 owner／模型整合仍待處理，人工／製包接手結案保留，未改產品或啟動遊戲。`n")
[IO.File]::WriteAllText($path,$text,$utf8)
