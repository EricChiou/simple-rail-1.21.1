# T-010 軌道、礦車回呼與工具互動 API 查證

2026-09-27。**開發完成；R-01 程式審查待審；人工遊戲未執行**。前置 T-004／T-005 已交付。本項是指定版本的來源查證及候選簽名編譯，不是軌道／扳手移植或遊戲回呼觀察；T-025 等實作任務未開始。

## 固定版本與交付

- NEW `D:/workspace/java/simple-rail-1.21.1`；OLD `D:/workspace/java/simple-rail`。HEAD／差異／產品指紋見 [範圍核對](verification.json)。OLD build 由使用者先前驗證，本次流程不重跑；舊行為均「依原始碼推定／待確認」。
- 目標 **Minecraft 1.21.1／NeoForge 21.1.251**，編譯 classpath 的 FML **4.0.44**、event bus **8.0.5**；Java 21（Temurin **21.0.12.1**）、Gradle **9.2.1**／ModDevGradle **2.0.147**。來源固定到本機 merged sources archive，版本與 SHA-256 見 [來源 manifest](source-manifest.json)、[classpath 指紋](classpath-manifest.json)、[編譯器](compiler.txt)。
- [API 探針](probe/T010Probe.java)、[init script](probe.init.gradle)、[完整狀態表](state-domains.md)、[機器可讀狀態值域](state-domains.json)。77 個快照＝35 個指定目標來源＋42 個 OLD Java；本次未執行 OLD 程式。
- 探針沒有 mod 入口、註冊、main 或 metadata；沒有加入產品 sourceSet。只編譯，不載入／實例化。PoweredProbe／MachineProbe 的屬性聯集只用來查簽名，**不是任何產品 ID 的實際 StateDefinition**。每個 ID 的候選值域以狀態表為準。

`M/`＝`sources/target/net/minecraft/`，`N/`＝`sources/target/net/neoforged/neoforge/`，`O/`＝`sources/old/`。以下方法名稱及行號對應快照；來源推論、編譯可用性與遊戲結果分開。

## API 與編譯對照

