# Simple Rail 遷移指南 v1.0

> 盤點日期：2026-09-26；分工修訂：2026-09-27。狀態：**需求基線保留；T-001、T-003–T-007 歷史、T-002 免執行及 R-01 原範圍保留；T-019–T-022／T-093 開發完成、R-02 待審；T-025 原開發交付／R-03 待審；T-092 受阻；T-018／T-089 人工已結案；T-026 使用者回報不通過，斜坡需求範圍與銜接改向根因待確認**。
> D1–D8 不變，`TASK.md` 已經使用者審閱。本輪收錄 [T-026 失敗回報](docs/evidence/T-026/REPORT-001.md)及既有來源分析；未改程式／資源、執行 build／遊戲或簽 Review。T-025 原 build／靜態證據保留；I-021-01／I-092-02 不自行解除，不改正式依賴。
> **OLD build 由使用者先前驗證，本次流程不重跑**；這是使用者陳述，不是 Agent 執行 T-002 或 NEW 建置／API／遊戲驗收的證據。
> **實際遷移起點是 Minecraft 1.16.5 + Forge 36.1.0，不是 NeoForge。**
> T-003 來源參考、T-004 案例設計、T-005 框架 build 已完成；T-006 client 新世界與 T-007 dedicated server 啟停已有舊分工下的 Agent 歷史紀錄，退出碼均為 0。原始證據保留，不倒填為使用者已測、不代表後續功能人工驗收；T-018／T-089 已依使用者完成確認結案，無需提交人工證據。T-008 指定 API 來源與最小編譯、T-009 格式／ID／非遊戲檢查、T-010 軌道／互動／狀態最小編譯、T-011 方塊實體／計時／保存候選、T-012 專用容器／箱子式 GUI、T-013 車頭／編組保存、T-014 實體生成／同步、T-015 模型／材質／渲染及 T-016 區塊事件／票證候選已交付；T-017 正式空功能入口與離線 build 已交付。其餘 API 與未實作功能保持未驗證。

## 1. 目標與範圍

將 Simple Rail 的既有軌道、列車、工具與機器功能，遷移至 Minecraft 1.21.1 + NeoForge；保留可追溯的功能、識別名稱及資料格式清單，作為分階段實作與驗收依據。

本輪只記錄 T-026 使用者失敗及來源調查。高速不能成坡源自已移植的舊版禁坡 hook，但使用者現在期待原版動力軌斜坡，是否改為高速例外或共用基底全改仍待確認；不先改指南。平軌與原版斜坡銜接改向已登錄，根因待確認，不以禁坡要求否定其回報。T-025 原開發證據、凍結包、D1–D8 與人工確認即可結案規則保留，功能修正／審查／重測均未完成。

### 路徑與證據範圍

以下縮寫均指向實際目錄；例如 `OLD/build.gradle` 即 `D:/workspace/java/simple-rail/build.gradle`。

| 縮寫 | 完整路徑 |
| --- | --- |
| `OLD` | `D:/workspace/java/simple-rail` |
| `NEW` | `D:/workspace/java/simple-rail-1.21.1` |
| `J` | `D:/workspace/java/simple-rail/src/main/java/ericchiu/simplerail` |
| `R` | `D:/workspace/java/simple-rail/src/main/resources` |

盤點時 OLD HEAD 為 `6698b1c5f494095a15b055c10045293e91540012`，NEW HEAD 為 `8bd977dbb9f9000411ae5f4d10750228e5f33560`；開始盤點時兩者 `git status --short` 均無變更。主要依據為建置宣告、42 個 Java 原始檔與 `src/main/resources`。README 僅作補充，不能取代實作證據；本輪未檢查實際使用中的世界 NBT 或玩家設定檔。

本文的「已確認」限於專案文字及程式結構；「風險」為根據該實作提出的檢查項目；無法據此確定的執行結果或產品選擇一律標為「待確認」。

第 5 節另記錄使用者已決定的需求；需求已定案不代表相關 API 或執行結果已驗證。

## 2. 原專案技術基線

| 項目 | 已確認內容 | 判斷依據 |
| --- | --- | --- |
| Minecraft | 建置與 official mappings 都指定 `1.16.5`；描述檔接受 `[1.16.5,1.17)` | `OLD/build.gradle` 的 `minecraft`／`dependencies`；`R/META-INF/mods.toml` |
| 載入器 | **Forge**，建置依賴 `net.minecraftforge:forge:1.16.5-36.1.0`；`javafml`、loader 與 Forge 範圍均為 `[36,)` | `OLD/build.gradle`、`R/META-INF/mods.toml`；`J/SimpleRail.java` 使用 `net.minecraftforge.*` |
| Java | 宣告 Java toolchain **8**；實際開發機／發行 JAR 所用 JDK 待確認 | `OLD/build.gradle` 的 `JavaLanguageVersion.of(8)` |
| 模組 | ID `simplerail`；名稱 `Simple Rail`；版本 `1.16.5-0.3.25` | `J/SimpleRail.java`、`R/META-INF/mods.toml`、`OLD/build.gradle` |
| 建置工具 | Gradle Wrapper **6.8.1-all**；ForgeGradle **4.1.+**（動態版本，當時實際解析版本待確認） | `OLD/gradle/wrapper/gradle-wrapper.properties`、`OLD/build.gradle` |
| 建置流程 | 使用 Gradle Wrapper；`jar.finalizedBy('reobfJar')`；套用 `eclipse`、`maven-publish`；本機 Maven 輸出位置 `mcmodsrepo` | `OLD/build.gradle`、`OLD/gradlew`、`OLD/gradlew.bat` |
| 開發執行 | 宣告 client、server、data；data 輸出 `src/generated/resources` 並加入 resources source set。未在盤點的來源中找到自訂資料產生器 | `OLD/build.gradle`、`OLD/src/main/java` |
| Artifact | group `ericchiu.simplerail`；archivesBaseName `simplerail` | `OLD/build.gradle` |
| 外部模組 | 描述檔只要求 Minecraft 與 Forge；未找到其他必要／可選模組宣告或直接整合程式 | `R/META-INF/mods.toml`、`OLD/build.gradle`、`OLD/src/main/java` imports |
| 程式庫 | 原始碼使用 Apache Commons Lang `Pair`、Log4j、Mojang Blaze3D；Gradle 未額外直接宣告這些函式庫的版本。實際傳遞依賴樹待確認 | `J/config/CommonConfig.java`、`J/SimpleRail.java`、`J/render/`、`OLD/build.gradle` |

