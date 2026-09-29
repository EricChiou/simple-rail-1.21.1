# T-004 名冊與來源規格

來源：T-003 的 OLD HEAD、B-01–B-25 與 [source-inventory.json](../T-003/source-inventory.json)。**舊版行為均為依原始碼推定／待確認**；本清冊不是 NEW 實測 registry dump。機器可讀完整名冊見 [catalogue.json](catalogue.json)；資源逐檔路徑及 SHA-256 保留，不只核對總數。

## Registry 名冊

全表 namespace 均為 `simplerail:`；同名但不同 registry 必須分別核對。

| 類別 | 固定 ID |
| --- | --- |
| 方塊11個 | `high_speed_rail`、`holding_rail`、`oneway_rail`、`eject_rail`、`destory_rail`、`timer_holding_rail`、`cross_rail`、`y_cross_rail`、`y_cross_right_rail`、`train_dispenser`、`signal_timer` |
| BlockItem11個 | 與上述11個方塊逐一同名 |
| 獨立物品2個 | `wrench`（stack1）、`locomotive_cart`（stack64）；共13物品 |
| Entity1個 | `locomotive_cart` |
| 既有BlockEntity2個 | `timer_holding_rail`、`signal_timer` |
| 必要新增BlockEntity | 發射器專用型別 ID 待T-012定義；D4已定，但不可充作原有第三個BE |
| 分頁 | 舊標籤 `simplerail.tab`、圖示高速軌；NEW registry方式待T-008 |
| tag | block `simplerail:rails`=9軌；block `simplerail:machines`=2機器；item `simplerail:wrench`=wrench；block `minecraft:rails`擴充9軌；四檔replace=false |

`destory_rail` 不改拼字。reverse 模型、額外 wrench blockstate 不增方塊或物品。既有 metadata 的外部需求只有 Minecraft／Forge，NEW驗收依D7只含Minecraft／NeoForge／Simple Rail。

## 方塊狀態名冊

布林值域 true/false、level值域0–9、direction宣告為完整Direction enum。继承欄位的實際預設、值域與目標版映射由T-010／T-019查證；NEW存讀逐欄核對，不能因未定而省略。

| 方塊 | 來源父類 | 必查狀態 | 可見預設／缺口 |
| --- | --- | --- | --- |
| high_speed_rail | BasePoweredRail | shape／powered | 繼承預設和值域待 T-010；不猜父類 |
| holding_rail | BasePoweredRail | direction；shape／powered | 顯式direction=NORTH；direction enum本身含六向，繼承欄位待查 |
| oneway_rail | BasePoweredRail | reverse／need_power／use_power；shape／powered | reverse=false；其餘兩值由設定true/false；继承待查 |
| eject_rail | BasePoweredRail | reverse／need_power；shape／powered | false／設定true；繼承待查 |
| destory_rail | BasePoweredRail | need_power；shape／powered | 設定false；繼承待查 |
| timer_holding_rail | BasePoweredRail | direction／level；shape／powered | 兩次registerDefaultState；level0明示，最終direction待U-08確認，不直接判NORTH |
| cross_rail | BaseRail | shape | onMinecartPass依來車改NS/EW；原始預設待查 |
| y_cross_rail | BaseRail | direction／powered；shape | 顯式NORTH／false；onPlace讀電源；繼承待查 |
| y_cross_right_rail | BaseRail | direction／powered；shape | 顯式NORTH／false；onPlace讀電源；繼承待查 |
| train_dispenser | DispenserBlock | facing／triggered | onPlace限制水平，非水平轉NORTH；繼承預設及triggered用途待查 |
| signal_timer | RedstoneBlock | level／powered | 顯式0／false；自訂level0–9 |

## 設定名冊

來源 CommonConfig.java:55–149、constants/Config.java。COMMON檔名及重載策略待T-008／T-020，兩計時類的static final快取見U-07。

| 路徑 | 預設 | 邊界／案例 |
| --- | --- | --- |
| cart.locomotive.disableLoadingChunk | true，原碼true啟用 | true/false兩分支；D3首版啟用，不依名稱反轉 |
| rail.high_speed_rail.maxSpeed | 0.8 | 0.4／0.8／2.0；不是實測blocks/s |
| rail.oneway_rail.needPower | true | 與下項、powered、reverse全組合 |
| rail.oneway_rail.usePowerChangeDirection | false | 註解與實作差異U-07 |
| rail.eject_rail.transportDistance | 3 | 1／3／100；以來源座標公式核對 |
| rail.eject_rail.needPower | true | true/false×供電開關 |
| rail.destory_rail.needPower | false | true/false×供電開關 |
| rail.timer_holding_rail.lv1–lv9 | 5,10,15,20,25,30,40,50,60 秒 | 各允許0–2147483647；乘1000的int邊界由T-037定義，不直接睡最大秒數 |
| rail.signal_timer_block.lv1–lv9 | 同上 | 各允許0–2147483647；乘20減10的邊界由T-011／T-042定義 |

