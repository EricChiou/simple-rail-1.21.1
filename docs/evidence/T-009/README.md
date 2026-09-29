# T-009 配方、loot、tag 與資源格式查證

2026-09-27。狀態：**開發完成；R-01 程式審查待審；人工遊戲未執行**。前置 T-004／T-005 已交付。此報告交付指定來源的格式／ID 對照及非遊戲檔案檢查；不是資源移植、Minecraft codec 載入、合成、掉落、模型烘焙或 reload 通過。

NEW：`D:/workspace/java/simple-rail-1.21.1`，HEAD `8bd977dbb9f9000411ae5f4d10750228e5f33560`；OLD：`D:/workspace/java/simple-rail`，HEAD `6698b1c5f494095a15b055c10045293e91540012`。OLD Git 沙箱內擁有權檢查失敗，經允許沙箱外唯讀重試退出 0、狀態乾淨；初次 collection.json 的空 OLD 欄位不是乾淨狀態，詳 [準備與失敗紀錄](preparation-notes.json)。**OLD build 由使用者先前驗證，本次流程不重跑**。舊行為均「依原始碼推定／待確認」。

## 固定來源及交付

- Minecraft **1.21.1** 的本機 client archive 僅作 ZIP 讀取，其 `version.json` 確認版本、resource pack **34**／data pack **48**；不是啟動 client。
- NeoForge **21.1.251** merged sources：44 個目標 Java 來源；11 個 vanilla 資源／版本檔；OLD 42 個 Java 與 144 個資源檔。共 241 個快照的來源 archive／檔案 SHA-256 見 [主要 manifest](source-manifest.json)、[補充 manifest](extra-source-manifest.json)。收集方式見 [collect.ps1](collect.ps1)、[collect-extra.ps1](collect-extra.ps1)。
- [全部 144 個檔案的舊路徑→候選路徑／邏輯 ID](resource-map.json)、[13 配方摘要](recipes.md)、[完整材料／排列／候選 JSON](recipe-candidates.json)、[266 條模型／貼圖直接引用](reference-trace.json)。候選只寫在證據 JSON，不放入產品資源樹。
- [非遊戲檢查結果](static-audit.json)、[實際命令與退出碼](audit-commands-2.json)、[編譯 log](compile-2.log)、[檢查 log](audit-2.log)、[工具與 class 雜湊](audit-toolchain.json)。
- [12 個產品來源／Gradle／資源指紋](product-source-check.json) 未變；本次沒有 Gradle build、runData、Minecraft client／server 或 OLD build。T-021／T-022 等移植任務未開始。

以下 `M/`＝`sources/target/net/minecraft/`、`N/`＝`sources/target/net/neoforged/neoforge/`、`V/`＝`sources/vanilla/`、`O/`＝`sources/old/src/main/`；行號以本次快照為準。本機指定 patch 來源為主要依據，官方 1.21.1 文件作輔助。

## 格式與 ID 對照

