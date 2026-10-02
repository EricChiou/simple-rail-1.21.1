# T-048／T-049／T-050／T-051／T-053 開發證據

> 歷史開發快照：本頁的熔爐礦車父類描述已由[使用者指定的 T-052 R2](../T-052/fix-R2/README.md)取代。現行車頭直接繼承一般 `Minecart`，原始 SHA／JAR 僅供追溯，請使用 R2 固定包。

狀態：五項**開發完成**；R-05 程式審查待執行；T-052、T-056、T-082、T-084 等遊戲驗收未由 Agent 執行。T-054／T-055 的疑點調查及修正界線另見 [T-054](../T-054/README.md) 與 [T-055](../T-055/README.md)。OLD 行為只依原始碼推定／待確認，不是 OLD 實測基線。

| 任務 | 交付、資料與責任 | 待遊戲驗證 |
| --- | --- | --- |
| T-048 | `ModEntities` 保留 `simplerail:locomotive_cart`；`LocomotiveCartEntity` 延伸 `MinecartFurnace`，父類保存燃料／推力，本類保存 NEW `TrainSchema`、`Facing`、`PrevPos`、`Train`、`TrainStops`。覆寫 `getDropItem`／拾取物品，讓父類 `VehicleEntity.destroy` 依掉落規則走單一路徑；未另掛 entity loot 表。碰撞分支按 OLD 原始碼移植。 | 燃料父類行為、實際碰撞／破壞與有名物品掉落由 T-052。 |
| T-049 | `FACING` 用內建 `BYTE`、`LINKABLE` 用內建 `BOOLEAN`，在 `defineSynchedData` 預設初始化；八方向 byte 0–7；只有 server tick／讀取更改朝向，NeoForge 實體一般生成與追蹤資料走已查證的標準途徑，沒有新增自訂頻道。 | 雙 client、重新進追蹤範圍、重連由 T-052／T-062。 |
| T-050 | client 專屬 `SimpleRailClient` 註冊 layer／renderer；依 OLD 六個盒子、UV 和 96×64 貼圖建模；renderer 依指定版 minecart 路徑插值、坡度及受損姿態接上八朝向。九類軌道所在模型中 33 個 JSON 為 cutout；common 入口不引用 client 類。 | 轉彎／坡度外觀、UV、透明材質由 T-052。 |
| T-051 | `LocomotiveCartItem` 保留原 item ID、堆疊 64；只接受 Simple Rail／原版 rails tag，server 單次生成，位置含升坡偏移，轉交自訂名稱，成功才減少一件；無效目標不生成或消耗。 | 物品數量、名稱、合法／非法目標與實際朝向由 T-052。 |
| T-053 | `TrainFormation` 保存有序 UUID／每車 stop；`TrainOwnershipData` 為各 `ServerLevel` 的 SavedData 所有權索引；`linkNewCart` 防重複，`unlinkCart` 與車頭永久移除釋放，暫時未載入的 UUID 保留。有診斷包 `/t054 link` 作最小建列車入口，正式扳手／發射器 UI 留 T-057／T-059。 | 跟車、晚載入、永久移除、跨維度／世界及重啟由 T-121／T-056。 |

差異位置：`src/main/java/com/ericchiu/simplerail/{SimpleRail.java,SimpleRailClient.java,entity/,registry/ModEntities.java,registry/ModItems.java,item/LocomotiveCartItem.java,client/}`。OLD 對照：`D:\workspace\java\simple-rail\src\main\java\ericchiu\simplerail\entity\LocomotiveCartEntity.java`、`link\LinkageManager.java`、`render\model\LocomotiveCartModel.java`；固定版 API 檢查依既有 T-013／T-014／T-015 來源快照。資料只支援 NEW 世界，D1 不做 OLD NBT 轉換；`destory_rail` 等註冊 ID 與 D7 無外部模組不變。

驗證命令與退出碼：

| 命令 | 結果 | 證據 |
| --- | --- | --- |
| `javac -d docs/evidence/T-048-055/classes src/main/java/com/ericchiu/simplerail/entity/Facing8.java src/main/java/com/ericchiu/simplerail/entity/TrainFormation.java docs/evidence/T-048-055/TrainFormationTest.java`；`java -cp docs/evidence/T-048-055/classes TrainFormationTest` | 均 0；41 項有序、重複、位移、晚載入與八方向斷言通過 | [原始碼](TrainFormationTest.java)、[編譯 log](test-compile.log)、[執行 log](test-run.log) |
| `.\gradlew.bat build --offline --no-configuration-cache --console plain` | 預設沙盒 C:\.gradle 鎖檔退出 1；授權環境初版退出 0；最終 SavedData 修改後退出 0 | [首次失敗](build-attempt-01.log)、[初版](build-attempt-02.log)、[最終](build-attempt-03.log) |
| `.\gradlew.bat build t054Jar --offline --no-configuration-cache --console plain -I docs/evidence/T-054/probe.init.gradle` | 退出 0；同一輪產品 build up-to-date、fixture 編譯與診斷 JAR 成功；Gradle `test NO-SOURCE` | [最終建置 log](../T-054/build-attempt-03.log) |
| `powershell -NoProfile -ExecutionPolicy Bypass -File docs/evidence/T-048-055/audit.ps1` | 退出 0；33 個軌道 cutout 模型、JAR 必要類／貼圖、產品與診斷 class 隔離 | [腳本](audit.ps1)、[SHA／來源指紋](audit.json) |

固定正式 JAR：[simplerail-1.0.0.jar](artifacts/simplerail-1.0.0.jar)，SHA-256 `63A31C515F0E4682AD16B78731ACF9653421723BA0254A487BC4063FF04D2766`。HEAD `11916b69c3549504928f7cfa6790d59a2717b4b6` **加未提交產品差異**，不能單由此 commit 重建；逐檔 SHA 在 `audit.json`。編譯和純 JVM 斷言不代表遊戲畫面、封包同步或世界存讀已通過。
