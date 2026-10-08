# Simple Rail 遷移指南 v1.0

> **2026-10-08 D3 政策已批准並實作：** 使用者確認「我同意採用這份提案」，包含 R1 一次性票證清理。整列位置／目標加一圈緩衝、差集回收、刪車／停用釋放與持久索引已交付；[R2 證據](docs/evidence/locomotive-chunks-R2/README.md)／[固定包](docs/test-packages/locomotive-chunks-R2/README.md)。NEW build 與 6,451 項非遊戲斷言通過；獨立程式審查與人工仍待執行。下方舊 D3、R1 與政策待決敘述為歷史，現行依本段及 D3 決策表。

> **2026-10-08 票證政策待決：** 已核對持久票證累積、首次載入與整列覆蓋三項限制，詳見 [車頭票證政策提案](docs/evidence/locomotive-chunks-R1/POLICY-PROPOSAL.md) 。本提案尚未批准，不改 D3；不將 R1 開發測試通過寫成票證生命週期已解決。

> **2026-10-08 車頭區塊載入修正：** 使用者回報無玩家時停止載入；確認產品尚未接上 T-016 的票證候選，已依本次授權補齊 controller、生成／讀回初始化與跨區塊 ticking 票證，維持 D3 的中心呼叫與不新增釋放政策。[修正與證據](docs/evidence/locomotive-chunks-R1/README.md)／[局部重測包](docs/test-packages/locomotive-chunks-R1/README.md)。NEW build 與隔離事件測試通過；R-06／R-F、人工重測及 T-075 完整調查仍待辦。未宣稱整個票證階段結案。

> **需求更新（2026-10-02）：** 使用者要求 `y_cross_rail`、`y_cross_right_rail` 合併為 `t_cross_rail`，斷電右轉／通電左轉並切換相應貼圖。此決策取代 D2 對這兩個 registry ID 的保留要求，其餘 ID 不變；NEW 清單為 10 方塊、12 物品、8 軌道、12 配方。§3 的 OLD 原始碼盤點與既有證據保持歷史；NEW 依 [T 型規格與驗證](docs/evidence/T-cross-redesign/fix-R1/README.md)及 [T-cross-v2 測試包](docs/test-packages/T-cross-v2/README.md)。2026-10-03 使用者圖示明確：T 型外框與三個開口固定，紅石只切換內部彎軌；斷電主幹↔右分支、通電主幹↔左分支，另一側來車橫向直行。整體朝向由放置／扳手設定；R-06 與人工驗收待辦。

> 最新獨立審查（2026-10-01）：[R-04 報告](docs/evidence/R-04/README.md)，T-037～T-039／T-041／T-043～T-046 八項指定開發範圍及 T-040 R1 的 R-F 通過，無新增 S0–S3 缺陷。8 組非遊戲測試共 255,454 判定、28 份產品 Java 固定 API 編譯及 177 項靜態核對通過；現行 JAR 的 34 個 class 與重新編譯來源反組譯一致。既有五項人工、T-100／T-101／T-102 製包確認結案保留；不補造受測版本或 Agent 製包驗證。M-01、U-07／其他 U-09、T-060／T-082～T-084 及後續候選範圍保留。以下先前進度均為歷史快照，以本段／TASK 現況為準。

> 最新使用者確認（2026-10-01）：使用者[親自完成 T-102，並確認 T-047 人工驗收通過](docs/evidence/T-102-T-047-user-confirmation/README.md)。T-102 依完成確認結案，不記為 Agent 已核對固定測試包／build；T-047 依人工通過結案，不補填未提供的受測 JAR、逐案數值或 log。R-04 獨立程式審查、T-082 專用方塊實體存讀與 T-060 車頭／編組驗收仍各自待辦。下段「T-102／T-047 待執行」是使用者確認前快照。

> 最新判定（2026-10-01）：使用者[確認 T-120 診斷未發現異常](docs/evidence/T-120/USER_CONFIRMATION.md)；結合 T-045 的來源／固定 JAR 與非遊戲測試，[T-046 條件式修正](docs/evidence/T-046/README.md)判為**開發完成／無需新增補丁**。這不是正式 JAR 遊戲驗收；R-04 獨立程式審查、T-102 測試包及 T-047 使用者正式回歸仍待執行。T-120 無逐案數值，原結果欄保持空白；下段「異常尚未說明」為補充前快照。

> 最新使用者確認（2026-10-01）：[T-120 已由使用者親自驗證完成並結案](docs/evidence/T-120/USER_CONFIRMATION.md)，不要求人工測試附件；本次未提供逐案現象或是否發現異常，診斷包結果欄保持空白。T-046 已完成的靜態判定不變，條件式修正仍待釐清有無具體異常；T-120 隔離診斷不能替代 T-045 正式產品 JAR 的 T-047 回歸。R-04 獨立程式審查仍待執行；下段 T-120「尚無使用者結果」為確認前快照。

> 最新判定（2026-10-01）：[T-046 發射器觸發／車種辨識條件式修正](docs/evidence/T-046/README.md)已核對 OLD／NEW 來源及 T-045 固定 JAR。已確認的裸字串辨識移植風險由現行物品身分映射避免，父類九格消耗路徑亦未進入；本項無新增產品補丁或 NEW build。T-120 的重複回呼、占位／落地與特殊車種執行期觀察尚無使用者結果，故 T-046 僅靜態分項完成、整項受阻；R-04 待審，T-047 正式回歸未開始。以下 T-045 與更早段落保留當時快照。

> 最新開發（2026-09-30）：[T-045 原版礦車生成與觸發接線](docs/evidence/T-045/README.md)已完成開發；NEW 最終 build 退出 0、正式掃描器純 JVM 15 項通過，固定 JAR 及九項範圍稽核通過。沿 T-043 原始碼規格，每個仍有電的鄰居更新立即掃描、占位先於空槽判斷，27 格樣板只讀不消耗；車種按物品身分對應，未加入節流或外部模組。R-04 程式審查、T-120／T-047 使用者遊戲驗收、T-046 條件式修正與自訂車頭／編組均未執行。OLD 遊戲結果依原始碼推定／待確認；以下較早進度保留當時快照。

> 最新開發（2026-09-30）：[T-044 專用發射器方塊實體與 27 格箱子式 GUI](docs/evidence/T-044/README.md)已完成開發；保留 `simplerail:train_dispenser` 方塊／物品 ID，新增同路徑專用 BE ID。NEW build 退出 0，固定 JAR 與七項範圍稽核通過；普通 Gradle test NO-SOURCE。R-04 審查及 T-047／T-082 使用者遊戲 GUI／存讀驗收未執行，T-045 礦車生成未開始。此項沒有舊箱子資料轉換或外部模組整合；以下 T-043 與更早進度均保留當時快照。

> 最新開發（2026-09-30）：[T-043 發射器觸發／車種來源調查](docs/evidence/T-043/README.md)及 [T-120 固定診斷包](docs/test-packages/T-043-v1/README.md)已交付；NEW build 退出 0、純 JVM 模型 18 項斷言與九項證據稽核通過，正式產品未修改。OLD 行為仍為依原始碼推定／待確認；R-04 獨立審查及 T-120 使用者遊戲觀察未執行。診斷包以上方原版單箱作 27 格樣板、原版爐車作車頭替身，不代表 D4 的正式專用方塊實體／GUI 或編組已實作。以下較早的進度文字保留當時快照，以本段為 T-043 現況。

> 最新使用者確認（2026-09-30）：[T-040 計時停車與 R1 扳手修正驗收通過、T-042 訊號計時器驗收通過，T-101 由使用者親自完成](docs/evidence/T-040-T-042-T-101-user-confirmation/README.md)。T-040／T-042 依人工確認結案，T-101 依使用者完成確認結案；未提供的逐例數值、受測 JAR、製包／build 紀錄不補造。R-04／R-F 獨立程式審查仍待執行，T-083 等其他驗收不由此推定通過。下列 T-040 R1「待重測」及 T-041「T-101／T-042 未執行」是當時快照，以本段為現況。

> 最新 T-040 使用者回報與修正（2026-09-30）：使用者在計時軌驗收發現「有礦車經過之後，扳手無法再修改 `level`」。[R1 局部修正與原因](docs/evidence/T-040/fix-R1/README.md)已完成開發與 NEW build；僅修 `timer_holding_rail` 水平 `direction` 覆蓋新 `level`，其他 U-09 複合行為不自行擴改。[固定重測包](docs/test-packages/T-040-R1/README.md)已備，R-04／R-F 獨立程式複查與使用者重測仍待執行；T-040 整項未通過，D5 的正式停車／卸載／離線驗收不由局部修正推定完成。

> 最新開發（2026-09-30）：[T-041 `signal_timer` 與專用方塊實體](docs/evidence/T-041/README.md)開發完成；保留同名方塊／物品／BE ID，NEW 離線強制重編退出 0，隔離 tick 算術 250,009 項判定通過。R-04 獨立程式審查、T-101 開發製包與 T-042 使用者遊戲驗收未執行。重啟／卸載後的實際相位、設定 0 秒與極大值的產品期望仍待技術驗證；下列 T-039 當時「T-041 下一可開發」以本段更新，歷史結果不倒填。

> 最新確認與開發（2026-09-30）：使用者確認 [T-119 計時保存／讀回人工驗證完成、T-100 完成](docs/evidence/T-039/USER_CONFIRMATION.md)；[T-039 正式保存疑點逐項核對](docs/evidence/T-039/README.md)開發完成，五項已確認風險在 T-038 實作中有可核對的避免路徑，無新增補丁。R-04、T-040／T-083 正式遊戲驗收未開始；T-100 以使用者確認結案，不倒填 Agent 製包、雜湊或審查通過。下列 T-038／T-037 當時的 T-039／T-119／T-100「未開始」文字均以本段更新。

> 最新開發（2026-09-30）：[T-038 正式計時軌道與方塊實體](docs/evidence/T-038/README.md)開發完成；NEW build 0、真實 NEW NBT／時間 1,055 項與隔離 hook 1,526 項非遊戲判定通過。R-04 待審、T-039／T-100 未開始，T-040／T-083 人工未執行；D5 的正式遊戲秒數／卸載／離線行為仍待驗收。下列 T-037「正式產品未改／T-038 未開始」為當時紀錄，現況以本段為準。

> 最新開發（2026-09-30）：[T-037 計時保存調查與診斷包](docs/evidence/T-037/README.md)開發完成；NEW build 0、1,049 項非遊戲判定通過。正式產品未改，R-04 待審、T-119 人工待執行，T-038 未開始。OLD 未測仍為依原始碼推定／待確認，不重跑 OLD build。

> 最新程式審查（2026-09-30）：[R-03](docs/evidence/R-03/README.md)六項開發指定範圍通過，並完成 T-026 R1／R2、T-030 R1 的 R-F；無新增缺陷。U-07／U-09 的意圖及後續 owner／模型整合仍待處理，人工／製包接手結案保留，未改產品或啟動遊戲。

> 前次程式審查（2026-09-29）：T-019–T-022／T-093 [R-02 分項通過](docs/evidence/R-02/README.md)，無新增阻擋問題；REV-R02-001 為兩包分頁順序的 S3 勘誤。資源／資料／設定與包核對通過；I-021-01／I-092-02 的後續技術限制保留，R-03 最新結論見上段。

> 最新確認：[T-092／T-023／T-024 已結案](docs/evidence/T023-T024-T092-user-confirmation/README.md)；T-023／T-024 使用者人工通過，T-092 依使用者確認完成結案。原草稿與技術缺項保留；[R-02 指定開發範圍已審通過](docs/evidence/R-02/README.md)，不簽新版包或後續整合。

> 最新修正（2026-09-29）：[T-030 未供電自然滑行 R1](docs/evidence/T-030/fix-R1/README.md)開發完成，T-030 已依使用者確認人工通過結案，R-03／本次列明 R-F 修正範圍通過；原 T-029 原碼相容交付保留歷史。