**OLD build 由使用者先前驗證，本次流程不重跑**。不要求重新下載 Java 8／Gradle 6.8.1、修復 OLD 建置環境或重跑 OLD build。T-002 保留編號，狀態為「使用者決定免執行」，不代表 Agent 已完成或驗證該任務；本次未取得使用者該次 build log、退出碼、JAR 雜湊或測試結果，不補造證據。ForgeGradle 實際解析版本等歷史未知項仍待確認，但不作 NEW 建置或遷移的前置。

### 目標專案設定與建置基線

| 項目 | 目前宣告 | 依據 |
| --- | --- | --- |
| Minecraft／NeoForge | `1.21.1`／`21.1.251`；Minecraft 範圍 `[1.21.1]` | `NEW/gradle.properties` |
| Java／Gradle | Java toolchain `21`；Wrapper `9.2.1-bin` | `NEW/build.gradle`、`NEW/gradle/wrapper/gradle-wrapper.properties` |
| 建置外掛／mappings | ModDevGradle `2.0.147`；Parchment `1.21.1`／`2024.11.17`；Foojay resolver `1.0.0` | `NEW/build.gradle`、`NEW/gradle.properties`、`NEW/settings.gradle` |
| 識別資訊 | mod ID `simplerail`；mod version `1.0.0`；group `com.ericchiu.simplerail` | `NEW/gradle.properties` |
| 載入器描述檔 | `javafml`；loader 範圍 `[1,)`；NeoForge 依賴由 `${neo_version}` 展開 | `NEW/src/main/templates/META-INF/neoforge.mods.toml` |
| 程式內容 | 仍有 `example_block`、`example_item`、`example_tab` 與範例設定；client 類別已有設定畫面掛接程式 | `NEW/src/main/java/com/ericchiu/simplerail/{SimpleRail,SimpleRailClient,Config}.java` |
| CI | 宣告 JDK 21 與 `./gradlew build`，本輪未查核執行結果 | `NEW/.github/workflows/build.yml` |

以上表格列宣告值；T-005 已另以實際 build 核對 Java 21、Gradle 9.2.1、ModDevGradle 2.0.147、NeoForge 21.1.251、Parchment 1.21.1／2024.11.17，退出碼 0 並取得可識別框架 JAR。詳見 [T-005 證據](docs/evidence/T-005/README.md)。另有 [T-006 client](docs/evidence/T-006/README.md) 與 [T-007 server](docs/evidence/T-007/README.md) 的 Agent 歷史啟停證據。**範圍僅為既有框架 build／啟停**；T-089 使用者連線、功能與指定 API 遷移用法仍待確認，不是遷移完成。

依 D8，首版基線採用目前的 mod version `1.0.0`、授權宣告 `All Rights Reserved` 與 NeoForge `21.1.251`，Minecraft 目標為 `1.21.1`。

## 3. 功能與來源清單

### 註冊、物品與共用機制

| 功能 | 原始檔 | 靜態盤點結果 |
| --- | --- | --- |
| 模組入口與生命週期 | `J/SimpleRail.java` | `@Mod`、COMMON 設定、事件匯流排、client render setup、進入區塊事件；IMC helloworld 只送給自身，不能視為外部整合 |
| 註冊 | `J/setup/Registration.java`、`J/registry/{Blocks,Items,Entities,TileEntities}.java` | 方塊／物品／實體用 DeferredRegister；2 個 TileEntityType 另由 RegistryEvent 註冊 |
| 狀態與標籤 | `J/setup/{SimpleRailProperties,SimpleRailTags}.java`、`J/constants/{Properties,Tags,I18n,TileEntityCons}.java` | 集中宣告名稱、方塊屬性及 rails／machines／wrench 標籤 |
| 扳手 | `J/item/Wrench.java` | 點擊相鄰礦車所在位置來連結編組；修改軌道 reverse、level、direction 與機器 facing、level；最大堆疊 1 |
| 車頭物品 | `J/item/LocomotiveCart.java` | 在自訂或原版 rails tag 上放置車頭，傳遞自訂名稱；最大堆疊 64 |
| 方塊物品／創造模式分頁 | `J/registry/Items.java`、`J/itemgroup/Rail.java` | 11 個 BlockItem，搭配 2 個獨立物品；分頁使用高速軌道圖示 |
| 設定 | `J/config/CommonConfig.java`、`J/constants/Config.java` | 區塊載入、速度、動力需求、乘客移動距離與兩組計時等級 |

### 方塊（9 種軌道、2 種機器）

下表每個註冊路徑都帶有 `simplerail:` namespace，且都有同名 BlockItem。

| 註冊路徑 | 功能 | 原始檔 |
| --- | --- | --- |
| `high_speed_rail` | 高速動力軌道 | `J/block/HighSpeedRail.java` |
| `holding_rail` | 未供電時停車並記錄行進方向；供電時推動礦車 | `J/block/HoldingRail.java` |
| `oneway_rail` | 依 reverse 與設定控制礦車行進；動力／方向切換語意需作行為基線 | `J/block/OnewayRail.java` |
| `eject_rail` | 使乘客下車並移動到軌道側邊，可反轉方向與設定距離 | `J/block/EjectRail.java` |
| `destory_rail` | 移除礦車；遇車頭則呼叫刪除整列編組 | `J/block/DestoryRail.java` |
| `timer_holding_rail` | 等級 1–9 計時停車，等級 0 不停車；透過方塊實體記錄目前車輛與放行時間 | `J/block/TimerHoldingRail.java` |
| `cross_rail` | 依進入方向穿越十字路口，暫存速度與目標位置 | `J/block/CrossRail.java` |
| `y_cross_rail` | 依方向、來車方向與紅石狀態選擇分岔路徑 | `J/block/YCrossRail.java` |
| `y_cross_right_rail` | 另一組分岔方向配置 | `J/block/YCrossRightRail.java` |
| `train_dispenser` | 紅石觸發後依 27 格內容排列礦車；第 0 格為車頭時連結後續一般礦車 | `J/block/TrainDispenserBlock.java` |
| `signal_timer` | 等級 1–9 週期性輸出強度 15 的紅石訊號，等級 0 無輸出 | `J/block/SignalTimerBlock.java` |

共用基底為 `J/block/base/BaseRail.java` 與 `BasePoweredRail.java`：兩者都讀取 `highSpeedRailMaxSpeed`，禁止形成斜坡，並覆寫實體破壞判斷。速度設定並非只影響 `high_speed_rail`；遷移驗收需涵蓋其他軌道。

### 方塊實體、GUI、實體、網路與渲染

