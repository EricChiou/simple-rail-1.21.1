# T-040 扳手換級失效修正 R1

> 後續使用者確認（2026-09-30）：[T-040 整項人工測試通過並結案](../../T-040-T-042-T-101-user-confirmation/README.md)。下列「待使用者重測」是 R1 開發交付當時的狀態；受測 JAR 與逐例數值未提供，R-04／R-F 程式複查仍待執行。

2026-09-30。使用者於 T-040 人工驗收回報：「`timer_holding_rail` 有礦車經過之後，就無法再使用板手修改 `level`，必須拆掉重新擺放後才能再用板手修改。」這是**實際使用者失敗回報**，未提供受測 JAR／逐例資料；不倒填其版本、方向或遊戲 log。T-040 整項尚未通過。本項只修已定位的計時軌扳手狀態覆寫，**沒有**執行遊戲或代填重測結果。

## 原因與修正範圍

[T-038 契約](../../T-038/DATA_AND_TIME.md)與 [T-035 U-09 來源分析](../../T-035/WRENCH_CONTRACT.md)已預警：礦車經過時 `TimerHoldingRail.onMinecartPass` 將 `direction` 設為礦車的水平行進方向；原 [Wrench.java](../../../../src/main/java/com/ericchiu/simplerail/item/Wrench.java) 先用點擊前 `state` 寫入新 `level`，再用同一舊 `state` 寫入旋轉後 `direction`。第二次寫入把 `level` 恢復為舊值。這是產品資料流與使用者症狀吻合的根因判定，不是由 Agent 在遊戲重現。

R1 僅對真實 `TimerHoldingRail` 型別，從同一點擊前狀態計算 `rotate(cycleLevel(state), "direction")`，**一次** `setBlock(..., Block.UPDATE_ALL)`：水平 `direction` 仍順時針旋轉，0–9 級仍循環，其他 BlockState 屬性不覆寫。原空格無礦車門檻、client 返回、扳手消耗與其他軌道／機器的既有 U-09 行為不變；沒有改 `TimerHoldingRail` 方塊／BE、D5 時鐘／讀回、資源、Gradle 或設定。原有其他複合操作疑點仍待各自任務處理。本輪 [單檔產品差異](wrench.patch)與 [全部產品輸入 SHA-256](product-inputs.json)供複查。

## 已執行證據

| 驗證 | 命令／退出碼 | 結果與限制 |
| --- | --- | --- |
| 生產 `Wrench.java` 配既有 30 個明示替身及新增 TimerHoldingRail 型別替身 | `powershell -NoProfile -ExecutionPolicy Bypass -File docs/evidence/T-040/fix-R1/run-isolated-test.ps1`；退出 **0**；[結果](results.json)、[編譯](compile.log) | [既有回歸](historical-regression.log) 388 案／1,575 判定通過；[計時軌新回歸](timer-regression.log) 207 判定通過，覆蓋四水平向×0–9 級、垂直向、供電屬性、佔用軌道與不消耗物品。替身測試不是 Minecraft 世界結果。 |
| NEW 指定版強制重編 | `.\gradlew.bat build --offline --console=plain --no-daemon --rerun-tasks`；退出 **0**；[完整 build log](new-build.log) | `:compileJava` 與 `:jar` 執行，`BUILD SUCCESSFUL`；普通 `:test NO-SOURCE`，不虛構 Gradle 單元測試。 |
| 製成固定包 | `Copy-Item build/libs/simplerail-1.0.0.jar docs/test-packages/T-040-R1/mods/simplerail-1.0.0.jar`；退出 **0**；[包與操作](../../../test-packages/T-040-R1/README.md) | [JAR 內 Wrench bytecode](packaged-wrench-bytecode.txt)含 `TimerHoldingRail` 分支；不代表 runtime 操作通過。 |

Minecraft **1.21.1**／NeoForge **21.1.251**／Simple Rail **1.0.0**／Java **21.0.12.1**／Gradle **9.2.1**。固定 JAR SHA-256 `E1C79C838055CEF0955E8B0CF46991DA51F24BBDDCA4FE2A1DA6C6891588EF39`。NEW HEAD `11916b69c3549504928f7cfa6790d59a2717b4b6` 加現存未提交 T-038／T-041 及本 R1 程式差異；不可單用 HEAD 對應該 JAR。[產品輸入名冊](product-inputs.json) SHA-256 `51A0F9C8DFFA3A741C45C8A81412AE127BB38BA5B078A272A148DDC5034C49EB`。

**狀態：R1 開發修正完成，R-04／R-F 獨立程式複查待執行；T-040 人工重測待使用者確認。** 使用者確認人工結果即可記錄，不需提供 log、截圖或其他證據；若重測失敗，再依開發修正→獨立複查→使用者重測流程處理。T-040 其他計時、真卸載與停服案例仍由使用者判定，不能用這次局部修正宣稱整項通過。