> 盤點日期：2026-09-26；分工修訂：2026-09-27；最新交付／分工調整：2026-09-29。狀態：**D1–D8 保留；T-026／T-028／T-030／T-032／T-034／T-036 使用者人工通過已結案；T-025／T-027／T-029／T-031／T-033／T-035 開發完成，R-03／本次列明 R-F 修正範圍通過；T-035 扳手原碼相容交付、U-09 意圖待確認，T-036 已依使用者確認人工通過結案；T-099 製包已結案（使用者接手）；T-033 一般移除軌交付，T-034 已依使用者確認人工通過結案；T-098 製包已結案（使用者接手）；T-031 下車軌交付，T-032 已依使用者確認人工通過結案；T-097 製包已結案（使用者接手）；T-029 原碼相容、U-07 意圖待確認，T-030 已依使用者確認人工通過結案；T-096 製包已結案（使用者接手）；T-094～T-099 製包已結案（使用者接手，取代下列製包未執行待辦）；歷史保留**。
> `TASK.md` 已經使用者審閱。[T-026 結案確認](docs/evidence/T-026/REPORT-003.md)已記錄；原失敗與 [R2 局部移動保護／包](docs/evidence/T-026/fix-R2/README.md)保留歷史。人工結果由使用者確認，非 Agent 重測；未提供的 JAR／逐例數據不補造。T-094／程式審查／整合缺口與正式依賴不倒填完成。
> **OLD build 由使用者先前驗證，本次流程不重跑**；這是使用者陳述，不是 Agent 執行 T-002 或 NEW 建置／API／遊戲驗收的證據。
> **實際遷移起點是 Minecraft 1.16.5 + Forge 36.1.0，不是 NeoForge。**
> T-003 來源參考、T-004 案例設計、T-005 框架 build 已完成；T-006 client 新世界與 T-007 dedicated server 啟停已有舊分工下的 Agent 歷史紀錄，退出碼均為 0。原始證據保留，不倒填為使用者已測、不代表後續功能人工驗收；T-018／T-089 已依使用者完成確認結案，無需提交人工證據。T-008 指定 API 來源與最小編譯、T-009 格式／ID／非遊戲檢查、T-010 軌道／互動／狀態最小編譯、T-011 方塊實體／計時／保存候選、T-012 專用容器／箱子式 GUI、T-013 車頭／編組保存、T-014 實體生成／同步、T-015 模型／材質／渲染及 T-016 區塊事件／票證候選已交付；T-017 正式空功能入口與離線 build 已交付。其餘 API 與未實作功能保持未驗證。

## 1. 目標與範圍

將 Simple Rail 的既有軌道、列車、工具與機器功能，遷移至 Minecraft 1.21.1 + NeoForge；保留可追溯的功能、識別名稱及資料格式清單，作為分階段實作與驗收依據。

僅高速軌道支援斜坡、其他軌道保持原規格的需求保留。使用者已確認斜坡通過，2026-09-29 再確認坡底反轉未再發生，T-026 整項人工驗收通過並結案。先前約 10%／高速接自身的失敗及 R1／R2 修正來源保留歷史，不將當時結果改成通過；本次人工結案不代表普遍物理根因或逐例量測已有證明。R-03／本次列明 R-F 修正範圍已通過（見 [報告](docs/evidence/R-03/README.md)），原交付／固定包與確認即可人工結案規則保留。

### 路徑與證據範圍

以下縮寫均指向實際目錄；例如 `OLD/build.gradle` 即 `D:/workspace/java/simple-rail/build.gradle`。

| 縮寫 | 完整路徑 |
| --- | --- |
| `OLD` | `D:/workspace/java/simple-rail` |
| `NEW` | `D:/workspace/java/simple-rail-1.21.1` |
| `J` | `D:/workspace/java/simple-rail/src/main/java/ericchiu/simplerail` |
| `R` | `D:/workspace/java/simple-rail/src/main/resources` |

盤點時 OLD HEAD 為 `6698b1c5f494095a15b055c10045293e91540012`，NEW HEAD 為 `8bd977dbb9f9000411ae5f4d10750228e5f33560`；開始盤點時兩者 `git status --short` 均無變更。主要依據為建置宣告、42 個 Java 原始檔與 `src/main/resources`。README 僅作補充，不能取代實作證據；本輪未檢查實際使用中的世界 NBT 或玩家設定檔。

本文的「已確認」限於專案文字及程式結構；「風險」為根據該實作提出的檢查項目；無法據此確定的執行結果或產品選擇一律標為「待確認」。

第 5 節另記錄使用者已決定的需求；需求已定案不代表相關 API 或執行結果已驗證。

## 2. 原專案技術基線

| 項目 | 已確認內容 | 判斷依據 |
| --- | --- | --- |
| Minecraft | 建置與 official mappings 都指定 `1.16.5`；描述檔接受 `[1.16.5,1.17)` | `OLD/build.gradle` 的 `minecraft`／`dependencies`；`R/META-INF/mods.toml` |
| 載入器 | **Forge**，建置依賴 `net.minecraftforge:forge:1.16.5-36.1.0`；`javafml`、loader 與 Forge 範圍均為 `[36,)` | `OLD/build.gradle`、`R/META-INF/mods.toml`；`J/SimpleRail.java` 使用 `net.minecraftforge.*` |
| Java | 宣告 Java toolchain **8**；實際開發機／發行 JAR 所用 JDK 待確認 | `OLD/build.gradle` 的 `JavaLanguageVersion.of(8)` |
| 模組 | ID `simplerail`；名稱 `Simple Rail`；版本 `1.16.5-0.3.25` | `J/SimpleRail.java`、`R/META-INF/mods.toml`、`OLD/build.gradle` |
| 建置工具 | Gradle Wrapper **6.8.1-all**；ForgeGradle **4.1.+**（動態版本，當時實際解析版本待確認） | `OLD/gradle/wrapper/gradle-wrapper.properties`、`OLD/build.gradle` |
| 建置流程 | 使用 Gradle Wrapper；`jar.finalizedBy('reobfJar')`；套用 `eclipse`、`maven-publish`；本機 Maven 輸出位置 `mcmodsrepo` | `OLD/build.gradle`、`OLD/gradlew`、`OLD/gradlew.bat` |
| 開發執行 | 宣告 client、server、data；data 輸出 `src/generated/resources` 並加入 resources source set。未在盤點的來源中找到自訂資料產生器 | `OLD/build.gradle`、`OLD/src/main/java` |
| Artifact | group `ericchiu.simplerail`；archivesBaseName `simplerail` | `OLD/build.gradle` |
| 外部模組 | 描述檔只要求 Minecraft 與 Forge；未找到其他必要／可選模組宣告或直接整合程式 | `R/META-INF/mods.toml`、`OLD/build.gradle`、`OLD/src/main/java` imports |
| 程式庫 | 原始碼使用 Apache Commons Lang `Pair`、Log4j、Mojang Blaze3D；Gradle 未額外直接宣告這些函式庫的版本。實際傳遞依賴樹待確認 | `J/config/CommonConfig.java`、`J/SimpleRail.java`、`J/render/`、`OLD/build.gradle` |

**OLD build 由使用者先前驗證，本次流程不重跑**。不要求重新下載 Java 8／Gradle 6.8.1、修復 OLD 建置環境或重跑 OLD build。T-002 保留編號，狀態為「使用者決定免執行」，不代表 Agent 已完成或驗證該任務；本次未取得使用者該次 build log、退出碼、JAR 雜湊或測試結果，不補造證據。ForgeGradle 實際解析版本等歷史未知項仍待確認，但不作 NEW 建置或遷移的前置。

### 目標專案設定與建置基線

| 項目 | 目前宣告 | 依據 |
| --- | --- | --- |
| Minecraft／NeoForge | `1.21.1`／`21.1.251`；Minecraft 範圍 `[1.21.1]` | `NEW/gradle.properties` |
| Java／Gradle | Java toolchain `21`；Wrapper `9.2.1-bin` | `NEW/build.gradle`、`NEW/gradle/wrapper/gradle-wrapper.properties` |
| 建置外掛／mappings | ModDevGradle `2.0.147`；Parchment `1.21.1`／`2024.11.17`；Foojay resolver `1.0.0` | `NEW/build.gradle`、`NEW/gradle.properties`、`NEW/settings.gradle` |
| 識別資訊 | mod ID `simplerail`；mod version `1.0.0`；group `com.ericchiu.simplerail` | `NEW/gradle.properties` |
| 載入器描述檔 | `javafml`；loader 範圍 `[1,)`；NeoForge 依賴由 `${neo_version}` 展開 | `NEW/src/main/templates/META-INF/neoforge.mods.toml` |
| 程式內容 | 仍有 `example_block`、`example_item`、`example_tab` 與範例設定；client 類別已有設定畫面掛接程式 | `NEW/src/main/java/com/ericchiu/simplerail/{SimpleRail,SimpleRailClient,Config}.java` |
| CI | 宣告 JDK 21 與 `./gradlew build`，本輪未查核執行結果 | `NEW/.github/workflows/build.yml` |

以上表格列宣告值；T-005 已另以實際 build 核對 Java 21、Gradle 9.2.1、ModDevGradle 2.0.147、NeoForge 21.1.251、Parchment 1.21.1／2024.11.17，退出碼 0 並取得可識別框架 JAR。詳見 [T-005 證據](docs/evidence/T-005/README.md)。另有 [T-006 client](docs/evidence/T-006/README.md) 與 [T-007 server](docs/evidence/T-007/README.md) 的 Agent 歷史啟停證據。**範圍僅為既有框架 build／啟停**；T-089 使用者連線、功能與指定 API 遷移用法仍待確認，不是遷移完成。

依 D8，首版基線採用目前的 mod version `1.0.0`、授權宣告 `All Rights Reserved` 與 NeoForge `21.1.251`，Minecraft 目標為 `1.21.1`。

## 3. 功能與來源清單

### 註冊、物品與共用機制

| 功能 | 原始檔 | 靜態盤點結果 |
| --- | --- | --- |
| 模組入口與生命週期 | `J/SimpleRail.java` | `@Mod`、COMMON 設定、事件匯流排、client render setup、進入區塊事件；IMC helloworld 只送給自身，不能視為外部整合 |
| 註冊 | `J/setup/Registration.java`、`J/registry/{Blocks,Items,Entities,TileEntities}.java` | 方塊／物品／實體用 DeferredRegister；2 個 TileEntityType 另由 RegistryEvent 註冊 |
| 狀態與標籤 | `J/setup/{SimpleRailProperties,SimpleRailTags}.java`、`J/constants/{Properties,Tags,I18n,TileEntityCons}.java` | 集中宣告名稱、方塊屬性及 rails／machines／wrench 標籤 |
| 扳手 | `J/item/Wrench.java` | 點擊相鄰礦車所在位置來連結編組；修改軌道 reverse、level、direction 與機器 facing、level；最大堆疊 1 |
| 車頭物品 | `J/item/LocomotiveCart.java` | 在自訂或原版 rails tag 上放置車頭，傳遞自訂名稱；最大堆疊 64 |
| 方塊物品／創造模式分頁 | `J/registry/Items.java`、`J/itemgroup/Rail.java` | 11 個 BlockItem，搭配 2 個獨立物品；分頁使用高速軌道圖示 |
| 設定 | `J/config/CommonConfig.java`、`J/constants/Config.java` | 區塊載入、速度、動力需求、乘客移動距離與兩組計時等級 |

### 方塊（9 種軌道、2 種機器）

下表每個註冊路徑都帶有 `simplerail:` namespace，且都有同名 BlockItem。

| 註冊路徑 | 功能 | 原始檔 |
| --- | --- | --- |
| `high_speed_rail` | 高速動力軌道 | `J/block/HighSpeedRail.java` |
| `holding_rail` | 未供電時停車並記錄行進方向；供電時推動礦車 | `J/block/HoldingRail.java` |
| `oneway_rail` | 依 reverse 與設定控制礦車行進；動力／方向切換語意需作行為基線 | `J/block/OnewayRail.java` |
| `eject_rail` | 使乘客下車並移動到軌道側邊，可反轉方向與設定距離 | `J/block/EjectRail.java` |
| `destory_rail` | 移除礦車；遇車頭則呼叫刪除整列編組 | `J/block/DestoryRail.java` |
| `timer_holding_rail` | 等級 1–9 計時停車，等級 0 不停車；透過方塊實體記錄目前車輛與放行時間 | `J/block/TimerHoldingRail.java` |
| `cross_rail` | 依進入方向穿越十字路口，暫存速度與目標位置 | `J/block/CrossRail.java` |
| `y_cross_rail` | 依方向、來車方向與紅石狀態選擇分岔路徑 | `J/block/YCrossRail.java` |
| `y_cross_right_rail` | 另一組分岔方向配置 | `J/block/YCrossRightRail.java` |
| `train_dispenser` | 紅石觸發後依 27 格內容排列礦車；第 0 格為車頭時連結後續一般礦車 | `J/block/TrainDispenserBlock.java` |
| `signal_timer` | 等級 1–9 週期性輸出強度 15 的紅石訊號，等級 0 無輸出 | `J/block/SignalTimerBlock.java` |

