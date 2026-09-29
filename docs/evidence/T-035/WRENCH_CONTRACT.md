# T-035 扳手來源、屬性身份與 U-09 契約

2026-09-29。MIGRATION.md §3 扳手／狀態／tag、§4.1、§6 階段 3，T-003 B-15／U-09、T-004 C-012、T-010 A09–A14。OLD [Wrench](sources/old/Wrench.java)／[SimpleRailProperties](sources/old/SimpleRailProperties.java) 為來源參考，**依原始碼推定／待確認**，沒有 OLD build／遊戲實測。

## 來源與目標規則

| 項目 | OLD 來源行為 | NEW 相容交付／限制 |
| --- | --- | --- |
| 註冊／物品 | stacksTo(1)、COMMON、防火、ToolType.HOE 0 | same simplerail:wrench，registerItem factory→Wrench(Properties)，原物品屬性不變。canPerformAction 宣告 [ItemAbilities.DEFAULT_HOE_ACTIONS](sources/target/net/neoforged/neoforge/common/ItemAbilities.java)＝HOE_DIG／HOE_TILL；[IItemExtension](sources/target/net/neoforged/neoforge/common/extensions/IItemExtension.java) 預設 false。不自動加 HoeItem 耕地、tier／速度／耐久或新玩法 |
| 端／結果 | client SUCCESS，server CONSUME | client guard 在讀世界前；非 ServerLevel PASS，server 原有 CONSUME。不使用 context.getPlayer，不因 null player 解參考；CONSUME 不等於扣物品 |
| 車輛條件 | 查第一格／第二格，第一格無車且 rails 才改屬性 | T-035 只保留點擊格 new AABB(pos) 的 AbstractMinecart 查詢；第二格、小數邊界、找車頭／編組留 T-057／T-058，不提前做 link。實際 [EntityGetter](sources/target/net/minecraft/world/level/EntityGetter.java) 查詢預設排旁觀者，AABB 是實體包圍盒相交，非僅車中心是否在格內；幾何 fixture 不驗實際載入／光譜狀態 |
| rails／machines | rails 無車：reverse→level→direction；machines 無車要求以外：facing→level | 相同 gates 與順序；缺屬性不動，沒有改 shape／powered／need_power／use_power，不掃鄰格。機器即使有車仍可調適用屬性；非 tagged block 不變 |
| Property 身份 | OLD 共用 singleton properties | 目標 [StateHolder](sources/target/net/minecraft/world/level/block/state/StateHolder.java) values 為 Reference2ObjectArrayMap，hasProperty／getValue 依實例查詢；[StateDefinition](sources/target/net/minecraft/world/level/block/state/StateDefinition.java).getProperty(name) 取得當前方塊的真實 property。不能為 Wrench 重建同名 singleton，Property.equals 也不能解決 reference key；現有各軌道各自宣告 property 不必重寫 |
| reverse | Boolean 值反轉 | 名称 reverse／BooleanProperty 型別才操作，用實際實例 getValue／setValue；錯型不動 |
| level | 0–9，>=9→0，其餘+1 | 名称 level／IntegerProperty，值域含 0／9 且 size=10（IntegerProperty 連續範圍）；不把 vanilla level=0–15 當本模組計時等級。全部 0–9 有 [矩陣](operation-matrix.json) |
| direction／facing | 四水平 N→E→S→W→N，up／down 不進分支 | 指定名字／EnumProperty／getValueClass=Direction，水平 getClockWise 且 next 在該 property 值域內才寫；垂直不動，錯型不會 cast 到 Direction。保留原六向宣告，不擅改方塊 domain |
| 更新／保存 | 每項適用操作對同一份初始 state 分別 setBlock(...,3) | 保留 U-09 逐次初始 state 寫回，沒有累積修正；沒有變化不寫（例如垂直旋轉），UPDATE_ALL=3。沿 blockstate／既有父類同步保存，未新增 BE／NBT／自訂 packet；通知後真實 parent 時序與世界結果待人工 |
| GUI 管線 | 舊右鍵 block.use／item.useOn 可能有先後 | [ServerPlayerGameMode](sources/target/net/minecraft/server/level/ServerPlayerGameMode.java)、[MultiPlayerGameMode](sources/target/net/minecraft/client/multiplayer/MultiPlayerGameMode.java)、[ItemStack](sources/target/net/minecraft/world/item/ItemStack.java) 先 block.useItemOn 等，再 item.useOn；[UseOnContext](sources/target/net/minecraft/world/item/context/UseOnContext.java) 允許 null player。當前機器骨架無 GUI；未加全域攔截。未來 T-044 要用已查證 SKIP_DEFAULT_BLOCK_INTERACTION 等候選承接扳手優先序，主副手／蹲下／GUI 實況待整合驗收 |

