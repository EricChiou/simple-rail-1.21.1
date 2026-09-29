# T-027 holding_rail 來源行為、目標介面與差異

日期：2026-09-29。OLD 行為均為 **依原始碼推定／待確認**，沒有重跑 OLD build／舊版遊戲。目標限於 Minecraft 1.21.1／NeoForge 21.1.251 的本次介面與來源，不宣稱全部 API 已驗證。[來源指紋](source-manifest.json)保存 OLD 三檔及目標九檔／merged sources.jar。

| 行為 | OLD 依據 | NEW 交付／界限 |
| --- | --- | --- |
| ID／物品 | 原 holding_rail 登錄及 BlockItem；D2 | 同 ID 的 ModBlocks.HOLDING_RAIL 改用 HoldingRail factory，ModItems 既有 BlockItem 不變；其他十個方塊／十三物品 ID 不變 |
| 狀態／預設 | [HoldingRail](sources/old/HoldingRail.java)、[SimpleRailProperties](sources/old/SimpleRailProperties.java)：direction 完整 Direction enum，顯式 NORTH | direction 全六值保留；使用 defaultBlockState 加 NORTH，保留父類 shape=NORTH_SOUTH、powered=false、waterlogged=false。PoweredRailBlock／EnumProperty 來源及實際編譯支持，沒有新增 BE／NBT／舊資料轉換 |
| 未供電停車 | OLD onMinecartPass：非零完整向量記 getMotionDirection；速度 ZERO；moveTo(pos,yRot,xRot) | 相同非零條件及 getMotionDirection，先記方向再歸零；Block.UPDATE_ALL=3。以 moveTo(BlockPos,...) 停在底部中心，保留旋轉；已靜止不重寫 direction |
| 座標 | OLD BlockPos moveTo 使用方式，精確結果非旧實測 | 目標 [Entity](sources/target/net/minecraft/world/entity/Entity.java) 1453–1469 及 [BlockPos](sources/target/net/minecraft/core/BlockPos.java) getBottomCenter：x+0.5、y、z+0.5。對負座標同樣成立，不多加 y 位移 |
| 供電放行／選車 | OLD updateState：進入的 powered=true 時，用 new AxisAlignedBB(pos) 查所有 AbstractMinecart；direction normal×0.4；然後呼叫父類 | new AABB(pos)，所有相交的 AbstractMinecart 沿 direction 的各分量×0.4。保持原單一方塊範圍／多車語意，不加 UUID cache、跨格搜尋或牽引編組功能 |
| updateState 時序差異（U-06／C-008） | 舊碼在父類之前看輸入 powered，不足以代表該次更新後的電力；是否依賴額外通知才放行待舊實測 | 固定版 [PoweredRailBlock](sources/target/net/minecraft/world/level/block/PoweredRailBlock.java) 146–157 在 updateState 計算直接／鐵軌電力並 setBlock。NEW 先父類、再讀回且確認仍是本方塊，只在 false→true 放行，true→true／true→false 不重設向量；避免重複通知／斷電時再次推動。這是明列的時序調整，不宣稱已重現舊版 bug |
| client／同步與保存 | OLD 本類沒有獨立 client guard；實際回呼管線待舊實測 | 两個修改 hook 都先排除 client；[AbstractMinecart](sources/target/net/minecraft/world/entity/vehicle/AbstractMinecart.java) 標準服務端 moveAlongTrack 呼叫過車 hook，呼叫後仍有父類分支。direction 在 blockstate，自動進世界方塊狀態存讀；setBlock UPDATE_ALL 請求既有更新管線，無自訂 packet。client 畫面、礦車移動同步、新世界存讀仍待使用者後續驗收 |
| 共用速度／禁坡／實體破壞／工具 | [BasePoweredRail](sources/old/BasePoweredRail.java)：共同設定、canMakeSlopes=false、canEntityDestroy=false、pickaxe、動力 true | 繼承本專案 BasePoweredRail；COMMON 即時快照及 cart cap 仍限制實際速度，保留原版動力／煞車／摩擦。只有高速可成坡，holding 不加例外；僅 pickaxe tag 附加 holding_rail，不加 requiresCorrectToolForDrops |

## 宣告狀態與模型的界限

direction 6×shape 6×powered 2×waterlogged 2，共 144 宣告組合。原有四個 selector 忽略 direction／waterlogged，可映射 48 個平軌組合；96 升坡組合在繼承值域內，但禁坡的正常放置不產生、現有模型未覆蓋。見 [全表](state-coverage.json)。不增加 holding 斜坡、改模型或縮小歷史值域；也不因此整體解除 I-021-01／T-092，強制寫入非自然升坡的場景不在本次新玩法範圍。

## 已執行與待執行

- NEW build 實際退出 0，真實 class 的 major=65 與 API bytecode 留存。
- 實際 HoldingRail 原始碼在獨立目錄另編譯，配 15 個明示測試替身，85 項判定通過。包含六 direction 值（正常來車四水平向）、非零／零向量、底部中心與角度、供電邊沿、重入、單格多車／外格、client guard、被替換方塊／空軌。**沒有載入真正 Minecraft 類別或啟動遊戲**；不能驗證真實紅石通知、碰撞／yaw、父類礦車回呼時序、registry／模型 baking／存讀／兩端同步。
- source＋編譯確認介面／父類更新順序；實際供電上升沿通知是否由一次操作產生多次、第一 tick 的進車 heading 與 moveTo 後的同步效果仍交 T-028／T-095。沒有用隔離替身推定 Minecraft runtime 通過。
- 不開始 T-029 或六疑點的其他修正；沒有修改 HighSpeedRail／R2 helper，T-026 使用者通過仍保留為該次歷史，本次新 JAR 的完整回歸不自動套用。

## T-095／T-028 的測例輸入（尚未執行）

C-008 保留 SP＋dedicated server；四水平向各做未供電進入→中心停車→供電沿保存方向放行，空軌／多車／外格、已供電直接過車、重複鄰居通知、反覆切電、不同原版接口與 COMMON 三設定。需要觀察低速進車受原版煞車影響的方向與新世界存讀後方向；載人／空車及水中的父類行為列清楚，不因配置值宣稱實際速度。完整操作／期望及固定包由 T-095 製作，T-028 由使用者確認即可結案，附件選用；本項不填人工結果。