共用基底為 `J/block/base/BaseRail.java` 與 `BasePoweredRail.java`：兩者都讀取 `highSpeedRailMaxSpeed`，禁止形成斜坡，並覆寫實體破壞判斷。速度設定並非只影響 `high_speed_rail`；遷移驗收需涵蓋其他軌道。

**NEW 需求例外（2026-09-28 使用者已確認）：僅 `high_speed_rail` 支援與原版動力軌相同的四方向升坡；其他軌道維持原禁坡規格。** 上段仍描述 OLD 來源，不改寫為舊版已支援。T-025／T-026／T-094 承接高速平軌及升坡、供電／未供電模型、原版斜坡接口及坡底／坡頂的回歸；不修改共用基底的禁坡或擴到其他特殊軌道。

### 方塊實體、GUI、實體、網路與渲染

| 類別 | 功能與原始檔 |
| --- | --- |
| 自訂方塊實體 | `J/tileentity/TimerHoldingRailTileEntity.java` 保存計時資料；`J/tileentity/SignalTimerTileEntity.java` 透過 tick 排程紅石方塊 tick；註冊見 `J/registry/TileEntities.java` |
| 原版方塊實體／GUI | `J/block/TrainDispenserBlock.java` 的 `newBlockEntity()` 回傳原版 `ChestTileEntity`；`use()` 用 `player.openMenu(...)` 開箱子介面。**有容器 GUI 功能，但無自訂 Screen／Menu 註冊**；不可因沒有 GUI 資料夾而漏掉 |
| 車頭與編組 | `J/entity/LocomotiveCartEntity.java` 繼承 `FurnaceMinecartEntity`，自行控制朝向、碰撞、掉落與跟車位置；`J/link/LinkageManager.java` 維護車頭 UUID → 有序車廂 UUID 清單 |
| 區塊載入 | `J/event/ChunkEventManager.java`，入口 `J/SimpleRail.java#entityEnteredChunk`；使用 `ForgeChunkManager.forceChunk` |
| 生成與同步 | `J/entity/LocomotiveCartEntity.java` 的 `getAddEntityPacket()`／`defineSynchedData()`；`J/registry/Entities.java` 自訂 client factory；`J/setup/SimpleRailDataSerializers.java` 註冊 FacingDirection enum serializer。同步欄位是 `FACING`、`LINKABLE`；未找到自訂 SimpleChannel 或訊息處理器 |
| 客戶端渲染 | `J/setup/Render.java` 設定 9 種軌道 cutout 及車頭 renderer；`J/render/LocomotiveCartRender.java`、`J/render/model/LocomotiveCartModel.java`、`J/constants/Texture.java` 負責模型、貼圖與 8 方向朝向 |

本輪未在 Java 與 data 資源中找到世界生成實作，因此不設世界生成遷移階段。區塊強制載入屬於執行期行為，不是世界生成。

### 配方與資料資源

| 路徑 | 內容／數量 | 後續驗收重點 |
| --- | --- | --- |
| `R/data/simplerail/recipes/` | 13 個 JSON，均為 `minecraft:crafting_shaped`；涵蓋全部 13 種物品；`destory_rail` 產出 3，其餘產出 1 | 逐一核對材料、排列、產量與結果 ID；沒有自訂 RecipeType／Serializer 需搬移 |
| `R/data/simplerail/loot_tables/blocks/` | 12 個 JSON：11 方塊與額外的 `locomotive_cart.json` | 後者宣告 `minecraft:entity` 卻置於 blocks 路徑；車頭另在 Java 主動生成掉落。實際表格是否被使用待確認，勿據檔名新增方塊或重複掉落 |
| `R/data/simplerail/tags/blocks/{rails,machines}.json` | 分別列出 9 種軌道、2 種機器 | 扳手與車頭放置判斷依賴 |
| `R/data/simplerail/tags/items/wrench.json` | `simplerail:wrench` | Java 的 `SimpleRailTags.WRENCH` 卻宣告為 Block tag，且未找到使用處；依 D2 保留既有 tag ID，型別不一致的整理列入後續任務 |
| `R/data/minecraft/tags/blocks/rails.json` | 將全部 9 種自訂軌道加入原版 rails，`replace: false` | 核對原版礦車辨識與標籤合併 |
| `R/assets/simplerail/blockstates/` | 12 個 JSON | 11 種方塊外還有 `wrench.json`；扳手並非註冊方塊，額外資源用途待確認 |
| `R/assets/simplerail/models/block/`、`models/item/` | 40 個方塊模型、14 個物品模型 | 含反向、動力及計時等級變體；模型數量不等於註冊數量 |
| `R/assets/simplerail/textures/` | 44 個貼圖檔，含 blocks／items／entity | 核對引用、透明材質、車頭模型 UV |
| `R/assets/simplerail/lang/{en_us,zh_tw}.json` | 2 種語言 | 名稱與創造模式分頁翻譯 |
| `R/pack.mcmeta`、`R/logo.png` | 舊 pack format 為 `6` 與模組標誌 | 目標版格式及 metadata 引用待確認 |

data JSON 內找到的 namespace 僅為 `minecraft`、`simplerail`，沒有額外模組材料引用。T-009 已以指定來源查證單數資料目錄、配方 result.id、loot／tag／pack 格式，並交付 [格式與 ID 對照](docs/evidence/T-009/README.md)；既有 ID 保留。舊 blocks／items 貼圖需補 atlas 來源，額外車頭 loot context 與 wrench 型別問題明列。格式查證／獨立 JSON 檢查不是實際遊戲載入或驗收，移植與 runtime 仍待執行。

## 4. 舊資料與相容性風險

本節保留舊版格式與實作證據，供新版本功能設計及疑點修正參考。依 D1，舊世界匯入、NBT 格式轉換、舊箱子方塊實體轉換與 Forge 票證轉換均不在首版範圍；不要求取得舊世界樣本作為交付門檻。

### 4.1 註冊名稱與方塊狀態

依 D2 及 2026-10-02 使用者的 T 型合併例外，目標 ID 如下（原始 OLD 名冊仍見 §3）：

- 方塊 registry：上表 11 個 ID 移除 `y_cross_rail`、`y_cross_right_rail`，加入 `t_cross_rail`，合計 10 個 `simplerail:*` ID。
- 物品 registry：同名的 10 個 BlockItem，加上 `simplerail:wrench`、`simplerail:locomotive_cart`，合計 12 個。
- 實體 registry：`simplerail:locomotive_cart`。
- 自訂方塊實體 registry：`simplerail:timer_holding_rail`、`simplerail:signal_timer`。
- 標籤：`simplerail:rails`、`simplerail:machines`、`simplerail:wrench`，以及對 `minecraft:rails` 的擴充。

依據：`J/constants/I18n.java`、`J/constants/TileEntityCons.java`、`J/registry/`、`J/setup/SimpleRailTags.java` 與前述 tag JSON。`oneway_reverse_rail` 只有模型等資源，不是額外註冊方塊／物品。

**依 D2 保留 `destory_rail`，不改成 `destroy_rail`。** 配方、掉落表、tag 與資源 ID／引用也維持既有名稱。Java package 從 `ericchiu.simplerail` 改為 `com.ericchiu.simplerail`，不改變 registry namespace。D2 的回覆明確決定的是 ID；舊設定檔自動匯入與設定鍵整理方式並未另行指定，留待相關任務定義，不推定需要轉換器。

依 D4，發射器將新增專用方塊實體；T-012 已定義新增 BLOCK_ENTITY_TYPE ID 候選 `simplerail:train_dispenser`（與方塊／物品分屬不同 registry），BE 正式註冊和載入仍待 T-044。T-019 只完成同名方塊／物品骨架，不註冊 BE，不影響保留既有方塊／物品 ID 的要求。

| 自訂狀態名 | 定義值域 | 使用方塊 |
| --- | --- | --- |
| `reverse` | boolean | oneway、eject |
| `need_power` | boolean | oneway、eject、destory |
| `use_power` | boolean | oneway |
| `level` | 0–9 | timer_holding、signal_timer |
| `direction` | `Direction` enum，定義本身未限制為水平 | holding、timer_holding、兩種 Y 分岔 |

另需核對繼承的 `shape`、`powered`、發射器的 `facing`／`triggered` 等狀態與預設值。依據為 `J/setup/SimpleRailProperties.java`、各 `J/block/*.java` 與 `R/assets/simplerail/blockstates/`；完整原版繼承狀態和值域仍需確認，作為新版本行為與資源變體的驗收依據，不實作舊世界狀態轉換。

### 4.2 實際可見的持久化資料

| 所在位置 | 格式與行為 | 遷移風險／待確認 |
| --- | --- | --- |
| 車頭實體 NBT | `Train`：ListNBT，元素為 UUID 字串，順序代表車廂順序；`Facing`：字串 `east`、`west`、`north`、`south`、`north_east`、`north_west`、`south_east`、`south_west`；呼叫父類讀寫 | 新版本須保存車廂次序與朝向，並測讀寫一致性；不必讀取舊格式。父類欄位及目標版保存方式待確認。舊實作沒有自訂資料 schema version |
| 計時停車軌方塊實體 NBT | `save_time`：long 毫秒；`cart_uuid`：透過 `putUUID` 寫入；`go_time`：long 毫秒。載入時計算 `go_time + (目前時間 - save_time)` | D5 已決定維持實際秒數＋讀回補償，卸載／離線期間暫停。舊 `cart_uuid`／`go_time` 可不寫入，但 load 未先檢查鍵是否存在；新版本仍須測空白及不完整保存資料 |
| 訊號計時器 | 未覆寫自訂 NBT 讀寫；等級與供電由 BlockState 表達，週期依賴 tick 排程 | 重啟後訊號相位如何恢復、排程如何保存待確認 |
| 列車發射器 | 直接使用原版 `ChestTileEntity`，27 格內容由原版容器負責 | 舊版沒有 `simplerail:train_dispenser` 自訂方塊實體註冊。D4 已決定改用專用方塊實體、維持 27 格樣板及箱子式 GUI；只驗收新版本容器保存，不轉換舊箱子資料 |
| 區塊票證 | `ForgeChunkManager.forceChunk(world, simplerail, entity, chunkX, chunkZ, true, true)` | D3 初始保留原碼，現依使用者批准的 R2 政策與指定版 API 改為整列滾動集合／回收／索引。不讀取或轉換舊 Forge 票證 |

依據：`J/entity/LocomotiveCartEntity.java#readAdditionalSaveData`／`addAdditionalSaveData`、`J/constants/I18n.java`、`J/tileentity/TimerHoldingRailTileEntity.java#save`／`load`、`J/tileentity/SignalTimerTileEntity.java`、`J/block/TrainDispenserBlock.java`、`J/event/ChunkEventManager.java`。

`J/constants/WorldData.java` 雖宣告 `timerholdingrail`、`savetime`、`cartUuid`、`goTime`，但全文搜尋未找到引用，也未找到自訂 WorldSavedData／SavedData 實作。**不能據此宣稱存在對應 `.dat` 存檔。** 這組名稱與目前 TileEntity 實際使用的底線命名不同；歷史發行版是否用過該格式待確認。

### 4.3 暫存狀態與舊行為疑點

以下是原始碼可見的風險，尚未經遊戲重現。依 D6，舊疑點修正將納入依本指南產生的 `TASK.md`，經使用者審閱後依序處理；本文件不自行啟動修正。D3 已指定的區塊載入邏輯，在經審閱的對應修正任務明訂變更前維持原專案行為。

