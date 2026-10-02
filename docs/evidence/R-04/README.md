# R-04 獨立程式審查（2026-10-01）

**指定開發範圍通過：T-037～T-039、T-041、T-043～T-046；沒有新增 S0–S3 審查發現。** T-040 R1「經車後扳手換級被方向寫回覆蓋」的 R-F 程式複查亦通過。

本結論涵蓋現行計時／容器程式、調查與條件式無需補丁判定、已保存診斷包及測例覆蓋。T-100／T-101／T-102 維持使用者完成確認結案，未取得其可核對產物，**不簽成 Agent 製包驗證通過**。T-119／T-040／T-042／T-120／T-047 的使用者人工通過結案全部保留；沒有倒填其受測 JAR 或逐案數值。

## 固定輸入與獨立性

受審 HEAD 為 `11916b69c3549504928f7cfa6790d59a2717b4b6`，加審查開始時已暫存的產品／文件變更；不能只用 HEAD 指認產品。版本為 Minecraft 1.21.1、NeoForge 21.1.251、Simple Rail 1.0.0、Java 21、All Rights Reserved。

本審查者未實作受審產品。本輪只新增 R-04 審查工具、證據與報告，更新 TASK／REVIEW／MIGRATION；未改 Java／資源／Gradle、歷史證據、使用者確認或固定包，未執行 stage／reset／commit。[reviewed-inputs.json](reviewed-inputs.json) 保存 431 份產品、開發證據、包及確認資料指紋；[test-inputs.json](test-inputs.json) 保存重新編譯的實際來源／替身／依賴。審查前主文件與 index 名冊保存在 [before](before/)。收尾觀察到部分 R-04 新檔已加入 index，原因未判定；原有 index 項目逐項未變，新增項目與觀察時間見 [index-observation.json](index-observation.json)，本輪未重設這些變動。

| 固定產物 | SHA-256 |
| --- | --- |
| T-037 診斷包 | `AAF9977E094981A481305DCDCF6C60694931FFD3483A29C9A6A5B31BB10415C7` |
| T-038 計時正式版 | `EABD253F9EA50B58B62A5311D2B7289F22AA1DEECADF9059FFF76A736DEAE21B` |
| T-040 R1 重測包 | `E1C79C838055CEF0955E8B0CF46991DA51F24BBDDCA4FE2A1DA6C6891588EF39` |
| T-043 診斷包 | `4026BB07B15FA97179ABADDB211CAADD20FC69B752ADCA9665D07CA91B07E41A` |
| T-044 容器正式版 | `9B0107CA2DA90AA98946E12DB51A6508E7A927479A6F50D6305B1BA2E288C35A` |
| T-045／T-046 現行整合版 | `61B933A80F9B984E9AF35D7E55713803DF36328371D6B08CC02A63ADCEDA6C1E` |

六個雜湊均已重核。`build/libs` 與 T-045 固定 JAR 相同；其 **34 個 class 的完整 `javap -p -c` 輸出與本輪重新編譯的現行來源一致**，全部現行 resources 亦逐檔對上。這是程式／資源對應證據，不將不同編譯 debug 資料或 JAR 時間戳宣稱成位元組可重現 build。T-041 單獨交付時的 `46D87F…` 僅為歷史 build 記錄；本次不假裝重新取得該中間 JAR。

## 逐項審查