| 項目／OLD | 1.21.1 指定來源與候選簽名 | 編譯證據／限制 |
| --- | --- | --- |
| A01 BaseRail／BasePoweredRail 建構 | `M/world/level/block/{RailBlock,PoweredRailBlock}.java`；`RailBlock(Properties)`、`PoweredRailBlock(Properties, boolean isPoweredRail)`；`BlockBehaviour.Properties.of().noCollission().strength(0.7F).sound(SoundType.METAL)` | FlatRailProbe／PoweredProbe／railProperties。**OLD 傳 true，NEW 仍須 true 才是 powered；此 patch 單參數建構子傳 false，會成 activator。**不因名稱相同就省掉第二參數 |
| A02 速度 | `N/common/extensions/IBaseRailBlockExtension.java:61` 的 `float getRailMaxSpeed(BlockState,Level,BlockPos,AbstractMinecart)`；`M/world/entity/vehicle/AbstractMinecart.java:841–863,909` 的 cap／moveMinecartOnRail | 兩基底均覆寫編譯；cartOperations 可呼叫 getMaxSpeedWithRail。最終上限為 rail 回傳值與 current cart cap 的 min；預設 getMaxCartSpeedOnRail=1.2，還有乘客倍率／摩擦等。0.8／2.0 設定不能直接當作實測位移或保證速度 |
| A03 禁坡、禁止彎接、方向 | `IBaseRailBlockExtension` 的 `canMakeSlopes(BlockState,BlockGetter,BlockPos)`、`isFlexibleRail(...)`、`isValidRailShape(RailShape)`、`getRailDirection(...,@Nullable AbstractMinecart)`；`RailState.java:27–28,184–208,314–334` | FlatRailProbe 覆寫四方法，PoweredProbe 禁坡。RailState 用 isFlexibleRail，不呼叫可覆寫 isStraight；BaseRailBlock 自身也有 private isStraight。路口不能只搬 OLD isStraight=true。候選禁彎／isValidRailShape 與形狀宣告分開，不擅改完整 shape 值域 |
| A04 實體破壞判斷 | `N/common/extensions/IBlockExtension.java:712` 的 `boolean canEntityDestroy(BlockState,BlockGetter,BlockPos,Entity)` | 兩基底覆寫 false 編譯。不是「所有破壞都禁止」：玩家挖掘、支撐移除、爆炸、活塞等仍各有路徑，不從此 hook 宣稱全部防破壞 |
| A05 過車回呼 | `IBaseRailBlockExtension.java:76` 的 `void onMinecartPass(BlockState,Level,BlockPos,AbstractMinecart)`；`AbstractMinecart.tick`／moveAlongTrack 的呼叫位置 | 兩基底覆寫編譯，探針 guard client。標準 tick 的 server 分支在 canUseRail＋BaseRailBlock.isRail、shouldDoRailFunctions 條件下呼叫；不是所有礦車／所有重寫 tick 都保證呼叫。自訂車頭／編組留 T-013／T-048 |
| A06 紅石與鄰居回呼 | `BaseRailBlock.java:83–123`：`protected void updateState(BlockState,Level,BlockPos,Block)`；`PoweredRailBlock.java:145` 的同名覆寫；`BlockBehaviour.neighborChanged(BlockState,Level,BlockPos,Block,BlockPos,boolean)`；`Level.hasNeighborSignal(BlockPos)` | PoweredProbe.updateState、MachineProbe.neighborChanged。BaseRailBlock 鄰居路徑先檢查 server／仍是該方塊及支撐，再進 updateState；powered 計算含直接紅石與沿線搜尋。incoming state、直接訊號、父類更新後 state 三者不是同一值 |
| A07 放置／連線／預設 | `BaseRailBlock.onPlace`、`getStateForPlacement(BlockPlaceContext)`、updateDir；`BlockStateProperties`／StateDefinition | PoweredProbe.onPlace／getStateForPlacement／createBlockStateDefinition 編譯。NEW rail 父類加入 waterlogged；getStateForPlacement 依水平朝向及水設定。onPlace 不能一概標 server-only；更新世界／設定讀取須按呼叫端保護 |
| A08 路口清理 | OLD destroy／removedByPlayer → `Block.destroy(LevelAccessor,BlockPos,BlockState)`、`IBlockExtension.onDestroyedByPlayer(BlockState,Level,BlockPos,Player,boolean,FluidState)`；`BlockBehaviour.onRemove(BlockState,Level,BlockPos,BlockState,boolean)` | FlatRailProbe 三方法編譯。onDestroyedByPlayer 有 client/server 分支；onRemove 須區分「同 block 改 state」與被換掉，否則路口更新 shape 也可能清 cache。實際跨維度／生命週期清理政策交 T-072／T-073，不在此修補 |
| A09 礦車／乘客移動與移除 | `Entity.getDeltaMovement/setDeltaMovement/getMotionDirection/getYRot/getXRot/moveTo/getPassengers/stopRiding/ejectPassengers/discard`；`Level.getEntitiesOfClass(...,new AABB(pos))` | cartOperations／WrenchProbe 編譯。NEW `moveTo(BlockPos,yRot,xRot)` 使用 pos.getBottomCenter，即 x+0.5,y,z+0.5；不能猜成方塊整數角落。discard 是移除候選，並不等於 destroy(DamageSource) 的掉落語意；乘客與編組由後續任務驗收 |
| A10 Item useOn／扳手 | `Item.useOn(UseOnContext)`；UseOnContext 的 clickedPos／clickLocation／horizontalDirection／player；`ServerLevel.getEntity(UUID)` | WrenchProbe 編譯且 server guard 後才使用 ServerLevel。getPlayer 可 null；getHorizontalDirection 取玩家水平朝向（null 時 NORTH），不是 getClickedFace。AABB 查詢保留 OLD 相鄰兩格策略的 API，但未實作編組 |
| A11 方塊 use 的拆分 | OLD Block.use → `protected InteractionResult useWithoutItem(BlockState,Level,BlockPos,Player,BlockHitResult)` 及 `protected ItemInteractionResult useItemOn(ItemStack,BlockState,Level,BlockPos,Player,InteractionHand,BlockHitResult)`；BlockBehaviour:222–230、DispenserBlock.useWithoutItem | MachineProbe 兩方法編譯；專用 BE／Menu 不在探針。扳手分支 SKIP_DEFAULT_BLOCK_INTERACTION 是候選，避免 block 先開 GUI 吃掉 item useOn；是否採用由 T-035／T-044 的既有操作需求與案例判斷，不能以編譯證明優先順序效果 |
| A12 結果與右鍵管線 | `M/world/{InteractionResult,ItemInteractionResult}.java`；ServerPlayerGameMode.useItemOn、MultiPlayerGameMode.performUseItemOn、ItemStack.useOn／onItemUseFirst；`N/common/CommonHooks.onPlaceItemIntoWorld` | WrenchProbe 用 client SUCCESS／server CONSUME；MachineProbe 可用 sidedSuccess、PASS_TO_DEFAULT_BLOCK_INTERACTION、SKIP_DEFAULT_BLOCK_INTERACTION。CONSUME 表示動作被處理，**不是扣物品**。兩端有各自呼叫，取消事件／旁觀／蹲下／主副手／冷卻會影響後續分支 |
| A13 狀態／tag／旋轉 | StateDefinition.Builder.add、BooleanProperty／IntegerProperty.create／EnumProperty.create；BlockState.hasProperty/getValue/setValue/cycle/is(TagKey)；Direction.getClockWise、Level.setBlock(...,Block.UPDATE_ALL) | 探針宣告全部自訂欄位、六向 facing、triggered；WrenchProbe 使用累積 state、level 9→0、水平旋轉 guard。UPDATE_ALL=3 的更新旗標可編譯；不保證一次右鍵只發一個 packet／更新。rails／machines 是 block tag，wrench 為 item tag，對應 T-009 |
| A14 工具與挖掘分類 | OLD harvestTool(PICKAXE)／addToolType(HOE,0) → `BlockTags.MINEABLE_WITH_PICKAXE`、`IItemExtension.canPerformAction(ItemStack,ItemAbility)`、`ItemAbilities.DEFAULT_HOE_ACTIONS` | railProperties 去除舊 Material／harvestTool，WrenchProbe 編譯能力查詢候選。能力宣告不會自動實作 HoeItem 耕地；不能把工具能力、挖掘速度與掉落門檻混為一談。T-022／T-035 決定標籤／工具行為，沒有默加 requiresCorrectToolForDrops 或新玩法 |
| A15 訊號機器回呼 | `BlockBehaviour.tick(BlockState,ServerLevel,BlockPos,RandomSource)`、getSignal(BlockState,BlockGetter,BlockPos,Direction)、isSignalSource(BlockState)；Level.scheduleTick | MachineProbe 編譯。只確認回呼／紅石介面，訊號排程去重、BE tick、保存與相位留 T-011／T-041；不改 D5 停車的實際秒數計時 |
| A16 子類 codec 泛型 | RailBlock.codec 回傳 **MapCodec<RailBlock>**；PoweredRailBlock.codec 回傳 **MapCodec<PoweredRailBlock>**；Block 父類可用 wildcard | 探針最初用 MapCodec<子類> 覆寫前兩者失敗（泛型不協變）；改為父類回傳型別、simpleCodec 的建構 factory 仍指向探針子類，最小編譯成功。未註冊 block type／未做 codec runtime，不假定其他父類也接受同一寫法 |

