# OLD 與 NEW 的連結／跟車差異

OLD 快照：[Wrench](../../T-057/old-Wrench.java)、[LocomotiveCartEntity](old-LocomotiveCartEntity.java)；後者 SHA-256 `BA3F2F9D83A31087E8A48CC9BF29ECB465CE2EFC34CD2CD86F558BB8E74F3588`，原路徑 `D:\workspace\java\simple-rail\src\main\java\ericchiu\simplerail\entity\LocomotiveCartEntity.java`。以下 OLD 結論僅**依原始碼推定／待確認**，不是 OLD 遊戲實測。

| 項目 | OLD 1.16.5 原始碼 | NEW R2 |
| --- | --- | --- |
| 扳手選車 | 點擊格與依玩家面向、點擊位置小數選出的相鄰格；先第一格、再第二格找車頭，對兩格車廂依序嘗試連結。 | 沿用兩格與先後順序；直接找已載入車頭，或由當前維度的 owner 資料找已連結車廂的車頭。這部分是來源相容，但內部資料來源不同。 |
| 編組身份／去重 | `LinkageManager` 是程序全域 static UUID map；`linkNewCart` 檢查 map 並向 `train` 追加 `Car`。 | 車頭保存有序 UUID，當前維度 `TrainOwnershipData` 保存車廂 owner；防重複及跨編組認領。另一車頭不作車廂，且只在真正新增時發粒子／音效。因此**不是完全照搬 OLD**。 |
| 跟車位置 | 車頭跨入新方塊時，第一節取得車頭上一格 `prevPos`；後節取得前節的舊 `stopPos`。`moveCarts()` 將車廂 `moveTo(stopPos + 0.5)` 的格中心，並清零速度；移動中另受 `detectRange=0.2` 的格內範圍限制。沒有 `1.2`／`1.5` 固定間距常數。 | 車頭每 tick 記錄實際世界位置路徑；第 n 節取沿路徑後方 `1.5 × n` 格之點並 `moveTo`，然後清零速度。弧長算法、頻率、存讀資料與 OLD 均不同；1.5／3.0／4.5 是此次使用者指定的 NEW 值。 |
| 車廂消失 | `updateCartsStopPos` 以 `getEntity(UUID)==null` 切掉該車與尾段，且只在車頭跨格更新時發生；無法從這段來源區分摧毀與暫時卸載。 | R1 起只在永久移除事件切斷該車及尾段；暫時卸載保留 UUID。若車頭未載入，待辦 cut 由 NEW SavedData 保存。結果意圖符合本次破壞要求，但觸發時序與資料生命週期不等同 OLD。 |
| 保存 | OLD `Train` 車廂 UUID 在車頭 NBT；`prevPos`、每節 `stopPos` 未見自訂保存，全域 map 亦非每世界保存。 | NEW 保存有序 `Train`、`PrevPos`、`TrainStops` 與 `TrainPath`；owner 與待處理 cut 在每維度 SavedData。D1 不做 OLD NBT／世界轉換。 |

因此對「目前連結與間距數值、邏輯是否完全依照 OLD」的答案是**否**。兩格選取與有序加入承接 OLD 來源；存儲、防重複、破壞時機、跟車取點與間距按已定需求重新實作。實際遊戲外觀、距離及事件時序待 T-058 使用者重測，不能由來源或 build 宣稱相同。