| 範圍 | 結論及核對要點 |
| --- | --- |
| T-037 調查／診斷 | 通過。五項疑點各有 OLD 來源、NEW API／模型及修正准入；int 乘法溢位、缺 UUID、未標髒與保存到卸載間活動時間分開處理。T119-01～07 含首次／缺鍵／dirty 控制／上界／重複保存／真卸載／離線；SP／DS 共 13 變體。合成 UUID、arm 注入及診斷來源不冒充正式礦車停車或 OLD 實測。 |
| T-038 實際時間及 NBT | 通過。`System.nanoTime` 差值按真實毫秒遞減，不按 tick 計數；長整數秒換算涵蓋 INT_MAX。新版 `holding_timer` 的 version／UUID／long 範圍均防護，無效或缺鍵回 idle；無舊格式轉換。新 UUID 捕捉當次設定、同 UUID 到期後不重新等待；序列化不重設時間，讀回先暫停，首次有效活動恢復。 |
| T-038 保存／卸載接線 | 通過。新車 `setChanged`、活動時 `blockEntityChanged`、卸載時直接對事件 chunk `setUnsaved(true)`；遍歷使用 `changed \|=`，不短路漏掉後續計時器。固定 API 明確為 **ChunkEvent.Unload → save → ServerLevel.unload**，故凍結發生在最終序列化前；未請求重新載入 chunk 或變更 D3 票證。 |
| T-038 軌道／端權責 | 通過。0 級／缺 BE 採既有旁路；1–9 級新車記方向並停車，同車到期按方向 ×0.4 放行。client 不寫狀態、不讀 COMMON 作決策，ticker 檢查 BE 型別。保留六向 state 與非高速禁坡；不將繼承動力軌物理說成已被取消。 |
| T-039 條件式保存修正 | 通過。I-037-01～05 均可追到 T-038 的具體防護與時間／保存順序證據，無需另加補丁的判定成立；沒有把 OLD 的可能遺失描述為已遊戲重現，也沒有把 T-119 診斷確認套為正式 JAR 驗收。 |
| T-040 R1／R-F | 通過。只對 `TimerHoldingRail` 從同一 state 計算 `rotate(cycleLevel(state), "direction")` 後一次寫回，避免第二次方向更新恢復舊 level；0–9、四水平向、垂直向、佔用門檻與供電屬性均有隔離回歸。其他方塊 U-09 未擅自擴改。固定重測包四案例涵蓋經車、9→0、佔用與 SP／DS。 |
| T-041 訊號計時器 | 通過已交付排程規格。0 級輸出固定 0 並清 POWERED；1–9 級弱訊號 15，高 10 ticks、一般低段 `秒數×20−10`；低段最少 1、上限 INT_MAX 的邊界已明訂。BE 僅補缺少的排程，方塊 tick 負責切換／續排，client 無 ticker。reload／換級不改寫現有排程；`block_ticks` 保存相對 delay，缺排程按 POWERED 補建，不另造計時 NBT。未宣稱未提供的重啟相位實測數值。 |
| T-043 調查／診斷 | 通過。七項疑點與 T120-01～08 對應完整：供電回呼、空槽、占位先查且命中終止、四向座標、Item 身分辨識、第 0 格連結模型、不消耗。上方原版單箱、爐車替身及 `link_plan` 限制明示；診斷不冒充正式 BE／GUI／編組。 |
| T-044 容器／GUI／同步 | 通過。專用 BE 與同名 BLOCK_ENTITY_TYPE 正確註冊；固定 27 格，讀取前重建槽位，`ContainerHelper` 帶 registry provider 保存 ItemStack。父類保存名稱／鎖、setItem／removeItem 標髒，額外移除／清空亦標髒。server 開啟 `ChestMenu.threeRows`，原版 GENERIC_9x3 對應 ContainerScreen，27 個樣板槽及 36 玩家槽由原版 menu 同步；不需自訂 menu ID 或 BE 廣播 NBT。父類 onRemove 走 Container 掉落，不強轉為九格 Dispenser BE。 |
| T-045 生成／不消耗 | 通過。僅 server 且當下有電的鄰居回呼立即掃描，父類 tick／dispenseFrom 空覆寫；每槽先查 AbstractMinecart AABB，再讀樣板，空槽不自行終止。四方向及 0～26 索引對上 OLD 公式；CHEST／FURNACE／HOPPER／TNT 按 Items 身分辨識，其他 MinecartItem 按已交付來源規格回落普通車。生成傳 ItemStack.EMPTY，不修改樣板或複製其資料元件；無額外節流／消耗。 |
| T-046 條件式觸發／辨識修正 | 通過。裸字串誤判及父類九格／延遲消耗路徑已由 T-045 避開；其餘按來源規格和 T-120 整項「未發現異常」確認結案，現無已確認需本項新補丁的問題。自訂車頭明示跳過，正式車頭／編組仍屬 T-048／T-059／T-060。 |

