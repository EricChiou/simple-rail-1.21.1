# T-016 區塊事件與票證機制 API 查證

日期：2026-09-28。狀態：**開發交付完成；R-01 程式審查待審；人工遊戲未執行**。本輪依 D3 只對照 OLD 呼叫與 Minecraft 1.21.1＋NeoForge 21.1.251 指定版 API，提供維持現有中心區塊呼叫的候選和觀測方案。OLD 實際票證結果是**依原始碼推定／待確認**；未重跑 OLD build，未啟動 NEW client／server、未修改模組程式或票證政策。

## 來源、版本及編譯證據

- [15 個 Java 來源快照與 SHA-256](source-manifest.json)包含指定版 12 個、OLD 3 個；[蒐集命令與來源 JAR 雜湊](collection.json)。NEW 來源取自 `build/moddev/artifacts/neoforge-21.1.251-sources.jar`；OLD 專案宣告 Forge `1.16.5-36.1.0`，本輪只讀 OLD 原始碼。Forge 官方 [1.16.x `ForgeChunkManager` 來源](https://github.com/MinecraftForge/MinecraftForge/blob/1.16.x/src/main/java/net/minecraftforge/common/world/ForgeChunkManager.java)補充 `forceChunk` 參數語意；該分支目前原始碼不等同已核對 OLD 專案所宣告的 **36.1.0 精確 binary**，相關語意仍須後續對照／實測。
- [獨立候選探針](probe/T016Probe.java)以[Gradle init 腳本](probe.init.gradle)編譯，命令：`.\gradlew.bat compileT016Probe --offline --console=plain --info --no-configuration-cache -I docs/evidence/T-016/probe.init.gradle`。[初次紀錄](compile-01.json)退出 **1**，沙箱內無法建立 `C:\.gradle\...zip.lck` 父目錄，[原 log](compile-01.log)保留；[獲允許的重試](compile-02.json)退出 **0**、`BUILD SUCCESSFUL`，[完整 log](compile-02.log)保留。Java 21.0.12.1、`--release 21 -Xlint:deprecation -Werror`，[編譯器](compiler.txt)、[classpath](compile-classpath.txt)、[major 65 class](compiled-classes.json)及[指紋／產品範圍](verification.json)均保存。探針不在產品 sourceSet／JAR，未執行或載入。
- [任務、依賴、連結及雜湊自查](final-check.json)僅屬開發 Agent 靜態檢查，不是 R-01 審查或遊戲驗收；12 個產品基線檔與 T-009 一致，產品 Java／Gradle／資源無差異。

## OLD 呼叫與指定版對應

OLD `sources/old/SimpleRail.java:99–101` 在一般 Forge event bus 將 `EntityEvent.EnteringChunk` 交給 `sources/old/event/ChunkEventManager.java:19–51`。OLD `sources/old/config/CommonConfig.java:57–61` 的 `disableLoadingChunk` 預設 **true**，原碼為 true 時才進入強制載入；不能依鍵名反轉語意。

| OLD 參數／呼叫 | 指定版候選與來源 | 差異及後續要求 |
| --- | --- | --- |
| `EnteringChunk`，進區塊時觸發 | `sources/target/net/neoforged/neoforge/event/entity/EntityEvent.java:63–113` 的 `EntityEvent.EnteringSection` 在 `NeoForge.EVENT_BUS`；用 `didChunkChange()` 篩掉僅 Y section 變更 | 新事件粒度較細。正式 T-076 應只在 X／Z 區塊變更處理；首次生成、傳送、載入後是否觸發等價尚未實測，T-077 需觀測 |
| `entity instanceof LocomotiveCartEntity`，`!entity.level.isClientSide` | `event.getEntity()` 和 `entity.level() instanceof ServerLevel`；探針暫以 `MinecartFurnace` 佔型別 | 正式 T-076 換回既有 `simplerail:locomotive_cart` 類型並接 T-020 設定值；探針不能作正式 handler |
| `world = server.getLevel(entity.level.dimension())` | 直接使用事件實體所在 `ServerLevel`，其 `dimension()` 可記入診斷 | 必須以該維度呼叫 ticket controller；跨維度同座標不可混算。`ServerLevel` 類型候選可編譯，跨維度效果未測 |
| `entity.blockPosition()`、`x >> 4`、`z >> 4` | 同一 `BlockPos` 與中心 `chunkX/chunkZ`；`ChunkPos` 記錄／觀察使用相同座標 | 負座標及邊界跨越要入 T-077 測例；目前沒有實際世界讀值 |
| `CHUNK_RADIUS=2`，兩層 `-2..+2` 迴圈 | 探針保留 **25 次呼叫**，每次傳**中心 `chunkX/chunkZ`**，與 OLD 原碼相同；不用迴圈變數 `x/z` 取代中心 | 25 次呼叫不等於 25 張票證或 5×5 區塊；不在 T-016／T-076 自行改範圍。NEW 內部 `addRegionTicket(..., 2, ...)` 的 2 是票證等級用距離，不是 OLD 迴圈半徑，不能混為一談 |
| `ForgeChunkManager.forceChunk(world, SimpleRail.MOD_ID, entity, chunkX, chunkZ, true, true)` | `sources/target/net/neoforged/neoforge/common/world/chunk/TicketController.java:27–69`：先在 mod bus 的 `RegisterTicketControllersEvent` 註冊穩定 `ResourceLocation` controller，再呼叫 `controller.forceChunk(serverLevel, entity, chunkX, chunkZ, true, true)` | 舊 mod ID 字串改為 controller ID（探針候選 `simplerail:locomotive`，**新增 ID 待正式 T-076 定稿**）；Entity owner 在新版轉 UUID；兩個 true 分別為 add、ticking。指定版 API 能承接此呼叫，但 runtime 等價仍待驗 |
| 未找到解除 `forceChunk(..., false, ...)`、票證驗證回呼或清理呼叫 | 探針用無 callback 的 `TicketController(id)`，只加載、不新增解除；指定版 `ForcedChunkManager.java:129–153` 會在新世界重載已保存票證 | 維持 D3 的未釋放現狀，不自設車頭刪除／停車時釋放政策。持久票證的代價及是否形成 OLD 疑點由 T-075／T-078 調查，政策變更需依 D6 審閱；D1 不轉換舊 Forge 世界／票證資料 |

指定版 `ForcedChunkManager.java:81–103,116–121` 先以 `(controller ID, owner UUID, chunk, ticking)` 加入保存集合；僅集合新增／移除成功才標髒並向 chunk source 加／移票證，`forceChunk` 回傳 boolean。因 OLD 迴圈重複傳同中心，探針保留重複呼叫；若初次呼叫已加入，後續相同 key 會回傳未新增，**這是來源層推論，非 OLD 或 NEW 遊戲觀測**。`TicketController.java:20–24` 明示未註冊 controller 會拋錯或在載入時捨棄票證，因此 mod bus 註冊是正式實作必要前置。`ForcedChunkManager.java:190–262` 的持久儲存／重載只作 NEW 新世界查證；不安排 D1 排除的舊世界或 NBT 轉換。

## D3 最小候選及觀測方式

正式 T-076 應在 mod bus 註冊一個穩定的 Simple Rail controller，於一般 NeoForge event bus 接 `EnteringSection`；只有 OLD 設定值為 true、實體是車頭、事件 X／Z 區塊變更且 level 為 server 時，採實體當前位置計算中心，保留 radius=2 的兩層迴圈並反覆呼叫 `forceChunk(level, entity, centerX, centerZ, true, true)`。探針中的 `MinecartFurnace` 與 `oldConfigEnabled=true` 只是佔位；正式設定讀值及 handler 接線仍須 T-020／T-076 實作。若首次生成或重載不產生相同進入事件，T-077 需先記錄具體差異，不由本輪偷偷加入另一個觸發器或新票證策略。

觀測包應在**固定版本 JAR** 上列任務／案例 ID、commit、JAR SHA-256、Minecraft／NeoForge 版本、世界與維度、車頭 UUID、操作步驟、預期、空白實際結果欄及 log 取得方法。T-076 可為測試版本加入必要診斷 log：事件舊／新 section、`didChunkChange`、維度、車頭 UUID、中心座標、25 次呼叫及 boolean 回傳分布。這類記錄有助核對**呼叫**，不能單憑它宣稱附近 25 區塊載入或車頭持續 tick；應另以 server 端區塊狀態與車頭／計時器的 tick 觀測，分列「已載入」「可 tick」「實體有活動」。`ServerChunkCache#hasChunk` 僅表明快取可見區塊，不證明是哪個 owner 的票證；`ForcedChunkManager#hasForcedChunks` 是整個 level 聚合值，也不證明單車票證。不要以 vanilla `/forceload query` 單獨推定 mod controller 票證。

由使用者在 T-077／T-080／T-084 實際操作 NEW 新世界：設定 true／false、中心及負座標跨界、停車、離開玩家範圍、移除車頭、保存重啟、跨維度同座標及多車頭，逐步回傳 server log、tick／位置及必要截圖。T-075／T-124 另調查 OLD 疑點；OLD 未實測保持「依原始碼推定／待確認」。D5 的約 3 秒卸載測例若受 D3 票證影響而未實際卸載，該次不能作為卸載通過證據，需由後續任務安排可證明卸載的場景，不由 T-016 新增釋放政策。

## 完成條件與未驗證範圍

| T-016 完成條件 | 本輪證據 | 判定邊界 |
| --- | --- | --- |
| 舊參數的目標對應與差異 | 上表含事件粒度、維度、owner UUID、中心座標、兩個 boolean、controller 註冊及持久化；指定版 12 個來源快照 | **來源與設計完成**；OLD 36.1.0 精確 binary 與 runtime 效果未實測 |
| D3 最小候選不擅改範圍／釋放 | 探針保留 25 次中心呼叫、true／true、無解除或 callback，指定版最小編譯退出 0 | **編譯候選完成**；正式車頭型別、設定／事件註冊與新世界重啟仍未執行 |
| 票證及持續 tick 的觀測可交接 | 上述固定版本交接欄位、呼叫／ticket／實際 tick 分層、T-077–T-084 場景 | **測例規格完成**；沒有使用者實際結果、不能宣稱 5×5 或持續運作 |

目前沒有來源層面的 API 硬阻礙；正式註冊時機、首次生成／重載觸發、票證恢復、跨維度及持續 tick 效果均待查證。獨立 R-01 審查和所有遊戲案例尚未執行。