1. **編組載入時序：** `LinkageManager.trains` 是 static map，沒有世界／維度範圍或獨立存檔；持久化來源是車頭 `Train`。`LocomotiveCartEntity.initTrain()` 只加入當時 `getEntity(UUID)` 找得到的車廂，再覆寫清單；晚載入、跨區塊或暫時找不到的車廂可能失去連結。`prevPos`、每車 `stopPos` 也沒有自訂持久化。
2. **區塊票證生命週期：** `ChunkEventManager` 的 radius 是 2，但 x/z 雙迴圈中傳入的始終是中心 `chunkX, chunkZ`；設定名 `disableLoadingChunk` 為 true 時實際執行載入。全文未找到解除 forceChunk 或票證驗證／清理呼叫。原 D3 曾保留此邏輯；使用者現已批准整列目前集合與 3×3 緩衝、差集釋放、索引恢復及 R1 清理，按 T-078／T-079 的 R2 交付與人工回歸驗收。舊版實際票證結果未實測者標「依原始碼推定／待確認」；以來源呼叫與 NEW API 對照及 NEW 實測推進，不要求 OLD 執行紀錄。
3. **路口暫存：** `CrossRail`、`YCrossRail`、`YCrossRightRail` 以 Block 實例內的 `Map<BlockPos, CartData>` 保存過車資料，鍵沒有維度。未看到持久化及世界卸載清理；須測不同維度同座標、路口中途存檔及多人同時通行。
4. **計時保存：** `TimerHoldingRailTileEntity` 的 setters 未呼叫 `setChanged()`；目前檔案是否可靠寫回不能單憑 save 方法存在來保證。計時計算另有 int 乘法及很大的可設定上限，邊界行為待測。
5. **發射器玩法：** `neighborChanged()` 有電就嘗試生成，沒有看到扣除槽位物品；使用物品作為列車樣板。一般礦車種類以物品 `toString()` 比對幾個原版名稱。D4 已決定保留不消耗物品的模式；觸發頻率與種類辨識疑點留給後續任務，D7 不要求第三方礦車支援。
6. **伺服器權責：** 部分 rail callback 沒有明確 client/server 判斷，車頭朝向也在 tick 更新；哪些舊回呼由哪一端執行及目標同步方式待確認。多人測試不可用單人結果取代。

### 4.4 設定檔與外部整合

`J/SimpleRail.java` 以 COMMON 類型註冊 `CommonConfig.SPEC`；沒有明訂設定檔名稱，實際舊檔名待確認。依 `J/config/CommonConfig.java` 與 `J/constants/Config.java` 可列出：

| 設定路徑 | 預設值 |
| --- | --- |
| `cart.locomotive.disableLoadingChunk` | true；實作語意見上方疑點 |
| `rail.high_speed_rail.maxSpeed` | 0.8，允許 0.4–2.0 |
| `rail.oneway_rail.needPower` | true |
| `rail.oneway_rail.usePowerChangeDirection` | false |
| `rail.eject_rail.transportDistance` | 3，允許 1–100 |
| `rail.eject_rail.needPower` | true |
| `rail.destory_rail.needPower` | false |
| `rail.timer_holding_rail.lv1` 至 `lv9` | 5、10、15、20、25、30、40、50、60 秒 |
| `rail.signal_timer_block.lv1` 至 `lv9` | 同上；注意實際群組在 `rail` 下 |

兩組計時值在類別的 static final 欄位讀取；是否支援設定重新載入、客戶端與伺服器如何一致，待確認。`usePowerChangeDirection` 的註解與程式是否達成同一行為也需以測例確認。

以上為 OLD 來源與未實測限制，保留不倒填。T-020 已實作 NEW 的 25 個同鍵／同預設／同範圍 COMMON 設定，固定檔名 `simplerail-common.toml`，Loading／Reloading 發布不可變快照、Unloading 清空；註冊不提早讀值，COMMON 不自動同步，以 logical server 決定功能。[完整載入／生效契約與預設表](docs/evidence/T-020/config-contract.md)及獨立 JVM 159 項測試已交付，R-02 待審；實際 FML 事件／檔案監看／遊戲功能生效未驗證。reload 不重寫世界、票證、既有等待 deadline 或已排程訊號；秒數值與 signal 的 20 ticks／秒、10 ticks 脈衝分開。極大值換算與 state 投影仍待原有功能任務，不提前修舊疑點。

未發現 Railcraft、Create、JEI 或其他模組的直接相依宣告／imports。依 D7，目前不需要任何外部模組，因此不新增外部模組依賴或整合驗收矩陣；以 Minecraft＋NeoForge＋Simple Rail 驗收。外部 datapack／腳本未指定需求，不推定需要整合。

發行 metadata 的歷史落差保留供參考：舊 `R/META-INF/mods.toml` 宣告 MIT，但 `OLD/LICENSE.txt` 開頭是 Forge／FML 的 LGPL 說明；新 `NEW/gradle.properties` 為 `All Rights Reserved`，另有 `NEW/TEMPLATE_LICENSE.txt`。依 D8，首版採目前的 `1.0.0`、`All Rights Reserved` 與 NeoForge `21.1.251`；本輪只記錄此決策，不變更 metadata 或授權檔案。

## 5. 已確認的需求決策

| 編號 | 使用者決策 | 對後續工作的影響 |
| --- | --- | --- |
| D1 | 不支援舊世界，不需要轉換流程 | 移除舊世界／NBT／箱子資料／票證轉換及升級測試；保留新版本自身存讀驗收 |
| D2 | 原決策保留全部 ID；2026-10-02 T 型合併例外 | 使用者要求將 `y_cross_rail`／`y_cross_right_rail` 方塊、物品、配方與掉落合併為 `t_cross_rail`；其餘名稱（含 `destory_rail`）保留。不實作 ID／舊世界轉換；舊材質資源可由新模型沿用 |
| D3 | 區塊載入預設啟用；依 2026-10-08 已批准提案，以整列目前位置／移動目標的 3×3 聯集維持 ticking，先加後回收；停車保留、永久刪車／關閉設定釋放，索引只恢復目前集合，R1 歷史票證清理後既有整列載入一次。見 [新 D3 契約](docs/evidence/locomotive-chunks-R2/README.md)。 | 取代初始『沿用 OLD 中心呼叫、不新增釋放』；OLD 盤點與 R1 證據保留，D1 不做 OLD 存檔轉換。API 編譯／自動化檢查完成，遊戲驗收尚未執行。 |
| D4 | 維持「27 格不消耗物品的列車樣板」，改用專用方塊實體，維持箱子式 GUI | 新增發射器專用方塊實體及必要容器連接；保留方塊／物品 ID，不承接舊箱子資料 |
| D5 | 保持實際秒數＋讀回補償，卸載／離線期間暫停 | 新版本保存剩餘等待時間所需資料並於讀回補償；不改用遊戲 tick 計時，須驗證卸載及關服後剩餘時間不被扣除 |
| D6 | `TASK.md` 將依本指南產生，經使用者審閱後，作為執行順序與舊疑點修正範圍的依據，後續依序完成 | 2026-09-29 使用者確認坡底反轉未再發生，T-026 人工通過結案；T-025／R1／R2 及原失敗保留歷史。R-03／R-F 待審、T-094 待執行，兩基底／其他功能／正式依賴不變，不倒填其他任務完成 |
| D7 | 目前不需要任何外部模組 | 不新增外部模組依賴或專用整合功能，以無其他模組環境驗收 |
| D8 | 目前發行版本號、授權宣告及目標 NeoForge 版本作為首版基線 | 固定本次規劃基線為 mod `1.0.0`、`All Rights Reserved`、NeoForge `21.1.251`，Minecraft `1.21.1`；不代表工具鏈或 API 已驗證 |

### 執行範圍補充決策（2026-09-26）

本輪使用者決定：**OLD build 由使用者先前驗證，本次流程不重跑**，優先推進 NEW 的 Minecraft 1.21.1＋NeoForge。此決策補充執行方式，不改動 D1–D8。

- T-002 免執行與已完成／已驗證分開；其前置阻擋移除。T-001 的既有 Git／工具鏈盤點及歷史草案保留，舊環境補下載方案不採用。
- T-003 僅整理舊版行為參考及未確認差異。已有可用 OLD JAR 時可按必要個案觀察，不為此重建；未實測一律標「依原始碼推定／待確認」，不稱舊版實測基線。
- T-002／T-003 不作 NEW 任務的硬性前置；API、實作及驗收各自追溯原始碼與已定需求。舊行為未明且影響驗收者，只列具體個案待確認，不全域停工；詳見 TASK.md「依賴阻礙與待查證細節」。六疑點仍先確認問題才修正，D3 不自行改為 5×5 或新增釋放政策。
- T-007 僅驗證 dedicated server 啟停；T-006／T-007 的 Agent 歷史結果保留。T-089 改由使用者連線驗證，前置含 T-090 固定版本測試包；T-017 只依賴開發所需 T-005／T-008，不等待 T-089。此為新分工下正式依賴，取代先前 T-017 等待連線的規劃。


### 新分工與交接（2026-09-27）

| 角色 | 責任與邊界 |
| --- | --- |
| 開發 Agent | API 查證、程式／資源遷移、Gradle build、非遊戲自動化程式測試、版本固定的 JAR 測試包、分析並修正使用者回報。不啟動 Minecraft，也不以無畫面／自動化方式代跑 server 或世界 |
| 獨立 Review Agent | 只審程式／資源差異、邏輯、功能與測例覆蓋、保存與同步設計、D1–D8；可檢查 build／靜態測試證據，不啟動 Minecraft、不重跑遊戲、不簽署人工測試通過 |
| 使用者 | 親自執行所有 client／dedicated server、世界、GUI、存讀、卸載、多人及候選 JAR 遊戲測試；只有使用者回報能成為人工測試結果 |

TASK.md 共 126 項、階段 0–8 不變。T-090–T-118 拆出 29 項測試包；T-119–T-124 承接六疑點人工重現；T-125 承接 T-081 的最終 runtime 清單／外觀驗收；T-126 承接 T-087 的效能實測。原任務編號、功能與驗收強度不變；新增項中 T-090／T-091 已開發完成，其餘待執行。T-003 始終只是來源參考；未實測 OLD 保持「依原始碼推定／待確認」。若未來確需既有 OLD JAR 觀察，也由使用者操作，不重建 OLD。

開發 Agent 的每次交接仍必須列 T／案例 ID、實際 commit（未提交差異另附指紋）、JAR SHA-256、Minecraft／NeoForge／mod／JDK／工具版本、安裝啟動步驟、NEW 場景與設定、事先預期／量測容差；log／截圖取得方法可供使用者選用。**2026-09-28 使用者決策：人工審查／遊戲測試項目不需提供證據，使用者確認完成即可記人工通過並結案。** 不要求使用者回傳版本證明、JAR 雜湊、log、畫面、存檔或逐案例資料；未提供的細節不虛構。指南各階段的操作、功能與驗收要求保留，所稱人工記錄與附件均為選用，不作人工結案門檻。開發與獨立程式審查仍保存自身證據，人工結案不推定其已完成。完整模板見 [TASK.md](TASK.md)，程式審查規範見 [REVIEW.md](REVIEW.md)。

開發完成、程式審查通過、待人工測試、人工測試通過／不通過及受阻分欄；T-006／T-007 只記 Agent 歷史。人工測試失敗後由開發 Agent 修正、Review Agent 複查程式、使用者重測原失敗及受影響案例。不同 JAR 結果不得無依據沿用。

人工測試不是技術必要前提時，不阻擋開發：T-017 依 T-005／T-008，T-019 依 T-017／T-008／T-010／T-004；T-018／T-089 人工閘門留在功能／整體交付。六疑點只有確認問題才修正；若某分項必須實測才能確認，只等待對應使用者重現，不擋其他開發。必要人工案例與程式審查未通過前，不宣稱受影響功能或最終候選交付完成；T-088 統一核對。

## 6. 分階段遷移順序與驗收

D1–D8、歷史／T-002／R-01／T-018／T-089 保留。T-019–T-022／T-093 仍 R-02 待審，T-092 已依使用者確認完成結案；T-023／T-024 已依使用者確認人工通過，R-02 仍待審。T-025／T-027／T-029／T-031／T-033／T-035 開發完成，R-03／R-F 待審；T-026／T-028／T-030／T-032／T-034／T-036 使用者人工通過已結案，其他包／遊戲不倒填完成。T-035 扳手原碼相容交付、U-09 意圖待確認，T-036 已依使用者確認人工通過結案；T-099 製包已結案（使用者接手）；T-033 一般移除軌交付，T-034 已依使用者確認人工通過結案；T-098 製包已結案（使用者接手）；T-031 下車軌交付，T-032 已依使用者確認人工通過結案；T-097 製包已結案（使用者接手）；T-029 先按原碼分支、U-07 註解／模型／方向意圖待確認，T-030 已依使用者確認人工通過結案；T-096 製包已結案（使用者接手）。T-094～T-099 Agent 製包已由使用者接手結案，不再阻擋對應人工；未決意圖／功能 owner 與其他前置保留。以下完整功能及驗收要求不刪減；角色／前置以 TASK.md 為準，全部遊戲由使用者操作確認，附件選用。

