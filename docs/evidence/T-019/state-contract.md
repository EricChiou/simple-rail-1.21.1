# T-019 屬性與註冊骨架邊界

2026-09-28。對照 [T-010 完整值域](../T-010/state-domains.md) 與其固定來源；OLD 未執行，舊行為為**依原始碼推定／待確認**。

**本次產品的 11 個方塊均為暫時的 `Block` 骨架，StateDefinition 沒有以下自訂／軌道屬性。** 本表交付 T-019 要求的名稱與值域對照，供後續功能類別實作；不是 runtime dump，不表示屬性已上線。不要把骨架加入可正式遊玩的測試包，或將其沒有狀態、碰撞形狀／接軌及互動的暫時表現當作產品需求。

## 完整值域

| 名稱 | 完整值域 |
| --- | --- |
| `shape_straight` | `north_south`, `east_west`, `ascending_east`, `ascending_west`, `ascending_north`, `ascending_south` |
| `shape_all` | 上列六值，加 `south_east`, `south_west`, `north_west`, `north_east` |
| boolean | `false`, `true` |
| `direction`／`facing` | `down`, `up`, `north`, `south`, `west`, `east` |
| `level` | 整數 0–9 |

## 11 方塊的來源／目標對照

所有 ID 的 namespace 為 `simplerail`；NEW 欄位都是後續**待實作**的狀態契約，並非本次 `Block` 已宣告的屬性。OLD 九軌沒有 `waterlogged`；NEW 依 T-010 指定父類來源新增此繼承狀態，不安排舊資料轉換。

| ID | OLD 宣告／繼承的名稱與值域 | NEW 後續對照（待實作） | 預設／差異與承接 |
| --- | --- | --- | --- |
| `high_speed_rail` | `shape=shape_straight`; `powered=boolean` | 保留兩鍵，增加 `waterlogged=boolean` | 目標父類預設 `north_south/false/false`；真正 powered 基底須傳 `true`。T-025 |
| `holding_rail` | 上列兩鍵，`direction=direction` | 保留三鍵，增加 `waterlogged` | OLD 明設 north，但 any() 對其餘父類值的影響未實測。候選從父類 default 再設 north；T-027 調查通電時序 |
| `oneway_rail` | `shape=shape_straight`; `powered/reverse/need_power/use_power=boolean` | 保留五鍵，增加 `waterlogged` | OLD reverse=false、設定預設 need_power=true/use_power=false；T-020 定設定投影時點，T-029 實作；不在註冊階段讀 COMMON |
| `eject_rail` | `shape=shape_straight`; `powered/reverse/need_power=boolean` | 保留四鍵，增加 `waterlogged` | OLD reverse=false、設定預設 need_power=true；T-020／T-031 承接 |
| `destory_rail` | `shape=shape_straight`; `powered/need_power=boolean` | 保留三鍵及拼字，增加 `waterlogged` | OLD 設定預設 need_power=false；回呼用設定，未證明與 state 永遠一致。T-020／T-033 |
| `timer_holding_rail` | `shape=shape_straight`; `powered=boolean`; `direction=direction`; `level=0–9` | 保留四鍵，增加 `waterlogged` | OLD 兩次 any() 覆蓋前次方向；候選一次在父類 default 設 north/0，最終決定仍交 T-037／T-039 疑點處理，不在本項修正 |
| `cross_rail` | `shape=shape_all` | 保留 shape，增加 `waterlogged` | 父類候選 north_south/false；禁坡／禁彎不等於刪除宣告值域。T-066 |
| `y_cross_rail` | `shape=shape_all`; `powered=boolean`; `direction=direction` | 保留三鍵，增加 `waterlogged` | OLD 明設 powered=false/direction=north；父類其他預設未實測。T-068；不得合併另一 Y 路口矩陣 |
| `y_cross_right_rail` | 同上 | 保留三鍵，增加 `waterlogged` | 候選父類 default＋false/north；T-070，使用自己的 32 組來源矩陣 |
| `train_dispenser` | `facing=direction`; `triggered=boolean` | 保留兩鍵；專用類別與 BE 待實作 | 目標 DispenserBlock 父類來源預設 north/false，只作對照；不能直接照搬其九格、消耗物品或紅石發射邏輯。D4／T-044：專用 BE、27 格非消耗樣板、箱子式 GUI |
| `signal_timer` | `level=0–9`; `powered=boolean` | 保留兩鍵 | OLD 明設 0/false；T-041 承接 tick 排程與 BE，不在本項生成紅石 |

`reverse` 是布林屬性及模型變體，不是註冊物品；`wrench` 資源的 blockstate 不是額外方塊。六向宣告保持完整，正常扳手旋轉只在四水平向；up/down 邊界交 T-035／T-066–T-071，不擅自縮成四向。九軌水中放置、禁坡／接軌及實際 shape 可達性交 T-025／T-026／T-023／T-082。

## 已實作的靜態建構屬性

| 骨架 | T-019 實際設定 | 來源／尚未實作 |
| --- | --- | --- |
| 九個 rail ID 的普通 Block | noCollission、strength=0.7、METAL 聲音 | OLD BaseRail／BasePoweredRail；尚無軌道父類、薄形狀、速度／禁坡／防實體破壞及回呼 |
| 兩機器 ID 的普通 Block | strength=5.0、爆炸抗性=6.0、METAL 聲音 | OLD TrainDispenserBlock／SignalTimerBlock；尚無 BE、GUI、紅石、計時或資料保存 |
| 十一個 BlockItem | Item 預設屬性、各配對同 ID 的 Block supplier | OLD Items.java；挖掘／loot/tag／模型在 T-021／T-022 後續處理 |
| `wrench` 普通 Item | stacksTo=1、COMMON、fireResistant | OLD Wrench.java；工具能力、右鍵、方向／level 修改與編組 T-035／T-053 待實作 |
| `locomotive_cart` 普通 Item | stacksTo=64、UNCOMMON、fireResistant | OLD LocomotiveCart.java；尚無放車、命名／扣物品或 EntityType，T-048 待實作 |

未搬 OLD Material／harvestTool API，不自動增加 requiresCorrectToolForDrops；工具分類交 T-022／T-035。COMMON 設定、D5 秒數計時與讀回補償、D3 區塊票證均沒有在本項開始實作。

## 分頁與時序

- 正式分頁新 registry key：`simplerail:tab`。OLD ItemGroup 沒有同類 registry key，只有 `simplerail.tab` label；保留 `itemGroup.simplerail.tab` 翻譯鍵。這是新增目標 registry key，不是改舊方塊／物品 ID。
- 圖示：`high_speed_rail`。明列順序：wrench、locomotive_cart、high_speed_rail、holding_rail、oneway_rail、eject_rail、destory_rail、timer_holding_rail、cross_rail、y_cross_rail、y_cross_right_rail、train_dispenser、signal_timer。採 OLD Items.java 宣告順序作 NEW 穩定順序，不宣稱 OLD 實際 GUI 排序已測。
- common 入口將 blocks、items、tabs 三個 DeferredRegister 接到 mod bus；BlockItem 傳 DeferredBlock supplier，圖示及內容在回呼內才 `.get()`。不在靜態欄位初始化提早解析 holder 或讀取 COMMON。
- 本項無 client-only 類別引用。分頁名稱翻譯、模型、材質及正式資源均待 T-021；編譯不能證明 client／dedicated server 載入與創造物品可取得，T-092 包／R-02／使用者 T-023 承接。