| 類別 | 功能與原始檔 |
| --- | --- |
| 自訂方塊實體 | `J/tileentity/TimerHoldingRailTileEntity.java` 保存計時資料；`J/tileentity/SignalTimerTileEntity.java` 透過 tick 排程紅石方塊 tick；註冊見 `J/registry/TileEntities.java` |
| 原版方塊實體／GUI | `J/block/TrainDispenserBlock.java` 的 `newBlockEntity()` 回傳原版 `ChestTileEntity`；`use()` 用 `player.openMenu(...)` 開箱子介面。**有容器 GUI 功能，但無自訂 Screen／Menu 註冊**；不可因沒有 GUI 資料夾而漏掉 |
| 車頭與編組 | `J/entity/LocomotiveCartEntity.java` 繼承 `FurnaceMinecartEntity`，自行控制朝向、碰撞、掉落與跟車位置；`J/link/LinkageManager.java` 維護車頭 UUID → 有序車廂 UUID 清單 |
| 區塊載入 | `J/event/ChunkEventManager.java`，入口 `J/SimpleRail.java#entityEnteredChunk`；使用 `ForgeChunkManager.forceChunk` |
| 生成與同步 | `J/entity/LocomotiveCartEntity.java` 的 `getAddEntityPacket()`／`defineSynchedData()`；`J/registry/Entities.java` 自訂 client factory；`J/setup/SimpleRailDataSerializers.java` 註冊 FacingDirection enum serializer。同步欄位是 `FACING`、`LINKABLE`；未找到自訂 SimpleChannel 或訊息處理器 |
| 客戶端渲染 | `J/setup/Render.java` 設定 9 種軌道 cutout 及車頭 renderer；`J/render/LocomotiveCartRender.java`、`J/render/model/LocomotiveCartModel.java`、`J/constants/Texture.java` 負責模型、貼圖與 8 方向朝向 |

本輪未在 Java 與 data 資源中找到世界生成實作，因此不設世界生成遷移階段。區塊強制載入屬於執行期行為，不是世界生成。

### 配方與資料資源

| 路徑 | 內容／數量 | 後續驗收重點 |
| --- | --- | --- |
| `R/data/simplerail/recipes/` | 13 個 JSON，均為 `minecraft:crafting_shaped`；涵蓋全部 13 種物品；`destory_rail` 產出 3，其餘產出 1 | 逐一核對材料、排列、產量與結果 ID；沒有自訂 RecipeType／Serializer 需搬移 |
| `R/data/simplerail/loot_tables/blocks/` | 12 個 JSON：11 方塊與額外的 `locomotive_cart.json` | 後者宣告 `minecraft:entity` 卻置於 blocks 路徑；車頭另在 Java 主動生成掉落。實際表格是否被使用待確認，勿據檔名新增方塊或重複掉落 |
| `R/data/simplerail/tags/blocks/{rails,machines}.json` | 分別列出 9 種軌道、2 種機器 | 扳手與車頭放置判斷依賴 |
| `R/data/simplerail/tags/items/wrench.json` | `simplerail:wrench` | Java 的 `SimpleRailTags.WRENCH` 卻宣告為 Block tag，且未找到使用處；依 D2 保留既有 tag ID，型別不一致的整理列入後續任務 |
| `R/data/minecraft/tags/blocks/rails.json` | 將全部 9 種自訂軌道加入原版 rails，`replace: false` | 核對原版礦車辨識與標籤合併 |
| `R/assets/simplerail/blockstates/` | 12 個 JSON | 11 種方塊外還有 `wrench.json`；扳手並非註冊方塊，額外資源用途待確認 |
| `R/assets/simplerail/models/block/`、`models/item/` | 40 個方塊模型、14 個物品模型 | 含反向、動力及計時等級變體；模型數量不等於註冊數量 |
| `R/assets/simplerail/textures/` | 44 個貼圖檔，含 blocks／items／entity | 核對引用、透明材質、車頭模型 UV |
| `R/assets/simplerail/lang/{en_us,zh_tw}.json` | 2 種語言 | 名稱與創造模式分頁翻譯 |
| `R/pack.mcmeta`、`R/logo.png` | 舊 pack format 為 `6` 與模組標誌 | 目標版格式及 metadata 引用待確認 |

data JSON 內找到的 namespace 僅為 `minecraft`、`simplerail`，沒有額外模組材料引用。T-009 已以指定來源查證單數資料目錄、配方 result.id、loot／tag／pack 格式，並交付 [格式與 ID 對照](docs/evidence/T-009/README.md)；既有 ID 保留。舊 blocks／items 貼圖需補 atlas 來源，額外車頭 loot context 與 wrench 型別問題明列。格式查證／獨立 JSON 檢查不是實際遊戲載入或驗收，移植與 runtime 仍待執行。

## 4. 舊資料與相容性風險

本節保留舊版格式與實作證據，供新版本功能設計及疑點修正參考。依 D1，舊世界匯入、NBT 格式轉換、舊箱子方塊實體轉換與 Forge 票證轉換均不在首版範圍；不要求取得舊世界樣本作為交付門檻。

### 4.1 註冊名稱與方塊狀態

依 D2，以下全部既有 ID 均保留：

- 方塊 registry：上表 11 個 `simplerail:*` ID。
- 物品 registry：同名的 11 個 BlockItem，加上 `simplerail:wrench`、`simplerail:locomotive_cart`。
- 實體 registry：`simplerail:locomotive_cart`。
- 自訂方塊實體 registry：`simplerail:timer_holding_rail`、`simplerail:signal_timer`。
- 標籤：`simplerail:rails`、`simplerail:machines`、`simplerail:wrench`，以及對 `minecraft:rails` 的擴充。

依據：`J/constants/I18n.java`、`J/constants/TileEntityCons.java`、`J/registry/`、`J/setup/SimpleRailTags.java` 與前述 tag JSON。`oneway_reverse_rail` 只有模型等資源，不是額外註冊方塊／物品。

**依 D2 保留 `destory_rail`，不改成 `destroy_rail`。** 配方、掉落表、tag 與資源 ID／引用也維持既有名稱。Java package 從 `ericchiu.simplerail` 改為 `com.ericchiu.simplerail`，不改變 registry namespace。D2 的回覆明確決定的是 ID；舊設定檔自動匯入與設定鍵整理方式並未另行指定，留待相關任務定義，不推定需要轉換器。

依 D4，發射器將新增專用方塊實體；T-012 已定義新增 BLOCK_ENTITY_TYPE ID 候選 `simplerail:train_dispenser`（與方塊／物品分屬不同 registry），BE 正式註冊和載入仍待 T-044。T-019 只完成同名方塊／物品骨架，不註冊 BE，不影響保留既有方塊／物品 ID 的要求。

| 自訂狀態名 | 定義值域 | 使用方塊 |
| --- | --- | --- |
| `reverse` | boolean | oneway、eject |
| `need_power` | boolean | oneway、eject、destory |
| `use_power` | boolean | oneway |
| `level` | 0–9 | timer_holding、signal_timer |
| `direction` | `Direction` enum，定義本身未限制為水平 | holding、timer_holding、兩種 Y 分岔 |