| 階段 | 工作內容／依賴 | 驗收方式 |
| --- | --- | --- |
| 0. 任務清單與行為參考 | 維護已審閱的 `TASK.md`；T-002 依使用者決策免執行，T-003 整理原始碼中的功能、registry／state 與設定參考；既有 OLD JAR 的必要觀察為選用，不重建或轉換世界 | 任務清單符合 D1–D8 且經使用者審閱；對應第 3 節建立測例，標明沿用行為及各修正任務的預期差異；涵蓋未使用及計時中的軌道、27 格樣板、空／多節編組與跨區塊車廂；未實測 OLD 行為標「依原始碼推定／待確認」，不要求 OLD 實測紀錄才可推進 NEW |
| 1. 目標框架與 API 查證 | 使用 NEW 既有設定起步；查對指定 1.21.1／NeoForge 版本的來源及文件，建立舊符號→候選替代方式→驗證結果表；確認 Java／Gradle／mappings；後續再移除範例內容 | 執行目標 `./gradlew.bat build`，分別驗證 client 啟動（T-006）、dedicated server 啟停（T-007）與 client 連線（T-089），確認載入 mod ID 與 metadata；紀錄實際依賴版本。不可以只有 IDE 無紅字為驗收 |
| 2. 註冊、設定與基礎資源 | 依 D2 及 T 型合併例外核對 10 方塊、12 物品與創造分頁、標籤／狀態／設定結構；依已查證格式處理模型、語系、配方與掉落資料 | registry 清單與第 4.1 節比對；物品可取得，模型與兩語系正確；12 配方逐一測合成、10 方塊測掉落，資料載入無相關錯誤；註冊成功尚不代表行為完成 |
| 3. 基礎軌道與扳手 | 共用基底禁坡；僅高速軌道可成四方向升坡，其餘停車／單向／下車／移除等維持原規格；扳手調向／調等級。先驗原版礦車，編組刪除留階段 5 | 測高速平軌／四升坡、供電／未供電模型、坡底／坡頂、原版一般／動力斜坡接口、正反方向及速度設定邊界；共用速度／其他軌道禁坡不變。供電有效連續路線不得意外反轉；正常制動／低動能回滾分開判定。下車／停車／掉落及 client／dedicated server 一致性保留 |
| 4. 方塊實體、計時與容器 | 依 D4 建立發射器專用方塊實體、27 格不消耗物品樣板與箱子式 GUI；依 D5 保留實際秒數＋讀回補償，並處理訊號排程；先測一般礦車生成 | 測等級 0–9、供電／停電、改設定與重啟；計時剩餘例如 3 秒時卸載或關服，讀回後仍約需 3 秒，允許誤差由測例明訂；未使用的計時軌及缺鍵資料能正確處理；容器存讀不遺失物品，觸發生成前後 27 格樣板內容及數量不變，GUI 可正常操作 |
| 5. 車頭、同步、渲染與編組 | 查證實體生成、資料同步、模型註冊與父類行為；完成車頭、扳手編組、發射器整列生成及 destory 整列移除 | 至少雙客戶端連到 dedicated server，測加入／重連、8 朝向、放置／命名／破壞／掉落與碰撞；編組順序在保存重啟及車廂晚載入後符合決策；不出現重複實體、殘留連結或同步錯誤 |
| 6. 路口與區塊生命週期 | 十字、合併後 T 型分岔（斷電右轉／通電左轉與貼圖切換）；依已修訂 D3 維持整列滾動區塊集合、回收與重啟索引；暫存、票證疑點依 D6 清單分別修正 | 四朝向、4 種來車方向及紅石開關，單車／編組依 NEW T 型表通過並觀察貼圖；測不同維度同座標、切換世界、破壞、卸載、中途存讀及兩車並行。票證／區塊行為按 D3 比對，OLD 未測仍為「依原始碼推定／待確認」；T 型與 R2 票證不宣稱 OLD 等價；依已批准範圍驗收長途有界、尾車覆蓋、刪車／停用清理及索引重啟 |
| 7. 新版本存讀回歸 | 依 D1 不做舊資料轉換；在 1.21.1 新世界整合驗證編組、專用容器、計時與方塊狀態保存 | 保存並重啟至少兩次，比對方塊／狀態、物品數量、車頭／車廂 UUID 與次序、27 格樣板及計時剩餘值；測卸載再載入，不遺失或重複內容；不執行 1.16.5 世界匯入驗收 |
| 8. 整合與發行候選 | 依 D6 清單完成回歸，採 D8 的 `1.0.0`／`All Rights Reserved`／NeoForge `21.1.251` 基線；更新本指南的已驗證與未支援項目 | 依 D7 在無其他模組的乾淨 client／dedicated server 以產出 JAR 重跑代表案例；確認 metadata、資源完整、無範例註冊殘留、日誌無本模組相關載入錯誤；記錄效能、已知限制及不支援舊世界的範圍 |

階段 1 的 API 查證至少涵蓋：註冊與事件、設定載入時機、rail hooks／礦車運動、BlockState、方塊實體 tick 與 NBT、容器開啟／同步、實體生成與資料序列化、client 模型／渲染、區塊票證、資源與資料包格式。其中入口／註冊／事件／設定／分頁候選已有 T-008 指定來源及最小編譯；資源／資料格式及 ID 對照由 T-009、軌道／互動／完整狀態值域及回呼來源由 T-010、方塊實體／計時／保存候選與卸載順序由 T-011、專用 27 格容器／箱子式 GUI 與槽位同步候選由 T-012、車頭／車廂運動與編組保存候選由 T-013、實體生成／追蹤與欄位同步候選由 T-014、模型／renderer／九軌 cutout 與 UV 候選由 T-015、區塊事件／票證與 D3 最小候選由 T-016 交付；其餘仍是待研究清單，不代表實際遊戲語意或整套 API 已驗證。

驗收以具體玩家行為及資料不變性為主；適合自動化的編組還原、缺鍵資料讀取、路徑選擇等再加入測試。目標專案雖宣告 gameTestServer 執行設定，目前未在來源找到本模組測例，不能當作現成驗收成果。

## 7. 定版狀態、待確認與待技術驗證項目

