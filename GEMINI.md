# 專案全局設定 (Project Context)
這是一份給 AI Agent (Gemini) 的核心指導原則。在生成任何程式碼前，請務必嚴格遵守以下所有規範。

## 1. 專案元資料 (Project Metadata)
* **模組名稱 (Mod Name):** Simple Rail
* **模組 ID (Mod ID):** simplerail
* **Minecraft 版本:** 1.21.1
* **NeoForge 版本:** 21.1.224
* **Java 版本:** Java 21
* **基礎套件路徑:** `com.ericchiu.simplerail`
* **模組主類別:** `SimpleRail.java`

## 2. 絕對禁忌與紅線 (Strict Taboos - DO NOT DO THIS)
* **嚴禁使用舊版 Forge:** 絕對不可引入 `net.minecraftforge.*` 的任何類別。所有 Forge 相關 API 皆已遷移至 `net.neoforged.*`。
* **嚴禁混用 Fabric API:** 我們是純正的 NeoForge 模組，拒絕任何 Fabric 相關的程式碼或註解。
* **嚴禁使用 FMLJavaModLoadingContext:** NeoForge 1.21 已徹底移除此類別。取得 Mod Event Bus 必須透過模組主類別的建構子參數 (`public SimpleRail(IEventBus modEventBus)`) 注入，絕不可使用舊版的靜態獲取方法。
* **嚴禁手寫 JSON:** 所有配方 (Recipes)、掉落物 (Loot Tables)、方塊狀態 (Blockstates)、模型 (Models) 與標籤 (Tags)，**必須**透過 Data Generation (Datagen) 生成，嚴禁在 `src/main/resources` 下手動建立 JSON。
* **嚴禁在物品上使用 NBT (No Item NBT):** Minecraft 1.21 已經徹底廢除 `ItemStack` 的 NBT 系統。若要替物品附加自訂資料，**必須**註冊並使用 **Data Component Types (資料組件)** 系統。
* **嚴禁使用 @OnlyIn 註解:** `@OnlyIn` 是遊戲底層專用的標記。模組開發中，**絕對禁止**使用 `@OnlyIn` 來區分 Client/Server。必須使用實體類別隔離與 `Dist.CLIENT` 事件總線來處理客戶端邏輯。
* **嚴禁隨意更改 Mod ID:** 註冊所有物品、方塊時，必須參照頂層的 Mod ID。
* **嚴禁**直接進行實作，**必須**先完整查詢 NeoForge 社群 1.21 的推薦最佳實踐 (Best Practices)，並依此實作。
* **嚴禁**一次給所有程式碼，**必須**一步一步給程式碼 (Give the code step by step)。

## 3. 專案架構與命名規範 (Architecture & Naming)
請將程式碼放入對應的套件 (Package) 中：
* `...registry`: 存放所有的 `DeferredRegister` (如 `ItemRegistry`, `BlockRegistry`)。
* `...block`: 存放自訂方塊類別與對應的 BlockEntity。
* `...item`: 存放自訂物品類別。
* `...entity`: 存放實體邏輯 (Entity Classes)。
* `...client`: **必須**將所有僅限客戶端的程式碼 (Renderers, Models, Screens) 放在此處。客戶端事件必須透過 `@EventBusSubscriber(modid = MODID, bus = Bus.MOD, value = Dist.CLIENT)` 進行安全註冊，避免 Server 崩潰。
* `...datagen`: 存放所有的 Data Providers (ItemModelProvider, RecipeProvider 等)。
* `...network`: 存放封包與網路傳輸邏輯 (Payloads & Handlers)。
* `...event`: 存放事件監聽器。
* `...config`: 存放模組設定檔 (ModConfig)。

## 4. NeoForge 核心實作標準 (NeoForge Standards)
* **註冊機制:** 一律使用 `DeferredRegister` 及其變體 (如 `DeferredRegister.Items`, `DeferredRegister.Blocks`)，並使用對應的 `DeferredItem<T>` 或 `DeferredBlock<T>` 接收回傳值。禁止直接操作 `ForgeRegistries` 或 `BuiltInRegistries` 進行註冊。
* **方塊與物品連動:** 註冊 `Block` 後，若該方塊需要能在物品欄出現，**必須**同步註冊對應的 `BlockItem`。
* **創造模式物品欄:** 使用 `DeferredRegister<CreativeModeTab>` 建立自訂 Tab，或透過 `BuildCreativeModeTabContentsEvent` 將物品加入原版標籤頁。
* **全新 Capability 系統:** 嚴禁使用舊版 `LazyOptional`。在處理物品欄 (Inventory)、能量或流體時，必須使用 NeoForge 1.21 全新的 Capability 查詢系統 (例如：`level.getCapability(Capabilities.ItemHandler.BLOCK, pos, state, blockEntity, side)`)。
* **標籤優先 (Tags First):** 在判斷方塊或物品身分時，嚴禁硬編碼 (Hardcoding)，必須優先使用 `ItemTags` 或 `BlockTags` (例如：`stack.is(Tags.Items.INGOTS_IRON)`)。
* **事件訂閱:** 善用 `@EventBusSubscriber` 註解。務必區分清楚 `mod` 總線 (註冊、Setup、Datagen) 與 `game` 總線 (遊戲內事件，如 TickEvent、EntityJoinLevelEvent)。
* **網路同步:** 使用 NeoForge 1.21 的 `IPayloadRegistrar` 與 `CustomPacketPayload` 系統進行 Client/Server 同步。
* **屬性設定:** 使用 `Item.Properties` 和 `BlockBehaviour.Properties` 來設定屬性。
* **模組設定檔:** 使用 `ModConfig` (`net.neoforged.neoforge.common.ModConfigSpec`) 系統，設定檔 `comment` 使用英文。

## 5. 程式碼風格 (Code Style)
* 程式縮排: 2 spaces
* 註解語言: 繁體中文
* 充分利用 Java 21 特性：使用 Records 處理資料載體 (Data Carriers) 與封包、使用 Switch Expressions 簡化條件判斷、使用 Pattern Matching。
* 變數與函式命名應具備高度可讀性。
* 複雜的遊戲邏輯 (如自訂方塊的 `tick` 運算或 Data Components 的轉換) 必須加上詳盡的繁體中文註解。
* **日誌系統:** 嚴禁使用 `System.out.println`，統一使用 SLF4J (`org.slf4j.Logger`) 進行模組的日誌輸出。

## 6. 當前開發進度與焦點 (Current State & Focus)
[這裡由你動態更新，讓 AI 知道目前專案進度與現在該專注什麼]