$ErrorActionPreference='Stop'
$utf8=[Text.UTF8Encoding]::new($false)
$root=(Get-Location).Path
$taskPath=Join-Path $root 'TASK.md'
$task=[IO.File]::ReadAllText($taskPath)
$start=$task.IndexOf('## 階段 2：')
$end=$task.IndexOf('## 階段 3：')
if ($start -lt 0 -or $end -le $start) { throw 'Missing stage boundaries' }
$section=$task.Substring($start,$end-$start)
$section=$section.Replace('R-02 程式審查待審','R-02 程式審查通過（指定開發範圍，見 [R-02 報告](docs/evidence/R-02/README.md)）')
$section=$section.Replace('開發完成；R-02 待審；T-024','開發完成；R-02 包製作／測例審查通過（REV-R02-001 S3 勘誤見報告）；T-024')
$section=$section.Replace('人工測試通過、已結案；R-02 待審。','人工測試通過、已結案；R-02 指定開發範圍已審，見 [報告](docs/evidence/R-02/README.md)。')
$section=$section.Replace('R-02 待審；T-023 人工','R-02 原草稿及限制已審，不簽新版包開發完成；T-023 人工')
$prefix=$task.Substring(0,$start)
$prefix=$prefix.Replace('五項 R-02 待審','五項 R-02 指定範圍通過')
$prefix=$prefix.Replace('T-019–T-022／T-093 仍 R-02 待審','T-019–T-022／T-093 已 R-02 指定開發範圍通過（見 [報告](docs/evidence/R-02/README.md)）')
$prefix=$prefix.Replace('先前人工結果保留，程式審查仍待審。','先前人工結果保留；R-02 最新分項結論見 [報告](docs/evidence/R-02/README.md)，R-03／R-F 仍待審。')
$task=$prefix+$section+$task.Substring($end)
$task += @'

## R-02 獨立程式審查完成（2026-09-29）

[完整報告](docs/evidence/R-02/README.md)：**T-019／T-020／T-021／T-022／T-093 指定開發交付與測例審查通過**，無新增 S0–S2；REV-R02-001 為兩包 TABLES 創造分頁順序的 S3 錯誤，報告提供外部勘誤，固定包不覆寫。T-092 原草稿／技術限制已審，仍依使用者確認結案，不記成 Agent 新版包完成；T-023／T-024 使用者人工通過保留，不綁定受審 JAR、不補結果或證據。

本次重跑固定資源 2,519 項、固定資料 393 項、現行設定 159 項均通過；另新增 389 項來源／雜湊／註冊／包／測例核對通過。初次資料檢查將現行 R-03 額外 pickaxe tag 套入歷史 29 檔斷言而失敗，原紀錄保留；改用固定 T-022 資料重驗，並逐檔核對現行相同，未改產品或放寬斷言。原四項 Gradle build 證據重查，未重跑 Gradle／OLD／遊戲。

I-021-01／I-092-02 的未實作 state／模型／設定觀測仍由後續功能與最終整合核對，不重開已確認任務，也不推定全部技術缺項修復。現行 R-03 類別、坡面、Mixin 與功能行為不由本次簽通過；R-03／R-F 仍待審。審查固定 JAR 以 T-022 `3D4BFC8926509DCE28C6DE11E8198D3639EB288E1EB29FAD89D3AEC9C1C6BBD3` 為兩包基線，現行來源以 report manifest 固定。

共 126 項、九階段：六歷史、一免執行、二十三開發（十二 R-01 通過、五 R-02 指定範圍通過、六 R-03 待審）、十人工通過、六製包接手結案、一製包依確認結案、79 待執行；無任務重設受阻。編號／正式前置／D1–D8／既有人工與歷史證據不變，本輪未開始其他功能開發。
'@
[IO.File]::WriteAllText($taskPath,$task,$utf8)
$reviewPath=Join-Path $root 'REVIEW.md'
$review=[IO.File]::ReadAllText($reviewPath)
$firstEnd=$review.IndexOf("`n")+1
$review=$review.Insert($firstEnd,"`n> 最新獨立審查（2026-09-29）：[R-02 報告](docs/evidence/R-02/README.md)，T-019–T-022／T-093 指定開發範圍通過；一項 S3 分頁順序勘誤。T-092 原草稿已審並維持使用者確認結案，T-023／T-024 人工通過保留；R-03／R-F 與後續整合仍待審。見 §46。`n")
$review += @'

## 46. R-02 指定開發範圍獨立審查通過（2026-09-29）

[獨立報告](docs/evidence/R-02/README.md)簽核 **T-019／T-020／T-021／T-022／T-093** 的原交付、固定 JAR／包、設定生命週期、ID／資源／資料差異及測例覆蓋。無新增 S0–S2；**REV-R02-001（S3）**：T-092／T-093 TABLES 把 wrench／locomotive_cart 寫在分頁末端，實際程式及 T-019 原契約為最先；报告提供外部勘誤，責任交未來新版包開發者採正確來源順序，不覆寫固定包，不改產品。

審查者未實作受審變更。原四個 NEW build／JAR 與指定版來源已核對；本次普通 JVM 重跑資源 2,519、資料 393、設定 159 項通過，加上 389 項雜湊／來源／註冊／ZIP／測例檢查通過。工具第一次把現行額外 R-03 tag 套用到歷史 29 檔斷言而失敗，原命令／結果保留，固定版本重驗與現行逐檔同一性另存；不是產品 build 失敗。沒有重跑 Gradle、OLD build、Minecraft／GameTest 或代簽人工。

兩固定包共用 T-022 JAR SHA-256 `3D4BFC8926509DCE28C6DE11E8198D3639EB288E1EB29FAD89D3AEC9C1C6BBD3`；所有受審輸入與當前 HEAD `139985ffbc6827ccf585a98ff06773b30d8947bc` 另存 manifest。T-092 草稿與限制已審，依 §45 維持使用者確認結案，不簽正式新版包；T-023／T-024 人工通過保留，不自行綁定任何產物。

I-021-01／I-092-02 不因分項通過而被記成全部修復；後續 state／模型／COMMON 消費者及最終候選整合保留。現行功能類別、斜坡、Mixin 行為屬 R-03／R-F，不由本次簽核；不重開已確認的 T-092／T-023／T-024。§8–45 與所有原包／開發／人工證據保留歷史。126 任務／九階段／正式前置／D1–D8 不變；五項 R-02 待審改為指定範圍通過，其他任務狀態不變。
'@
[IO.File]::WriteAllText($reviewPath,$review,$utf8)
$migrationPath=Join-Path $root 'MIGRATION.md'
$migration=[IO.File]::ReadAllText($migrationPath)
$migration=$migration.Replace('原草稿與技術缺項保留，R-02 待審。','原草稿與技術缺項保留；[R-02 指定開發範圍已審通過](docs/evidence/R-02/README.md)，不簽新版包或後續整合。')
$firstEnd=$migration.IndexOf("`n")+1
$migration=$migration.Insert($firstEnd,"`n> 最新程式審查（2026-09-29）：T-019–T-022／T-093 [R-02 分項通過](docs/evidence/R-02/README.md)，無新增阻擋問題；REV-R02-001 為兩包分頁順序的 S3 勘誤。資源／資料／設定與包核對通過；I-021-01／I-092-02 的後續技術限制及 R-03／R-F 待審保留，未啟動遊戲或更改人工結案。`n")
[IO.File]::WriteAllText($migrationPath,$migration,$utf8)