## 執行端與順序：來源可確認的界線

**標準礦車來源路徑：** AbstractMinecart.tick 的 client 分支主要插值；server 分支找軌道 → moveAlongTrack。移動函式先辨識 powered／activator、取 rail direction、執行未供電煞車與運動／摩擦，再在第 504–505 行呼叫 onMinecartPass；其後仍可能執行供電加速。回呼收到的是本輪先前取得的 state／pos；回呼內改 shape、移除車或歸零，不能推定會終止父類剩餘工作。這是 source trace，不是錄製的實際時序。無回呼觀察 log。

`BaseRailBlock.isRail` 同時要求 minecraft:rails tag 與 BaseRailBlock 型別；只加 tag 或只繼承類別均不能單獨當成完整接軌證據。getRailDirection 在非車輛呼叫可收到 null cart，不可無條件解參考。getRailMaxSpeed 回傳設定只是一層限制，速度驗收仍涵蓋原版車／車頭、乘客／水、直線、每個共用基底。

**右鍵來源路徑：** client/server 都可能經過自己的 game mode／ItemStack 管線；先受事件與模式控制，item.onItemUseFirst 可提前處理；一般 block.useItemOn → 若 PASS_TO_DEFAULT 且主手才考慮 useWithoutItem → 尚未消耗動作才呼叫 item.useOn。SKIP_DEFAULT 只跳過預設 block 互動，不代表取消 item.useOn。探針無 client 寫世界；伺服器才變更狀態與編組。連線、蹲下、空手、主副手及 GUI 與扳手競合必須由使用者測試，不能只看回傳列舉宣稱正確。

