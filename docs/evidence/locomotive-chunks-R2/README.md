# 車頭區塊載入 R2：已批准的 D3 新政策（2026-10-08）

使用者原文：「我同意採用這份提案」。批准範圍為 [政策提案](../locomotive-chunks-R1/POLICY-PROPOSAL.md) 全部六點，包含 R1 歷史票證清理及既有列車一次性重新載入。D3 的原中心呼叫／不釋放要求成為歷史基線，其他 D1–D8 決策不變。

**開發完成；R-06／R-F 獨立程式審查、Minecraft 人工驗收尚未執行。** 不將政策批准寫成遊戲通過，不重跑 OLD build。

## 實作契約

| 項目 | 實作與限制 |
| --- | --- |
| 覆蓋 | 每個維度、車頭 UUID 獨立。車頭＋連結車廂的實際位置、下一次移動目標各擴一圈 chunk，取 3×3 聯集。長列車以各車位置覆蓋，不僅車頭周圍；負座標 floorDiv。取消 25 次重複中心呼叫。 |
| 回收 | `ChunkTicketSet` 先新增差集；所有目標 chunk 的實體 IO 完成且可 entity tick、連結車廂已找到，才釋放舊集合。沒有變化不重複 forceChunk。同 chunk 不同 UUID 的票證各自持有，不釋放另一列的 owner。 |
| 等待 | `LocomotiveCartEntity.tick` 在普通 minecart physics 前判定可前進；等待時保留速度。跟車 move 前再次檢查新目標。等待列車的已載入車廂也取消當次 EntityTickEvent.Pre，避免動力軌自行拖動；就緒後恢復。先處理 pending cuts，避免已被明確移除的尾段阻擋整列。 |
| 真實位置 | 新 `LocomotiveChunkData` 保存實際觀察到的 head／cart block positions；既有 `TrainStops` 僅供缺資料時的有限搜尋提示，不能覆蓋實際最後位置。找不到車廂時保留 UUID、不假定已刪除，停止移動並記警告；由其原位置載入或明確解除連結後恢復。 |
| 停車／移除／停用 | 停車保留必要集合；永久移除與跨維度離開釋放舊維度 owner 及索引；解除車廂連結由下一次 prepare 收縮。設定 false 在下一個 server level Pre tick 清全部 runtime leases＋索引，包含未實例化 owner，並解除等待車廂的暫停；true 為仍已載入列車重建。COMMON 設定鍵／預設及其 true＝啟用语意不變。 |
| 初始／讀回 | Join 只排隊，LevelTickEvent.Pre 才訪問 chunk。未成功加入／已移除的 Join 不建票證。世界作用域依 ServerLevel 身分，Unload 清 transient state，正常關服仍保存索引。 |
| 重啟與 R1 清理 | 註冊原 `simplerail:locomotive` 的 validation callback，在 NeoForge 恢復前清除本 controller 的 raw block/entity tickets。下一個 level Pre 只按 R2 索引恢復目前集合；沒有索引即不復活 R1 歷史票證。callback 每次啟動都先過濾，R1「清理後需重新登錄」只在沒有有效 R2 索引的首次升級發生。其他 controller 與 vanilla Forced 不修改。 |
| 首次啟動邊界 | 升級前備份 NEW 世界；R1 既有整列需由玩家載入一次，讓車頭與車廂的實際位置登錄。從未登錄的遠方實體不掃描發現。關閉載入清索引後若列車已卸載，重新啟用也需載入一次；正常啟用中關服重啟不需玩家靠近。 |

## 保存與故障恢復

每維度 SavedData 檔 `simplerail_locomotive_chunks.dat`，`Schema=1`；`Owners` 每列含 `Owner` UUID、`Positions`（Entity UUID／實際 BlockPos long）、`Chunks`（當前申請集合 long[]）。位置或集合變更才 dirty。保存中的暫時新舊聯集代表尚在等待的當前需求，不是歷史路線清單。在主世界位於 `world/data/`；地獄通常 `world/DIM-1/data/`。

