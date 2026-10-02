# T-055 編組恢復與作用範圍的條件式修正

> 後續使用者已[確認 T-055 驗證完成](../T-054-T-055-T-056-T-104-user-confirmation/README.md)。原下文執行期待 T-121 是開發交付時快照；T-121 已依使用者確認結案，但未提供分項有無異常，不能補寫「未重現」。R-05 程式審查仍待執行。

狀態：**已確認靜態分項的開發修正完成**；R-05 程式審查及 T-121／T-056 使用者執行期回歸待執行。沒有把尚未觀察到的遊戲問題記為已重現或已修復。

| 已確認的來源／設計問題 | 最小修正與可核對點 | 還待確認 |
| --- | --- | --- |
| OLD `initTrain`／`updateCartsStopPos` 以 `getEntity(UUID)==null` 直接縮短清單，將未載入等同永久刪除。 | `TrainFormation` 有序 UUID 是權威資料；`moveLoadedCarts` 僅略過未載入者，不刪 UUID；`advance` 保留未解析 stop。41 項純 JVM 測試包括保留晚載入 ID。 | 實際跨 chunk 時序、長時間跟車由 T-121／T-056。 |
| OLD `LinkageManager.trains` 全域 static 無維度／存檔作用域。 | 編組在車頭的 NEW 實體存檔；所有權索引在每 `ServerLevel` 的 `TrainOwnershipData` SavedData。無 static mutable map；車頭永久移除以 owner UUID 釋放所有 claim，含未載入車廂；卸載不釋放。 | 同程序切換世界、跨維度同時運作、重新進入世界由 T-121。 |
| 本輪初版曾考慮把 owner UUID 寫入車廂 persistent tag；若車廂卸載時拆除車頭，tag 無法立即清除，會造成永久誤鎖。這是開發中的**靜態設計缺陷**，不是 OLD 遊戲重現。 | 最終產品不用車廂 tag；採 per-level `TrainOwnershipData.releaseTrain`，可解除尚未載入車廂。初版 build/JAR 只保留在開發 log，不作測試包；正式 JAR 另固定。 | 車頭移除／車廂晚載入的真實結果由 T121-08。 |
| OLD `prevPos`／`stopPos` 沒有保存。 | NEW 實體寫 `PrevPos`、`TrainStops`；僅 NEW schema，缺鍵安全；不讀舊 NBT。 | 真實保存週期與重新載入的車廂位置待 T-121。 |

差異為 [`LocomotiveCartEntity.java`](../../../src/main/java/com/ericchiu/simplerail/entity/LocomotiveCartEntity.java)、[`TrainFormation.java`](../../../src/main/java/com/ericchiu/simplerail/entity/TrainFormation.java)、[`TrainOwnershipData.java`](../../../src/main/java/com/ericchiu/simplerail/entity/TrainOwnershipData.java)。[T-054 分項來源／缺口](../T-054/README.md)先確認上述可靜態判定的問題；執行期才能判斷的分項只列待確認，不追加猜測式補丁。最終 NEW build 退出 0、41 項非遊戲斷言通過；原始 log 與固定正式 JAR 見 [共同證據](../T-048-055/README.md)。D1／D2／D6 不變；T-121 使用者結果回來後如有缺陷，再由開發修正、R-05 複查及使用者重測。