| 類別／OLD 數量 | 1.21.1／21.1.251 指定依據 | 遷移候選與限制 |
| --- | --- | --- |
| pack.mcmeta，舊值 6 | `V/version.json` 的 pack_version；`M/SharedConstants.java:85,93`；`N/resource/ResourcePackLoader.java:144–207` | vanilla resource=34、data=48，不能把單一 6 照搬。此 NeoForge 的模組 pack 可無 pack.mcmeta；缺 pack metadata 或省略 format 的處理由 readMeta 決定，合併 pack 依 PackType 產生格式。不盲填單一 34／48 同時當成兩種 pack 都已驗證。T-021 可採不攜帶舊 format 6，或只留 description 的 NeoForge 模組策略；若另發獨立 pack，須分別定格式。此處未改資源 |
| 配方 13 | `M/core/registries/Registries.java:237,251`、`M/world/item/crafting/RecipeManager.java:45,60`；vanilla `V/data/minecraft/recipe/rail.json` | `data/simplerail/recipes/<name>.json` → `data/simplerail/recipe/<name>.json`，ID 仍 `simplerail:<name>`。全為 crafting_shaped，無需自訂 serializer；材料／排列／產量不變 |
| 配方結果與 ingredient | `M/world/item/crafting/ShapedRecipe.java:94–100`；`M/world/item/ItemStack.java:103–129`；`Ingredient.java` 的 ItemValue／TagValue；`N/common/crafting/CraftingHelper.java`；`ShapedRecipePattern.java` 的 unpack／shrink | result 使用 `{"id":"simplerail:destory_rail","count":3}`，其餘產量 1；ingredient 仍可 `{"item":"minecraft:..."}`／`{"tag":"..."}`，不可把所有 item 欄位一律改 id。結果走 STRICT_CODEC，需已註冊物品並檢查堆疊上限；此輪沒有跑 registry codec。空白 pattern 邊界可由 shrink 裁去，保留原排列，不自行更改玩法 |
| loot 12（11 方塊＋額外車頭表） | `Registries.java:233,251`、`M/server/ReloadableServerRegistries.java:63–88`；`M/world/level/storage/loot/{LootTable,LootPool}.java` 的 CODEC；`entries/LootItem.java` | 目錄 `loot_tables` → `loot_table`；**blocks 子路徑保留**，如 ID `simplerail:blocks/high_speed_rail`。type／pools／rolls／entries／conditions 格式由指定 codec 支持；NeoForge LootPool:37 仍支援 name。物品 entry 的 name 不改成 id。不新增 block 或重複掉落 |
| tag 4 | `Registries.java:118,159,255`；`M/tags/TagManager.java`；`TagFile.java:8–15`、`TagEntry.java:15–22` | `tags/blocks` → `tags/block`，`tags/items` → `tags/item`；rails、machines、wrench、minecraft:rails 邏輯 ID 保留。values／replace（預設 false）可沿用；9 軌、2 機器、1 扳手成員保持，型別是 ID 身分的一部分。wrench 舊 Java 型別疑點見下表 |
| blockstate 12（11 已註冊方塊＋wrench） | `M/client/resources/model/BlockStateModelLoader.java:51,87–106`；`M/client/renderer/block/model/BlockModelDefinition.java`、`Variant.java:91–127`；`M/client/resources/model/BlockModelRotation.java:66` | `assets/simplerail/blockstates/` 不改為單數；variants／model／x／y／uvlock 可用。旋轉按正模 360 查表，舊 -90 可對應 270，不能只因負號判錯。state 鍵與值須等 T-010／T-019 的實際 BlockState 定義再核對；不是本輪已烘焙 |
| block model 40、item model 14 | `M/client/resources/model/ModelBakery.java:64,110–118,175,218`；`M/client/renderer/block/model/BlockModel.java:333–414`、BlockElement.java；vanilla rail_flat／cube_all／item/generated 快照 | `models/block`／`models/item` 仍有效，parent／textures／elements／display 依來源解析；1.21.1 使用 `models/item/<id>.json`，不套用較新版本的 item definition 結構。namespace:path 保留；模型數不等於物品數。直接引用存在不等於父模型、UV、材質和外觀已驗收 |
| 貼圖 44 | `M/client/renderer/texture/atlas/SpriteSourceList.java:73` 的 atlas stack 合併；`sources/DirectoryLister.java:18–39`；`N/client/textures/NamespacedDirectoryLister.java:24–37`（ClientNeoForgeMod.onRegisterSpriteSourceTypes 註冊）；`V/assets/minecraft/atlases/blocks.json` | vanilla 圖集掃描 block／item，OLD 用 **blocks／items**。依 D2 保留 PNG 路徑與 sprite ID；T-021 應向 `assets/minecraft/atlases/blocks.json` 增加來源，例如 namespace=simplerail、source=blocks、prefix=blocks/ 的 neoforge:namespaced_directory，items 同理。這是必要候選新增資源，未實作／未載入。entity/locomotive_cart.png 是 renderer 直接引用，交 T-015／T-050；不需把它當方塊圖集素材 |
| en_us／zh_tw 2 | `M/client/resources/language/ClientLanguage.java:44,68`；`M/locale/Language.java` 的 loadFromJson（UTF-8）；OLD `O/resources/assets/simplerail/lang/` | 保留 lang 目錄、兩檔及全部 15 個既有 key；包括 `itemGroup.simplerail.tab`。目前兩語系 key 集合一致、value 均字串；實際翻譯與創造分頁接線交 T-019／T-021／T-023 |
| logo.png／mod metadata | OLD `O/resources/META-INF/mods.toml:13` 的 logoFile；NEW `src/main/templates/META-INF/neoforge.mods.toml` 的 logoFile 範例與 T-005 來源指紋 | logo 是 JAR 根路徑、非 registry／sprite ID；舊 PNG 512×512。NEW logoFile 目前為註解，T-021／發行工作接線時使用既有 logo.png，不複製舊 Forge mods.toml 蓋掉 NeoForge metadata／D8。本輪 PNG 僅檢查標頭與尺寸 |

**圖集候選（說明用；不是已部署檔案）：**

```json
{
  "sources": [
    {"type":"neoforge:namespaced_directory","namespace":"simplerail","source":"blocks","prefix":"blocks/"},
    {"type":"neoforge:namespaced_directory","namespace":"simplerail","source":"items","prefix":"items/"}
  ]
}
```