原 `chunks.dat` 的本 controller 票證不再作 owner 發現來源。索引與 chunk/entity 檔案不是跨檔交易：正常保存／重啟依目前索引恢復；突然中斷造成索引位置與實體檔不一致時，不保證自動尋遍世界恢復。先等整個索引集合的 `areEntitiesLoaded` 與 entity ticking 都成立；若仍找不到 owner，清其票證並把索引轉為 `Chunks=[]` 暫停狀態、保留位置與 UUID、記警告。這不是刪除實體；使用者載入其實際位置後會重新登錄。未完成 IO 時 `getEntity()==null` 不會觸發此處理。索引缺失／無效亦不能猜測 R1 車頭位置，須從備份恢復或一次性重新載入。

無法定位的車廂會保留最後實際位置的有限覆蓋並等待，不在背景無限搜尋；這是明確保守行為。突然中斷、磁碟失敗、異常缺車與正常關服必須分開驗收，不宣稱資料已具交易一致性。

## 指定 API 與檢查

API 來源由 `build/moddev/artifacts/neoforge-21.1.251-sources.jar` 取出，見 `api/` 與 [指紋](api-manifest.json)。查閱 TicketHelper 的 controller 隔離／removeAllTickets、validation 發生在 reinstatement 前、MinecraftServer.prepareLevels、ServerLevel.areEntitiesLoaded／isPositionEntityTicking、EntityTickEvent.Pre 可取消及 SavedData 的使用方式；成功編譯固定版本，不冒稱其他版 API 已查證。

- [初次 build](build-01.log) 退出 0；加入等待車廂的防漂移之後，[最終 build＋測試](build-test-02.log) 退出 0。正式 Gradle `test NO-SOURCE`，不等於內建測試已跑。
- 命令：`GRADLE_USER_HOME=C:\Users\Kinoko\.gradle; .\gradlew.bat --offline --no-configuration-cache -I docs/evidence/locomotive-chunks-R2/test.init.gradle build testChunkR2`（PowerShell 以環境變數設定）。init script 僅增加 evidence task，未修改正式 Gradle 設定或 JAR 來源集合。
- 實際 `ChunkTicketSet`／`LocomotiveChunkLoader`／`LocomotiveChunkData` 以隔離 world、ticket、event 替身執行，使用真實 1.21.1 BlockPos／ChunkPos 與 NBT binary 讀寫；**6,451 項斷言通過**。包含 2,000 次跨 chunk 的長列車集合固定大小、先加後釋放、未 ready／缺車 gate、車廂防漂移、共享 owner 隔離、停用／重啟／暫停 owner、R1 清理、不干擾另一 controller、NBT round trip／schema／dirty。實體運動、真實 NeoForge 票證與遊戲世界沒有在此測試中啟動。

產品差異：新增 `ChunkTicketSet`、`LocomotiveChunkData`；重寫 `LocomotiveChunkLoader`；車頭 tick、跟車 move、永久移除接上 gate／release，提供 route target／hint 查詢。車距仍為 1.35 倍數，既有 IDs、T 型路口、渲染、配方及資源不改。

## 任務與交接

T-078 的政策批准與範圍交付完成；T-079 本次政策修正開發完成。R-06／R-F 待審，T-077／T-080／T-124 未人工通過；T-075 的其他完整調查分項不憑本次開發結果自動結案。T-076 的 R1 build 是真實歷史，本版驗收以新 D3 為準。

[R2 測試包](../../test-packages/locomotive-chunks-R2/README.md)含固定 JAR、commit＋未提交差異、來源指紋、操作步驟與空白人工結果。使用者直接確認即可人工結案，log／截圖／票證計數均可選附；既有歷史測試結果不套用本次政策變更。

[固定包核對](final-check.log) 與 [產品 class 核對](jar-check.log) 均退出 0：204 個來源指紋、JAR／ZIP、12 個空白人工結果一致；126 任務／九階段／依賴無缺號或循環。包內四個受影響產品 class 與 Gradle 輸出相同，沒有测试替身進入發行 JAR。JAR SHA-256：`15D0C2B52027ED025628AD74BC4D2E156202539A163C3B4B0BF1EA9F997BC093`。[製包腳本](package.ps1)及 [log](package.log)保留，退出 0。反組譯 `javap.log` 退出 0，車頭 physics／跟車移動前有 prepare gate、永久移除有 release；不將反組譯稱為遊戲運動驗證。