另需核對繼承的 `shape`、`powered`、發射器的 `facing`／`triggered` 等狀態與預設值。依據為 `J/setup/SimpleRailProperties.java`、各 `J/block/*.java` 與 `R/assets/simplerail/blockstates/`；完整原版繼承狀態和值域仍需確認，作為新版本行為與資源變體的驗收依據，不實作舊世界狀態轉換。

### 4.2 實際可見的持久化資料

| 所在位置 | 格式與行為 | 遷移風險／待確認 |
| --- | --- | --- |
| 車頭實體 NBT | `Train`：ListNBT，元素為 UUID 字串，順序代表車廂順序；`Facing`：字串 `east`、`west`、`north`、`south`、`north_east`、`north_west`、`south_east`、`south_west`；呼叫父類讀寫 | 新版本須保存車廂次序與朝向，並測讀寫一致性；不必讀取舊格式。父類欄位及目標版保存方式待確認。舊實作沒有自訂資料 schema version |
| 計時停車軌方塊實體 NBT | `save_time`：long 毫秒；`cart_uuid`：透過 `putUUID` 寫入；`go_time`：long 毫秒。載入時計算 `go_time + (目前時間 - save_time)` | D5 已決定維持實際秒數＋讀回補償，卸載／離線期間暫停。舊 `cart_uuid`／`go_time` 可不寫入，但 load 未先檢查鍵是否存在；新版本仍須測空白及不完整保存資料 |
| 訊號計時器 | 未覆寫自訂 NBT 讀寫；等級與供電由 BlockState 表達，週期依賴 tick 排程 | 重啟後訊號相位如何恢復、排程如何保存待確認 |
| 列車發射器 | 直接使用原版 `ChestTileEntity`，27 格內容由原版容器負責 | 舊版沒有 `simplerail:train_dispenser` 自訂方塊實體註冊。D4 已決定改用專用方塊實體、維持 27 格樣板及箱子式 GUI；只驗收新版本容器保存，不轉換舊箱子資料 |
| 區塊票證 | `ForgeChunkManager.forceChunk(world, simplerail, entity, chunkX, chunkZ, true, true)` | D3 已決定保持啟用及原專案邏輯；目標版對應機制待確認。不讀取或轉換舊 Forge 票證 |

依據：`J/entity/LocomotiveCartEntity.java#readAdditionalSaveData`／`addAdditionalSaveData`、`J/constants/I18n.java`、`J/tileentity/TimerHoldingRailTileEntity.java#save`／`load`、`J/tileentity/SignalTimerTileEntity.java`、`J/block/TrainDispenserBlock.java`、`J/event/ChunkEventManager.java`。

`J/constants/WorldData.java` 雖宣告 `timerholdingrail`、`savetime`、`cartUuid`、`goTime`，但全文搜尋未找到引用，也未找到自訂 WorldSavedData／SavedData 實作。**不能據此宣稱存在對應 `.dat` 存檔。** 這組名稱與目前 TileEntity 實際使用的底線命名不同；歷史發行版是否用過該格式待確認。

### 4.3 暫存狀態與舊行為疑點

以下是原始碼可見的風險，尚未經遊戲重現。依 D6，舊疑點修正將納入依本指南產生的 `TASK.md`，經使用者審閱後依序處理；本文件不自行啟動修正。D3 已指定的區塊載入邏輯，在經審閱的對應修正任務明訂變更前維持原專案行為。

1. **編組載入時序：** `LinkageManager.trains` 是 static map，沒有世界／維度範圍或獨立存檔；持久化來源是車頭 `Train`。`LocomotiveCartEntity.initTrain()` 只加入當時 `getEntity(UUID)` 找得到的車廂，再覆寫清單；晚載入、跨區塊或暫時找不到的車廂可能失去連結。`prevPos`、每車 `stopPos` 也沒有自訂持久化。
2. **區塊票證生命週期：** `ChunkEventManager` 的 radius 是 2，但 x/z 雙迴圈中傳入的始終是中心 `chunkX, chunkZ`；設定名 `disableLoadingChunk` 為 true 時實際執行載入。全文未找到解除 forceChunk 或票證驗證／清理呼叫。依 D3 保持啟用及此原專案邏輯，不自行改成 5×5 區塊，也不新增釋放政策；這些疑點保留給 D6 後續修正任務。舊版實際票證結果未實測者標「依原始碼推定／待確認」；以來源呼叫與 NEW API 對照及 NEW 實測推進，不要求 OLD 執行紀錄。
3. **路口暫存：** `CrossRail`、`YCrossRail`、`YCrossRightRail` 以 Block 實例內的 `Map<BlockPos, CartData>` 保存過車資料，鍵沒有維度。未看到持久化及世界卸載清理；須測不同維度同座標、路口中途存檔及多人同時通行。
4. **計時保存：** `TimerHoldingRailTileEntity` 的 setters 未呼叫 `setChanged()`；目前檔案是否可靠寫回不能單憑 save 方法存在來保證。計時計算另有 int 乘法及很大的可設定上限，邊界行為待測。
5. **發射器玩法：** `neighborChanged()` 有電就嘗試生成，沒有看到扣除槽位物品；使用物品作為列車樣板。一般礦車種類以物品 `toString()` 比對幾個原版名稱。D4 已決定保留不消耗物品的模式；觸發頻率與種類辨識疑點留給後續任務，D7 不要求第三方礦車支援。
6. **伺服器權責：** 部分 rail callback 沒有明確 client/server 判斷，車頭朝向也在 tick 更新；哪些舊回呼由哪一端執行及目標同步方式待確認。多人測試不可用單人結果取代。

### 4.4 設定檔與外部整合

`J/SimpleRail.java` 以 COMMON 類型註冊 `CommonConfig.SPEC`；沒有明訂設定檔名稱，實際舊檔名待確認。依 `J/config/CommonConfig.java` 與 `J/constants/Config.java` 可列出：

| 設定路徑 | 預設值 |
| --- | --- |
| `cart.locomotive.disableLoadingChunk` | true；實作語意見上方疑點 |
| `rail.high_speed_rail.maxSpeed` | 0.8，允許 0.4–2.0 |
| `rail.oneway_rail.needPower` | true |
| `rail.oneway_rail.usePowerChangeDirection` | false |
| `rail.eject_rail.transportDistance` | 3，允許 1–100 |
| `rail.eject_rail.needPower` | true |
| `rail.destory_rail.needPower` | false |
| `rail.timer_holding_rail.lv1` 至 `lv9` | 5、10、15、20、25、30、40、50、60 秒 |
| `rail.signal_timer_block.lv1` 至 `lv9` | 同上；注意實際群組在 `rail` 下 |

