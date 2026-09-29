# T-008 入口、註冊、設定與創造分頁 API 查證

日期：2026-09-27。狀態：**開發完成；R-01 程式審查待審；人工遊戲未執行**。前置 T-004／T-005 已有各自歷史交付。本項只確認指定來源的 API 與最小編譯，不代表模組移植、FML 載入實測、設定重載、GUI 或多人驗收完成。

## 固定版本與證據範圍

NEW `D:/workspace/java/simple-rail-1.21.1`，HEAD `8bd977dbb9f9000411ae5f4d10750228e5f33560`；OLD `D:/workspace/java/simple-rail`，來源 HEAD 沿用 T-003 的 `6698b1c5f494095a15b055c10045293e91540012`。本次未重建／啟動 OLD，舊行為仍是「依原始碼推定／待確認」。

目標為 Minecraft **1.21.1**、NeoForge **21.1.251**；本地實際編譯 classpath 含 FML loader **4.0.44**、event bus **8.0.5**。Java／javac **21.0.12.1**、Gradle **9.2.1**、ModDevGradle **2.0.147**、Parchment **1.21.1／2024.11.17** 沿用 NEW 設定；版本值及 classpath 有快照／指紋，不使用其他遊戲版本作替代。

- [來源與 archive SHA-256](source-manifest.json)：17 個指定 NeoForge／FML／Minecraft 來源快照，加 11 個 OLD 來源；來源檔保留原版權與授權標頭。NEW merged sources 由既有 ModDevGradle 產物提供。
- [實際 compile classpath](compile-classpath.txt)、[classpath SHA-256](classpath-manifest.json)、[編譯器路徑](compiler.txt)、[javac 版本命令](javac-version.json)。
- [Java 探針](probe/T008Probe.java)、[client 探針](probe/T008ClientProbe.java)、[測試專用 init script](probe.init.gradle)。不加入 main sourceSet、不產生 mod metadata、不打包成正式 JAR，未載入／實例化。
- [來源未變更核對](product-source-check.json)、[Git／範圍核對](verification.json)：12 個產品來源／Gradle／資源檔案與 T-005 指紋相同；未改 `src/`、專案 Gradle、ID 或設定。T-017／T-019／T-020 未執行。

## 符號與最小編譯對照

下表的 `N/` 指 `sources/neoforge/net/neoforged/neoforge/`，`F/` 指 `sources/fml/net/neoforged/fml/`，`M/` 指 `sources/neoforge/net/minecraft/`，`O/` 指 `sources/old/`。行號依本次快照；所有用法均由同一次成功編譯涵蓋。P 為 `probe/T008Probe.java`，C 為 `probe/T008ClientProbe.java`。來源／簽名確認與 runtime 通過分開。

