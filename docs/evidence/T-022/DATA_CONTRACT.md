# T-022 資料遷移與掉落責任

2026-09-28。OLD 行為均為「依原始碼推定／待確認」；本輪沒有 Minecraft codec／registry／reload 或遊戲操作。採手寫 JSON，不新增 datagen provider、不執行 runData。

## 既有 ID、材料與標籤

[29 檔映射](data-map.json)保留邏輯 ID，只將目錄改成 1.21.1 單數。13 配方的 result.item 改 result.id；ingredient.item、原 pattern（含空白行）、key、材料與 count 原值保留。destory_rail=3，其餘=1，wrench 堆疊上限 1。完整逐配方材料／排列／結果見 [recipes.json](recipes.json)。靜態檢查確認 pattern 的所有非空符號都有材料且沒有未使用 key，不以保留空白邊界推定遊戲不可合成。

| Registry／ID | OLD → NEW 路徑 | 交付 |
| --- | --- | --- |
| recipe simplerail:&lt;原檔名&gt; | data/simplerail/recipes → recipe | 13 crafting_shaped，原材料／排列／產量 |
| loot_table simplerail:blocks/&lt;原檔名&gt; | data/simplerail/loot_tables/blocks → loot_table/blocks | 11 方塊表及 1 額外車頭表；blocks 子路徑不更名 |
| block tag simplerail:rails | tags/blocks → tags/block | 9 軌道，replace=false |
| block tag simplerail:machines | tags/blocks → tags/block | train_dispenser／signal_timer，replace=false |
| item tag simplerail:wrench | tags/items → tags/item | wrench 1 成員，replace=false |
| block tag minecraft:rails | data/minecraft/tags/blocks → tags/block | 原 9 自訂成員，replace=false；保留 vanilla rail 成員 |

新增 [ModTags.java](../../../src/main/java/com/ericchiu/simplerail/registry/ModTags.java)只宣告三個 TagKey，rails／machines 用 Registries.BLOCK，wrench 用 Registries.ITEM；不用額外事件註冊、不建立新物件。舊 SimpleRailTags.WRENCH 在完整 OLD Java 搜尋只見宣告、沒有消費者，但 JSON 本來就是 item tag；不複製錯誤的 block 型別，不修改 OLD。後續軌道／機器／工具消費者使用對應型別；本輪不實作任何工具行為或外部整合。

## 額外車頭表的處置

保留 `simplerail:blocks/locomotive_cart`、type=minecraft:entity、pool name、rolls=1 與 item name。只移除該 pool 的 `minecraft:survives_explosion`：T-009 指定版 ExplosionCondition 引用 EXPLOSION_RADIUS，而 ENTITY 參數集沒有此參數；LootContextParamSet／ReloadableServerRegistries 的來源有驗證路徑。這是已調查的資料相容修正，尚未執行 loader 或取得警告 log，不宣稱 runtime 驗證通過。

不把表改成 block／generic 或換到 entities 子路徑，不新增 locomotive_cart 方塊、不自動接上實體 loot，也不新增 global loot modifier。11 真正方塊表保留 type=block 與原 survives_explosion 條件；BLOCK 參數集允許可選 EXPLOSION_RADIUS。

OLD LocomotiveCartEntity.destroy 由 getReturnItem／spawnAtLocation 自行掉落；完整 OLD Java 搜尋未找到上述額外表的直接消費者。NEW 尚無車頭實體，本輪的 ordinary item 不會建立其 destroy 路徑。**T-048 承接車頭 Java destroy 作唯一正常車頭物品掉落路徑，保留表不代表同時呼叫它。** T-052／T-062 及其測試包應核對普通破壞、爆炸、移除／編組與 gamerule 等有來源的情境，不漏掉也不雙重掉落；具體路徑仍待該實作／人工驗收。一般命令顯式讀取此表的結果與舊非標準 context 的差異未實測；不推定所有外部消費者均不存在。

## 指定版來源與驗證範圍

[17 個固定來源／雜湊](source-references.json)涵蓋 Registries 的 elementsDirPath／tagsDirPath、ShapedRecipe／ItemStack STRICT_CODEC、Ingredient、ShapedRecipePattern、LootTable／LootPool（含 NeoForge pool name）、ExplosionCondition／context／loader、TagFile／TagManager、TagKey，以及 OLD tag／車頭來源。TagKey 從 NeoForge 21.1.251 sources archive 另存，T-010 的最小探針已有三種相同 tag 型別候選；本輪產品 build 確認這三個宣告可編譯。

[393 項獨立檔案契約檢查](audit-results.json)核對嚴格 JSON、OLD→NEW 完整語意、13 項輸出、材料／pattern 符號、12 表條件與既有物件名冊、4 tag 內容與可加總成員，以及 [85 次引用](references.json)。vanilla 材料以固定 client ZIP 的 item model 作來源代理，**不是 runtime item registry 證據**；tag 合併是集合比對，context 相容是指定來源比對，均未執行 Minecraft codec／loot validator。

T-024／T-125 仍須由使用者確認實際配方、工具損傷材料、排列／鏡像、13 產量、方塊工具／爆炸掉落與 tag／reload；T-023 的無資料載入錯誤也未測。人工確認即可結案，不要求附件。I-021-01 仍限制 T-092／T-023 的可操作包；本輪不修 state／模型、不改正式前置。T-025 可依原前置繼續開發，但本輪未開始。