## 配方、掉落及資源名冊

13配方均為 `minecraft:crafting_shaped`。下表用「·」可視化空格，以 / 分隔三列；完整原JSON含空格見catalogue.json。材料皆為minecraft namespace，結果皆為同名simplerail物品。T-024逐配方展開案例，不只抽測。

| 配方ID路徑 | 3×3排列（·為空） | 材料key | 產量 |
| --- | --- | --- | --- |
| simplerail:cross_rail | `·I·/·R·/···` | I=minecraft:iron_ingot；R=minecraft:rail | 1 |
| simplerail:destory_rail | `·P·/·I·/···` | P=minecraft:iron_pickaxe；I=minecraft:powered_rail | 3 |
| simplerail:eject_rail | `R··/·I·/···` | I=minecraft:powered_rail；R=minecraft:redstone | 1 |
| simplerail:high_speed_rail | `·I·/·R·/···` | I=minecraft:powered_rail；R=minecraft:redstone | 1 |
| simplerail:holding_rail | `·R·/·I·/···` | R=minecraft:redstone；I=minecraft:powered_rail | 1 |
| simplerail:locomotive_cart | `·G·/·C·/···` | G=minecraft:gold_ingot；C=minecraft:minecart | 1 |
| simplerail:oneway_rail | `···/RI·/···` | R=minecraft:redstone；I=minecraft:powered_rail | 1 |
| simplerail:signal_timer | `·R·/·I·/···` | R=minecraft:repeater；I=minecraft:iron_block | 1 |
| simplerail:timer_holding_rail | `·R·/·I·/·R·` | R=minecraft:redstone；I=minecraft:powered_rail | 1 |
| simplerail:train_dispenser | `·C·/·D·/···` | C=minecraft:minecart；D=minecraft:dispenser | 1 |
| simplerail:wrench | `·G·/·I·/···` | G=minecraft:gold_nugget；I=minecraft:iron_pickaxe | 1 |
| simplerail:y_cross_rail | `·I·/·R·/·S·` | I=minecraft:iron_nugget；R=minecraft:rail；S=minecraft:redstone | 1 |
| simplerail:y_cross_right_rail | `·S·/·R·/·I·` | I=minecraft:iron_nugget；R=minecraft:rail；S=minecraft:redstone | 1 |

11方塊loot各為同名物品、rolls1、survives_explosion；額外 `simplerail:blocks/locomotive_cart` 宣告entity型別，與Java掉落關係待T-009／T-048。資源：12 blockstates（含額外wrench）、40 block models、14 item models（含oneway_reverse）、44貼圖、en_us／zh_tw各1、pack.mcmeta格式6、根logo.png。保留邏輯ID，NEW格式與目錄由T-009查證；不把舊pack6當NEW合法值。

## 保存欄位與案例比較鍵

| 功能 | OLD可見欄位／暫存 | NEW驗收鍵 |
| --- | --- | --- |
| 編組 | Train有序UUID字串list、Facing八向字串；父類讀寫；static trains、prevPos、stopPos | 世界／維度、車頭UUID、有序車廂UUID、朝向、相關父類資料，暫存恢復或重建依已定規格 |
| 計時軌 | save_time／cart_uuid／go_time | 剩餘等待時間、保存/卸載/讀回時刻、車UUID、等級；不是逐位元相同時間戳 |
| 發射器 | OLD ChestTileEntity內容／名稱 | NEW專用BE、槽位0–26物品種類/數量/名稱/資料；不轉換舊箱子 |
| 訊號計時器 | level／powered，排程由引擎處理 | level、輸出時序與重啟相位，規格待T-011 |
| 路口／票證 | 位置Map、forceChunk呼叫 | 維度隔離、UUID、路徑；owner/區塊集合/tick/存讀後果；機制待API查證 |

WorldData.java的另一组名稱未見引用，不推定有.dat。D1不要求讀取以上任何舊格式。