| 編號／OLD 來源 | 指定版本候選與來源位置 | 編譯證據／下游 |
| --- | --- | --- |
| A01 入口 `O/SimpleRail.java:37`，無參數入口／getModEventBus | `@Mod(String value)`；入口可用單一 public 建構子 `IEventBus, ModContainer, Dist` 注入。`F/common/Mod.java:24`；`F/javafmlmod/FMLModContainer.java:91` 起檢查建構子數量、允許型別與重複參數 | P:33、59；候選編譯通過。實際 FML 注入未執行；T-017／T-018 |
| A02 setup 與 game bus；`O/SimpleRail.java:42`、`O/setup/Registration.java:11` | `modBus.addListener` 用於 mod lifecycle／register／config；`NeoForge.EVENT_BUS.addListener` 用於 `ServerStartingEvent`。`F/javafmlmod/FMLModContainer.java:57` 的 IModBusEvent 標記；`N/internal/CommonModLoader.java:69` 的 setup 派發 | P:59–74、94；沒有把 ServerStartingEvent 接到 mod bus；T-017 |
| A03 舊巢狀 `@Mod.EventBusSubscriber(bus=MOD)`，`O/SimpleRail.java:86` | `@EventBusSubscriber(modid=..., value=Dist.CLIENT)`。**FML 4.0.44 的 bus() 已棄用且忽略**；按事件是否實作 IModBusEvent 自動選 bus。`F/common/EventBusSubscriber.java:38`、`F/javafmlmod/AutomaticEventSubscriber.java:52`、74；處理器須 static、單一 Event 參數 | C:13、16；不照搬舊 bus 參數，不和手動訂閱同一 handler 重複接線；T-017 |
| A04 並行 setup／client 分離，`O/SimpleRail.java:62`、67 | `FMLCommonSetupEvent`／`FMLClientSetupEvent` 的 `enqueueWork(Runnable)`（本次候選）；`F/event/lifecycle/ParallelDispatchEvent.java:21`。client 用獨立 `@Mod(value=..., dist=Dist.CLIENT)`；`F/common/Mod.java:19`、37；subscriber 先篩 dist 再載入類別，見 AutomaticEventSubscriber:52–55 | P:74；C:12–19。common 探針不 import net.minecraft.client。物理 client 隔離不等同邏輯 server 權責驗證；T-017／T-018，後者 T-063 |
| A05 方塊／物品，`O/registry/Blocks.java:25`、`O/registry/Items.java:17` | `DeferredRegister.createBlocks(String)`／`createItems(String)`，`registerSimpleBlock(String, Properties)`／`registerSimpleBlockItem(String, Supplier<? extends Block>)`／`registerSimpleItem(String, Item.Properties)`；回傳 DeferredBlock／DeferredItem。`N/registries/DeferredRegister.java:142` 起及 Blocks／Items 類別 | P:36–43，保留 namespace＋既有 path 的策略；不是移植軌道功能；T-019 |
| A06 RegistryObject／延遲綁定，舊 Items 的 Blocks.get 及 TileEntities 的靜態建立 | `DeferredHolder<T,I>`、`register(String, Supplier<? extends I>)`、`register(IEventBus)`；`N/registries/DeferredRegister.java:214`、314；`DeferredHolder.java:100`、115 的 value/get 在未綁定時可失敗。不可在提早靜態初始化中急取尚未註冊物件 | P:44 的 tab/icon／items supplier 與 P:81 泛型 factory；T-019、T-011／T-013 接續實際型別工廠 |
| A07 RegistryEvent.Register／setRegistryName，`O/registry/TileEntities.java:18` | `RegisterEvent implements IModBusEvent`；`<T> register(ResourceKey<? extends Registry<T>>, ResourceLocation, Supplier<T>)` 或 helper overload；`N/registries/RegisterEvent.java:27`、46、60。不使用 setRegistryName；key 與 namespace/path 分開傳入 | P:77–80 兩種 overload 均編譯；此處用 Item 作最小泛型例，不冒充 BE factory 已查證；T-011／T-019 |
| A08 跨 registry 型別骨架，`O/registry/Entities.java`、`TileEntities.java` | `DeferredRegister.create(Registries.ENTITY_TYPE, id)`、`create(Registries.BLOCK_ENTITY_TYPE, id)`；延遲 Supplier。`N/registries/DeferredRegister.java:113`、214；registry 派發見 `N/registries/GameData.java` 的 postRegisterEvents | P:39–40、62–63、81；只證泛型與註冊接線，entity／BE 建構與保存留 T-011／T-013 |
| A09 ForgeConfigSpec.Builder，`O/config/CommonConfig.java:13` | `ModConfigSpec.Builder`、`define(String, boolean)`、`defineInRange(String,double,double,double)`、`defineInRange(String,int,int,int)`、`build()`；`N/common/ModConfigSpec.java:733`、753、770。舊 configure/Pair 可改為直接持有 spec／value 欄位，不必保留 Pair 結構 | P:50–54；示範 Boolean／Double／Int，不修改既有 25 個設定值／語意；T-020 |
| A10 COMMON 註冊，`O/SimpleRail.java:48` | 建構時 `ModContainer.registerConfig(ModConfig.Type.COMMON, IConfigSpec)`；可另有 filename overload。`F/ModContainer.java:102`、119；`F/config/ConfigTracker.java:101` 決定預設 `modid-common.toml` | P:70；只編譯未指定檔名 overload。NEW 預設推導為 simplerail-common.toml，不宣稱 OLD 實際檔名／檔案相容；T-020 |
| A11 設定載入／reload，舊 static final LV 值讀取 | `Loading`／`Reloading` 事件、`event.getConfig().getSpec()` 過濾；`getAsBoolean/getAsDouble/getAsInt`。`F/event/config/ModConfigEvent.java:12`、28、40；`F/config/ModConfig.java:72` 先 acceptConfig 再派發；`N/common/ModConfigSpec.java:1219`、1232 | P:87–92 編譯以不可變 Snapshot＋volatile 發布的候選，不觸及世界。正式重載生效策略仍待 T-020；不承諾本探針已驗證並行行為 |
| A12 ItemGroup／Item.Properties.tab，`O/itemgroup/Rail.java:10`、`O/registry/Items.java` | CreativeModeTab 是 registry；`DeferredRegister<CreativeModeTab>`、`CreativeModeTab.builder().title(Component).icon(Supplier<ItemStack>).displayItems(DisplayItemsGenerator).build()`；`M/world/item/CreativeModeTab.java:79`、221、226、231、361 | P:38、44–48。正式分頁用高速軌圖示並列 13 物品，後續 T-019；探針只列兩個樣本，不等於完整分頁已實作 |
| A13 向既有分頁添項 | `BuildCreativeModeTabContentsEvent.getTabKey()`／`accept(...)`；`N/event/BuildCreativeModeTabContentsEvent.java:27`、50，實作 CreativeModeTab.Output。依來源可能多次觸發，原版多在邏輯 client 但模組可在 server 請求，不一概標成只能物理 client | P:84–85；本模組自有分頁優先使用 displayItems；事件為候選用法而非新增產品需求 |
| A14 namespace／ResourceLocation／ID | 註冊 path 由 `DeferredRegister.register` 組合 namespace；直接事件使用 `ResourceLocation.fromNamespaceAndPath(String,String)`，`N/registries/DeferredRegister.java:224` 起；舊 I18n／名冊及 D2 為產品 ID 依據 | P:78–79、75 的 getId；`destory_rail` 拼字不變，不新增 alias／舊資料轉換；T-019 |

