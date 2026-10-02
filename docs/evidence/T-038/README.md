# T-038 實作 timer_holding_rail 與計時方塊實體

2026-09-30。**開發完成；R-04 程式審查待審；T-040／T-083 人工未執行。** [資料與時間契約](DATA_AND_TIME.md)定義功能及未知範圍。本項只實作 T-038；T-039 的條件式修正／無需補丁判定尚未開始。沒有 OLD build、Minecraft client／server、GameTest 或遊戲案例。

| 完成條件 | 交付與證據 | 界線 |
| --- | --- | --- |
| 同 ID 與專用 BE | 同名 `simplerail:timer_holding_rail` BLOCK_ENTITY_TYPE，正式方塊 factory 已換；[來源指紋](product-after.json)、[JAR](artifacts/simplerail-1.0.0.jar) | 方塊／物品 ID、其他方塊與資源未改；JAR 僅供後續審查／製包，不冒充使用者測試包 |
| 0–9、方向、停車與放行 | [TimerHoldingRail](../../../src/main/java/com/ericchiu/simplerail/block/TimerHoldingRail.java) 和 [方塊實體](../../../src/main/java/com/ericchiu/simplerail/blockentity/TimerHoldingRailBlockEntity.java)；9×6×2 狀態／回呼矩陣的隔離測試 | 隔離環境使用明示外部替身；父類移動、紅石及遊戲 tick 實效仍待使用者 |
| 正式設定及實際時間 | 等級 1–9 使用 T-020 COMMON snapshot；[HoldingTimer](../../../src/main/java/com/ericchiu/simplerail/blockentity/HoldingTimer.java) 的單調時鐘與 long 毫秒換算 | reload 對活動計時不回寫；tick 不是秒數來源；正式容許誤差 M-01 待技術定義 |
| 新資料存讀與卸載暫停 | [HoldingTimerData](../../../src/main/java/com/ericchiu/simplerail/blockentity/HoldingTimerData.java) 的 NEW 版號 schema；卸載事件在來源固定版 save 前凍結；讀回先暫停後恢復 | 不讀 OLD NBT／不轉換舊世界；世界實際持久化、卸載及離線邊界留人工驗收 |
| build 與非遊戲測試 | [build-01](build-01.json) 因受限 wrapper 鎖退出 1；[build-02](build-02.json)、[build-03](build-03.json) 退出 0。正式產品時間與真實 NEW NBT 1,055 判定；實際產品軌道／BE 的隔離 hook 1,526 判定（[結果](hooks-04.json)） | 普通 Gradle `test NO-SOURCE`；Hook 外部模型是替身，不能推定 Minecraft 啟動或執行期保存通過 |
| 指紋／任務一致性 | [audit.json](audit.json) 核對七份預期 Java、舊資源／Gradle 不變、HEAD／index、固定 JAR、九階段／126 項及依賴 | 自查不等於獨立審查或人工測試 |

實際成功命令：

```powershell
.\gradlew.bat build testT038 --offline --console=plain --no-configuration-cache -I docs/evidence/T-038/tests.init.gradle
powershell -NoProfile -ExecutionPolicy Bypass -File docs/evidence/T-038/run-hooks.ps1 -Attempt 4
```

Gradle 測試在 plain JVM 使用生產 `HoldingTimer`／`HoldingTimerData`、實際固定版 `CompoundTag`，無 Minecraft bootstrap。Hook 測試把實際四個產品 Java 與 25 份明示 Minecraft／NBT／COMMON／registry 替身一起編譯，觀察呼叫次序、各等級、方向、兩種供電值、伺服器 client 邊界、末次保存及重新讀回。Hook 曾因替身 `MapCodec` 覆蓋真實 NBT 造成 JVM linkage／驗證錯誤；[01–03 原始記錄](hooks-01.json)及其 log 保留，移除衝突、將 NBT 替身明示後第 04 次通過。此失敗屬隔離工具，不是正式產品 build 失敗。

HEAD 與 T-037 時一致為 `11916b69c3549504928f7cfa6790d59a2717b4b6`，本次產品檔案尚未提交，全部七份 Java 來源已複製到 [sources](sources/) 並保存 SHA-256；已有 R-03 審查 staged 差異與 T-037 歷史證據原樣保留。固定整合 JAR SHA-256 **`EABD253F9EA50B58B62A5311D2B7289F22AA1DEECADF9059FFF76A736DEAE21B`**。普通 Gradle build 退出 0，`test NO-SOURCE` 如實紀錄，沒有替成「Gradle 標準測試通過」。

本項的已確認缺鍵／上限／標髒設計仍須在 T-039 對正式程式逐項核對，不能因本項完成自動將 T-039 記完成或把 T-119 視為已操作。R-04 審查差異、時鐘及保存設計；T-040、T-083 的礦車、世界與時間結果只能由使用者回報，T-100 正式測試包另行製作。U-08／U-09 意圖與後續模型等缺口仍依原任務追蹤。

具體而言，現行扳手從初始 state 先寫計時 level，再在水平 `direction` 上以初始 level 寫旋轉，會覆蓋剛寫入的級數；這是 U-09 待決對 T-040 扳手換級案例的局部阻礙，見 [契約](DATA_AND_TIME.md)。本項沒有修改既有扳手或代替使用者決定 U-09。