兩組計時值在類別的 static final 欄位讀取；是否支援設定重新載入、客戶端與伺服器如何一致，待確認。`usePowerChangeDirection` 的註解與程式是否達成同一行為也需以測例確認。

以上為 OLD 來源與未實測限制，保留不倒填。T-020 已實作 NEW 的 25 個同鍵／同預設／同範圍 COMMON 設定，固定檔名 `simplerail-common.toml`，Loading／Reloading 發布不可變快照、Unloading 清空；註冊不提早讀值，COMMON 不自動同步，以 logical server 決定功能。[完整載入／生效契約與預設表](docs/evidence/T-020/config-contract.md)及獨立 JVM 159 項測試已交付，R-02 待審；實際 FML 事件／檔案監看／遊戲功能生效未驗證。reload 不重寫世界、票證、既有等待 deadline 或已排程訊號；秒數值與 signal 的 20 ticks／秒、10 ticks 脈衝分開。極大值換算與 state 投影仍待原有功能任務，不提前修舊疑點。

未發現 Railcraft、Create、JEI 或其他模組的直接相依宣告／imports。依 D7，目前不需要任何外部模組，因此不新增外部模組依賴或整合驗收矩陣；以 Minecraft＋NeoForge＋Simple Rail 驗收。外部 datapack／腳本未指定需求，不推定需要整合。

發行 metadata 的歷史落差保留供參考：舊 `R/META-INF/mods.toml` 宣告 MIT，但 `OLD/LICENSE.txt` 開頭是 Forge／FML 的 LGPL 說明；新 `NEW/gradle.properties` 為 `All Rights Reserved`，另有 `NEW/TEMPLATE_LICENSE.txt`。依 D8，首版採目前的 `1.0.0`、`All Rights Reserved` 與 NeoForge `21.1.251`；本輪只記錄此決策，不變更 metadata 或授權檔案。

## 5. 已確認的需求決策

| 編號 | 使用者決策 | 對後續工作的影響 |
| --- | --- | --- |
| D1 | 不支援舊世界，不需要轉換流程 | 移除舊世界／NBT／箱子資料／票證轉換及升級測試；保留新版本自身存讀驗收 |
| D2 | 保留全部 ID | 保留第 4.1 節名稱及配方、掉落表、tag、資源 ID，包括 `destory_rail` 拼字；不實作 ID 重新映射 |
| D3 | 區塊載入保持啟用，行為維持原版邏輯 | 此處「原版」指原 1.16.5 Simple Rail 專案實作；以該程式為移植基線，不自行擴大載入範圍或新增釋放政策。疑點依 D6 另列修正任務 |
| D4 | 維持「27 格不消耗物品的列車樣板」，改用專用方塊實體，維持箱子式 GUI | 新增發射器專用方塊實體及必要容器連接；保留方塊／物品 ID，不承接舊箱子資料 |
| D5 | 保持實際秒數＋讀回補償，卸載／離線期間暫停 | 新版本保存剩餘等待時間所需資料並於讀回補償；不改用遊戲 tick 計時，須驗證卸載及關服後剩餘時間不被扣除 |
| D6 | `TASK.md` 將依本指南產生，經使用者審閱後，作為執行順序與舊疑點修正範圍的依據，後續依序完成 | `TASK.md` 已產生並經使用者審閱；本輪收錄 T-026 使用者失敗，斜坡需求範圍／銜接根因先釐清，未擅改共用基底、依賴或其他功能。歷史保留，疑點先調查再修正 |
| D7 | 目前不需要任何外部模組 | 不新增外部模組依賴或專用整合功能，以無其他模組環境驗收 |
| D8 | 目前發行版本號、授權宣告及目標 NeoForge 版本作為首版基線 | 固定本次規劃基線為 mod `1.0.0`、`All Rights Reserved`、NeoForge `21.1.251`，Minecraft `1.21.1`；不代表工具鏈或 API 已驗證 |

### 執行範圍補充決策（2026-09-26）

本輪使用者決定：**OLD build 由使用者先前驗證，本次流程不重跑**，優先推進 NEW 的 Minecraft 1.21.1＋NeoForge。此決策補充執行方式，不改動 D1–D8。

- T-002 免執行與已完成／已驗證分開；其前置阻擋移除。T-001 的既有 Git／工具鏈盤點及歷史草案保留，舊環境補下載方案不採用。
- T-003 僅整理舊版行為參考及未確認差異。已有可用 OLD JAR 時可按必要個案觀察，不為此重建；未實測一律標「依原始碼推定／待確認」，不稱舊版實測基線。
- T-002／T-003 不作 NEW 任務的硬性前置；API、實作及驗收各自追溯原始碼與已定需求。舊行為未明且影響驗收者，只列具體個案待確認，不全域停工；詳見 TASK.md「依賴阻礙與待查證細節」。六疑點仍先確認問題才修正，D3 不自行改為 5×5 或新增釋放政策。
- T-007 僅驗證 dedicated server 啟停；T-006／T-007 的 Agent 歷史結果保留。T-089 改由使用者連線驗證，前置含 T-090 固定版本測試包；T-017 只依賴開發所需 T-005／T-008，不等待 T-089。此為新分工下正式依賴，取代先前 T-017 等待連線的規劃。


### 新分工與交接（2026-09-27）

| 角色 | 責任與邊界 |
| --- | --- |
| 開發 Agent | API 查證、程式／資源遷移、Gradle build、非遊戲自動化程式測試、版本固定的 JAR 測試包、分析並修正使用者回報。不啟動 Minecraft，也不以無畫面／自動化方式代跑 server 或世界 |
| 獨立 Review Agent | 只審程式／資源差異、邏輯、功能與測例覆蓋、保存與同步設計、D1–D8；可檢查 build／靜態測試證據，不啟動 Minecraft、不重跑遊戲、不簽署人工測試通過 |
| 使用者 | 親自執行所有 client／dedicated server、世界、GUI、存讀、卸載、多人及候選 JAR 遊戲測試；只有使用者回報能成為人工測試結果 |

TASK.md 共 126 項、階段 0–8 不變。T-090–T-118 拆出 29 項測試包；T-119–T-124 承接六疑點人工重現；T-125 承接 T-081 的最終 runtime 清單／外觀驗收；T-126 承接 T-087 的效能實測。原任務編號、功能與驗收強度不變；新增項中 T-090／T-091 已開發完成，其餘待執行。T-003 始終只是來源參考；未實測 OLD 保持「依原始碼推定／待確認」。若未來確需既有 OLD JAR 觀察，也由使用者操作，不重建 OLD。