- 歷史完成：T-001 環境、T-003 的 25 項來源參考、T-004 的 44 組案例設計、T-005 NEW 框架 build。T-002 為使用者決定免執行，非 Agent build 結果。
- Agent 歷史啟停：T-006 client 已進入 NEW 新世界並正常結束；T-007 dedicated server 已完成新世界啟動、保存、停止；兩者退出碼 0。原始證據與限制保留，不代表使用者人工測試、T-089 連線或後續功能完成。
- 已知歷史限制：T-006 出現範例 example_block／example_item 模型缺失的非致命警告，交 T-017／T-018 與後續資源驗收處理；同名世界兩次登入的中間操作未完整取證，不能當作存讀回歸通過。T-005 test 為 NO-SOURCE，不能稱自動化測試通過。
- T-008 開發完成：[A01–A14 API 對照及原始證據](docs/evidence/T-008/README.md) 固定 NeoForge 21.1.251／FML 4.0.44；最小編譯重試退出 0，原始沙箱失敗退出 1 亦保留。只查證候選簽名與來源，未執行探針或遊戲。COMMON 載入前讀值風險、不自動同步及重載執行緒限制交 T-020 等後續處理；正式創造分頁 key／順序由 T-019 定義。
- T-009 開發完成：[格式／ID／引用及非遊戲檢查](docs/evidence/T-009/README.md)；144 檔／13 配方／266 條直接引用有對照，獨立工具編譯與檢查退出 0。沒有執行 Minecraft codec、pack 載入、datagen 或 Gradle build；額外資源與 atlas 問題交 T-021／T-022／T-048。
- T-010 開發完成：[API／執行端對照及完整狀態](docs/evidence/T-010/README.md)；77 個來源快照、最小編譯退出 0，失敗 log 與探針原稿保留。PoweredRailBlock 的 true 參數、isFlexibleRail、any() 預設覆蓋、waterlogged、回呼前後的礦車邏輯及 use 互動順序均列明；沒有執行回呼或遊戲測試。
- T-011 開發完成：[方塊實體／計時／保存 API、資料邊界與生命週期證據](docs/evidence/T-011/README.md)；指定版來源快照 34 個，最小編譯重試退出 0，沙箱內 Wrapper 鎖檔失敗退出 1 保留。來源顯示卸載時先保存再呼叫 BE `onChunkUnloaded`，因此該回呼不能當最後寫盤點；D5 實際秒數、讀回補償及缺鍵處理已有候選設計，尚未實作或遊戲驗收。
- T-012 開發完成：[專用 27 格容器、箱子式 GUI 與同步候選](docs/evidence/T-012/README.md)；指定版來源快照 23 個、OLD 來源 1 個，最小編譯重試退出 0，初次 Wrapper 鎖檔失敗退出 1 保留。新增 BE ID 候選 `simplerail:train_dispenser`，位於不同 registry，不更動同名既有方塊／物品 ID；原版 `GENERIC_9x3` 可作 GUI 候選。正式註冊、觸發、存讀與多人介面均未驗收。
- T-013 開發完成：[車頭、車廂運動與編組保存 API／資料所有權候選](docs/evidence/T-013/README.md)；指定版來源 25 個、OLD 來源 6 個，最小編譯重試退出 0，初次 Wrapper 鎖檔失敗退出 1 保留。`ServerLevel#getEntity(UUID)` 查不到時不等於車廂已刪除；有序 UUID 清單需與暫存實體引用分開。正式移植、晚載入、動力父類行為、存讀與同步均未驗收。
- T-014 開發完成：[實體生成、FACING／LINKABLE 及追蹤資料同步候選](docs/evidence/T-014/README.md)；指定版來源 21 個、OLD 來源 5 個，最小編譯重試退出 0，初次 Wrapper 鎖檔失敗退出 1 保留。OLD `LINKABLE` 僅見宣告／預設 true；舊 enum serializer 的直接註冊不能照搬，內建 BYTE／BOOLEAN 為可編譯候選。正式實作、重連及雙 client 一致性仍待查證／使用者測試。
- T-015 開發完成：[九軌 cutout、模型／UV／渲染候選](docs/evidence/T-015/README.md)；指定版來源 16 個、OLD 來源 5 個，九軌資源靜態盤點為 29 個引用模型及 29 張透明貼圖；車頭 PNG 實測 96×64。最小編譯重試退出 0、初次 Wrapper 鎖檔失敗退出 1 保留。正式 JSON／atlas 遷移、renderer 坡度與 UV 畫面尚未驗收。
- T-016 開發完成：[區塊事件／票證指定版候選及 D3 觀測邊界](docs/evidence/T-016/README.md)；指定版來源 12 個、OLD 來源 3 個，最小編譯重試退出 0、初次 Wrapper 鎖檔失敗退出 1 保留。保留 radius=2 迴圈反覆傳中心區塊、ticking=true 及不新增釋放政策；正式票證保存／運作及舊疑點未實測。
- T-017 開發完成：[正式空功能入口、範例移除、NEW build 與 client 邊界證據](docs/evidence/T-017/README.md)；離線 build 重試退出 0、初次沙箱 Wrapper 鎖檔退出 1 保留。JAR 的 `simplerail`／D8 metadata 及無模板註冊已靜態核對；`test NO-SOURCE`，R-01 程式審查通過；T-018 的使用者 runtime 回報另列，不自行綁定此 JAR。
- T-090／T-091 開發完成：[連線包](docs/evidence/T-090/README.md)、[正式框架包](docs/evidence/T-091/README.md)，各 5 案例／16 檔；含固定 JAR、來源差異／指紋、版本、安裝步驟、場景／預期、選用 log／畫面方法與空白結果欄。共享 NEW build 退出 0、`test NO-SOURCE`；JAR SHA-256 與 T-017 相同，ZIP 逐檔內容核對成功。R-01 程式審查通過，未啟動新包的遊戲測試，不把使用者舊回報代填為此包結果。
- 使用者人工回報：2026-09-28 使用者表示「我已驗證完 T-089、T-018，皆正確執行」，並明定「人工審查項目不需提供證據，由使用者確認完成即可結案」。[T-089 確認紀錄](docs/evidence/T-089/README.md)、[T-018 確認紀錄](docs/evidence/T-018/README.md)已保存，兩項**人工測試通過並已結案**，不要求補證。T-090／T-091 已有實際開發交付，R-01 本輪獨立審查通過，並非由人工確認推定；不自行填寫逐案例細節或受測 JAR 身分。
- T-019 開發完成：[11 方塊／13 物品／正式分頁與建置證據](docs/evidence/T-019/README.md)、[ID／配對／順序](docs/evidence/T-019/checks.json)、[完整屬性對照與未實作清單](docs/evidence/T-019/state-contract.md)。destory_rail 保留，分頁新 key simplerail:tab、圖示 high_speed_rail、明列 13 物品；NEW 離線 build 退出 0，18 項靜態檢查通過，test NO-SOURCE。十一個普通 Block 尚無軌道／自訂 state／機器行為；R-02 待審，未啟動 Minecraft，runtime 可取得性／GUI 待使用者 T-023。
- T-020 開發完成：[25 個正式 COMMON 設定及實際證據](docs/evidence/T-020/README.md)、[預設／值域／載入及生效契約](docs/evidence/T-020/config-contract.md)。NEW 離線 build 退出 0，獨立 JVM 159 項檢查通過，Gradle test NO-SOURCE；初次測試工具失敗另存。保留全部鍵與 D3 true＝啟用；尚無功能消費者、時間換算或同步協議，R-02 待審，FML／遊戲 reload 與生效未驗證。
- T-021 開發完成：[114 來源資源／atlas／logo 交付與證據](docs/evidence/T-021/README.md)、[全部去向／ID](docs/evidence/T-021/resource-map.json)、[資源決策與 I-021-01](docs/evidence/T-021/RESOURCE_DECISIONS.md)。29 模型 cutout、43 sprite 來源、雙語及 pack 策略已接；2519 靜態檢查／563 引用／45 PNG 完整解碼通過，NEW build 退出 0、test NO-SOURCE。10 個骨架缺 selector 屬性、9 種候選域部分變體未覆蓋，T-092／T-023 不可據此宣稱 ready；正式依賴／狀態域不改，需依 D6 後續承接。R-02 與遊戲／外觀／codec 載入均未通過。
- T-022 開發完成：[29 資料檔與實際證據](docs/evidence/T-022/README.md)、[ID／映射](docs/evidence/T-022/data-map.json)、[資料與掉落契約](docs/evidence/T-022/DATA_CONTRACT.md)。配方只換結果欄位，destory_rail=3／其餘=1，tag 9／2／1 與 replace=false 保留；ModTags.WRENCH 為 item 型別。額外車頭 loot 保留原 ID／entity type，僅移除不相容爆炸條件，不掛接到未實作車頭；T-048／T-052／T-062 承接正常單一路徑與回歸。393 靜態檢查／85 引用通過，NEW build 退出 0，test NO-SOURCE；R-02 待審，遊戲合成／掉落／tag／reload 未測。
- 未執行：T-025／T-027／T-029／T-031／T-033／T-035 以外功能行為／自訂狀態、T-026／T-028／T-030／T-032／T-034／T-036 以外後續使用者人工功能／候選測試與 R-02 以後獨立程式審查；T-026／T-028 已依使用者確認通過並結案，不推定其他任務或新 JAR 回歸通過。資料或程式已建置不等於 runtime 載入通過。
- T-092／T-093 包製作（原開發歷史；最新結案見本文末尾）：[T-092 受阻草稿／命令與靜態證據](docs/evidence/T-092/README.md)、[T-093 完成判定](docs/evidence/T-093/README.md)。31 檔／156 及 226 案例，固定同一 T-022 JAR、全部 actual=null；本輪未重跑 build／遊戲。I-021-01 及 I-092-02（有效 COMMON 觀測未齊）阻擋 T-023 新包，T-024 前置仍等 T-023；T-093 包完成不表示功能交付或人工通過。R-02 待審。
- 保留排除項：不支援舊世界／NBT／箱子／票證轉換，不加入外部模組。OLD build 由使用者先前驗證，本次流程不重跑。
- T-025 原開發交付保留：[build／bytecode／JAR 證據](docs/evidence/T-025/README.md)、[來源行為及未測差異](docs/evidence/T-025/RAIL_CONTRACT.md)。兩基底及高速工廠接共同速度快照、禁坡與實體破壞 false；動力 true、父類狀態／紅石保持，只加本軌 pickaxe tag；原 NEW build 0、40 靜態核對通過、test NO-SOURCE。當時人工未測及先前 T-026 失敗是歷史；最新人工通過依使用者确认，不沿用靜態結果推定。I-021-01／I-092-02 其他整合缺口、R-03 待審；T-094 製包已結案（使用者接手）。
- T-026 [最初回報](docs/evidence/T-026/REPORT-001.md)、[第二次回報](docs/evidence/T-026/REPORT-002.md)、[R1](docs/evidence/T-026/fix-R1/README.md)及 [R2](docs/evidence/T-026/fix-R2/README.md)保留歷史；最新 [2026-09-29 使用者確認](docs/evidence/T-026/REPORT-003.md)：坡底反轉未再發生，T-026 驗證通過並結案。I-026-01／I-026-02 依確認完成，不補造逐例數據或受測產物；其他任務／程式審查不推定通過。
- T-027 開發完成：[來源／產品／build／隔離測試及固定 JAR](docs/evidence/T-027/README.md)。未供電記方向／中心停車，父類電力更新後只在上升沿放行單格所有礦車；時序差異、server guard、六向狀態及保存／同步界限明列。NEW build 0、隔離 hook 85 判定、175 靜態核對，均非 Minecraft 遊戲結果；R-03 待審，T-028 依使用者確認人工通過已結案；T-095 製包已結案（使用者接手）。
- T-029 原碼相容開發完成：[來源／U-07／設定／狀態／build／隔離測試及固定 JAR](docs/evidence/T-029/README.md)。server 放置投影、過車當前快照／原碼方向分支；重載既有投影與規則可不一致，usePowerChangeDirection 不按名稱擅改紅石翻向。NEW build 0、3,097 隔離判定、178 靜態核對；U-07 意圖仍待確認、R-03 待審，T-030 已依使用者確認人工通過結案；T-096 製包已結案（使用者接手），模型 baking／世界／多人未驗證。
- T-031 開發完成：[來源／精確側邊座標／API／build／隔離測試及固定 JAR](docs/evidence/T-031/README.md)。server 供電條件、reverse、距離 1–100，直接乘客快照後一次 detach／動量歸零；玩家用已查證的同世界位置封包 API，其他乘客 moveTo，未加避障／票證。NEW build 0、23,821 隔離判定／48 分支列、191 靜態核對；R-03 待審，T-032 已依使用者確認人工通過結案；T-097 製包已結案（使用者接手），玩家連線確認、落點碰撞及世界／存讀尚未驗證。
- T-033 開發完成：[一般移除／來源副作用／API／build／隔離測試及固定 JAR](docs/evidence/T-033/README.md)。原 destory_rail ID、server 供電条件、discard 保留原版容器／乘客 hook、移除後廣播原煙霧與聲音參數；已移除目標不重複處理。NEW build 0、8,173 隔離判定／四條件列、200 靜態核對；R-03 待審，T-034 已依使用者確認人工通過結案；T-098 製包已結案（使用者接手）。OLD 父類副作用、實際內容掉落／乘客／兩端效果未驗證；TNT 等同 tick 後續工作不被本軌截斷，未新增抑制政策；T-061 整列移除未實作。
- T-035 原碼相容開發完成：[來源／Property 身份／U-09／build／隔離測試及固定 JAR](docs/evidence/T-035/README.md)。原 wrench ID／stack1，rails 無車與 machines gates、level 9→0／水平輪轉；沿原初始 state 逐次覆寫，U-09 已提問未收到決策，不默改複合操作。NEW build 0、388 隔離案例／1,575 判定、204 靜態核對；R-03 待審、T-036 已依使用者確認人工通過結案；T-099 製包已結案（使用者接手）。level／facing 與部分方向 owner 未實作，fixture 不當成實際方塊／GUI／兩端通過，後續任務承接。
- 製包分工更新：[T-094～T-099 使用者接手指示](docs/evidence/T094-T099-user-handoff/README.md)，六項 Agent 製包已結案、由使用者自行處理；原開發交付列的包未執行為 Agent 歷史，以本次例外取代待辦。不是實際包／新 JAR／審查或遊戲已通過，不要求使用者製包證據。階段 3 六項人工均已依使用者確認通過結案，程式審查仍待審；U-07／U-09 待確認、D1–D8 與全部功能驗收不變。
- 待技術驗證：各功能的 1.21.1 API／資料格式、專用方塊實體保存與 GUI、車廂 UUID 次序／晚載入／同步、實際時間與讀回補償、訊號相位、全部 ID、區塊載入原邏輯與六疑點。剩餘約 3 秒卸載／關服後仍約需 3 秒的兩條路徑均保留；容許誤差仍待技術定義。

`TASK.md` 已經使用者審閱，原歷史／R-01／T-018／T-089／T-026／T-028 結案保留。[T-035 扳手](docs/evidence/T-035/README.md)原碼相容開發完成、U-09 意圖待確認、R-03 待審，T-036 已依使用者確認人工通過結案；T-099 製包已結案（使用者接手）；未實作屬性 owner、T-033／T-031 交付與原包／人工未執行、T-029／U-07 待確認保留。其他整合／審查閘門不倒填完成；下一可獨立開發調查 T-037，本輪未開始其他任務。使用者確認即可人工結案，不要求附件。

本次 T-094～T-099 由使用者接手、Agent 製包工作已結案；上述包未執行文字僅保留歷史，不再視為 Agent 待辦或人工的製包阻擋。其餘人工與程式審查仍分開記錄，不推定通過；沒有開始新任務。

最新人工確認（2026-09-29）：使用者表示「我已完成T-028驗收，測試通過」，[T-028 已登錄人工通過並結案](docs/evidence/T-028/README.md)。不要求補交證據，不虛構受測 JAR、版本或逐案例數據；R-03／R-F 仍待審。此輪只更新文件，未執行新任務。

### T-030 使用者需求調整：未供電單向軌自然滑行（2026-09-29）

使用者於 T-030 回報並要求 oneway_rail 未供電時像一般軌道、不對礦車施加動力軌額外煞車。此明確決策補充 §3／§6 階段 3；原方向啟用條件與 reverse 行為保持，規則未啟用時移除原 1.2 補償，保留自然摩擦。needPower=false／usePowerChangeDirection=true 仍按既有規則啟用，不由此推定 U-07 電力翻向意圖已決定。

[R1 修正與證據](docs/evidence/T-030/fix-R1/README.md)：保留 powered rail 紅石／狀態繼承，僅在礦車 moveAlongTrack 略過未供電單向軌的動力分類煞車；tick activator 判斷、供電加速、其他軌道與全部 ID 保留。NEW build 退出 0，3,247 非遊戲判定／11 bytecode 核對通過；Mixin 實際載入／weaving、遊戲滑行與車種／紅石回歸待使用者重測。T-030 尚未通過，R-03／R-F 待審；D1–D8、T-028 及其他人工確認與歷史來源不改寫。未執行 OLD、Minecraft 或其他任務。

### 最新人工確認：T-030／T-032／T-034／T-036 結案（2026-09-29）

使用者原文：「T-030驗證成功，另外T-032、T-034、T-036接驗證完成，測試通過」。[四項已登錄人工通過並結案](docs/evidence/T030-T036-user-confirmation/README.md)，T-030 的 I-030-01 依確認已解決。上述開發時／R1 交付時未測與待重測描述保留歷史，本行更新目前人工狀態；不補造受測版本／JAR 或逐案例數據，不要求附件。階段 3 六項人工驗收已結案，R-03／R-F 仍待審，不能宣稱該階段完整交付；U-07／U-09 意圖與後續未實作功能仍待確認／實作。正式前置、全部驗收要求與 D1–D8 保留，不推定 T-024、後續整合或新候選 JAR 通過。此輪只更新文件，未修改產品或執行其他任務。

### 最新確認：T-092／T-023／T-024 結案（2026-09-29）

使用者原文：「T-092、T-023、T-024已驗證完成」。[三項確認紀錄](docs/evidence/T023-T024-T092-user-confirmation/README.md)已保存：T-023／T-024 人工測試通過並結案，不要求補交證據；T-092 原為製包開發任務，依使用者確認完成結案並解除受阻／製包閘門，不改寫成 Agent 已製作新版包或遊戲實測通過。

原 I-021-01／I-092-02、受阻草稿及原包 actual=null 保留歷史與技術追溯，不再阻擋本次已確認任務；未提供的版本、JAR 雜湊、逐例結果或修正不補造。後續未實作功能／全部狀態／最終整合仍按原任務核對，R-02／R-03／R-F 仍待審，不宣稱階段 2 完整交付。D1–D8、U-07／U-09、編號／正式前置及原驗收要求不變；本輪只登錄文件，未修改程式或執行 build／遊戲／其他任務。