## 設定時序與需要避免的直接照搬

精確來源鏈為 `CommonModLoader.begin`：建構 mod → registry 初始化與 RegisterEvent → 正常非 datagen 路徑載入 CLIENT／COMMON；`load` 再派發 FMLCommonSetupEvent／sided setup。`ModConfigSpec.ConfigValue.getRaw()` 在 spec 未建好或設定未載入時拒絕讀取；Loading 事件發生前 spec 已接受讀入資料。這是**指定來源的靜態查證**，不是本次錄製的遊戲時序。

OLD `block/TimerHoldingRail.java:27–35` 與 `tileentity/SignalTimerTileEntity.java:19–27` 在 static final 初始化讀取等級設定。推論：在 NEW 註冊階段直接照搬這種讀取，可能在 COMMON 尚未載入時失敗；即使初始讀取成功，static final 的 Java 值也不會因設定重載自動改變。T-020 應明確設計載入後讀取／快照更新，而不是在註冊建構時讀 COMMON；實際效果交 T-023／T-040／T-042 使用者驗收。

FML 4.0.44 `ModConfig.Type.COMMON` 明訂不自動同步；`Reloading` 可來自檔案監看且不保證遊戲執行緒。候選採只讀設定並發布不可變快照，避免回呼直接操作世界；何時生效、是否需排程以及 client/server 權威使用方式須由 T-020 與 T-014／T-063 查證實作，不自行改為 SERVER 設定或添加網路協議。D3 的 true＝啟用、D5 秒數與訊號 tick 的區別均不改。

## 最小編譯的實際結果

執行工作目錄為 NEW，完整命令：

```powershell
.\gradlew.bat compileT008Probe --offline --console=plain --info --no-configuration-cache -I docs/evidence/T-008/probe.init.gradle
```