模組透過相同 atlas ID 合併 sources，不把 vanilla sources 覆寫掉；正式效果由使用者 resource reload／各變體外觀案例確認。OLD 透明材質的 NEW render type 尚屬 T-015／T-021 範圍，PNG 格式可讀不代表透明效果正確。

## 額外檔案與引用追蹤

| 項目 | 來源可確認的鏈 | 結論／後續 |
| --- | --- | --- |
| `simplerail:blocks/locomotive_cart` loot | OLD 表 type=entity、entry 為車頭 item、survives_explosion。`O/java/ericchiu/simplerail/entity/LocomotiveCartEntity.java:75–87` 的 destroy 自行 getReturnItem／spawnAtLocation，沒有在此呼叫表；完整 OLD Java 與資源搜尋未找到直接指定此 loot ID 的消費者。Blocks 名冊也沒有 locomotive_cart | **依原始碼推定／待確認**：現有 destroy 路徑由 Java 掉落，不證明任意命令或其他 runtime 永遠不會讀表。保留 `blocks/locomotive_cart`，不得為了 type=entity 自行移到 entities/（那會改 ID）；更不能新增方塊 |
| 上表的條件相容性 | `ExplosionCondition.java:26–28` 引用 EXPLOSION_RADIUS；`parameters/LootContextParamSets.java:37–45` 的 ENTITY 沒有該參數；`LootContextParamSet.java:57–68` 檢查 referenced-minus-allowed；ReloadableServerRegistries 會驗證載入的 loot registry | 靜態來源支持「直接照搬將產生 context 驗證問題」的推論，即使一般破壞沒有消費該表也不能忽略。**未實際執行 loader、未取得警告 log**。T-022／T-048 決定保留 ID 下的正確表格內容及 Java 掉落分工，T-024／T-052／T-062 使用者確認無警告／無雙重掉落；不在本輪擅改 type 或刪條件 |
| `blockstates/wrench.json` | 只指向 `simplerail:item/wrench`；OLD Blocks 沒有 wrench，Items 註冊 wrench；NEW BlockStateModelLoader 由 block registry 逐項載入定義 | 依來源推定為額外未接線資源，不建立 wrench block。D2 下保留資源身分，T-021 記錄其非方塊用途／保留理由；NEW 是否被額外消費仍未實測 |
| `tags/items/wrench.json` 與 Java WRENCH | OLD `setup/SimpleRailTags.java:14,18` 以 BlockTags.createOptional 建立 WRENCH；JSON 內容則是 item tag。全 OLD Java 搜尋只有宣告，未找到 SimpleRailTags.WRENCH 消費者；rails／machines 另有使用 | item tag `simplerail:wrench` 保留並搬到 tags/item；不要把值當 block tag 載入或新增方塊。T-022 整理未使用的 Java tag 宣告（刪除未用宣告或改正型別須記錄理由），不改 ID、不新增整合；runtime 消費未測 |
| `models/item/oneway_reverse_rail.json` | 14 個 item model 中只有 13 個註冊物品根；本次模型圖從 11 blockstate＋13 item 根追蹤，只有此 item model 不可達。它引用 `simplerail:blocks/oneway_reverse_rail`，PNG 存在；反向 **block** 模型／貼圖仍由 oneway_rail 的 reverse variants 使用 | 額外 item model 不新增物品、不刪反向 block 變體。依 D2 保留 ID；人工是否可見／其他消費者待查證。T-021／T-023 處理保留與外觀，不宣稱舊版實測未使用 |

搜尋範圍是快照中的全部 42 個 OLD Java 及 144 個 OLD 資源；「未找到引用」只指此範圍，不能等同所有外部世界、指令或模組均無使用。D7 不加入外部整合。

## 驗證實際結果及範圍

實際主命令（NEW 工作目錄）：

```powershell
& ([scriptblock]::Create((Get-Content -Raw -Encoding UTF8 docs/evidence/T-009/collect.ps1)))
& ([scriptblock]::Create((Get-Content -Raw -Encoding UTF8 docs/evidence/T-009/collect-extra.ps1)))
& ([scriptblock]::Create((Get-Content -Raw -Encoding UTF8 docs/evidence/T-009/run-audit.ps1)))
```

最後一項實際使用 Temurin javac **21.0.12.1**，`--release 21 -encoding UTF-8 -Xlint:all -Werror`；執行 classpath **只有 ResourceAudit 與 Gson 2.10.1**，Minecraft JAR 是 ZipFile 的讀取參數，不在執行 classpath。完整 exe 路徑、逐參數、UTC、退出碼均在 audit-commands-2.json；stdout／stderr log 為 PowerShell UTF-16。