開發 Agent 的每次交接仍必須列 T／案例 ID、實際 commit（未提交差異另附指紋）、JAR SHA-256、Minecraft／NeoForge／mod／JDK／工具版本、安裝啟動步驟、NEW 場景與設定、事先預期／量測容差；log／截圖取得方法可供使用者選用。**2026-09-28 使用者決策：人工審查／遊戲測試項目不需提供證據，使用者確認完成即可記人工通過並結案。** 不要求使用者回傳版本證明、JAR 雜湊、log、畫面、存檔或逐案例資料；未提供的細節不虛構。指南各階段的操作、功能與驗收要求保留，所稱人工記錄與附件均為選用，不作人工結案門檻。開發與獨立程式審查仍保存自身證據，人工結案不推定其已完成。完整模板見 [TASK.md](TASK.md)，程式審查規範見 [REVIEW.md](REVIEW.md)。

開發完成、程式審查通過、待人工測試、人工測試通過／不通過及受阻分欄；T-006／T-007 只記 Agent 歷史。人工測試失敗後由開發 Agent 修正、Review Agent 複查程式、使用者重測原失敗及受影響案例。不同 JAR 結果不得無依據沿用。

人工測試不是技術必要前提時，不阻擋開發：T-017 依 T-005／T-008，T-019 依 T-017／T-008／T-010／T-004；T-018／T-089 人工閘門留在功能／整體交付。六疑點只有確認問題才修正；若某分項必須實測才能確認，只等待對應使用者重現，不擋其他開發。必要人工案例與程式審查未通過前，不宣稱受影響功能或最終候選交付完成；T-088 統一核對。

## 6. 分階段遷移順序與驗收

D1–D8 需求基線保留；T-001、T-003–T-007 歷史完成，T-002 免執行；R-01 原範圍通過，T-019–T-022／T-093 仍 R-02 待審，T-092 受阻；T-025 原開發交付／R-03 待審。T-018／T-089 人工結案保留，T-026 使用者已回報不通過，成坡需求及銜接改向待釐清／修正／重測；其他人工功能驗收未執行。以下功能及驗收要求保留，需求變更待使用者明定，責任／前置／狀態以 TASK.md 為準。開發 Agent 提供程式／build／非遊戲測試及包；Review Agent 審程式與覆蓋，全部遊戲由使用者執行並確認，人工附件選用。

| 階段 | 工作內容／依賴 | 驗收方式 |
| --- | --- | --- |
| 0. 任務清單與行為參考 | 維護已審閱的 `TASK.md`；T-002 依使用者決策免執行，T-003 整理原始碼中的功能、registry／state 與設定參考；既有 OLD JAR 的必要觀察為選用，不重建或轉換世界 | 任務清單符合 D1–D8 且經使用者審閱；對應第 3 節建立測例，標明沿用行為及各修正任務的預期差異；涵蓋未使用及計時中的軌道、27 格樣板、空／多節編組與跨區塊車廂；未實測 OLD 行為標「依原始碼推定／待確認」，不要求 OLD 實測紀錄才可推進 NEW |
| 1. 目標框架與 API 查證 | 使用 NEW 既有設定起步；查對指定 1.21.1／NeoForge 版本的來源及文件，建立舊符號→候選替代方式→驗證結果表；確認 Java／Gradle／mappings；後續再移除範例內容 | 執行目標 `./gradlew.bat build`，分別驗證 client 啟動（T-006）、dedicated server 啟停（T-007）與 client 連線（T-089），確認載入 mod ID 與 metadata；紀錄實際依賴版本。不可以只有 IDE 無紅字為驗收 |
| 2. 註冊、設定與基礎資源 | 依 D2 保留全部 ID；移植 11 方塊、13 物品與創造分頁、標籤／狀態／設定結構；依已查證格式處理模型、語系、配方與掉落資料 | registry 清單與第 4.1 節比對；物品可取得，模型與兩語系正確；13 配方逐一測合成、11 方塊測掉落，資料載入無相關錯誤；註冊成功尚不代表行為完成 |
| 3. 基礎軌道與扳手 | 共用 rail 基底、高速、停車、單向、下車與一般礦車移除；扳手調向／調等級。此時先驗證原版礦車，編組刪除留到階段 5 | 測四方向、紅石開關、反向、設定邊界與原版軌道銜接；速度設定覆蓋所有共用基底；下車位置、停車／放行與掉落符合決策；client 及 dedicated server 上結果一致 |
| 4. 方塊實體、計時與容器 | 依 D4 建立發射器專用方塊實體、27 格不消耗物品樣板與箱子式 GUI；依 D5 保留實際秒數＋讀回補償，並處理訊號排程；先測一般礦車生成 | 測等級 0–9、供電／停電、改設定與重啟；計時剩餘例如 3 秒時卸載或關服，讀回後仍約需 3 秒，允許誤差由測例明訂；未使用的計時軌及缺鍵資料能正確處理；容器存讀不遺失物品，觸發生成前後 27 格樣板內容及數量不變，GUI 可正常操作 |
| 5. 車頭、同步、渲染與編組 | 查證實體生成、資料同步、模型註冊與父類行為；完成車頭、扳手編組、發射器整列生成及 destory 整列移除 | 至少雙客戶端連到 dedicated server，測加入／重連、8 朝向、放置／命名／破壞／掉落與碰撞；編組順序在保存重啟及車廂晚載入後符合決策；不出現重複實體、殘留連結或同步錯誤 |
| 6. 路口與區塊生命週期 | 十字、兩種 Y 分岔；依 D3 維持區塊載入啟用與原專案邏輯；暫存、票證等疑點依 D6 清單分別修正 | 路口以適用的朝向、4 種來車方向及紅石狀態測試，分別以單車與編組通過；測不同維度同座標。記錄進入／離開區塊、停車、移除車頭、重啟及離開玩家範圍時的票證與列車行為，與原始碼呼叫及已查證 NEW API 規格比對，OLD 實際結果未知時標「依原始碼推定／待確認」，不宣稱兩版本實測等價；修正任務另訂前後差異，不預設 5×5 或新增釋放門檻 |
| 7. 新版本存讀回歸 | 依 D1 不做舊資料轉換；在 1.21.1 新世界整合驗證編組、專用容器、計時與方塊狀態保存 | 保存並重啟至少兩次，比對方塊／狀態、物品數量、車頭／車廂 UUID 與次序、27 格樣板及計時剩餘值；測卸載再載入，不遺失或重複內容；不執行 1.16.5 世界匯入驗收 |
| 8. 整合與發行候選 | 依 D6 清單完成回歸，採 D8 的 `1.0.0`／`All Rights Reserved`／NeoForge `21.1.251` 基線；更新本指南的已驗證與未支援項目 | 依 D7 在無其他模組的乾淨 client／dedicated server 以產出 JAR 重跑代表案例；確認 metadata、資源完整、無範例註冊殘留、日誌無本模組相關載入錯誤；記錄效能、已知限制及不支援舊世界的範圍 |

