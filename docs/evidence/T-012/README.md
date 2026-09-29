# T-012 專用容器與箱子式 GUI API 查證

日期：2026-09-27。狀態：**開發交付完成；R-01 程式審查待審；人工遊戲測試未執行**。本項只查證 Minecraft 1.21.1／NeoForge 21.1.251 的專用 27 格方塊實體、原版箱子介面及槽位同步候選；[探針](probe/T012Probe.java)只在證據目錄，未進模組 sourceSet／JAR，沒有載入或執行。OLD 行為均為**依原始碼推定／待確認**；不重跑 OLD build，不讀取或轉換舊箱子資料。

## 版本、來源與執行證據

- NEW HEAD `8bd977dbb9f9000411ae5f4d10750228e5f33560`；本地指定版來源 `build/moddev/artifacts/neoforge-21.1.251-sources.jar`，SHA-256 `236151EDEC930A89E78054FCB5551323761F801778305F290D0B74238C33693E`。23 個目標 Java 來源及 OLD `TrainDispenserBlock.java` 的快照、原路徑與雜湊見[來源名冊](source-manifest.json)；OLD 檔雜湊與 T-010 快照相同。
- 官方版本區間文件：[NeoForged 1.21–1.21.1 Containers](https://docs.neoforged.net/docs/1.21.1/inventories/container/)、[Menus](https://docs.neoforged.net/docs/1.21.1/gui/menus/)、[Block Entities](https://docs.neoforged.net/docs/1.21.1/blockentities/)，2026-09-27 查閱。精確到 NeoForge 21.1.251 的方法、父類呼叫及槽位順序以本地指定版來源為準。
- 來源收集命令 `& ([scriptblock]::Create((Get-Content -Raw -Encoding UTF8 docs/evidence/T-012/collect.ps1)))` 退出 0，[紀錄](collection.json)。編譯命令 `.\gradlew.bat compileT012Probe --offline --console=plain --info --no-configuration-cache -I docs/evidence/T-012/probe.init.gradle`，由 [compile.ps1](compile.ps1) 保存 UTC、退出碼和完整 log。[第一次](compile-01.json)在沙箱內因 Wrapper `C:\.gradle\...zip.lck` 權限失敗退出 1，[原始 log](compile-01.log)保留；經允許沙箱外重試[第二次](compile-02.json)退出 **0**、`BUILD SUCCESSFUL`，[完整 log](compile-02.log)保留。
- 編譯使用 Java 21.0.12.1、`--release 21 -Xlint:deprecation -Werror` 與 NEW 主來源 compile classpath。[Classpath](compile-classpath.txt)、[其雜湊](classpath-manifest.json)、[compiler](compiler.txt)、[3 個 major 65 class](compiled-classes.json)、[範圍／指紋](verification.json)保存。只執行最小 JavaCompile 探針；**沒有執行模組 build、遊戲、資料存讀或 GUI 測試**。相較 T-009 基線的 12 個產品檔均未變，[產品檔雜湊](product-source-check.json)及 `git diff HEAD --name-only -- src build.gradle settings.gradle gradle.properties gradle gradlew gradlew.bat` 空結果可覆核。
- [任務／文件／依賴／證據自查](final-check.json)退出 0；自查不等於獨立 Review Agent 結論。

下文 `M/` 指 `sources/target/net/minecraft/`，`N/` 指 `sources/target/net/neoforged/neoforge/`，`O/` 指 `sources/old/`；對應原檔與雜湊見[來源名冊](source-manifest.json)。

## 新 ID 與必要接線

| Registry／型別 | 本項定義 | 理由與界線 |
| --- | --- | --- |
| BLOCK `simplerail:train_dispenser` | **保留既有 ID** | D2；T-019 註冊／T-044 接線，不能更名。 |
| ITEM `simplerail:train_dispenser` | **保留既有 BlockItem ID** | D2；不增加替代物品。 |
| BLOCK_ENTITY_TYPE `simplerail:train_dispenser` | **新增唯一 BE ID** | OLD 只註冊 `timer_holding_rail`、`signal_timer` 兩種 BE，發射器借原版 `ChestTileEntity`；目標改用專用型別。方塊與 BE 在不同 registry，可有相同路徑。`DeferredRegister.create(Registries.BLOCK_ENTITY_TYPE,"simplerail")` 配 `BlockEntityType.Builder.of(TrainDispenserEntity::new, TRAIN_DISPENSER_BLOCK.get()).build(null)`；本項只證編譯，正式註冊／載入待 T-019／T-044。 |
| MENU_TYPE／SCREEN | **不新增自訂 ID** | 直接用原版 `MenuType.GENERIC_9x3`／`ChestMenu.threeRows` 及既有 `ContainerScreen`；`M/world/inventory/MenuType.java:14`、`M/client/gui/screens/MenuScreens.java:99` 有指定版綁定。箱子式介面不要求外部 GUI 模組。 |

以 `BaseContainerBlockEntity` 為專用方塊實體基底，維護固定長度 `NonNullList.withSize(27, ItemStack.EMPTY)`；該基底已實作 `Container`、`MenuProvider`、`stillValid`、自訂名稱／鎖及槽位寫入時的 `setChanged`（`M/world/level/block/entity/BaseContainerBlockEntity.java:24,101–157`）。專用型別覆寫 `getContainerSize`、`getItems`／`setItems`、`getDefaultName`、`createMenu`、`loadAdditional`／`saveAdditional`。`getDefaultName` 探針用原有箱子標題 `container.chest`；若產品需顯示既有 `block.simplerail.train_dispenser` 名稱，T-044 固定 UI 文案並交使用者確認。此文案選擇不影響 ID 或 27 格規格。

`M/world/ContainerHelper.java:24–57` 的 `saveAllItems`／`loadAllItems` 使用 `HolderLookup.Provider` 序列化 ItemStack（含資料元件）、`Items` 清單及每項 `Slot`；新 BE 的 `saveAdditional`／`loadAdditional` 先呼叫 `super`，讀取時先重建 27 個空格再填值。`Slot` 在此為 unsigned byte，0–26 均在範圍。`BaseContainerBlockEntity#setItem`、`removeItem` 會標髒；其 `clearContent` 與 `removeItemNoUpdate` **沒有**標髒，正式實作應審核所有直接修改路徑並在需要持久化時補 `setChanged`。探針為 `clearContent` 加標髒，沒有將尚未定義的「無更新移除」行為假設為自動安全。D4 的生成路徑只能讀取樣板或其 `copy()`，不得 `shrink`／`split`／取走原槽；探針的 `templateCopy` 只展示讀取邊界，不是列車生成實作。

## 槽位、介面與同步契約

| 區段 | `ChestMenu.threeRows` 槽位索引 | 依據與注意事項 |
| --- | --- | --- |
| 發射器樣板 | 0–26，按 3 排 × 9 格由左至右、由上至下 | `M/world/inventory/ChestMenu.java:56–66`；OLD `O/block/TrainDispenserBlock.java:43,65–90` 固定迴圈 0–26、索引 0 可作車頭。樣板順序不能以玩家背包索引替換。 |
| 玩家背包 | 27–53 | `ChestMenu.java:69–73`；玩家背包原生 slot 9–35 映射到 menu 27–53。 |
| 玩家快捷列 | 54–62 | `ChestMenu.java:76–78`；原生 slot 0–8。 |

伺服端由 `TrainDispenserBlock#useWithoutItem` 檢查專用 BE 後呼叫 `ServerPlayer#openMenu(be)`；候選在 client 回傳 `SUCCESS`、server 回傳 `CONSUME`，並保留 OLD 的 `Stats.OPEN_CHEST` 統計。`BaseEntityBlock#getMenuProvider` 可暴露 BE 給旁觀者；探針明確型別檢查。`BaseContainerBlockEntity#createMenu` 回傳 `ChestMenu.threeRows(id, playerInventory, this)`；本方案的 BE 明訂恰有 27 槽，`ChestMenu` 的通用檢查只要求**至少** 27 槽（`M/world/inventory/AbstractContainerMenu.java:84–89`），並開始開啟介面；關閉時 `ChestMenu.removed` 呼叫 `stopOpen`（`ChestMenu.java:55–62,114–119`）。目前 `Container#startOpen`／`stopOpen` 預設空實作，故箱子**畫面**可沿用，但音效、掀蓋動畫及具體文案是否要比照原版箱子均**待確認**，不得從編譯推定。

`ServerPlayer#openMenu` 會建立伺服端 menu 並送出對應 `MenuType`／標題封包（`M/server/level/ServerPlayer.java:1141–1192`）；客戶端由原版 `GENERIC_9x3` 建空 27 格容器並用 `ContainerScreen` 顯示（`ChestMenu.java:14–21`、`MenuScreens.java:97–102`）。開啟中的 ItemStack 透過 vanilla menu slot 同步：`ServerPlayer.tick` 呼叫 `containerMenu.broadcastChanges()`（`ServerPlayer.java:518`），`AbstractContainerMenu.java:173–191` 逐槽比較／同步；**不需為此 GUI 增加自訂 packet、MenuType、Screen 或方塊實體 update tag**。這只證來源接線；初始內容、多人同時操作、重連、不同資料元件及關閉後存讀仍需 T-047／T-082 使用者實測。持物點擊與扳手互動優先序待 T-035／T-044 依已查證互動管線驗證。

`DispenserBlock` 父類的 `useWithoutItem` 只接受 `DispenserBlockEntity`，不能直接開專用 BE（`M/world/level/block/DispenserBlock.java:75–90`）；其 `dispenseFrom` 以 `BlockEntityType.DISPENSER` 讀 9 格並呼叫原版消耗式行為（同檔 93–110）。因此正式子類必須覆寫這兩個入口，不能只換 `newBlockEntity`。探針覆寫 `dispenseFrom` 為**空的編譯邊界**，絕非正式「停用生成」玩法；T-043／T-045 需接入 OLD 無扣物樣板邏輯。父類 `neighborChanged` 是供電沿觸發並延遲 4 tick（118–132），OLD 是每次 powered neighbor update 即生成（`O/block/TrainDispenserBlock.java:48–95`）；完整觸發時序屬疑點 5，由 T-043 調查、T-045 實作，不能在本項擅自改玩法。`DispenserBlock#onRemove` 呼叫 `Containers.dropContentsOnDestroy`（144–147）；專用 BE 作為 `Container` 時預期會走此路，實際掉落與保存仍待驗證。

## 完成條件與待查證

| T-012 條件 | 證據 | 判定 |
| --- | --- | --- |
| 指定版容器／GUI 接線與新 ID | 上述 registry 表、指定版 23 個來源快照與官方文件；方塊、BE、MenuProvider、`ChestMenu.threeRows` 候選皆在探針 | 達成**設計／編譯候選**；正式註冊與開啟未測 |
| 槽位索引、開關介面、存讀與同步可編譯 | 0–62 索引表，`ContainerHelper`、`BaseContainerBlockEntity`、`ServerPlayer.openMenu`／vanilla slot 同步候選；`compile-02` 退出 0、3 個 major 65 class | 達成**編譯與來源查證**；不是遊戲結果 |
| D4、D1、D7 與限制 | 27 格不消耗邊界、無原版 Chest BE／無舊箱子資料轉換、無外部 GUI 模組；父類 9 格／消耗路徑已隔離 | 達成**規格**；樣板生成及世界存讀留 T-044–T-047／T-082 |

待技術驗證：T-019／T-044 的真實 registry 順序、父類 `neighborChanged` 與持物／扳手互動；T-043／T-045 的實際觸發及不消耗；T-047 的 27 格與雙端 GUI、開關及名稱；T-082 的 NEW 世界兩輪存讀；`removeItemNoUpdate`／自動化是否產生未標髒變更；原版箱子音效／動畫與標題是否屬產品要求。上述未知只限制相應功能，不阻礙其他 API 研究。**本項未取得任何使用者人工遊戲結果或獨立程式審查通過。**