| 檢查 | 實際結果 | 界限 |
| --- | --- | --- |
| standalone auditor 編譯／執行 | 最新各退出 0 | 不是 mod build、Minecraft API 編譯或遊戲測試 |
| 資源盤點 | 144 檔；98 個 JSON／mcmeta 解析；45 PNG 標頭／尺寸（含 logo，模組貼圖仍 44） | 不宣稱完整 PNG 解碼／顯示 |
| 配方 | 13 種結果覆蓋 13 item 名冊；destory_rail=3，其餘=1；pattern/key 對應與候選 result.id 保留 | 未用已註冊 NEW item codec 解析、未合成 |
| tag／loot／語系 | tag 成員對應 OLD 名冊、loot entry 指向既有 item；兩語系各 15 key 且集合一致 | 不是 registry、loot context、翻譯畫面驗收；loot 額外問題獨立記錄 |
| 模型直接引用 | 266 條 parent／model／直接 texture 引用能找到 OLD 檔或 vanilla archive；註冊根的本地模型圖無循環 | 沒有做模型 baking、所有繼承 texture alias／UV／state 值域解析或 atlas stitching |

保留的失敗：第一次 javac 訊息擷取被 PowerShell NativeCommandError 中斷（工具退出 1，編譯器退出碼未取得，不能寫成功）；改為完整擷取後 audit attempt 1 編譯退出 0、檢查退出 1，原因是**檢查工具誤把 -90 當非法**。比對 BlockModelRotation.by 的模 360 邏輯後，只修正證據工具；[初次原始報告](static-audit-attempt-1.json)、[工具原稿](audit/ResourceAudit-attempt-1.java.txt)、[初次命令](audit-commands-1.json)、[初次 log](audit-1.log) 均保留。第二次編譯／檢查退出 0，沒有為使檢查過關修改產品資源。初次 Python alias 無法執行，未使用 Python 做驗證。

**最小載入的範圍：** 本輪只用獨立 Gson 解析 JSON，沒有 Minecraft pack／codec／registry 載入 log，也沒有必要條件尚未具備時冒稱 loader 通過。T-009 的所有格式類別已有精確來源；正式載入需 T-019／T-021／T-022 的註冊及資源，交 T-023／T-024／T-125 使用者執行。依新分工，開發 Agent 不代跑遊戲。

## Datagen 與下游交接

NEW build.gradle 宣告 data run 與 `src/generated/resources`，但本次搜尋 NEW `src/main/java` 沒有 GatherDataEvent／Provider 實作；宣告 run 不等於現成產生器或已驗證輸出。13 配方、loot、tag、models 可採手寫 JSON；**datagen 並非必要前提，是否採用由 T-021／T-022 決定並比對 ID／輸出**。本輪不新增 provider、不執行 runData。

| 任務／T-004 案例 | 帶入的具體事項 | 仍待驗證 |
| --- | --- | --- |
| T-021，C-004；T-023／T-125 使用者 | metadata 策略、舊 blocks/items 貼圖的圖集來源、雙語及額外模型保留 | reload、透明材質、全部模型變體、分頁翻譯、logo 顯示 |
| T-022，C-005／C-006；T-024 使用者 | 單數資料目錄、result.id、材料／排列／產量、4 tag 型別、額外 loot context | 所有配方／掉落／tag 載入、爆炸／工具差異；實際 log |
| T-010／T-019／T-015 | state 合法組合、註冊名冊、渲染材質 | 格式可解析不等於屬性存在；不因此通過其他 API 任務 |
| T-048／T-052／T-062 | 車頭 Java 掉落與保留 loot ID 的責任 | 車頭／整列移除時無重複或遺失 |
| T-081／T-085／T-086 | 144 檔映射、額外資源理由、ID 保留、D8 metadata | 最終 JAR 內容及使用者候選包遊戲結果 |

本項完成條件判定：全部指南資源類別有指定版本依據；144 檔／13 配方有格式與 ID 對照；額外檔案的引用／未確認處明列；非遊戲檢查及失敗／成功證據齊備。尚無獨立審查與人工結果，不宣稱功能交付完成，也不新增註冊物件、舊世界／NBT 轉換或外部模組。

## 官方文件索引

2026-09-27 閱讀 [1.21.1 Resources](https://docs.neoforged.net/docs/1.21.1/resources/)、[Recipes](https://docs.neoforged.net/docs/1.21.1/resources/server/recipes/)、[Tags](https://docs.neoforged.net/docs/1.21.1/resources/server/tags/)。頁面標示 1.21–1.21.1；上述具體欄位、路徑及邊界以 manifest 固定的本機 1.21.1／21.1.251 來源為準，不採其他版本文件的格式。

文件及證據最終自查：[命令腳本](final-check.ps1)、[退出碼與文件指紋](final-check.json)。126 項任務引用完整、依賴無循環且未變、九階段數量不變；Markdown／本機連結與來源快照雜湊檢查通過。這是開發者自查，不是獨立審查或人工驗收。