階段 1 的 API 查證至少涵蓋：註冊與事件、設定載入時機、rail hooks／礦車運動、BlockState、方塊實體 tick 與 NBT、容器開啟／同步、實體生成與資料序列化、client 模型／渲染、區塊票證、資源與資料包格式。其中入口／註冊／事件／設定／分頁候選已有 T-008 指定來源及最小編譯；資源／資料格式及 ID 對照由 T-009、軌道／互動／完整狀態值域及回呼來源由 T-010、方塊實體／計時／保存候選與卸載順序由 T-011、專用 27 格容器／箱子式 GUI 與槽位同步候選由 T-012、車頭／車廂運動與編組保存候選由 T-013、實體生成／追蹤與欄位同步候選由 T-014、模型／renderer／九軌 cutout 與 UV 候選由 T-015、區塊事件／票證與 D3 最小候選由 T-016 交付；其餘仍是待研究清單，不代表實際遊戲語意或整套 API 已驗證。

驗收以具體玩家行為及資料不變性為主；適合自動化的編組還原、缺鍵資料讀取、路徑選擇等再加入測試。目標專案雖宣告 gameTestServer 執行設定，目前未在來源找到本模組測例，不能當作現成驗收成果。

## 7. 定版狀態、待確認與待技術驗證項目