由 [compile.ps1](compile.ps1) 保存原始合併 stdout／stderr（PowerShell UTF-16 log）與起訖／退出碼。

| 嘗試 | 實際結果 | 證據 |
| --- | --- | --- |
| 01 沙箱內 | 退出 1，Wrapper 的 C:\.gradle 鎖檔路徑無法建立，尚未編譯 | [命令／時間／退出碼](compile-01.json)、[完整 log](compile-01.log) |
| 02 經允許沙箱外、同參數離線重試 | 退出 0，BUILD SUCCESSFUL in 7s；createMinecraftArtifacts 為 UP-TO-DATE、compileT008Probe 實際執行 | [命令／時間／退出碼](compile-02.json)、[完整 log](compile-02.log) |

`--release 21 -Xlint:deprecation -Werror`，產出 3 個 class、major version 65，保存 [class 指紋](compiled-classes.json) 與 compiled/ 副本。Java 編譯未報錯或棄用警告；Gradle 仍有未來 Gradle 10 相容性的 deprecation 提示，不宣稱零警告。任務圖只有 createMinecraftArtifacts／compileT008Probe，沒有 runClient／runServer／GameTest／data，也沒有執行探針 class 或正式模組 build／JAR 任務。

準備期曾因 `AutomaticEventSubscriber.java` 的來源路徑少了 `javafmlmod/` 導致提取退出 1，修正證據工具後來源提取成功；另一次只讀 rg 命令使用 PowerShell 不支援的 brace list 解析失敗，重做明確檔案路徑讀取。兩者不是 API 編譯失敗，不改寫為成功；原始編譯失敗與成功 log 均保留。此項不宣稱曾完成任何非編譯自動化程式測試。

## 待查證／下游驗證

| 未完成事項 | 責任／任務與影響 |
| --- | --- |
| 正式入口注入、dist 隔離及事件執行結果 | T-017 開發；T-091 測試包後由使用者 T-018 測；不能由 compile-only 宣稱 dedicated server 可載入新正式入口 |
| 正式創造分頁 registry ID、擺放順序 | T-019 定義：OLD 是 ItemGroup 名稱 `simplerail.tab`，語系 key 為 `itemGroup.simplerail.tab`，未取得舊 CreativeModeTab registry ID。須保留舊語系／內容並記錄新增 registry key 的理由；不直接採用探針的 t008_probe／probe_tab 或現有範例 key |
| COMMON 生效時點、重載與 client/server 一致性 | T-020 定義策略；T-014／T-063 處理必要權責／同步查證；設定操作由使用者 T-023 及各功能案例驗證。預設值／範圍與鍵不在此更改 |
| BE／entity 真正 factory、軌道方法、保存、同步、渲染 | T-010–T-016 仍待執行；本次只確認其 registry 泛型通道，未確認產品類別建構／遊戲語意 |
| 13 物品完整顯示、重複加入、reload、物件取用時序 | T-019／T-021 開發；使用者 T-023／T-024；探針不是實際遊戲測例 |
| 範例移除及先前缺模型警告 | T-017／T-018 與資源任務處理；本次完全未修正 |

以上是未實作／未實測的下游工作；本項 A01–A14 的候選均有精確來源與編譯交付，沒有以待確認的 API 猜測填補本項完成條件。R-01 程式審查仍待審，所有人工結果欄保持未執行。

## 官方文件輔助索引

2026-09-27 閱讀的 [1.21.1 入口文件](https://docs.neoforged.net/docs/1.21.1/gettingstarted/modfiles/)、[事件文件](https://docs.neoforged.net/docs/1.21.1/concepts/events/)、[設定文件](https://docs.neoforged.net/docs/1.21.1/misc/config/)、[物品／創造分頁文件](https://docs.neoforged.net/docs/1.21.1/items/) 均標示 1.21–1.21.1。文件可能持續更新，不足以單獨鎖定 patch；**本報告的精確簽名、bus 行為與時序以 source-manifest.json 的 21.1.251／FML 4.0.44 本機來源為準**，不採用搜尋結果中的 1.21.5／1.21.11 或第三方文章。