### T-037 計時保存調查與候選診斷包（2026-09-30）

[T-037 開發完成](docs/evidence/T-037/README.md)，補充 §4.2／§4.3(4) 與 §6 階段 4 的調查依據。OLD 秒數 int 乘法溢位、可省略 UUID 與無條件讀取不對稱、setters 無標髒及保存時點落差已具來源／非遊戲證據；OLD 遊戲後果仍是「依原始碼推定／待確認」。NEW 指定來源顯示 BE onChunkUnloaded 太晚，不能回改卸載路徑先前已序列化的資料；實際生命週期與存讀仍待使用者觀察。

NEW build 退出 0、1,049 非遊戲判定通過；[T-037-v1](docs/test-packages/T-037-v1/README.md)含固定診斷 JAR、7 組／13 個案例變體及空白人工结果。它是合成計時器與受控保存／卸載邊界，未實作正式礦車停車／放行，正式 Java／資源／Gradle 未改。D5、正式資料格式／保存策略／效能、M-01 約 3 秒容許誤差、T-040／083 均未宣稱通過。

T-037 的 R-04 待審、T-119 人工待執行；下一可獨立開發 T-038，尚未開始。126 項／九階段／全部 ID／D1–D8／免執行與使用者確認規則不變；歷史文字中的 T-037 未開始由本段更新。R-02／R-03 與列明 R-F 指定範圍通過依頁首／REVIEW §46–47 保留，不將通過外推到本診斷包。

### T-038 正式計時軌道開發交付（2026-09-30）

依 §3 與 §6 階段 4，[T-038](docs/evidence/T-038/README.md)已把 `simplerail:timer_holding_rail` 接至同名專用方塊實體；level 0–9、六向方向記錄、同 UUID 到期放行、新 UUID 重啟等待，以及正式 COMMON 設定接線。新資料只寫 `holding_timer` v1 的 UUID／剩餘毫秒；使用單調時鐘計實際經過時間，在保存時取當刻值，卸載前凍結並於讀回後首次活動恢復。設計與範圍見 [資料／時間契約](docs/evidence/T-038/DATA_AND_TIME.md)；不安排舊 NBT 或舊世界轉換，不改 D3 票證政策。既有方塊／物品與 `destory_rail` 等 ID 保留。

NEW build 退出 0、1,055 真實 NEW NBT／時間及 1,526 隔離 hook 非遊戲判定通過；普通 Gradle test NO-SOURCE。R-04 程式審查、T-039 的逐項疑點判定、T-119 人工調查、T-040／T-083 正式遊戲驗收與 T-100 製包均待執行。M-01 約 3 秒容許誤差待技術定義；不以非遊戲結果宣稱 D5 已在遊戲通過。U-08／U-09、實際父類供電與資源顯示依原後續工作處理。126 項／九階段不變，最新為 25 項開發完成、77 項待執行。
U-09 對 T-040 的具體影響：計時軌道有水平記錄方向時，現行扳手從初始 state 換級後再從初始 state 旋轉，會覆蓋級數；此分項待使用者決定／明確驗收期望。T-038 不擅改已保留的扳手原碼相容規則；其他可獨立進行的計時與資料工作不因此停擺。

### T-039 保存疑點逐項核對與 T-119／T-100 確認（2026-09-30）

[I-037-01～05 問題→正式 NEW 避免路徑](docs/evidence/T-039/DECISIONS.md)已逐項確認：新版資料缺鍵與錯型安全回 idle；秒數先轉 long；新車及計時更新標記待存；序列化取當刻剩餘，卸載事件在固定版 save 前暫停並標 chunk 待存。這些設計在 T-038 的正式 Java 與既有真實 NEW NBT／隔離 hook 測試有來源，T-039 因此以「無新增補丁」完成自身開發判定，產品／JAR 指紋未變。沒有重跑相同 build、OLD build 或 Minecraft。

使用者表示「我已驗證T-119 計時保存／讀回且已完成T-100。執行**T-039。**」，[原文與界線](docs/evidence/T-039/USER_CONFIRMATION.md)已記錄。T-119 依人工確認結案，不補造 13 個逐案觀察數值；T-100 依使用者完成確認結案，但未取得可供 Agent 核對的固定 JAR／版本／案例清單，不寫成 Agent 已驗證製包。T-040 的正式礦車停車／約 3 秒卸載與關服案例、T-083 存讀、R-04 程式審查仍待執行。M-01 誤差及 U-09 扳手換級的具體期望需在 T-040 前界定，不將 T-119 診斷驗證外推為正式 D5 遊戲通過。

126 項／九階段與 D1–D8、既有 ID 不變；現為 26 項開發完成、11 項人工驗證完成、T-092／T-100 兩項依使用者確認結案、74 項待執行。OLD build 仍由使用者先前驗證，本次流程不重跑。

### 車頭、同步、渲染與編組開發基線更新（2026-10-01）

§3／§4.2／§4.3(1)／§6 階段 5 的 T-048／049／050／051／053／054／055 已有[本輪開發與非遊戲證據](docs/evidence/T-048-055/README.md)、[疑點 1 調查](docs/evidence/T-054/README.md)與[已確認靜態分項修正](docs/evidence/T-055/README.md)。保留 `simplerail:locomotive_cart` 物品與實體 ID、新世界 `Train` 有序 UUID／停點與每維度所有權索引；車頭模型沿 OLD 六盒 96×64、同步八朝向，保留九軌 cutout。正式 JAR SHA-256 `63A31C515F0E4682AD16B78731ACF9653421723BA0254A487BC4063FF04D2766`，NEW build 退出 0，41 項純 JVM 斷言通過；Gradle `test NO-SOURCE`。T-054 提供 [T-121 診斷包](docs/test-packages/T-054-v1/README.md)，結果表全空白。

OLD `getEntity(UUID)==null` 時刪減編組與全域 static map 的風險由**原始碼**支持；OLD 實際遊戲影響仍「依原始碼推定／待確認」。NEW 的靜態設計修正不能取代執行期查證：R-05 獨立程式審查、T-121 使用者疑點觀察、T-103／T-104 正式驗收包與 T-052／T-056 人工驗收均待執行。沒有執行 Minecraft／GameTest、OLD build 或舊 NBT 轉換；D1–D8、全部既有 ID、126 項／九階段及使用者人工確認規則保持有效。上文歷史進度數字為當時快照，以 TASK.md 最新任務欄與本段為準。

### T-052 首次人工失敗與 R1 修正（2026-10-01）

使用者確認 T-103 親自完成，T-052 發現車頭額外顯示原版熔爐且速度無法達一般礦車；[原文與判定](docs/evidence/T-052/fix-R1/USER_REPORT.md)保留。T-052 **未通過／未結案**。開發 Agent 依固定版來源做 [R1 最小修正](docs/evidence/T-052/fix-R1/README.md)：車頭 renderer 不再繪製熔爐父類 display block，軌道速度 cap 與無燃料滑行對齊一般礦車，保留原父類燃料推進及既有 ID／存檔。NEW build 與固定 JAR bytecode 稽核退出 0；沒有遊戲結果。R-05／R-F 待獨立程式複查，[T-052-R1 固定包](docs/test-packages/T-052-R1/README.md)待使用者重測兩項失敗、受影響案例及原 T-052 全項。上段「T-103／T-052 待執行」為使用者回報前快照；D1–D8、OLD 不重跑及人工結果只由使用者確認的規則不變。

### T-052 R2：一般礦車速度與不可乘坐（2026-10-01）

使用者[確認 R1 速度仍失敗並指定新行為](docs/evidence/T-052/fix-R2/USER_REPORT.md)：車頭繼承一般礦車，速度機制與一般礦車一致，只禁止正常乘坐。[R2 正式修正](docs/evidence/T-052/fix-R2/README.md)已改為 `Minecart` 父類並移除自行實作的速度／阻力覆寫；熔爐燃料／推力不再提供，`simplerail:locomotive_cart` ID、車頭模型、朝向及編組資料保留。R1 的熔爐父類／燃料描述是歷史快照，已由本段取代。NEW build 與固定 JAR bytecode 稽核退出 0；[T-052-R2 重測包](docs/test-packages/T-052-R2/README.md)已備，R-05／R-F 獨立審查與使用者遊戲驗收均未完成。T-052 繼續未結案，R1 熔爐外觀結果不得推定；D1–D8、OLD 不重跑與使用者人工確認規則不變。

### T-052 人工驗收結案（2026-10-01）

使用者[確認「T-052驗證完成，測試通過」](docs/evidence/T-052/fix-R2/USER_CONFIRMATION.md)，故 T-052 依人工確認規則標為**測試通過／已結案**。上一段 R2 待遊戲驗收是確認前快照；失敗及修正歷史保留。未提供逐例數值或受測 JAR 指紋，不倒填測試包結果；R-05／R-F 獨立程式審查仍待執行，T-056／T-121 與後續驗收不因此通過。D1–D8、既有 ID、OLD 不重跑及人工結果只依使用者回報的分工不變。

### T-121 人工驗證完成（2026-10-01）

使用者[確認「T-121驗證完成」](docs/evidence/T-121/USER_CONFIRMATION.md)，依人工任務規則結案。回報未說明是否發現異常，不將 §4.3(1) 編組載入時序寫成「未重現」或「已修復」，也不補造逐例 UUID、載入時序或受測 JAR。T-055 已確認靜態問題的修正保留；是否有其他執行期缺陷待使用者補充，R-05 審查與 T-056 正式驗收仍待執行。D1–D8、OLD 不重跑及人工結果只依使用者回報的規則不變。

### T-104 完成與 T-054／T-055／T-056 驗證確認（2026-10-01）

使用者[確認原文](docs/evidence/T-054-T-055-T-056-T-104-user-confirmation/README.md)：T-104 已完成，T-054／T-055／T-056 已驗證完成。T-104 依使用者完成確認結案，不補造包的 commit／JAR 雜湊或 build；T-054／T-055 的開發調查與修正保留，另記使用者確認；T-056 依人工規則驗證完成／結案。前段 T-056 待驗收是使用者確認前快照。沒有逐例結果或 T-121 異常分類，不能宣稱 §4.3(1) 所有遊戲疑點「未重現」；R-05／R-F 獨立程式審查及 T-060／T-082／T-084 等後續任務仍獨立待辦。D1–D8、既有 ID、OLD 不重跑及使用者人工確認規則不變。

### T-057 扳手連結開發完成（2026-10-01）

[T-057 來源對照、連結條件與 NEW build 證據](docs/evidence/T-057/README.md)已保存。扳手依 OLD 原始碼所見的點擊位置與面向選取相鄰格，透過 NEW 每維度編組所有權尋找車頭並依兩格順序新增車廂；OLD 遊戲行為仍為**依原始碼推定／待確認**。NEW build 退出 0，41 項既有純 JVM 編組斷言退出 0，Gradle `test NO-SOURCE`。只標 T-057 開發完成；R-05 程式審查、T-105 固定包與 T-058 使用者人工驗收尚未進行。D1–D8、既有註冊 ID、OLD 不重跑及人工結果只由使用者確認的分工不變。

### T-058 首次缺陷與 R1 重測交接（2026-10-01）

使用者[首次驗收回報](docs/evidence/T-058/fix-R1/USER_REPORT.md)：摧毀中間車廂後尾段應斷鏈，車廂之間應留小幅距離。T-058 因此**未通過／未結案**，未提供的其他遊戲案例不補結果。[R1 開發修正](docs/evidence/T-058/fix-R1/README.md)將永久移除與暫時卸載分開處理，從被毀車起解除後段，並改以車頭的有限長路徑依 1.2 格中心距牽引；保留有序 UUID、`TrainStops` 與 NEW 存讀，新增 `TrainPath`。最終 NEW build 退出 0，17 項新增與 41 項既有純 JVM 斷言通過，Gradle `test NO-SOURCE`；[T-105 固定 R1 重測包](docs/test-packages/T-058-R1/README.md)已提供。R-05／R-F 獨立程式審查與使用者 T-058 重測均待執行，不宣稱遊戲缺陷已修復。OLD build 不重跑、不做舊 NBT 轉換；D1–D8 與全部既有 ID 不變。

### T-058 R2：使用者指定 1.5／3.0／4.5 格（2026-10-01）

