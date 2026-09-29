# T-033 destory_rail 一般礦車移除交付

2026-09-29。**開發完成；R-03 待審；T-034 人工／T-098 包未執行**。只執行 T-033；未啟動 Minecraft、GameTest、client／dedicated server，未重跑 OLD build、未實作 T-061 整列刪除。OLD build 由使用者先前驗證，本次流程不重跑；舊版行為均「依原始碼推定／待確認」。

## 自身完成判定

| 完成要求 | 實際交付／證據 | 限制 |
| --- | --- | --- |
| 一般礦車移除／動力條件 | [DestoryRail](../../../src/main/java/com/ericchiu/simplerail/block/DestoryRail.java)、[來源／API／狀態／副作用](RAIL_CONTRACT.md)、[四列條件矩陣](behavior-matrix.json) | server、未移除目標、powered OR !needPower 才 discard；讀當前設定、不依 stored need_power。舊父類移除副作用未驗證 |
| 聲音與粒子 | rail 整數座標 + (0.5,0.75,0.5)；一顆 LARGE_SMOKE、零 spread／speed；GENERIC_BURN／BLOCKS、volume=4／pitch=4 | 指定版 ServerLevel.sendParticles／playSound 廣播 API；不是已觀察到玩家收到或聽見 |
| 註冊／預設／設定 | 原 destory_rail factory、need_power 預設 false、server 新放置投影、同方塊更新／重載不改投影；附加 pickaxe tag | 保留 11 方塊／13 物品、配方／loot／模型 ID、D1–D8；只新增 DestoryRail、修改 ModBlocks 與 pickaxe tag，Gradle／其他產品不變 |
| 真實 API 可建置 | [命令／時間／退出碼](build-01.json)、[完整 build log](build-01.log)、[bytecode](DestoryRail-bytecode.txt)、[指定來源 manifest](source-manifest.json) | NEW build 退出 0；Gradle test **NO-SOURCE**，不冒充測試執行／遊戲通過 |
| 非遊戲驗證 | [實際產品 hook 測試](DestoryRailHooksTest.java)、[命令／退出碼／26 本地替身範圍](hooks-test.json)、[結果](hooks-test-01.log) | javac／java 各退出 0；四條件列、640 次回呼、8,173 判定。只檢查分派與參數，不測真實 inventory／loot／乘客／封包／FML |
| 差異／固定產物 | [完整未提交差異](source.diff)、[產品／Gradle 指紋](source-fingerprints.json)、[200 靜態核對](audit-results-01.json)、[固定 JAR](artifacts/simplerail-1.0.0.jar)、[版本／SHA-256](artifact.json) | 149 資源逐一比對 JAR、19 指定來源逐一比對 archive；原 T-027／T-029／T-031 JAR 保留，index 未變、未 stage／reset／commit |

T-033 自身建置、來源／API 對照、差異／log／行為表交付要求已達成，僅更新「開發完成」。R-03／T-034／T-098 及整體功能交付未完成。文件／任務編號／依賴／九階段／覆蓋與 Markdown 自查見 [doc-check.json](doc-check.json)。

固定 JAR SHA-256：`336FAFDF1237127E613E3B300BCD9263191A377284A8EB7B7BA77DE124A24473`。HEAD `8bd977dbb9f9000411ae5f4d10750228e5f33560`；含未提交變更，HEAD 單獨不能表示此產物，須合併差異／指紋。版本：MC 1.21.1、NeoForge 21.1.251、Simple Rail 1.0.0、Java toolchain 21、Gradle 9.2.1、ModDevGradle 2.0.147、Parchment 2024.11.17、All Rights Reserved。

## 尚未驗證與後續

- `discard` 不走礦車受傷／destroy 的車體物品掉落流程；**目標版容器父類仍會掉內容**，不清空或繞過。實際內容、loot、乘客下車、無關鄰車及兩端效果由 T-034／C-011 人工確認。
- 已移除目標提前返回，防重複 discard／容器 hook／效果；這是目標防重複保護，不宣稱 OLD 此問題已重現或 U-06／U-10 全部已修正。
- discard 不會截斷原版 tick：TNT 的 fuse=0／碰撞分支可在 super.tick 返回後繼續。沒有新增 TNT 保險政策或宣稱永不爆炸；原版各車種同 tick 副作用、掉落與乘客仍待針對性人工確認。
- T-098 全量測試包未製作，本項固定 JAR 為開發證據；T-034 實際結果未填。使用者確認即可人工結案，不強制附件。T-061／T-062 才承接車頭及整列移除，沒有票證／連結釋放新政策。
- blockstate 存讀、設定重載與既有模型投影差異、codec／baking runtime 仍待驗收。U-07、T-026 結案、I-021-01／I-092-02／T-092 原缺口保留，本項不解除全部整合閘門。

下一個依現有前置可進行的功能開發為 T-035，另可在 T-098 製作本功能的人工包；均未開始。
