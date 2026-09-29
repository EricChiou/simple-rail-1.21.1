# T-011 方塊實體、計時與保存 API 查證

日期：2026-09-27。狀態：**開發交付完成；R-01 程式審查待審；人工遊戲測試未執行**。本項只查證 Minecraft 1.21.1／NeoForge 21.1.251 的來源、編譯候選簽名及資料邊界；[探針](probe/T011Probe.java)不進模組 sourceSet／JAR，沒有載入或執行。OLD 行為均為**依原始碼推定／待確認**，OLD build 不重跑。

## 版本、來源與命令

- NEW HEAD `8bd977dbb9f9000411ae5f4d10750228e5f33560`；Java 編譯器 `javac 21.0.12.1`（退出碼 0）；目標來源是本地 `build/moddev/artifacts/neoforge-21.1.251-sources.jar`，SHA-256 `236151EDEC930A89E78054FCB5551323761F801778305F290D0B74238C33693E`。實際取出的 28 個目標來源與 6 個 OLD 來源、各自 SHA-256 見 [來源名冊](source-manifest.json)；OLD 的 6 檔與 T-010 快照相同。
- 指定版官方文件：[NeoForged 1.21–1.21.1 Block Entities](https://docs.neoforged.net/docs/1.21.1/blockentities/)（註冊、`saveAdditional`／`loadAdditional`、`setChanged`、ticker），2026-09-27 查閱。文件是版本區間說明；精確到 21.1.251 的方法與執行順序依上述來源快照。文件沒有提供本模組計時語意或實測結果。
- 來源收集命令：`& ([scriptblock]::Create((Get-Content -Raw -Encoding UTF8 docs/evidence/T-011/collect.ps1)))`，退出碼 0；[收集紀錄](collection.json)。編譯命令：`.\gradlew.bat compileT011Probe --offline --console=plain --info --no-configuration-cache -I docs/evidence/T-011/probe.init.gradle`，由 [compile.ps1](compile.ps1)記開始／結束 UTC、退出碼及完整 log。
- [第一次](compile-01.json)在沙箱內因 Wrapper `C:\.gradle\...zip.lck` 無法建立而退出 1，[原始 log](compile-01.log)保留。經允許在沙箱外重試的[第二次](compile-02.json)退出 **0**、`BUILD SUCCESSFUL`，完整[編譯 log](compile-02.log)保留。只執行 `compileT011Probe` 與其已快取的 `createMinecraftArtifacts`；沒有執行 `build`、`runClient`、`runServer`、`gameTestServer`。
- 編譯設定為 `--release 21 -Xlint:deprecation -Werror`，同 NEW 主來源的 compile classpath；[classpath](compile-classpath.txt)、[其 SHA-256](classpath-manifest.json)、[compiler](compiler.txt)、[5 個 class/Java major 65](compiled-classes.json)保存。編譯成功只證明候選呼叫簽名能連結本地依賴，**不證明正式註冊、資料持久化、相位或遊戲行為**。
- [範圍／指紋](verification.json)及[產品檔快照](product-source-check.json)：相較 T-009 的 12 個 Java／Gradle／資源產品檔均未改；`git diff HEAD --name-only -- src build.gradle settings.gradle gradle.properties gradle gradlew gradlew.bat` 為空（退出碼 0）。未修改 OLD、NEW 模組程式、Gradle 或資源。
- [文件／依賴／證據自查](final-check.json)退出 0：126 個任務、九階段數量、依賴無循環及未改前置、本地連結、34 個來源快照、5 個 class、84 個 classpath 檔案雜湊均核對。這只屬開發者自查，不是獨立 Review Agent 結論。

下文的 `M/` 指本項 `sources/target/net/minecraft/`、`N/` 指 `sources/target/net/neoforged/neoforge/`、`O/` 指 `sources/old/`，皆可由[來源名冊](source-manifest.json)核對原檔與雜湊。

## API 與生命週期對照

| 範圍 | 指定版來源與可編譯候選 | 整合限制／後續驗證 |
| --- | --- | --- |
| 兩個既有方塊實體 ID | `M/world/level/block/entity/BlockEntityType.java:328–342` 的 `Builder.of(factory, blocks...).build(null)`；`N/registries/DeferredRegister.java`；探針以 `simplerail:timer_holding_rail`、`simplerail:signal_timer` 註冊候選。`M/world/level/block/EntityBlock.java:15–19` 的 `newBlockEntity(pos,state)` 接方塊。 | D2 保留兩 ID。探針只有未呼叫的註冊方法，真正的方塊 Supplier、註冊順序及世界載入交 T-019／T-038／T-041；不能視為已載入。 |
| 計時軌 ticker | `PoweredRailBlock implements EntityBlock` 候選、`EntityBlock#getTicker(Level,BlockState,BlockEntityType)`、`BlockEntityTicker`；`M/world/level/chunk/LevelChunk.java:701–711` 僅在方塊實體有效且區塊可 tick 時呼叫。探針只在伺服端回傳符合型別的 ticker。 | `System.nanoTime()` 量**實際經過時間**，不可用遊戲 tick 數乘 50 ms 替代；來源可編譯，但停車流程與重入時序留 T-038／T-039。ticker 不等於每 50 ms 固定執行。 |
| 訊號計時器 | `EntityBlock#getTicker` 候選在伺服端 tick；`M/world/level/LevelAccessor.java:48–53` 可 `scheduleTick(pos, block, delay, TickPriority.VERY_HIGH)`；`M/world/level/block/state/BlockBehaviour.java:387` 為方塊排程回呼；`M/world/ticks/LevelTicks.java:203–205` 可查排程。 | 此為**遊戲 tick 排程**，與 D5 計時軌的實際秒數分離。`LevelChunkTicks.java:60–75` 同位置＋方塊型別去重，不能由此推定 OLD 每 tick 要求的最終脈衝相位。探針中的 20／10 tick 僅編譯示例，不是正式週期規格；T-041／T-042 需按設定及狀態設計／驗收。 |
| 保存／讀回 | `M/world/level/block/entity/BlockEntity.java:77–115` 的 `loadAdditional(CompoundTag,HolderLookup.Provider)`、`saveAdditional(...)` 與 final `saveWithFullMetadata`；呼叫 `super` 保留 NeoForge 附加資料。`M/nbt/CompoundTag.java:255–260,324–329,366–374` 可先 `hasUUID` 與 `contains(key,Tag.TAG_LONG)` 再讀。 | 缺鍵與型別錯誤不能用 `getLong` 默認 0 或無條件 `getUUID` 代替驗證。D1 只讀 NEW 新世界 schema，無舊 `save_time`／`go_time` 轉換。欄位最終命名在 T-038 固定。 |
| 髒標記與磁碟快照 | `BlockEntity.java:191–199` 的 `setChanged()` → `Level.java:984–986` 將區塊標未存；`ChunkMap.java:769–774` 未標髒便跳過保存。`LevelChunk.java:420` 以 `saveWithFullMetadata` 序列化。 | 計時開始、車 UUID／剩餘值改變時須標髒；活動期間若一次自動存檔後再經過時間，也要讓後續保存取得新剩餘值。探針每次有整毫秒進展便標髒只是候選，頻率／成本與真正保存窗口交 T-038／T-040。 |
| 區塊卸載順序 | `ChunkMap.java:538–546`：設 `loaded=false` → `ChunkEvent.Unload` → `save(chunkaccess)` → `ServerLevel.unload`；`LevelChunk.java:616–621` 在最後的 clear 中才呼叫 `BlockEntity.onChunkUnloaded()`。該回呼由 `N/common/extensions/IBlockEntityExtension.java:61` 定義。 | **不得在 `onChunkUnloaded` 才更新待存資料**：它晚於這次序列化；也不能假設回呼一定觸發寫盤。`ChunkDataEvent.Save`（`N/event/level/ChunkDataEvent.java:80–84`）在 `ChunkMap.save` 序列化後發出，可用於取證但不是回寫時機。 |

`ChunkMap.saveAllChunks(true)` 仍呼叫 `save`，而 `save` 檢查 `isUnsaved()`；單靠關服 flush 不能保證未標髒的計時變更寫盤。`LevelTicks.schedule` 對沒有 tick container 的位置報錯，訊號 timer 不應在卸載位置排程（`M/world/ticks/LevelTicks.java:73–81`）。

## 新版本資料邊界候選（T-038／T-041 實作前規格）

1. **計時軌狀態**：每一個 `simplerail:timer_holding_rail` 的 BE 持有 `cart_uuid`（可空）與非負 `remaining_ms`。NEW 新世界的完整活動記錄必須同時有合法 UUID 和 `TAG_LONG` 且剩餘值大於 0；全缺／任一缺／型別錯／負值皆歸 idle，不能默認 UUID 或認定立即放行。清空時兩個鍵可不寫；日誌應可定位方塊座標與缺鍵種類。正式欄位 ID 與異常資料修復策略由 T-038 固定；**不讀取、推斷或遷移 OLD `save_time`／`go_time`**。
2. **實際秒數與讀回補償**：在伺服端開始停車時用已驗證設定秒數安全換算成 `long` 毫秒，記錄單調時鐘；活動 tick 按實際經過毫秒扣 `remaining_ms`，不按 tick 次數扣。序列化時寫入可恢復的剩餘值，讀回將單調時鐘基準重設，在卸載／離線期間不扣除任何時間。這等同以讀回剩餘值補償離線時段；與 OLD 儲存絕對 `go_time` 加載入時間差的**資料格式不同**，但保留 D5 的玩家語意。首 tick 的基準化、活動 tick 間停頓及系統時鐘變動處置仍**待技術定義／遊戲驗證**。不得把探針運算當成最終已驗證演算法。
3. **保存窗口**：在改變計時狀態時 `setChanged`，活動 tick 期間需以可審核的策略保證最近剩餘值會在正常存檔／卸載前寫入。`saveAdditional` 應以**序列化時刻**的有效剩餘值製作快照；不能只寫上次自動儲存時的過時 deadline，也不能指望晚於 `save` 的 `onChunkUnloaded`。以來源順序推斷，探針逐 tick 髒標記可縮小過時窗口，但 flush／卸載、頻率負載和真實時序尚未測；T-038 實作前須選擇並審核具體策略。
4. **訊號計時器邊界**：等級與 powered 仍由方塊狀態表達；BE 只負責伺服端排程，候選不添自訂 NBT。來源 `O/tileentity/SignalTimerTileEntity.java:38–80` 每 tick 為 level>0 排程，`O/block/SignalTimerBlock.java:49–56` 的方塊 tick 切換 powered 並排下一次 10 tick；均為**依原始碼推定／待確認**。排程在區塊資料保存（`M/world/level/chunk/storage/ChunkSerializer.java:413–416`），但重啟／卸載後的相位與去重仍待 T-041／T-042，不能套用 D5 的實際秒數或假稱 OLD 相位已實測。

## 可執行的卸載與 3 秒取證方案

T-038／T-041 將在開發範圍提供可關閉的伺服端診斷紀錄，至少列維度＋方塊／chunk 座標、cart UUID、剩餘毫秒、單調／壁鐘觀測時刻與事件種類：計時開始、活動計時、`saveAdditional` 快照、`ChunkDataEvent.Save`、`ChunkEvent.Unload`、`onChunkUnloaded`、`loadAdditional`／首 tick、放行；時鐘值只用於比對，不把 JVM `nanoTime` 絕對值存 NBT。T-040／T-083 的固定版本包讓使用者操作：停車至剩餘約 3 秒，分別確認真卸載或正常存檔停服；離開足夠久後載入，觀察仍約需 3 秒才放行。需保存有時戳的服務端 log、事件序列、保存／讀回的 NEW NBT 片段、操作者的實際秒錶／錄影及版本／JAR SHA-256；車頭票證或玩家追蹤導致區塊未卸載時該次**不能記為真卸載案例**。正常存檔至實際卸載／停止前仍在活動的時間必須計入，不能以存檔時畫面作唯一 3 秒基準。測試容許誤差、量測起止、快照頻率與負載門檻維持**待技術定義**，正式使用者測試前先凍結。開發 Agent 不執行、也不填使用者人工結果。

## 完成條件與未驗證項目

| T-011 條件 | 交付證據 | 本項判定 |
| --- | --- | --- |
| 兩種 BE 的可編譯候選 | `probe/T011Probe.java` 中各自註冊、`newBlockEntity`、ticker、save/load／方塊排程；`compile-02` 退出 0、5 個 major 65 class | 達成**編譯候選**；尚非正式模組實作 |
| 實際秒數與 tick 分離、D5 | 上述資料邊界與探針 `System.nanoTime`／`scheduleTick` 分線；讀回重置時鐘基準 | 達成**設計候選**；計時精度與 D5 玩家行為待 T-040／T-083 人工驗收 |
| 缺鍵及卸載取證 | `hasUUID`／`contains` 候選、來源查明先 save 後 `onChunkUnloaded`、事件序列與 3 秒測例 | 達成**可執行取證方案**；未啟動遊戲、未取得實際卸載 log |
| 來源／編譯 log／生命週期、D1 | 本文、34 個來源快照、完整雙次 log、manifest／SHA、未安排舊資料轉換 | 達成；R-01 審查待審 |

後續待查證：T-037 疑點 4 的 OLD 可靠保存推論及範圍、T-038 計時持久化策略／整毫秒精度與效能、T-039 缺鍵與邊界非遊戲回歸、T-040／T-083 使用者真卸載及停服 3 秒實測；T-041／T-042 訊號相位；T-012 容器、T-013 實體保存、T-016 票證均未由本項驗證。