`Level.playLocalSound`／addParticle 的基底方法為空；僅編譯 OLD 呼叫不保證 server 廣播特效。聲音／粒子／資料同步的正式候選及實測交 T-014／T-063／T-065，不在這輪冒充已查證完整同步 API。

## 每種軌道／扳手的交接

| 功能 | 本項可用介面 | 來源差異／下一步與案例 |
| --- | --- | --- |
| high_speed_rail／兩共用基底 | A01–A05、A07、A13–A14 | 所有衍生軌都讀共同速度；powered 必須 true、速度受 cart cap 影響、禁坡不是刪值域。T-025／T-026，T-004 C-007 |
| holding_rail | A05–A07、A09 | OLD updateState 在 super 前讀 incoming powered，不能推定剛通電即釋放；after-state 查詢只是可用候選，T-027 調查並定義釋放時序，T-028／C-008 驗收 |
| oneway_rail | A05–A07、A09、A13 | OLD usePowerChangeDirection 是啟用分支，未直接切 reverse。NS：reverse=true→+Z、false→−Z；EW：true→−X、false→+X。未啟用的 ×1.2 還受父類煞車／cap 影響。T-029／T-030、C-009；不默修註解意圖 |
| eject_rail | A05、A09 | OLD server guard；NS 在 X 側移、EW 在 Z 側移，距離＋0.5、y=blockY；保留方向來源，不能猜按來車方向。乘客集合及障礙／多人由 T-031／T-032、C-010 驗證 |
| destory_rail | A05、A09 | discard 候選可編譯，但不等同破壞掉落；回呼後父類仍可能運算。T-033／T-034、T-061／T-062、C-011／C-029；不改拼字、票證政策或先做整列刪除 |
| timer_holding_rail | A05、A07、A09、A13 | 兩次 any() 設預設互相替換；COMMON static final 風險沿用 T-008。D5 秒數＋讀回補償不改 tick，T-011／T-037–T-040／T-083 接續；含剩餘約 3 秒卸載／關服後仍約 3 秒，容差待技術定義 |
| cross_rail | A03、A05、A08–A09 | isFlexibleRail／isValidRailShape 的接軌候選、getMotionDirection 與 bottom-center 可編譯；跨維度 cache 與 cleanup 未修。T-066／T-067／T-072–T-074 |
| y_cross_rail／y_cross_right_rail | A03、A05–A09、A13 | 兩者分別保留 T-003 的 32 組方向／來向／供電來源矩陣，未縮成同一算法；direct signal 與 powered rail 傳電規則不同。T-068–T-074 |
| wrench | A10–A14 | OLD clickLocation 與玩家水平朝向決定相鄰格；同格無礦車才改軌 state。多個 setBlock 若從同一舊 state 出發可能覆蓋先前更改，NEW 候選累積 state，但需逐功能／案例確認，不先修編組。T-035／T-036、T-053／T-054／T-063、C-012 |
| train_dispenser／signal_timer | A06–A07、A11–A13、A15 | 完整 facing／triggered／level／powered 值域列狀態表；D4 專用 BE＋27 格非消耗樣板，不能直接繼承原版 dispenser 的 9 格/消耗行為。GUI 優先與訊號 tick 留 T-011／T-012／T-041／T-044 |