來源固定 MC 1.21.1／NeoForge 21.1.251 merged archive，22 目標快照與 archive SHA-256 見 [manifest](source-manifest.json)。[DeferredRegister](sources/target/net/neoforged/neoforge/registries/DeferredRegister.java) typed factory、Item.useOn／ItemAbility／state lookup 真實 build 已編譯；不宣稱任意 1.21.1 API 或遊戲操作已通過。

## U-09：已確認靜態原因，意圖仍待確認

OLD 各 change 方法均以同一初始 state setValue／setBlock。這是可讀取的源碼資料流；[fixture 重現](U09-source-reproduction.json) 與本次產品 hook 也保留此行為。未宣稱 OLD 遊戲已重現或使用者已授權修改。

| fixture 起點 | 寫回順序 | 目前來源相容結果 | 未決 |
| --- | --- | --- | --- |
| rails、reverse=false／level=9／direction=north、無車 | reverse=true；level=0；direction=east，各以起始 state 寫 | reverse=false／level=9／direction=east | 是否改為全部累積，待使用者回覆 |
| machines、facing=north／level=9 | facing=east；level=0，各以起始 state 寫 | facing=north／level=0 | 是否改為全部累積，待使用者回覆 |
| rails、level=9／direction=up、無車 | level=0；垂直 direction 不寫 | level=0／direction=up | 舊水平分支邊界保留，不猜測新的垂直輪轉 |

已提出「採累積更新修正／保留原碼覆寫」釐清，尚未收到決策，故沿用原碼並保留待確認。U-09 影響的複合人工期望尚未定案；T-036／T-040 等不得直接將它判通過。D6 後續修正由確認後的具體範圍與回歸處理，不在本項默改。

## 屬性承接與測試限制

[11 方塊表](property-tag-map.json) 列出真實產品狀態與待實作 owner：holding direction、oneway／eject reverse 已宣告；timer level／direction 留 T-038、signal level 留 T-041、dispenser facing 留 T-044、Y 路口 direction 留 T-068／T-070。high_speed／destory／cross 沒扳手適用屬性。這些無屬性骨架目前無操作，不能以 fixture 推定它們已有功能、GUI 或可實測全部狀態。

產品 Wrench 原始碼另配 [30 本地替身](test-double-fingerprints.json) javac／java，各退出 0：388 案例、1,575 判定。[24 單屬性矩陣](operation-matrix.json) 及 U-09 例全部 gameResult=null。fixture 每次建立不同 Property 實例，驗證實際 lookup 而非碰巧使用 singleton；測 rails／machines／雙 tag／無 tag、車有無、null player、全 scalar 值、無屬性／錯型／0–15 range、垂直 no-op、client／非 ServerLevel、物品不消耗、HOE 能力與幾何邊界。替身 StateDefinition、StateHolder、AABB 不等於真實 Minecraft；只有 build 補足 real API 可編譯證據。

後續 T-036／C-012、階段 4／路口：真實 world scalar／複合屬性、車包圍盒阻擋、兩端同步、保存讀回、tag reload、主副手／蹲下／旁觀／取消事件／GUI 競合、機器／計時／路口副作用仍待使用者。T-099 包與 R-03 未執行，T-024 等正式前置不改；目前未 ready 的人工案例不無故阻擋其他無關開發。使用者確認即可人工結案，附件選用，Review 僅審程式／資源／覆蓋，不代跑世界或簽人工通過。
