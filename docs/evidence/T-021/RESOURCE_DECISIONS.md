# T-021 資源處置與整合限制

2026-09-28。OLD 行為均為「依原始碼推定／待確認」。資源靜態檢查不是 Minecraft codec、模型烘焙、atlas stitching 或畫面通過。

## 來源與目標

[完整 144 檔映射](resource-map.json)逐檔列 OLD 路徑／邏輯 ID／SHA-256、目標及處置：本輪遷移 114 檔＝12 blockstate、40 block model、14 item model、44 貼圖、2 語系、pack.mcmeta／logo；29 個資料檔留給 T-022，1 個舊 Forge mods.toml 不複製。OLD 144 檔均與 T-009 固定 manifest 雜湊相符，沒有重建 OLD。

| 處置 | 具體內容與界線 |
| --- | --- |
| 同路徑／ID 保留 | 全部 blockstate／模型／PNG 路徑原封保留，包含 `destory_rail`、反向模型及 `textures/blocks`／`textures/items`。模型元素、UV、紋理 alias、顯示變換與旋轉值保留；不從檔案數量新增 registry |
| 九軌透明接線 | 依 T-015 九軌引用集合，29 個模型只增加 `render_type=minecraft:cutout`。不使用棄用的 Java render layer hook，不改 PNG 像素，不宣稱 mipmap／透明外觀已測 |
| atlas 新增來源 | `assets/minecraft/atlases/blocks.json` 添加兩個 `neoforge:namespaced_directory`（namespace=simplerail，source 分別為 blocks／items，prefix 分別為 blocks/／items/）；43 個自訂 sprite ID 可靜態取得。指定版 SpriteSourceList 以同 ID atlas stack 合併，沒有複製或取代 vanilla sources。entity PNG 供正式 renderer 直接取用，不放入方塊 atlas |
| 雙語 | 每檔保留 15 個已解析 key 及原 value（14 個有效名稱＋_comment）；只把原本重複的 `_comment` 合併成其最後值，讓 target JSON 沒有重複 key。保留舊文案，包括 Destory Rail／板手；不更動名稱或新增翻譯決策 |
| pack metadata | 保留舊 description，移除 format 6，不硬填單一 34／48；使用 NeoForge 21.1.251 `ResourcePackLoader.OPTIONAL_FORMAT/readMeta`：缺 format 且缺 supported_formats 的 mod pack 按來源設為 compatible。這是指定 loader 來源策略，不宣稱普通獨立 pack 可用或遊戲載入已測 |
| logo 與 metadata | 舊 512×512 logo 原位元組搬入 JAR 根 `logo.png`；既有 NeoForge template 只啟用 `logoFile="logo.png"`，D8、依賴與版號不變。不把舊 Forge mods.toml 覆蓋到 NEW |
| wrench 額外 blockstate | 保留 `blockstates/wrench.json`／資源身分，不註冊 wrench 方塊。普通 loader 依 block registry，實際是否有額外消費者仍未實測 |
| 額外 reverse item model | 保留 `models/item/oneway_reverse_rail.json`，唯一不從 11 blockstate＋13 item 根可達的 item model；不新增反向物品，不刪被 oneway blockstate 使用的反向 block 變體 |
| 車頭 | item model／item PNG／96×64 entity PNG 已遷移且引用可解析；六盒 Java renderer／八向姿態、UV 呈現與 EntityType 仍待 T-048／T-050／T-052，不開始 renderer 任務 |
| data JSON | 13 配方／12 loot／4 tag 共 29 檔只記後續候選路徑，未遷移、未執行 T-022，也不為了建置提前加入資料 |

產品 resource tree 共 115 檔（114 舊來源＋1 新 atlas）；metadata template 是另一個既有檔案的單行變更，build 產生新的 neoforge.mods.toml。來源與處置逐項語意／位元組核對通過。

## 已確認的靜態整合限制 I-021-01

依 T-019 產品來源，11 方塊目前是沒有自訂 property 的普通 Block；除了 cross_rail 的空 selector，**10 個已註冊方塊的 JSON selector 所需屬性尚未實作**。T-009 固定 `BlockStateModelLoader.java` 第 224 行對未知 property 有拒絕路徑，因此不能把本次 build／JSON 檢查當成 T-023 無載入警告的可操作版本；本輪沒有取得遊戲 log，不宣稱已重現。

[完整狀態覆蓋](state-coverage.json)以 T-010 的**候選**全部屬性 Cartesian product 計算，不是 runtime registry。所有 variant 鍵和值都在候選域內、沒有重複 selector 匹配；但舊資源只覆蓋部分候選域：

| 方塊 | 候選組合 | 有模型 selector | 未覆蓋 |
| --- | ---: | ---: | ---: |
| high_speed_rail | 24 | 8 | 16 |
| holding_rail | 144 | 48 | 96 |
| oneway_rail | 192 | 64 | 128 |
| eject_rail | 96 | 32 | 64 |
| destory_rail | 48 | 16 | 32 |
| timer_holding_rail | 1440 | 480 | 960 |
| cross_rail | 20 | 20 | 0 |
| y_cross_rail | 240 | 160 | 80 |
| y_cross_right_rail | 240 | 160 | 80 |
| train_dispenser | 12 | 8 | 4 |
| signal_timer | 20 | 20 | 0 |

前六種的缺口是四個 ascending shape；兩 Y 路口是 direction=up/down；發射器是 facing=up/down。正常禁坡／水平放置可達性不等於宣告值域或 baking coverage；不擅刪 slope／六向 domain，也不猜上下向模型應如何顯示。`waterlogged` 在 selector 中省略代表任一值，不是此次缺口。

**T-092／T-023 交接有技術限制，尚未 ready。** 現有正式前置只列 T-020／T-021／T-022，沒有保證自訂 StateDefinition 與全部所需變體已接上。R-02 應核對 I-021-01；依 D6，後續需定義屬性骨架／邊界模型處理的任務承接，再檢查 T-092／T-023 前置。可審閱的調整方向是把必要的 state／模型整合開發前置與最終人工閘門分開，避免要求使用者先測不可操作的包；本輪**只提出限制與調整方向，不改正式依賴／編號，不補 Java／新變體，不簽人工通過**。T-022 的資料開發可依既有前置獨立進行。

## 尚未執行的驗收

使用者 T-023／T-125 檢查實際 pack／atlas reload、雙語、全部物品／變體、透明處下方地形與 logo；正式 renderer 後 T-052 看六盒與 UV／坡度／八向／多人畫面。開發自查只驗路徑、嚴格 JSON、繼承 alias、候選 selectors、PNG 解碼與 JAR 內容；不稱外觀正確或 codec 通過。人工完成仍只需使用者確認，不要求附件。
