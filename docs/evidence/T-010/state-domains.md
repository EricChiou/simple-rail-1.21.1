# T-010 完整方塊狀態值域

這是指定 1.21.1 來源＋OLD 宣告所得的 NEW 候選表，不是 runtime registry dump。所有 ID 保留，OLD 未實測行為均「依原始碼推定／待確認」。機器 BE／GUI 實作不在本項。

| 值域縮寫 | 全部值 |
| --- | --- |
| shape_straight | north_south, east_west, ascending_east, ascending_west, ascending_north, ascending_south |
| shape_all | north_south, east_west, ascending_east, ascending_west, ascending_north, ascending_south, south_east, south_west, north_west, north_east |
| boolean | false, true |
| direction | down, up, north, south, west, east |
| level | 0, 1, 2, 3, 4, 5, 6, 7, 8, 9 |

| ID（simplerail:） | 完整屬性／值域 | 宣告組合數 | 預設與行為限制 |
| --- | --- | --- | --- |
| high_speed_rail | shape=shape_straight；powered=boolean；waterlogged=boolean | 24 | OLD 只繼承基底。NEW 父類明設 shape=north_south,powered=false,waterlogged=false。 |
| holding_rail | shape=shape_straight；powered=boolean；waterlogged=boolean；direction=direction | 144 | OLD 明設 direction=north，但 any() 重置其餘值；OLD 父類最終預設未實測。NEW 候選保留父類 defaultBlockState 再設 north。 |
| oneway_rail | shape=shape_straight；powered=boolean；waterlogged=boolean；reverse=boolean；need_power=boolean；use_power=boolean | 192 | OLD reverse=false、need_power 讀設定（預設 true）、use_power 讀設定（預設 false）；NEW 載入前不得讀 COMMON，T-020 定策略。 |
| eject_rail | shape=shape_straight；powered=boolean；waterlogged=boolean；reverse=boolean；need_power=boolean | 96 | OLD reverse=false、need_power 讀設定（預設 true）；其餘 any() 影響須明列。 |
| destory_rail | shape=shape_straight；powered=boolean；waterlogged=boolean；need_power=boolean | 48 | OLD need_power 讀設定（預設 false）；回呼使用 config 值，不能假定和 state 永遠一致。 |
| timer_holding_rail | shape=shape_straight；powered=boolean；waterlogged=boolean；direction=direction；level=level | 1440 | OLD 先 any().direction=north，再 any().level=0，前次 direction 設定被替換。NEW 候選一次保留父類預設並明設 north/0；最終修正依 T-037/T-039，不冒充舊實測。 |
| cross_rail | shape=shape_all；waterlogged=boolean | 20 | OLD 覆寫 isStraight=true，但宣告 shape 仍繼承 RailBlock。NEW 候選 isFlexibleRail=false 且 canMakeSlopes=false；宣告值域不因禁坡自動縮小。 |
| y_cross_rail | shape=shape_all；waterlogged=boolean；powered=boolean；direction=direction | 240 | OLD powered=false,direction=north，再 onPlace/updateState 取直接紅石；NEW 候選保留父類 shape/waterlogged 預設。 |
| y_cross_right_rail | shape=shape_all；waterlogged=boolean；powered=boolean；direction=direction | 240 | 與另一 Y 型值域相同，分岔矩陣不同；不能互換路徑演算法。 |
| train_dispenser | facing=direction；triggered=boolean | 12 | OLD 依 DispenserBlock 繼承，onPlace 將非水平改 north；NEW DispenserBlock 預設 north/false。D4 改專用 BE 時仍保留既有鍵；不得照搬原版 9 格發射器邏輯。 |
| signal_timer | level=level；powered=boolean | 20 | OLD 明設 level=0,powered=false；NEW 候選保持。 |

來源：target 的 BlockStateProperties／RailShape／Direction／BooleanProperty／IntegerProperty／EnumProperty、RailBlock／PoweredRailBlock／DispenserBlock／StateDefinition，及逐類 OLD createBlockStateDefinition／建構子。以上檔案均在 source-manifest.json 固定；JSON 版逐項列出來源。

- 宣告可表示不等於正常可到達：禁坡／禁轉彎 hook 只影響自動接軌；不自動刪除 shape 值域。不能把 shape_straight 誤寫為僅兩個值。三種路口的正常通過只使用 north_south／east_west，Y 的水平 4×來向 4×供電 2 共 32 組／種類沿用 T-003 矩陣；up/down 仍在 direction 宣告值域，非正常旋轉目標，邊界由 T-019／T-066–T-071 測例定義。
- direction/facing 全六向；扳手正常旋轉 north→east→south→west→north，up/down 不直接呼叫 getClockWise（會失敗），不擅改四向 property。扳手 level 是 9→0；不要靠 IntegerProperty 的集合迭代順序猜循環。
- NEW 所有九種軌道按父類繼承 waterlogged={false,true}；父類預設 false，getStateForPlacement 可依水改 true。D1 不需舊資料轉換，但 T-019／T-025 要記錄新增繼承狀態及水中行為策略，T-023／T-026／T-082 使用者驗收。未在此承諾舊版水中等價。
- StateDefinition.any() 取狀態集合首項，不是父類 defaultBlockState。NEW BooleanProperty 迭代為 true,false；照搬 any() 會令未明設的 powered/waterlogged 取 true。完整 default 候選應在父類 defaultBlockState 基礎一次設定或逐欄明設，不宣稱 OLD 引擎預設已實測。
- 設定投影到 need_power/use_power 的時點交 T-020，避免註冊建構時讀取尚未載入 COMMON；不要把表中的來源預設當成正在執行的設定。
- 源自 OLD 的狀態疑點以 T-003 U-08／T-004 C-002 接續；此表沒有自行縮減 ID、狀態值域或執行修正。