## 本輪驗證

執行 `powershell -NoProfile -ExecutionPolicy Bypass -File docs/evidence/R-04/run-tests.ps1`：8 次 javac、8 次 plain JVM 主程式均退出 0，命令／時間／退出碼見 [commands.json](commands.json)。全部測試輸出寫入 R-04，未覆寫開發 log。

| 非遊戲測試 | 判定數 | 界線 |
| --- | ---: | --- |
| T-037 TimerInvestigationTest | 1,049 | 診斷時間模型＋真實 NEW CompoundTag；無遊戲 bootstrap |
| T-038 HoldingTimerTest | 1,055 | 當前產品時間／編解碼＋真實 NEW NBT |
| T-038 TimerRailHooksTest | 1,526 | 當前軌道／BE 配明示 MC／NBT 替身；不是世界保存測試 |
| T-041 SignalTimerTimingTest | 250,009 | 當前時間算式、邊界與單調性；不執行遊戲排程 |
| T-035 WrenchHooksTest | 1,575 | 原扳手回歸 388 案；使用明示替身 |
| T-040 TimerWrenchRegressionTest | 207 | 當前產品扳手修正；計時軌型別為替身 |
| T-043 DispenserSourceModelTest | 18 | 診斷來源模型，不是正式生成或 OLD 實測 |
| T-045 TrainDispenserScanTest | 15 | 當前純掃描器；不建立遊戲實體 |

合計 **255,454 項判定通過**。另以真實固定版 API 編譯全部 **28 份產品 Java** 成功，未執行所編出的遊戲類別。本輪未重跑 Gradle build；已核對開發保存的 build 紀錄，最終使用 [T-045 build-03](../T-045/build-03.log)。普通 Gradle `test NO-SOURCE` 不計成測試通過。

執行 [verify.ps1](verify.ps1)：**177 項檢查通過**，見 [checks.json](checks.json)／[verify.log](verify.log)，包括固定產物、34 class 對應、resources、卸載 API 次序、BE 註冊、水平模型與原人工結果欄未填寫。[API 快照](api/net/minecraft/) 取自固定來源 archive `236151EDEC930A89E78054FCB5551323761F801778305F290D0B74238C33693E`，各 entry 雜湊記於 checks.json。

第一次靜態檢查將 `event.getChunk()` 的事件存取誤當成向 Level 請求 chunk，造成一項誤報；已縮限辨識式，產品未改。失敗紀錄保留於 [checks-attempt-01.json](checks-attempt-01.json)，不把工具誤報列為產品缺陷。

## 保留限制與交接

- 沒有啟動 Minecraft client、dedicated server、GameTest 或 OLD build；程式審查與 JVM 測試不新增人工驗收結果。
- [T-119／T-100](../T-039/USER_CONFIRMATION.md)、[T-040／T-042／T-101](../T-040-T-042-T-101-user-confirmation/README.md)、[T-120](../T-120/USER_CONFIRMATION.md)、[T-102／T-047](../T-102-T-047-user-confirmation/README.md) 的確認照原文保留，不要求附件或重開已結案項目。診斷包原逐例 actual 仍為 null。
- M-01 的正式量測點／約 3 秒容差、訊號極大設定飽和後的產品期望及未提供的逐例相位數值未由本審查補定；不影響已接受的使用者結案，也不能外推為後續整合的定量保證。
- U-07／其他方塊 U-09 保留；僅 T-040 R1 已授權局部修正通過。垂直發射器與其他非自然 state 模型仍依既有 I-021／T-081 名冊處理，本次八個水平 selector 齊備不等於全部六向模型已補齊。
- T-060 車頭／編組、T-082 專用 BE 存讀、T-083 真卸載／離線整合、T-084 多人整合及最終候選仍依原任務驗收。D1–D8、126 項任務與正式依賴不變。

收尾完整性見 [final-check.json](final-check.json)：產品／受審歷史輸入及原有 Git index 項目保持審查前內容，文件引用與任務結構核對通過。
