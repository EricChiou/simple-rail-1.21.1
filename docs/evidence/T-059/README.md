# T-059 發射器車頭與自動編組

狀態：**開發完成；R-05 待審；T-060 人工驗收待執行**。OLD 行為僅依原始碼推定／待確認，未重跑 OLD build 或啟動 Minecraft。

OLD `TrainDispenserBlock.java` 的 `neighborChanged` 從槽 0 掃到 26；每格先查佔位，車頭樣板會生成車頭，但只有槽 0 車頭成為編組頭。普通礦車累積至掃描結束才依序連上槽 0 車頭；空格不終止掃描，其他格車頭不接管編組，多車頭的正式遊戲效果仍待 T-060。樣板不扣除。NEW 保留這些條件，並只將 `addFreshEntity` 成功的車加入本次編組。`TrainDispenserScan` 的四方向幾何及佔位順序沿用 T-045。

程式交付：`TrainDispenserBlock` 的自訂車頭建立、槽 0 選頭、原版車累積及事後連結。初始朝向在加入世界前依放置軌道設定；這同時處理 T-063 靜態查出的初次同步缺口，詳 T-064。

[工作樹相對索引差異](product.diff)供複查。此專案原本已有 staged／unstaged 歷史改動，該 diff 是目前工作樹相對 Git index 的快照，可能含本輪以前的未提交內容；本輪具體新增路徑以上段和 T-064 說明為準，未重設或提交工作樹。

驗證：`build-result.txt` 記錄 `./gradlew.bat build --console=plain`（Windows 實際為 `.\\gradlew.bat`），退出碼 0；[原始 log](build.log) 顯示 `compileJava`、`jar`、`build` 成功，`test NO-SOURCE`，故沒有宣稱自動化遊戲測試。固定產物與 dirty 工作樹指紋見 [T-122 manifest](../../test-packages/T-122-v1/manifest.json)。T-106 尚需製作 T-060 專用測試包；此處的 T-122 包只供權責疑點觀察。
