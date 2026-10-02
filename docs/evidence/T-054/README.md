# T-054 編組載入時序調查與 T-121 診斷包

> 後續使用者已[確認 T-054／T-055／T-056 驗證完成與 T-104 完成](../T-054-T-055-T-056-T-104-user-confirmation/README.md)；下文「T-121 待執行」是原開發交付時快照。T-121 亦已依使用者確認結案，但未提供有無異常或逐例結果；R-05 仍待審。

狀態：**開發調查與製包完成**；R-05 待審；T-121 使用者遊戲觀察待執行。來源推論不冒充 OLD 實測，所有 T-121 actual 欄位空白。操作包見 [T-054-v1](../../test-packages/T-054-v1/README.md)。

| 子疑點 | OLD 來源位置與依原始碼推定／待確認的風險 | NEW 靜態／非遊戲結論與缺口 |
| --- | --- | --- |
| 空／多節與順序 | `LocomotiveCartEntity.initTrain` 以靜態清單重建 `Car`，只加入當刻 `ServerWorld.getEntity(UUID)` 找到者；先後載入可改變成員。 | `TrainFormation` 41 項斷言含空列、重複與順序；實際遊戲次序待 T121-01／02。 |
| 跨區塊、晚載入、暫時 null | `initTrain` 忽略 null；`updateCartsStopPos` 遇 null 用 `subList(i, size).clear()`；`LinkageManager.checkCartLinkable` 把找不到車頭當作刪除靜態索引。程式路徑確定；發生頻率／具體遊戲結果未測。 | NEW 保存有序 UUID，`getEntity()==null` 不刪清單；停點保留；使用者需在 T121-03～05 區分卸載、晚載入及永久移除。 |
| 位置重建 | OLD `prevPos`／`Car.stopPos` 為記憶體欄位，save 只寫車廂 UUID／朝向；讀回後會取當刻位置重新建點。實際漂移待確認。 | NEW `PrevPos`／`TrainStops` 為 NEW schema，讀回缺欄安全；有序純 JVM 位移測試通過。真實保存／載入和車速待 T121-04／05。 |
| 跨維度、同程序世界切換 | OLD `LinkageManager.trains` 是全域 static `ConcurrentHashMap`，key 無維度或世界生命週期；可能跨作用域殘留，尚無 OLD 遊戲實測。 | NEW 順序隨實體保存、所有權在各 `ServerLevel` SavedData；無全域 static 編組 map。執行期隔離待 T121-06／07。 |
| 刪除與所有權 | OLD 查不到 UUID 與永久刪除混同；來源沒有可靠的卸載／永久刪除區分。 | NEW 永久移除釋放索引，卸載保留。車廂卸載時車頭移除後再連結的生命週期待 T121-08。 |

API 依據為既有 [T-013 固定版來源／探針](../T-013/README.md)：`ServerLevel.getEntity(UUID)` 只查已載入實體、`SavedData` 依 level 的資料儲存；本輪 `build` 對 NeoForge 21.1.251／Minecraft 1.21.1 的正式編譯已通過，**沒有啟動遊戲驗證 API 行為**。

診斷 fixture 位於 [`fixture/`](fixture/)，只以 [初始化腳本](probe.init.gradle) 疊加 common 入口和 OP 專用 `/t054 link`／`/t054 inspect`，正式來源與 Gradle 設定未增加診斷命令。前兩次建包失敗及退出碼 1 保留：[漏帶 `-I`](build-attempt-01.log)、[fixture 括號語法](build-attempt-02.log)；修正後同命令退出 0：[建置 log](build-attempt-03.log)。正式 JAR `63A31C...04D2766`，診斷 JAR `D48B2F529207B77B35E5FC02DAA2F0D4726313EB842E3A706167C0975E3C4477`；完整值及來源 SHA 見 [稽核](../T-048-055/audit.json)。普通 Gradle `test NO-SOURCE`；另有 41 項純 JVM 斷言，沒有人工測試結果。