- 歷史完成：T-001 環境、T-003 的 25 項來源參考、T-004 的 44 組案例設計、T-005 NEW 框架 build。T-002 為使用者決定免執行，非 Agent build 結果。
- Agent 歷史啟停：T-006 client 已進入 NEW 新世界並正常結束；T-007 dedicated server 已完成新世界啟動、保存、停止；兩者退出碼 0。原始證據與限制保留，不代表使用者人工測試、T-089 連線或後續功能完成。
- 已知歷史限制：T-006 出現範例 example_block／example_item 模型缺失的非致命警告，交 T-017／T-018 與後續資源驗收處理；同名世界兩次登入的中間操作未完整取證，不能當作存讀回歸通過。T-005 test 為 NO-SOURCE，不能稱自動化測試通過。
- T-008 開發完成：[A01–A14 API 對照及原始證據](docs/evidence/T-008/README.md) 固定 NeoForge 21.1.251／FML 4.0.44；最小編譯重試退出 0，原始沙箱失敗退出 1 亦保留。只查證候選簽名與來源，未執行探針或遊戲。COMMON 載入前讀值風險、不自動同步及重載執行緒限制交 T-020 等後續處理；正式創造分頁 key／順序由 T-019 定義。
- T-009 開發完成：[格式／ID／引用及非遊戲檢查](docs/evidence/T-009/README.md)；144 檔／13 配方／266 條直接引用有對照，獨立工具編譯與檢查退出 0。沒有執行 Minecraft codec、pack 載入、datagen 或 Gradle build；額外資源與 atlas 問題交 T-021／T-022／T-048。
- T-010 開發完成：[API／執行端對照及完整狀態](docs/evidence/T-010/README.md)；77 個來源快照、最小編譯退出 0，失敗 log 與探針原稿保留。PoweredRailBlock 的 true 參數、isFlexibleRail、any() 預設覆蓋、waterlogged、回呼前後的礦車邏輯及 use 互動順序均列明；沒有執行回呼或遊戲測試。
- T-011 開發完成：[方塊實體／計時／保存 API、資料邊界與生命週期證據](docs/evidence/T-011/README.md)；指定版來源快照 34 個，最小編譯重試退出 0，沙箱內 Wrapper 鎖檔失敗退出 1 保留。來源顯示卸載時先保存再呼叫 BE `onChunkUnloaded`，因此該回呼不能當最後寫盤點；D5 實際秒數、讀回補償及缺鍵處理已有候選設計，尚未實作或遊戲驗收。
- T-012 開發完成：[專用 27 格容器、箱子式 GUI 與同步候選](docs/evidence/T-012/README.md)；指定版來源快照 23 個、OLD 來源 1 個，最小編譯重試退出 0，初次 Wrapper 鎖檔失敗退出 1 保留。新增 BE ID 候選 `simplerail:train_dispenser`，位於不同 registry，不更動同名既有方塊／物品 ID；原版 `GENERIC_9x3` 可作 GUI 候選。正式註冊、觸發、存讀與多人介面均未驗收。
- T-013 開發完成：[車頭、車廂運動與編組保存 API／資料所有權候選](docs/evidence/T-013/README.md)；指定版來源 25 個、OLD 來源 6 個，最小編譯重試退出 0，初次 Wrapper 鎖檔失敗退出 1 保留。`ServerLevel#getEntity(UUID)` 查不到時不等於車廂已刪除；有序 UUID 清單需與暫存實體引用分開。正式移植、晚載入、動力父類行為、存讀與同步均未驗收。
- T-014 開發完成：[實體生成、FACING／LINKABLE 及追蹤資料同步候選](docs/evidence/T-014/README.md)；指定版來源 21 個、OLD 來源 5 個，最小編譯重試退出 0，初次 Wrapper 鎖檔失敗退出 1 保留。OLD `LINKABLE` 僅見宣告／預設 true；舊 enum serializer 的直接註冊不能照搬，內建 BYTE／BOOLEAN 為可編譯候選。正式實作、重連及雙 client 一致性仍待查證／使用者測試。
- T-015 開發完成：[九軌 cutout、模型／UV／渲染候選](docs/evidence/T-015/README.md)；指定版來源 16 個、OLD 來源 5 個，九軌資源靜態盤點為 29 個引用模型及 29 張透明貼圖；車頭 PNG 實測 96×64。最小編譯重試退出 0、初次 Wrapper 鎖檔失敗退出 1 保留。正式 JSON／atlas 遷移、renderer 坡度與 UV 畫面尚未驗收。
- T-016 開發完成：[區塊事件／票證指定版候選及 D3 觀測邊界](docs/evidence/T-016/README.md)；指定版來源 12 個、OLD 來源 3 個，最小編譯重試退出 0、初次 Wrapper 鎖檔失敗退出 1 保留。保留 radius=2 迴圈反覆傳中心區塊、ticking=true 及不新增釋放政策；正式票證保存／運作及舊疑點未實測。
- T-017 開發完成：[正式空功能入口、範例移除、NEW build 與 client 邊界證據](docs/evidence/T-017/README.md)；離線 build 重試退出 0、初次沙箱 Wrapper 鎖檔退出 1 保留。JAR 的 `simplerail`／D8 metadata 及無模板註冊已靜態核對；`test NO-SOURCE`，R-01 程式審查通過；T-018 的使用者 runtime 回報另列，不自行綁定此 JAR。
- T-090／T-091 開發完成：[連線包](docs/evidence/T-090/README.md)、[正式框架包](docs/evidence/T-091/README.md)，各 5 案例／16 檔；含固定 JAR、來源差異／指紋、版本、安裝步驟、場景／預期、選用 log／畫面方法與空白結果欄。共享 NEW build 退出 0、`test NO-SOURCE`；JAR SHA-256 與 T-017 相同，ZIP 逐檔內容核對成功。R-01 程式審查通過，未啟動新包的遊戲測試，不把使用者舊回報代填為此包結果。
- 使用者人工回報：2026-09-28 使用者表示「我已驗證完 T-089、T-018，皆正確執行」，並明定「人工審查項目不需提供證據，由使用者確認完成即可結案」。[T-089 確認紀錄](docs/evidence/T-089/README.md)、[T-018 確認紀錄](docs/evidence/T-018/README.md)已保存，兩項**人工測試通過並已結案**，不要求補證。T-090／T-091 已有實際開發交付，R-01 本輪獨立審查通過，並非由人工確認推定；不自行填寫逐案例細節或受測 JAR 身分。
- T-019 開發完成：[11 方塊／13 物品／正式分頁與建置證據](docs/evidence/T-019/README.md)、[ID／配對／順序](docs/evidence/T-019/checks.json)、[完整屬性對照與未實作清單](docs/evidence/T-019/state-contract.md)。destory_rail 保留，分頁新 key simplerail:tab、圖示 high_speed_rail、明列 13 物品；NEW 離線 build 退出 0，18 項靜態檢查通過，test NO-SOURCE。十一個普通 Block 尚無軌道／自訂 state／機器行為；R-02 待審，未啟動 Minecraft，runtime 可取得性／GUI 待使用者 T-023。
- T-020 開發完成：[25 個正式 COMMON 設定及實際證據](docs/evidence/T-020/README.md)、[預設／值域／載入及生效契約](docs/evidence/T-020/config-contract.md)。NEW 離線 build 退出 0，獨立 JVM 159 項檢查通過，Gradle test NO-SOURCE；初次測試工具失敗另存。保留全部鍵與 D3 true＝啟用；尚無功能消費者、時間換算或同步協議，R-02 待審，FML／遊戲 reload 與生效未驗證。
- T-021 開發完成：[114 來源資源／atlas／logo 交付與證據](docs/evidence/T-021/README.md)、[全部去向／ID](docs/evidence/T-021/resource-map.json)、[資源決策與 I-021-01](docs/evidence/T-021/RESOURCE_DECISIONS.md)。29 模型 cutout、43 sprite 來源、雙語及 pack 策略已接；2519 靜態檢查／563 引用／45 PNG 完整解碼通過，NEW build 退出 0、test NO-SOURCE。10 個骨架缺 selector 屬性、9 種候選域部分變體未覆蓋，T-092／T-023 不可據此宣稱 ready；正式依賴／狀態域不改，需依 D6 後續承接。R-02 與遊戲／外觀／codec 載入均未通過。
- T-022 開發完成：[29 資料檔與實際證據](docs/evidence/T-022/README.md)、[ID／映射](docs/evidence/T-022/data-map.json)、[資料與掉落契約](docs/evidence/T-022/DATA_CONTRACT.md)。配方只換結果欄位，destory_rail=3／其餘=1，tag 9／2／1 與 replace=false 保留；ModTags.WRENCH 為 item 型別。額外車頭 loot 保留原 ID／entity type，僅移除不相容爆炸條件，不掛接到未實作車頭；T-048／T-052／T-062 承接正常單一路徑與回歸。393 靜態檢查／85 引用通過，NEW build 退出 0，test NO-SOURCE；R-02 待審，遊戲合成／掉落／tag／reload 未測。
- 未執行：T-025 以外功能行為／自訂狀態、T-026 以外後續使用者人工功能／候選測試與 R-02 以後獨立程式審查；T-026 已回報不通過，不宣稱其他測例通過。資料或程式已建置不等於 runtime 載入通過。
- T-092／T-093 包製作：[T-092 受阻草稿／命令與靜態證據](docs/evidence/T-092/README.md)、[T-093 完成判定](docs/evidence/T-093/README.md)。31 檔／156 及 226 案例，固定同一 T-022 JAR、全部 actual=null；本輪未重跑 build／遊戲。I-021-01 及 I-092-02（有效 COMMON 觀測未齊）阻擋 T-023 新包，T-024 前置仍等 T-023；T-093 包完成不表示功能交付或人工通過。R-02 待審。
- 保留排除項：不支援舊世界／NBT／箱子／票證轉換，不加入外部模組。OLD build 由使用者先前驗證，本次流程不重跑。
- T-025 原開發交付保留：[build／bytecode／JAR 證據](docs/evidence/T-025/README.md)、[來源行為及未測差異](docs/evidence/T-025/RAIL_CONTRACT.md)。兩基底及高速工廠接共同速度快照、禁坡與實體破壞 false；動力 true、父類狀態／紅石保持，只加本軌 pickaxe tag；原 NEW build 0、40 靜態核對通過、test NO-SOURCE。當時人工未測是歷史；現在 T-026 使用者回報不通過，不沿用靜態結果推定行為正確。I-021-01／I-092-02、R-03／T-094 仍未完成。
- T-026 使用者回報：[原文、兩問題及來源調查](docs/evidence/T-026/REPORT-001.md)。無原版動力軌斜坡（I-026-01）與指南原禁坡規格不同，需求範圍待確認；高速平軌／原版斜坡銜接改向（I-026-02）已登錄，根因未確認、未修复。受測 JAR、配置、坡頂／坡底等未提供，不要求附件、不補造逐例結果。只記人工不通過，不倒填 T-094／程式審查，不改基底或資源。
- 待技術驗證：各功能的 1.21.1 API／資料格式、專用方塊實體保存與 GUI、車廂 UUID 次序／晚載入／同步、實際時間與讀回補償、訊號相位、全部 ID、區塊載入原邏輯與六疑點。剩餘約 3 秒卸載／關服後仍約需 3 秒的兩條路徑均保留；容許誤差仍待技術定義。

`TASK.md` 已經使用者審閱，原歷史／R-01／T-018／T-089 結案保留。[T-026 最新回報](docs/evidence/T-026/REPORT-001.md)為人工不通過：先釐清高速成坡範圍與銜接改向場景，再修正、程式複查及使用者重測；不擅改其餘軌道。T-027 原開發前置不因人工失敗自動變更，但本輪不推進其他功能。T-094／R-03、R-02 及 T-092／T-023 整合閘門仍未完成；使用者無需提供附件，不推定修復結果。
