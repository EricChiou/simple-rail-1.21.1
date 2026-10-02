# T-064 續查：現行來源的端權責與待觀察項目

日期：2026-10-02。範圍只涵蓋 T-064 的 client／server 重複寫入與同步責任；不代替 T-122 使用者在 dedicated server＋雙 client 的實測或 R-05 獨立審查。

| 路徑 | 本次來源核對 | 結論界線 |
| --- | --- | --- |
| `block/TrainDispenserBlock.java` | `neighborChanged` 僅在 `ServerLevel` 觸發樣板掃描；車頭在 `addFreshEntity` 前依軌道方向呼叫 `setFacingFromServer`；`useWithoutItem` 的 client 分支只回傳成功 | 可確認 server 寫入路徑；無法從來源證明兩個 client 的首幀、重連或每次紅石鄰居事件的生成次數 |
| `item/LocomotiveCartItem.java`、`item/Wrench.java` | 生成、物品扣除、編組連結、軌道狀態修改及聲光回饋均在 `ServerLevel` 路徑；client 互動只回傳結果 | 未見新的雙端權威寫入路徑；雙人同時操作的實體／回饋數仍須 T122-02／03 |
| `entity/LocomotiveCartEntity.java`、`entity/TrainCarRemovalHandler.java`、`entity/TrainOwnershipData.java` | 車頭 tick 的朝向、編組移動與索引變更走 server；碰撞中礦車速度修改有 client guard；移除／重新加入事件限定 `ServerLevel`；所有權索引屬每維度 server SavedData | 來源支持單端寫入設計；不能證明執行期不存在幽靈車、重複刪除或追蹤延遲 |
| `block/JunctionRail.java`、`block/AbstractYCrossRail.java`、`blockentity/JunctionRailBlockEntity.java` | T-063 之後新增的路口過車／暫存 `put`、`take` 只由 `JunctionRail.onMinecartPass` 的 `ServerLevel` 分支呼叫；Y 路口紅石狀態更新有 client guard | 本次未確認新的雙端寫入缺口；路口生命週期與同步仍按 T-123／T-074／T-084，不能以此靜態檢查結案 |

固定包核對：`docs/test-packages/T-122-v1/manifest.json` 的 `TrainDispenserBlock.java` SHA-256 為 `0D6FB5D5DBA1C79B4296F8A0AA9243F5F2A3255FA40FB5AEA88B1E150E4E5F64`，現行檔案計算值相同。包內 JAR 計算 SHA-256 為 `8FE277F07B81B737189F8D12524745B7CA90962107F9F9E635884797F9EDE581`，與 manifest 相同。這證明 T-064 初始朝向修正仍在 T-122-v1 包中，不表示它是目前所有後續任務的最新 JAR。`results.json` 的 T122-01～07 `actual` 均為 `null`／「待使用者執行」；沒有執行期問題報告可據以做進一步條件式修正或結案。

NEW build 嘗試命令：`& .\gradlew.bat --offline build *> docs/evidence/T-064/build-continuation.log`，**退出碼 1**。Gradle wrapper 在編譯前嘗試於沙箱外 `C:\.gradle\wrapper\dists\gradle-9.2.1-bin\...\gradle-9.2.1-bin.zip.lck` 建立鎖檔而失敗；[完整輸出](build-continuation.log)與[退出碼](build-continuation.exit.txt)保留。此次沒有編譯或測試成功結果。先前 [T-059 共用 NEW build](../T-059/build.log) 的 `BUILD SUCCESSFUL` 與 T-122 固定包證據仍保留，不能充當這次重跑結果；本次沒有變更產品程式碼。

結論：T-064 已確認的初始朝向缺口維持修正；這輪來源續查未確認新的可獨立修正缺陷。執行期分項仍須 T-122 使用者對應案例結果；R-05 獨立審查待執行，T-064 **不結案**。收到實際異常後，只修正有證據的分項並交 Review Agent 複查、使用者重測。

後續[使用者確認](T-122-USER-CONFIRMATION.md) T-122 全項驗證完成且未發現異常；上段「仍須 T-122／不結案」是確認前快照。T-064 其餘分項現依條件式規則作無需新增補丁的開發結案，R-05／T-065 尚未完成。
