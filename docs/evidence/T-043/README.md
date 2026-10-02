# T-043 發射器觸發與車種辨識開發調查

2026-09-30。**開發調查交付完成；R-04 獨立程式審查待審；T-120 使用者遊戲觀察未執行。** 前置 T-012、T-013、T-004 的來源／案例交付已存在。本項只建立來源矩陣、非遊戲最小模型與診斷 JAR，不修改正式 `src/`、Gradle 設定或資源，不提前執行 T-044～T-046。OLD 1.16.5 行為均為**依原始碼推定／待確認**；不重跑 OLD build。

## 發現與修正准入

[I-043-01～07 來源／NEW API／差異與待觀察表](INVESTIGATION.md)逐項追蹤持續供電／重複更新、空槽、阻擋、四朝向位置、原版車種、字串、槽 0 車頭與 27 格不消耗。重要靜態結論：OLD `neighborChanged` 對每個仍有電的回呼直接進迴圈，沒有使用原版邊緣鎖；NEW 原版 `DispenserBlock` 則有 `TRIGGERED`＋4 tick。**何時真的收到重複回呼及是否重複生成**仍需 T-120 世界操作。OLD 依裸字串分辨箱子／爐／漏斗／TNT 車，而指定版 NEW `Item.toString()` 回傳含 namespace 的註冊名；逐字移植會錯判，已足以為 T-045 訂「按物品身分辨識」的修正規格，但沒有在 T-043 改正式程式。D4 的 27 格不消耗保留，T-043 不自行加節流或新車種政策。

## 最小重現包與已執行命令

- [診斷包入口／固定版本](../../test-packages/T-043-v1/README.md)、[安裝與命令](../../test-packages/T-043-v1/INSTALL.md)、[T120-01～08 完整操作／預期](../../test-packages/T-043-v1/CASES.md)及[空白結果表](../../test-packages/T-043-v1/results.json)已備。包內僅使用 Minecraft＋NeoForge＋Simple Rail；不需外部模組。`train_dispenser` 診斷方塊從**上方原版單箱**讀 27 格；這不是 D4 正式專用 BE／GUI。原版車依指定版 API 生成；車頭 token 用原版爐車作占位替身，只輸出 `link_plan`，真實編組由 T-059／T-060 驗收。診斷命令 `/t043 scan <pos>` 可分離手動掃描與真正 powered 鄰居回呼，伺服端 `[T043]` log 記來源、槽位、占位、生成及停止索引。
- NEW HEAD `11916b69c3549504928f7cfa6790d59a2717b4b6` 加既有未提交 T-038／T-041／T-040 R1 產品差異；[179 個產品輸入／JAR 範圍核對](scope.json)確認本項產品 source、Gradle、資源沒有新變動，正式 JAR SHA-256 保持 `E1C79C838055CEF0955E8B0CF46991DA51F24BBDDCA4FE2A1DA6C6891588EF39`。診斷 [fixture 原始碼](fixture/)與外部 [Gradle init script](probe.init.gradle)只在 `docs/evidence/T-043`，不加進正式 sourceSet；[manifest](../../test-packages/T-043-v1/manifest.json)固定六個 fixture／test／init 輸入的 SHA-256。
- 執行 `powershell -NoProfile -ExecutionPolicy Bypass -File docs/evidence/T-043/build.ps1`，其內完整命令為 `.\gradlew.bat build t043Jar testT043 --offline --console=plain --no-configuration-cache -I docs/evidence/T-043/probe.init.gradle`；[UTC／退出碼](build.json)為 **0**、[完整 log](build.log) 顯示正式 NEW `build`、診斷 fixture 編譯、JAR、`testT043` 均成功。普通 Gradle `test NO-SOURCE`；額外的純 JVM [模型測試](tests/evidence/t043/DispenserSourceModelTest.java)有 **18** 項明示斷言通過，覆蓋四向邊界、空格繼續、空格占位中止、槽 0／非 0 車頭與多回呼。此測試沒有載入或啟動 Minecraft，不可當世界或 GUI 驗證。
- 固定診斷 JAR [mods/simplerail-1.0.0-T043-probe.jar](../../test-packages/T-043-v1/mods/simplerail-1.0.0-T043-probe.jar) SHA-256 `4026BB07B15FA97179ABADDB211CAADD20FC69B752ADCA9665D07CA91B07E41A`，Minecraft **1.21.1**／NeoForge **21.1.251**／Simple Rail **1.0.0**／Java **21.0.12.1**／Gradle **9.2.1**；指定版來源 archive SHA-256 `236151EDEC930A89E78054FCB5551323761F801778305F290D0B74238C33693E`。此 JAR 含診斷 `SimpleRail`／`ModBlocks` 覆蓋與 `[T043]` 探針，但不含測試 main；不是正式發行 JAR。[包內容、指紋、空白結果與引用自查](audit.json)另存。

**證據界線：** 編譯證明 21.1.251 指定 API 可連結，模型證明所寫來源假說的可執行邊界，診斷 JAR 證明可建成固定包；它們不證明 Minecraft 啟動、原 1.16.5 遊戲實際行為、T-120 人工通過、正式 BE／GUI、車頭編組或真正重複生成。T-120、R-04、T-044～T-047 仍待各自任務。T-120 若觀察到與模型不同的結果，逐分項分析後才交 T-046 修正／回歸；未測不可寫成未重現。
