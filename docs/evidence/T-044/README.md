# T-044 專用發射器方塊實體與 27 格箱子式 GUI

2026-09-30。**開發完成；R-04 獨立程式審查待審；T-047／T-082 使用者遊戲驗收未執行。** 本項只交付容器、GUI 與保存接線，不執行 T-045 的礦車生成、T-046 的條件式修正或 T-102 製包。OLD build 與 Minecraft client／server／GameTest 均未執行。OLD 世界與舊箱子資料不轉換（D1）。

## 實作與 ID

| 範圍 | 此次接線 | 證據／界線 |
| --- | --- | --- |
| BLOCK／ITEM | 維持 `simplerail:train_dispenser` 原 ID；`ModBlocks.TRAIN_DISPENSER` 改註冊 `TrainDispenserBlock`，既有 `ModItems` BlockItem 不變 | [方塊](../../../src/main/java/com/ericchiu/simplerail/block/TrainDispenserBlock.java)、[註冊](../../../src/main/java/com/ericchiu/simplerail/registry/ModBlocks.java)；D2 |
| BLOCK_ENTITY_TYPE | 新增 `simplerail:train_dispenser`，僅綁上列方塊；不是原版 Chest／Dispenser BE | [註冊](../../../src/main/java/com/ericchiu/simplerail/registry/ModBlockEntities.java)、[專用 BE](../../../src/main/java/com/ericchiu/simplerail/blockentity/TrainDispenserBlockEntity.java) |
| MENU_TYPE／SCREEN | 沿用原版 `GENERIC_9x3`／`ChestMenu.threeRows`／`ContainerScreen`，沒有新增 ID 或自訂 GUI 模組 | [T-012 指定版來源及編譯探針](../T-012/README.md)；遊戲顯示仍待使用者 |
| 方塊狀態 | 放置水平朝向，若輸入垂直方向則回正 NORTH；原版父類 `TRIGGERED` 的四向真／假模型均列入 blockstate | [blockstate](../../../src/main/resources/assets/simplerail/blockstates/train_dispenser.json)；扳手仍依既有 `MACHINES` tag 旋轉 facing |
| 紅石生成 | 父類九格消耗路徑被 `dispenseFrom` 空覆寫隔離；目前通電可觸發父類排程，但不生成車或消耗樣板 | T-045 才接 27 格原碼語意；T-043 持續供電疑點未由此解決 |

`TrainDispenserBlockEntity` 繼承指定版 `BaseContainerBlockEntity`，固定 `NonNullList<ItemStack>` 長度 27。`getDefaultName` 使用已有的 `block.simplerail.train_dispenser` 語系鍵；開啟時伺服端 `ServerPlayer.openMenu`，繼承基底的 `canOpen`／`stillValid`；client 交給原版 3×9 選單。這是原版箱子**版型**，不借用原版箱子方塊實體。範圍限 GUI 的選單槽位同步，不聲稱 BE 的內容已對未開 GUI 的每個 client 廣播；T-047／T-082 的兩端操作與存讀由使用者驗收。

| 選單索引 | 資料來源 | 規格 |
| --- | --- | --- |
| 0–26 | 專用 BE 樣板 | 三排 × 九格，由左至右、由上至下；槽 0 保留未來車頭判斷 |
| 27–53 | 玩家背包 | 原版 `ChestMenu.threeRows` 映射 |
| 54–62 | 玩家快捷列 | 原版 `ChestMenu.threeRows` 映射 |

保存沿用 `ContainerHelper.saveAllItems`／`loadAllItems` 與指定版 `HolderLookup.Provider`，讀取時先重建 27 個空槽，再按槽索引填值。基底 `setItem`／`removeItem` 會標髒；本項替 `removeItemNoUpdate` 與 `clearContent` 補 `setChanged`，後者重新建立固定 27 槽，避免原版基底 `.clear()` 將列表長度縮為 0。方塊被真正替換時沿用父類容器掉落路徑；掉落、持物互動優先序、多人同時開啟、重連與世界存讀的實際結果均待使用者。

## 建置、範圍與版本

- NEW HEAD：`11916b69c3549504928f7cfa6790d59a2717b4b6`，加先前未提交 T-038／T-041／T-040 R1 產品差異及本項五個產品檔差異；不可只以 commit 重建。基線正式 JAR SHA-256 `E1C79C838055CEF0955E8B0CF46991DA51F24BBDDCA4FE2A1DA6C6891588EF39`。
- 執行 `powershell -NoProfile -ExecutionPolicy Bypass -File docs/evidence/T-044/build.ps1`，其中命令為 `.\gradlew.bat build --offline --console=plain --no-configuration-cache`。[命令／UTC／退出碼](build.json)記 **0**，[完整 log](build.log)顯示 `BUILD SUCCESSFUL`；普通 Gradle `test NO-SOURCE`，不冒稱有遊戲或自動化程式測試。目標 Minecraft 1.21.1、NeoForge 21.1.251、Java 21、Gradle 9.2.1。
- 固定 [正式 JAR](artifacts/simplerail-1.0.0.jar) SHA-256 `9B0107CA2DA90AA98946E12DB51A6508E7A927479A6F50D6305B1BA2E288C35A`。[稽核命令與結果](audit.json)七項通過：對 T-040 R1 的 179 個既有產品檔，僅兩個註冊 Java 與 `train_dispenser` blockstate 改變，另新增兩個 Java；JAR 含兩個新 class 與 blockstate，固定副本同 SHA。首次未提交檔指紋：`ModBlocks.java` `7459B205…`、`ModBlockEntities.java` `A0131D7B…`、blockstate `D3B67DBC…`；完整此輪範圍見 audit。
- API 依 [T-012 指定版來源／槽位表](../T-012/README.md)與本地 `neoforge-21.1.251-sources.jar`（SHA-256 `236151EDEC930A89E78054FCB5551323761F801778305F290D0B74238C33693E`），並對照 [NeoForge 1.21.1 方塊實體](https://docs.neoforged.net/docs/1.21.1/blockentities/)、[容器](https://docs.neoforged.net/docs/1.21.1/inventories/container/)及[選單](https://docs.neoforged.net/docs/1.21.1/gui/menus/)文件。編譯僅確認指定版 API 可用，不能代替遊戲測試。

**驗收界線：** 本項具備可編譯的 27 格保存／選單／槽位同步設計與固定產物，完成條件按開發交付判定。R-04 尚未審，T-047／T-082 未由使用者操作；「27 格不消耗」的生成期不變性須 T-045 實作後由 T-047 驗證。T-043 診斷包使用上方原版箱子，與本項正式 BE 不混用。
