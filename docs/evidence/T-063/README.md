# T-063 client／server 權責調查

狀態：**開發調查與 T-122 最小重現包完成；R-05 待審；T-122 使用者觀察未執行**。OLD 只讀原始碼，所有舊行為均為「依原始碼推定／待確認」。指定 NEW 基線為 Minecraft 1.21.1、NeoForge 21.1.251、Java 21、mod 1.0.0；[固定 JAR／指紋](../../test-packages/T-122-v1/manifest.json)，[使用者操作包](../../test-packages/T-122-v1/README.md)／[ZIP](../../test-packages/T-122-v1.zip)。fixture 是案例中可重建的最小方塊／礦車／雙 client 場景及 server `/data` 查詢，不含另行注入的診斷程式；沒有遊戲啟動或回呼動態軌跡，因此執行期問題仍待 T-122。

| 子疑點／假說 | OLD 來源（依原始碼推定／待確認） | NEW 靜態結論與來源 | 待使用者觀察 |
| --- | --- | --- | --- |
| 軌道 callback 兩端重複改狀態／移除 | `block/DestoryRail.java`、`CrossRail.java` 的 `onMinecartPass` 無明確 side guard；`EjectRail.java`、`TimerHoldingRail.java` 有 guard | `block/DestoryRail.java`、`EjectRail.java`、`HoldingRail.java`、`OnewayRail.java`、`TimerHoldingRail.java` 的 `onMinecartPass` 在 server 才寫狀態／移動／移除。三種路口尚未實作，不能推定其權責正確 | T122-01／06；路口留階段 7 和 T-084 |
| 扳手互動重複寫入／回饋 | `item/Wrench.java` 有 client 提前回傳及 server 改狀態 | NEW `item/Wrench.java:44–86` client `SUCCESS`，server 執行連結／方塊狀態；粒子與聲音使用 `ServerLevel` 廣播 | T122-02，雙人同時操作觀察重複連結、方塊及回饋 |
| 車頭生成兩次／物品雙扣 | OLD `item/LocomotiveCart.java` 有 client 提前返回；發射器 `neighborChanged` 明確排除 client | NEW `item/LocomotiveCartItem.java:26–48` 只在 server `addFreshEntity`／扣物，`block/TrainDispenserBlock.java:85–152` 只在 `ServerLevel` 生成；雙 client 實際實體數仍未測 | T122-03／04 |
| 車頭 tick 雙寫、朝向初始不同步 | OLD `entity/LocomotiveCartEntity.java:115–136` 的 `updateFacingDirection()` 在 server guard 外；構造時依直軌設初始方向 | NEW `entity/LocomotiveCartEntity.java:169–224` 的車廂移動／朝向寫入只在 server。**已確認靜態缺口：**發射器生成車頭原本未像手持放置一樣先設初始朝向，東西軌道首次生成會先用預設 NORTH。T-064 已補生成前設值 | T122-05 的首幀與追蹤／重連兩端實測 |
| 刪除兩端執行或留索引 | OLD `block/DestoryRail.java` 沒有 side guard；`LocomotiveCartEntity.deleteTrain` 清除記憶體索引 | NEW `DestoryRail.java:44–60` server-only；`LocomotiveCartEntity.discardTrain` 與 `TrainCarRemovalHandler` server-only，已載入與暫時卸載分流。T-061 的生命週期效果尚未遊戲驗證 | T122-06、T-062／T-082 |
| GUI／計時狀態由 client 誤寫 | OLD `block/TrainDispenserBlock.java` GUI client 提前回傳；`TimerHoldingRail.java` 對通過事件有 side guard | NEW `TrainDispenserBlock.useWithoutItem` client 僅回傳；BE 由原版 menu 同步。`TimerHoldingRail` server 才處理過車，`TimerHoldingRailBlockEntity.serverTick` server-only。實際兩端槽位／倒數仍待測 | T122-07；詳細 GUI／讀回留 T-060／T-082 |

靜態調查使用 `rg -n 'isClientSide|ServerLevel|onMinecartPass|neighborChanged|addFreshEntity|setFacingFromServer'` 搜尋 OLD／NEW 的 `block`、`entity`、`item`、`blockentity` 來源；NEW 對指定版 API 的 `compileJava` 與 JAR 建置見 [本輪 log](../T-059/build.log)，退出碼 0，Gradle `test NO-SOURCE`。`EntityJoinLevelEvent` 的事件前插入順序另以 [既有固定版來源](../T-013/sources/target/net/minecraft/world/level/entity/PersistentEntitySectionManager.java) 核對。這些證據只證實來源路徑與可編譯，不能證明兩端實際無重複或同步延遲；T-122 的 actual 均為空白。

[交接包 JSON／JAR／ZIP 驗證](verify.txt)退出 0：192 個輸入指紋、7 個空白實際結果、JAR SHA 與 manifest 一致且 ZIP 含 `mods/` 路徑。首次 PowerShell 驗證因 `.Count` 展開方式誤判而退出 1，原輸出保留於 [verify-01.txt](verify-01.txt)；修正腳本計數後重驗通過，未改測試結果。
