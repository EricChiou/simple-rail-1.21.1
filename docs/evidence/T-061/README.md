# T-061 destory_rail 整列移除

狀態：**開發完成；R-05 待審；T-062 人工驗收待執行**。OLD `DestoryRail.java` 在車頭經過時呼叫 `LocomotiveCartEntity.deleteTrain()`；後者先清理 `LinkageManager`，再移除列內車廂及車頭。這是依原始碼推定／待確認，不是 OLD 遊戲實測。

NEW 保留 `destory_rail` ID、一般礦車 `discard()`、供電判斷及原有煙霧／聲音。車頭經過時，`discardTrain` 複製該車頭有序 UUID 清單，先篩除所有權明確屬於其他車頭的 ID，對已載入車廂收集待移除實體，對未載入車廂保存待移除 UUID，再先釋放該車頭所有權／待斷開索引，最後逐車廂與車頭 `discard()`。此順序避免車廂離開事件在整列刪除中途切斷尾節。未載入車廂下一次加入該維度時，由 server 端 `EntityJoinLevelEvent` 取消加入；依指定版 `PersistentEntitySectionManager.addEntity`，事件先於 UUID／section 插入，取消後不進入 section。這一段的實際存讀及跨區塊結果仍待 T-062／T-082 人工測試。

沒有新增或更改區塊票證政策。`PendingRemovals` 是 NEW 自身 SavedData 的待刪除標記，並非舊 NBT 轉換。JAR 和工作樹指紋見 [T-122 manifest](../../test-packages/T-122-v1/manifest.json)；本次共用 NEW [build log](../T-059/build.log) 退出 0、`test NO-SOURCE`。T-107 尚須製作 T-062 專用測試包。

[工作樹相對索引差異](product.diff)供複查；索引含既有 staged／unstaged 歷史，該 diff 可能包含本輪以前未提交內容，不代表所有列出的行均由 T-061 新增。原工作樹未重設或提交。
