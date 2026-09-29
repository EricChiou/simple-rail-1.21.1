# T-093 → T-024 配方、掉落與 tag 操作

**開發包已製作；R-02 待審，且 T-024 前置的 T-023 尚未通過，現在不開始人工測試。** JAR 與來源固定，實際結果留白。case-index.json 展開每配方／方塊／tag 的 SP 與 DS 案例，TABLES.md 有 13 配方完整 3×3 網格、符號材料、產量與名冊。

## C-005：每個配方各自合成

每件都用工作台，先以指令取各材料及工作台，在空地切生存；材料每個非空格放 1 個，不 Shift-click，取一次結果。依 TABLES 原網格擺放（`·` 只代表空格，不是材料），確認 ID 与 count，非空格各消耗 1 個原材料，沒有额外產出或回傳 pickaxe。destory_rail 取 3，其餘取 1；13 件全部逐一做 SP 與 DS。timer_holding_rail 的 R 有兩格，須兩個 redstone。

另外每件按包內 croppedPattern 去空白邊，將其放入仍容得下的另一位置，再鏡射該小網格；每次取一次同結果、同產量。不要把原配方轉置成另一配方，high_speed／holding 及 Y 左／右的排列不能互換。1.21.1 ShapedRecipePattern 的 shrink 與 matches 檢查支援平移／水平鏡射；這是指定來源預期，尚未實測。

wrench／destory_rail 再各做一次損傷 iron_pickaxe 材料案例：在生存用鎬採石至有損傷，仍按同配方使用；Ingredient 的一般 item 比對以種類判斷，不要求 damage=0，應產原結果且消耗該鎬。所有測試不加入外部模組。輸入／輸出及扣除不符時回報相應 case ID，不以 recipe unlock 或 `/recipe give` 成功代替實際合成。

## C-006：11 方塊正常掉落與爆炸邊界

每例在平台上放唯一被測方塊，附近先拾走掉落物；設定 `/gamerule doTileDrops true`，切生存，以無附魔 iron_pickaxe 完整破壞。11 件各應得到 1 個同 ID BlockItem（destory_rail 的配方產量 3 不代表破壞產 3）；別用創造破壞或 `/setblock ... air` 當挖掘替代。在平台復放同物件，再用手完整破壞，按原來源未 requireCorrectToolForDrops 的行為檢查同樣單件；這個預期若後續類別有不同工具限制，需先對照 OLD 及程式差異再更新新版包，不看結果後放寬。

每個方塊另做 **explicit loot mine** 對照：切創造以便設定，在空地單放目標，玩家聊天執行 `/loot spawn ~ ~1 ~ mine <被測 x> 65 <被測 z> minecraft:iron_pickaxe`；確認產一件同 ID，原目標方塊仍在。不要再破壞它混入同一計數。指定 LootCommand mine 路徑組 BLOCK context，沒有 EXPLOSION_RADIUS 時 survives_explosion 為 true；此預期是來源推定／待使用者確認。

爆炸以每種方塊各單獨新場景、隔開其他物件，由使用者引爆 TNT；若未破壞目標，換獨立位置重做並記未破壞。目標真正被破壞時，可得 0 或 1 件同 ID、不能得其他 ID／超過單件；檢查無相關 loot/context 錯誤。不得要求每次 TNT 都掉落、由一兩次結果推定機率，或把 command mine 的無 explosion context 當真 TNT。包不要求量測機率／效能。

## 四組 tag 與資料 reload

逐 9 軌道與 2 機器在座標 `(0,65,0)` 單放，依 case-index 使用 `/execute if block 0 65 0 #simplerail:rails run say MATCH` 或 machines；對方組用 unless 確認不誤列。再逐原版 rail、powered_rail、detector_rail、activator_rail 檢查 #minecraft:rails 仍 MATCH，9 自訂也要 MATCH；不要把 #simplerail:rails 當原版合併 tag。

持 wrench 在主手，用 `/execute if items entity @s weapon.mainhand #simplerail:wrench run say MATCH`；改持 minecraft:stick，再用 unless items 應確認不屬於。指令只在玩家聊天，不在 console 用 @s；slots／predicate 語法有固定 1.21.1來源核對，不代表已執行。

`/reload` 前後各核對配方、四組 tag 與 loot mine 對照（完整 13／11／成員仍按索引），看 server logs 無本模組 JSON、recipe、tag、registry、loot 或 context 錯誤。F3+T 不能替代 server reload。若 client 仍有 I-021-01 模型錯誤，不將它歸成 recipe／loot 修正已通過或結案 T-023。

## 額外車頭 loot 與範圍

保留 simplerail:blocks/locomotive_cart／entity type，reload 不應因舊 explosion condition 發出 context 警告；不要用 block mine 指令嘗試 nonexistent locomotive_cart 方塊，或用 context 不匹配的 `/loot ... loot` 來冒充實體 destroy。本包沒有車頭實體，不驗 Java 車頭掉落、不宣稱無雙重掉落；T-048／T-052／T-062 及對應包承接。此案例只確認表載入與來源責任，不刪後續真正破壞／編組／gamerule 驗收。

完成後只需確認「T-024 完成／通過」或列失敗案例／現象；選用 results.json 可填本次結果，log／截圖均非結案必要。失敗後開發修正、Review 複查，再交使用者重測受影響案例。新 JAR 要另產新版包，不覆寫此 v1；未經使用者確認，Agent 不填實際結果。