來源表與案例引用只表示有承接，不表示上述任務已執行。T-003 的 OLD 行為參考與 T-004 設計結果不改寫為 NEW／OLD 實測。

## 完整狀態與未決項

[狀態表](state-domains.md) 逐一列 11 方塊、全部屬性／值域／候選宣告組合數／來源預設與待確認。六向 direction／facing 不等於只允許水平；shape_straight 仍含四斜坡，RailBlock 的 shape 含四彎道。是否可由正常放置到達，與宣告能否表示要分開。九種 rail 繼承的 waterlogged 是 NEW 差異，沒有把它當 OLD 已驗證需求。

NEW `StateDefinition.any()` 取狀態集合首項，BooleanProperty 迭代為 true,false；照搬 OLD 在子類 any() 上只設自訂欄位，可能把父類明設 false 的 powered／waterlogged 覆蓋成 true。Timer 先設 direction 再第二次 any() 設 level，不能保留先前 north。**候選是沿用父類 defaultBlockState 並一次明設自訂欄位**，不在本輪執行修正，也不猜 OLD 引擎最終預設。

待查證／技術決定：T-019／T-020 的完整 default 與 COMMON 投影時點、T-025 水中行為、T-027 停車通電時序、T-035／T-044 GUI／扳手優先與挖掘能力、T-033／T-048 移除及父類後續運算、T-063 同步與粒子聲音，以及全部使用者回呼／遊戲案例。這些是明列的實作／runtime 邊界；本項候選方法均有來源與編譯證據，沒有宣稱整套 1.21.1 API／遊戲行為都已驗證。

## 最小編譯實際結果

NEW 工作目錄的實際 Gradle 命令：

```powershell
.\gradlew.bat compileT010Probe --offline --console=plain --info --no-configuration-cache -I docs/evidence/T-010/probe.init.gradle
```

由 [compile.ps1](compile.ps1) 保存 UTC／命令／退出碼／完整合併 stdout-stderr（UTF-16）。

| 嘗試 | 實際結果 | 證據 |
| --- | --- | --- |
| 01 沙箱內 | Wrapper 的 C:\.gradle 鎖檔父路徑無法建立；退出 1、尚未編譯 | [命令](compile-01.json)、[log](compile-01.log) |
| 02 經允許沙箱外離線 | 兩個 codec 泛型 override 編譯錯誤，退出 1；未執行探針 | [命令](compile-02.json)、[log](compile-02.log)、[修正前探針](T010Probe-attempt-02.java.txt) |
| 03 經允許沙箱外離線 | 修正查證工具後 BUILD SUCCESSFUL in 7s，退出 0 | [命令](compile-03.json)、[log](compile-03.log)、[class 指紋](compiled-classes.json) |

`--release 21 -Xlint:deprecation -Werror`。任務圖只有 createMinecraftArtifacts（UP-TO-DATE）、compileT010Probe（執行）；沒有 build／jar／runClient／runServer／GameTest／runData。Java 無編譯錯誤或 deprecation 警告；Gradle 有未來 Gradle 10 相容性的 deprecation 提示，不宣稱零警告。5 個 class（major 65）作為編譯證據保存，未載入／實例化；沒有功能單元測試或回呼觀察結果。

## 完成條件與後續審查

兩共用基底及所有互動類別均有 A01–A16 指定來源／可編譯候選；11 方塊完整值域、client/server 路徑與舊行為差異已明列。R-01 只審來源／簽名／邏輯／案例覆蓋，不啟動遊戲。本項不修改產品來源／Gradle／資源，D1–D8 不變；人工驗收依 TASK.md 由使用者執行。

官方輔助：[1.21.1 Blocks](https://docs.neoforged.net/docs/1.21.1/blocks/)、[Blockstates](https://docs.neoforged.net/docs/1.21.1/blocks/states/)（2026-09-27 查閱，標示 1.21–1.21.1）。互動文件網址本次開啟失敗，不用該失敗結果作依據；實際互動管線以 manifest 的 21.1.251 本機來源為準。