使用者[後續確認 1.2 倍數過近並指定新距離](docs/evidence/T-058/fix-R2/USER_REPORT.md)，R2 將 `TrainTrail.SPACING` 固定為 1.5 格，前三節沿車頭路徑的目標分別為 1.5／3.0／4.5 格。[OLD／NEW 對照](docs/evidence/T-058/fix-R2/OLD_COMPARISON.md)確認**連結和間距邏輯沒有完全依照 OLD**：OLD 的扳手兩格選取／加入順序是來源參考，OLD 跟車為跨格傳停靠點並移至格中心，無固定 1.5 格值；NEW 為逐 tick 路徑、每維度保存與永久移除判定。OLD 實際行為仍「依原始碼推定／待確認」。[R2 NEW build／15 項純 JVM 距離測試](docs/evidence/T-058/fix-R2/README.md)退出 0，[最新固定 R2 包](docs/test-packages/T-058-R2/README.md)已備；R1 是歷史快照。R-05／R-F 程式複查和 T-058 使用者重測仍待執行，未宣稱遊戲距離或斷鏈通過。D1–D8、既有 ID 與 OLD build 不重跑決策不變。

### T-058 R3：跟車停靠格邏輯改回 OLD 來源（2026-10-01）

使用者[最新決策](docs/evidence/T-058/fix-R3/USER_REPORT.md)要求先將車廂間距邏輯改成 OLD。依 [OLD 原始碼與 R3 差異](docs/evidence/T-058/fix-R3/README.md)，NEW 現在在車頭跨格時逐節傳遞舊停靠格，車廂移至格中心；移動中的車頭進入格內 x/z `0.2～0.8` 區域才更新車廂，停車時持續更新。R2 的 1.5／3.0／4.5 格路徑方案已被取代，R1/R2 證據保留歷史。永久摧毀中車切斷尾段、暫時卸載保留 UUID，以及 NEW 每維度 owner／資料保存仍維持；因此**不是整套編組照搬 OLD**。OLD 遊戲行為仍「依原始碼推定／待確認」。R3 NEW build 與 18 項純 JVM 斷言退出 0，[最新固定 R3 包](docs/test-packages/T-058-R3/README.md)已備；R-05／R-F 程式審查、T-058 使用者遊戲重測未開始，T-058 未結案。不重跑 OLD build、不轉換 OLD 存檔，D1–D8 與既有 ID 不變。

### T-058 R4：維持跨格跟車時機，車距改為 1.25 倍數（2026-10-02）

使用者[最新決策](docs/evidence/T-058/fix-R4/USER_REPORT.md)要求在 R3 基礎上將第 1、2、3 節車廂間距改為 1.25／2.5／3.75 格，後續依 `1.25 × 節序`。NEW 仍只在車頭跨格時新增方塊中心路線點，沿用車頭在格內 x/z `0.2～0.8` 或停止時才移動車廂的時機；沿路線插值產生目標，路線不足時暫用 R3 停靠格中心。R4 `TrainRoute` 隨 NEW 車頭保存，`TrainSchema=4`；原 UUID、停靠格、owner、永久摧毀斷尾及暫時卸載保留均維持。[R4 NEW build／22 項純 JVM 斷言](docs/evidence/T-058/fix-R4/README.md)退出 0，[最新固定 R4 包](docs/test-packages/T-058-R4/README.md)已備。1.25 是 NEW 需求，**不是 OLD 原始碼的固定間距**；OLD 遊戲行為仍「依原始碼推定／待確認」。R-05／R-F 程式審查與 T-058 使用者遊戲驗收尚未執行，T-058 未結案。R1～R3 保留歷史；D1–D8、既有 ID 與不重跑 OLD build 決策不變。

### T-058 R5：車距改為 1.4 倍數（2026-10-02）

使用者[最新決策](docs/evidence/T-058/fix-R5/USER_REPORT.md)要求前三節車廂沿既有路線分別距車頭 1.4／2.8／4.2 格，後續依 `1.4 × 節序`。R5 只改 `TrainBlockRoute.SPACING`，維持 R4 的跨格路線、車頭格內更新時機、路線不足時的停靠格回退、`TrainRoute` NEW 存讀、永久摧毀斷尾與暫時卸載保留。[R5 NEW build／22 項純 JVM 斷言](docs/evidence/T-058/fix-R5/README.md)退出 0，[最新固定 R5 包](docs/test-packages/T-058-R5/README.md)已備。1.4 是 NEW 需求，**不是 OLD 原始碼的固定間距**；OLD 遊戲行為仍「依原始碼推定／待確認」。R-05／R-F 程式審查與 T-058 使用者 R5 遊戲驗收未執行，T-058 未結案。R1～R4 僅保留歷史；D1–D8、既有 ID 與不重跑 OLD build 決策不變。

### T-058 R6：車距改為 1.3 倍數（2026-10-02）

使用者[最新決策](docs/evidence/T-058/fix-R6/USER_REPORT.md)要求前三節車廂沿既有路線分別距車頭 1.3／2.6／3.9 格，後續依 `1.3 × 節序`。R6 只改 `TrainBlockRoute.SPACING`，維持 R5 的跨格路線、車頭格內更新時機、路線不足時的停靠格回退、`TrainRoute` NEW 存讀、永久摧毀斷尾與暫時卸載保留。[R6 NEW build／22 項純 JVM 斷言](docs/evidence/T-058/fix-R6/README.md)最終退出 0，[最新固定 R6 包](docs/test-packages/T-058-R6/README.md)已備。1.3 是 NEW 需求，**不是 OLD 原始碼的固定間距**；OLD 遊戲行為仍「依原始碼推定／待確認」。R-05／R-F 程式審查與 T-058 使用者 R6 遊戲驗收未執行，T-058 未結案。R1～R5 僅保留歷史；D1–D8、既有 ID 與不重跑 OLD build 決策不變。

### T-058 R7：車距改為 1.35 倍數（2026-10-02）

使用者[最新決策](docs/evidence/T-058/fix-R7/USER_REPORT.md)要求前三節車廂沿既有路線分別距車頭 1.35／2.7／4.05 格，後續依 `1.35 × 節序`。R7 只改 `TrainBlockRoute.SPACING`，維持 R6 的跨格路線、車頭格內更新時機、路線不足時的停靠格回退、`TrainRoute` NEW 存讀、永久摧毀斷尾與暫時卸載保留。[R7 NEW build／22 項純 JVM 斷言](docs/evidence/T-058/fix-R7/README.md)退出 0，[最新固定 R7 包](docs/test-packages/T-058-R7/README.md)已備。1.35 是 NEW 需求，**不是 OLD 原始碼的固定間距**；OLD 遊戲行為仍「依原始碼推定／待確認」。R-05／R-F 程式審查與 T-058 使用者 R7 遊戲驗收未執行，T-058 未結案。R1～R6 僅保留歷史；D1–D8、既有 ID 與不重跑 OLD build 決策不變。

### T-058 使用者人工驗收通過（2026-10-02）

使用者[原文確認](docs/evidence/T-058/fix-R7/USER_CONFIRMATION.md)「**T-058驗證完成，測試通過**」；依人工確認即可結案規則，T-058 記為**人工測試通過／已結案**。前述 R1～R7 的失敗、修正與待驗收敘述為當時歷史，不倒改原始證據。使用者未提供受測 JAR SHA-256、逐例結果或量測數值，[R7 預備包](docs/test-packages/T-058-R7/README.md)的雜湊不可倒填為實際受測版，空白 `actual` 保留。R-05／R-F 獨立程式審查仍待執行；不由人工確認推定審查或其他任務通過。本輪只登錄使用者結果，沒有執行新 build、Minecraft 或程式變更；D1–D8 與 OLD build 不重跑決策不變。

### T-059／T-061／T-063／T-064 開發進度（2026-10-02）

[T-059](docs/evidence/T-059/README.md)已依 OLD 原始碼接上發射器槽 0 車頭與後續原版車編組；[T-061](docs/evidence/T-061/README.md)已接上 `destory_rail` 整列移除及未載入車廂待移除記錄。兩項 NEW build 退出 0，T-060／T-062 人工驗收和 R-05 程式審查待執行。[T-063](docs/evidence/T-063/README.md)已交來源權責表與 [T-122-v1 使用者測試包](docs/test-packages/T-122-v1/README.md)；全部實際案例待使用者執行。[T-064](docs/evidence/T-064/README.md)只修正發射器車頭加入世界前的初始朝向；其他執行期同步／重複問題尚待 T-122 觀察，未結案。OLD 未測行為仍為「依原始碼推定／待確認」；本輪未啟動 Minecraft、未重跑 OLD build，也未變更 D1–D8 或票證政策。

### T-066／T-068／T-070／T-072／T-073 開發進度（2026-10-02）

[T-066 十字](docs/evidence/T-066/README.md)、[T-068 左 Y](docs/evidence/T-068/README.md)、[T-070 右 Y](docs/evidence/T-070/README.md)已接上來源方向表與原 ID，NEW build 退出 0、96 項非遊戲路徑斷言通過；遊戲中的 4 向／紅石／速度／編組／材質仍待 T-067／T-069／T-071。[T-072](docs/evidence/T-072/README.md)以 OLD 原始碼確認 Block 實例只用座標儲存單車暫存且未保存，已交 [T-123-v1 使用者測試包](docs/test-packages/T-123-v1/README.md)；18 個實際案例均待使用者。[T-073](docs/evidence/T-073/README.md)在 NEW 改用每放置位置的專用方塊實體，以 UUID 區分暫存並寫入 NEW NBT。R-06 審查及 T-123／T-074 生命週期實測仍未完成；OLD 遊戲效果為「依原始碼推定／待確認」。沒有重跑 OLD build、啟動 Minecraft、改舊世界轉換或 D3 票證政策。

### T-106／T-107 完成與 T-060／T-062 測試確認（2026-10-02）

使用者[原文及更正](docs/evidence/T-106-T-107-T-060-T-062-user-confirmation/README.md)確認 T-106／T-107 已完成，**測試通過的是 T-060／T-062**，原訊息中的 T-061 為筆誤。兩項人工任務依確認規則記為**人工測試通過／已結案**；T-061 保持既有開發完成、R-05 待審。T-106／T-107 依使用者完成確認結案，但目前工作樹沒有可由 Agent 核對的固定包及建置證據，不記為 Agent 已製作或驗證。R-05 獨立程式審查仍待執行；未提供的受測 JAR 與逐例結果不倒填。本次只更新紀錄，沒有執行新 build、Minecraft 或程式變更；D1–D8 不變。

### T-064 來源續查（2026-10-02）

[續查紀錄](docs/evidence/T-064/CONTINUATION-2026-10-02.md)核對發射器、扳手、車頭、所有權及後續新增路口的 server 寫入路徑；未確認新的來源可證缺口。T-122-v1 的發射器來源與 JAR 指紋仍吻合原包，但七項人工案例結果仍空白；T-064 執行期分項與 R-05 審查待辦，不以靜態路徑推定遊戲通過。本輪離線 NEW build 在編譯前因沙箱外 Gradle wrapper 鎖檔退出 1；先前成功 build 不改寫成本輪成功。未改程式碼、未啟動 Minecraft。

### T-122 人工完成與 T-064 條件式開發結案（2026-10-02）

使用者[確認](docs/evidence/T-064/T-122-USER-CONFIRMATION.md) T-122 已驗證完成，並回答七項案例**未發現異常**。依人工確認規則，T-122 結案；逐例數值、受測 JAR 與 log 未提供，不倒填固定包的空白實際結果。T-064 初始朝向來源缺口已修正，其餘疑點在使用者觀察後無新增確認問題，按條件式規則**開發分項結案／無需新增補丁**。上一段「T-122 待執行」是確認前快照；R-05 獨立程式審查與 T-065 多人回歸仍待辦，本次沒有新 build 或程式變更。

### T-108 完成與 T-065 使用者驗證（2026-10-02）

使用者[原文](docs/evidence/T-108-T-065-user-confirmation/README.md)確認 T-108 已完成、T-065 已驗證完成。T-065 依人工確認規則**已結案**；使用者未說明是否發現異常，故不寫為「未發現異常」或逐案例通過。T-108 依使用者確認結案，但目前工作樹無可由 Agent 核對的固定包與建置證據，不冒充 Agent 製包結果。上一段 T-065 待辦是本次確認前快照；R-05 獨立程式審查仍待執行。本次只更新紀錄，沒有新 build、Minecraft 或程式變更。





