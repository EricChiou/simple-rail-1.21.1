# T-003 舊版行為參考與未確認差異

執行日期：2026-09-26（Asia/Taipei）。OLD：`D:/workspace/java/simple-rail`，HEAD `6698b1c5f494095a15b055c10045293e91540012`；NEW：`D:/workspace/java/simple-rail-1.21.1`，HEAD `8bd977dbb9f9000411ae5f4d10750228e5f33560`。開始時 OLD 工作樹乾淨，NEW 三份規劃文件已暫存新增，另有未追蹤 docs；不重設使用者變更。

**本次只完成來源分析，不是舊版實測基線。所有下列舊行為均為「依原始碼推定／待確認」。** 靜態檔案、宣告與分支已閱讀；舊 client／server、既有 JAR 行為觀察均未執行，相關 log／JAR 雜湊未取得。本次未嘗試尋找或啟動舊 JAR。OLD build 由使用者先前驗證，本次流程不重跑。

J = OLD/src/main/java/ericchiu/simplerail；R = OLD/src/main/resources。表內 Java 路徑均相對 J，冒號後為本次來源行號。原始讀取輸出與命令見 [commands.json](commands.json)，192 個追蹤來源／建置檔指紋、完整配方及 tag／loot 內容見 [source-inventory.json](source-inventory.json)。NEW API 未在本任務查證。

## 行為參考表

每列 B 編號供 T-004 引用。來源推定不能代替實測；D1–D8 已定需求優先於舊疑點，尤其 D3／D4／D5。

| 參考 | 功能 | 原始碼位置／符號範圍 | 原始碼可見分支與推定預期（均未實測） | 後續任務 | 未確認差異 |
| --- | --- | --- | --- | --- | --- |
| B-01 | 入口／生命週期／COMMON 設定 | SimpleRail.java:42–55,63–74,94–101；setup/Registration.java:13–16 | 入口註冊三個 DeferredRegister；兩種 BE 另經 registry event；client render setup；EnteringChunk；IMC 僅送自己 | T-008、T-017、T-018 | 事件與 client 隔離待 NEW API 查證 |
| B-02 | 11 方塊／13 物品／分頁 | registry/Blocks.java:29–52；registry/Items.java:21–49；constants/I18n.java:5–27；itemgroup/Rail.java:10–14 | 9 軌道＋2 機器及同名 BlockItem；wrench、locomotive_cart；分頁名稱 simplerail.tab、圖示 high_speed_rail | T-019、T-023、T-081 | D2 保留 ID；NEW 創造分頁註冊方式待查證 |
| B-03 | 狀態／標籤／設定 | setup/SimpleRailProperties.java:11–16；setup/SimpleRailTags.java:12–18；config/CommonConfig.java:52–149 | reverse/need_power/use_power 為 boolean，level 0–9，direction 未限水平；rails/machines block tag；wrench 程式宣告 block tag 但檔案在 items | T-004、T-008、T-009、T-020、T-081 | 繼承狀態預設、tag 用途及設定重載待確認；不新增虛構 registry |
| B-04 | 共用 rail／high_speed_rail | block/base/BaseRail.java:18–39；block/base/BasePoweredRail.java:18–40；block/HighSpeedRail.java:5–9 | 兩基底都回傳 maxSpeed，canMakeSlopes=false、canEntityDestroy=false；高速軌僅繼承 PoweredRail 基底 | T-025、T-026 | 設定值不是實測速度；父類加速／供電及禁坡效果待 NEW 驗收 |
| B-05 | holding_rail | block/HoldingRail.java:24–62 | 未供電：記錄非零運動方向，速度歸零並 moveTo(pos)；updateState 見 powered=true 時，方塊 AABB 內所有礦車沿 direction×0.4 放行，然後呼叫父類 | T-027、T-028 | updateState 新舊 powered 時序、中心精確座標及多人效果待確認 |
| B-06 | oneway_rail | block/OnewayRail.java:23–84 | 啟用條件 usePowerChangeDirection OR powered OR !needPower；reverse=true 時 NS→+Z、EW→−X；false 時 NS→−Z、EW→+X，幅度0.4；未啟用且運動非零則乘1.2 | T-029、T-030 | usePowerChangeDirection 分支只令作用啟用，未直接按電力翻轉；與註解意圖差異 U-07 |
| B-07 | eject_rail | block/EjectRail.java:41–82 | server-only；needPower 且無電則返回；逐乘客 eject/速度歸零。NS: x=pos.x±(距離+0.5),z=pos.z+0.5；EW: z=pos.z±(距離+0.5),x=pos.x+0.5；reverse 控正負，y=pos.y | T-031、T-032 | 與來車方向無直接分支；障礙位置與多乘客副作用待確認，不自行新增安全傳送政策 |
| B-08 | destory_rail | block/DestoryRail.java:37–51；entity/LocomotiveCartEntity.java:236–245 | !needPower 或 powered 時，普通礦車 remove；車頭 deleteTrain 移除已持有車廂與車頭；加入煙及聲音 | T-033、T-034、T-061、T-062 | 父類移除的乘客／容器掉落及執行端待查證；不改 destory 拼字、不默改票證釋放 |
| B-09 | timer_holding_rail | block/TimerHoldingRail.java:37–40,51–118,139–148 | server-only；level0或缺 BE 時非零運動乘1.2；首次車 UUID 記方向、停止並設定現在時間+等級秒數×1000；同車達 goTime 方向×0.4 放行；else 停止 | T-011、T-037–T-040 | 紅石不直接控制此回呼的計時分支；父類作用待查；兩次 defaultState 設定與 int 乘法風險 U-04/U-08 |
| B-10 | 計時 BE 與資料 | tileentity/TimerHoldingRailTileEntity.java:12–17,28–52 | save_time 為現在毫秒；cart_uuid/go_time 可缺寫；load 無先檢查 UUID，go_time 加上 current−save_time；setter 未顯式 setChanged | T-037、T-039、T-040、T-083 | D5 保留實際秒數＋讀回補償且暫停離線／卸載；缺鍵後果、保存點到卸載的差值仍待測 |
| B-11 | signal_timer／BE | block/SignalTimerBlock.java:32–75；tileentity/SignalTimerTileEntity.java:19–82；constants/Config.java:33–34 | 0級輸出0；level>0且powered輸出15；BE每tick請求 level秒×20−10 tick 排程；block tick 開關 powered，開啟時另排10tick關閉；沒有自訂 NBT | T-011、T-041、T-042、T-083 | 實際週期由排程去重／載入生命週期共同決定；不能把呼叫式當量測相位 |
| B-12 | 27 格樣板與箱子 GUI | block/TrainDispenserBlock.java:39–41,98–126 | OLD 使用 ChestTileEntity，server use 開箱子 menu；onPlace 將非水平朝向改 NORTH | T-012、T-044、T-047、T-082 | D4 NEW 改專用 BE，保持27格不消耗與箱子 GUI；繼承 triggered/facing 預設及自訂名称責任待查 |
| B-13 | 發射位置／觸發／原版車種 | block/TrainDispenserBlock.java:52–95,129–165 | 有電的 server neighborChanged 每次遍歷0–26；不扣槽物品，空格不生成但仍檢查占位；任一位置有礦車就 break。E:(x+1.5,y,z+i+0.5), W:(x−0.5,y,z−i+0.5), N:(x+i+0.5,y,z−0.5), S:(x−i+0.5,y,z+1.5)；chest/furnace/hopper/tnt字串特判，其餘 MinecartItem 走普通車 | T-043、T-045–T-047 | 無顯式去抖，實際鄰居回呼頻率待確認；command_block_minecart 若符合 MinecartItem 也可能走 default，不猜父類 |
| B-14 | 發射器整列連結 | block/TrainDispenserBlock.java:61–93 | 僅第0格生成車頭時保存為連結目標；收集普通 MinecartItem 產生的車廂，最後依槽位遍歷順序 link；其他格車頭生成但未加入 trainCars | T-059、T-060 | 多車頭、空格、阻擋與名稱／資料複製的玩法待確認；D4 不消耗不等於將所有 ItemStack 資料複製給車輛 |
| B-15 | 扳手／連結入口 | item/Wrench.java:32–80,83–183 | stack1、防火；server側取得點擊格及側向相鄰格礦車，找已登錄車頭／所屬車頭後 link；點擊格無車且為rails才改 reverse/level/direction；machines 改facing/level；level9→0，水平N→E→S→W→N | T-035、T-036、T-057、T-058 | 點擊小數=0.5時第二格不偏移；多屬性以同一舊state逐次寫入可能覆寫，尤其計時軌 level+direction，列 U-09 |
| B-16 | 車頭物品放置／命名 | item/LocomotiveCart.java:20–60 | stack64、防火、UNCOMMON；非兩種rails tag失敗；合法點擊先 shrink1再client早退，server於中心x/z、y+0.0625（坡加0.5）生成；由 shrink後 stack讀名稱 | T-013、T-051、T-052、T-063 | 最後1個命名物品與雙端消耗的實際結果待驗；不把發射器不消耗延伸到手持物品 |
| B-17 | 車頭實體／碰撞／掉落 | entity/LocomotiveCartEntity.java:40–47,75–111,140–145,199–215,288–290；registry/Entities.java:18–24 | 繼承FurnaceMinecart；自稱FURNACE但isPoweredCart=false；destroy按doEntityDrops掉自身物品保留名再移除索引／實體；push僅對玩家呼父類；canCollideWith玩家false、車頭父類、其他礦車被設同速度、運動時其他活體kill | T-048、T-052、T-062 | 碰撞規則沿原碼查證，不憑名稱推定蒸汽車／燃料功能；父類動力、掉落與觸发端待確認 |
| B-18 | 編組次序與跟車 | entity/LocomotiveCartEntity.java:115–138,222–245,297–366；link/LinkageManager.java:13–73 | static 車頭UUID→有序車廂UUID；initTrain 只納入當時查到車廂再覆寫；跨格更新 stopPos，isOnGround可清空，缺車可截斷後綴；車廂 moveTo(stopPos+0.5x/z)並速度歸零 | T-053–T-056、T-082、T-084 | 晚載入／跨維度清理／prevPos與stopPos恢復 U-01；來源不是已驗證可靠復原 |
| B-19 | 實體保存／同步／生成 | entity/LocomotiveCartEntity.java:68–92,148–197,259–285；setup/SimpleRailDataSerializers.java:10–50 | Train UUID字串list、Facing八向字串，呼父類存讀；FACING enum序列化，LINKABLE預設true；生成packet與client factory；FACING在tick更新 | T-013、T-014、T-049、T-052、T-065 | LINKABLE在所讀來源只見define，未見其他讀寫；NEW必需欄位/封包/儲存方式待API任務，不要求舊NBT |
| B-20 | cross_rail | block/CrossRail.java:22–88 | 依方塊座標暫存UUID、max(abs(vx),abs(vz))、進入方向、鄰格目的地與旋轉；新車先停並改shape，下次移目的格恢復速度；destroy/removedByPlayer移除該座標 | T-066、T-067、T-072–T-074 | 不同維度同座標、同時兩車、卸載重啟暫存 U-03 |
| B-21 | y_cross_rail | block/YCrossRail.java:30–111,114–244 | 同十字兩段過車，方向由來車方向×DIRECTION×powered分支選擇；onPlace/updateState读取鄰居電源；兩種破壞路徑移除暫存 | T-068、T-069、T-072–T-074 | 完整32組方向表需獨立比對，不能憑左轉名稱簡化；見 route-reference.md |
| B-22 | y_cross_right_rail | block/YCrossRightRail.java:30–111,114–244 | 獨立getDestDirection分支表，其餘暫存與兩段回呼類似左Y | T-070、T-071、T-072–T-074 | 不假設完整鏡射；見 route-reference.md；執行時序待確認 |
| B-23 | 區塊載入 | event/ChunkEventManager.java:19–50；SimpleRail.java:99–101 | true啟用；server車頭進區塊事件，位置>>4取中心；radius2的雙迴圈反覆以相同中心和true,true呼叫forceChunk；原碼無明確解除 | T-016、T-075–T-080 | D3沿用原邏輯；25次呼叫不等於25票證或5×5載入，owner/tick/重啟後果待NEW觀察 |
| B-24 | 渲染／模型／材質 | setup/Render.java:13–27；render/LocomotiveCartRender.java:99–123；render/model/LocomotiveCartModel.java:20–55；constants/Texture.java | 9軌cutout；車頭renderer依八向設Y角：E180,W0,N−90,S90,NE−135,NW−45,SE135,SW45；模型96×64並有六個子部件及本地UV；textures/entity/locomotive_cart.png | T-015、T-021、T-050、T-052 | NEW模型接線及UV待查證，不能以编譯代替視覺驗收 |
| B-25 | 配方／掉落／資料與語系 | R/data/**；R/assets/simplerail/**；R/pack.mcmeta；source-inventory.json | 13 shaped配方，destory產3其餘1；11方塊loot加額外blocks/locomotive_cart entity型別loot；4 tags；12 blockstate、40 blockmodel、14 itemmodel、44貼圖、2語系，pack6與根logo | T-009、T-021–T-024、T-081 | 額外wrench blockstate/oneway_reverse itemmodel不增registry；額外loot與Java掉落責任 U-11；NEW目錄/格式待查證 |

## 六疑點及其他局部待確認事項

以下均為待調查，沒有一項被本任務宣告「已重現」或「已修復」。確認問題後才進對應修正；沒有 OLD 執行紀錄不阻擋 NEW API、建置或可獨立驗收分支。

| 編號 | 對應需求／疑點 | 來源證據 | 必須釐清的個案 | 負責查證／回歸任務 |
| --- | --- | --- | --- | --- |
| U-01 | §4.3(1) 編組載入 | B-18／B-19：initTrain丟棄查不到UUID；checkCartLinkable按目前ServerWorld清理全域map；缺車截斷後綴；暫存無獨立保存 | 晚載入能否導致編組遺失、跨維度互相清理；NEW恢復次序與未載入判定 | T-013、T-054→T-055→T-056；T-082、T-084 |
| U-02 | §4.3(2) 票證 | B-23：重複中心、true啟用、無明確解除 | 實際載入集合與持續tick／重啟；D3等價對照；政策改動須另具體決策 | T-016、T-075→T-076/T-077；T-078→T-079→T-080 |
| U-03 | §4.3(3) 路口 | B-20–B-22：Map只用BlockPos；有破壞移除但未見世界卸載清理 | 同座標不同世界／維度、兩车輪流覆寫、中途存讀與暫存過期 | T-072→T-073→T-074；T-084 |
| U-04 | §4.3(4) 計時保存 | B-09／B-10：可缺寫鍵但無UUID存在檢查、setter未標髒、int乘法 | 實際保存可靠性與缺鍵後果；大秒數溢位；剩餘3秒兩路徑測試方法 | T-011、T-037→T-039→T-040；T-083 |
| U-05 | §4.3(5) 發射器 | B-13／B-14：每有電鄰居更新生成；toString車種；占位break | 實際觸發次數、空格仍占位中止、多車頭連結及字串辨識；D4不消耗非bug | T-043→T-046→T-047；T-060 |
| U-06 | §4.3(6) 端權責 | B-05／B-06／B-08／B-19等回呼未全顯式判端 | OLD父類回呼在哪端未實測；NEW雙client是否重複生成/刪除/連結/扣物 | T-010、T-014、T-063→T-064→T-065；T-084 |
| U-07 | 單向軌設定與重載 | B-06；CommonConfig:81–83；計時兩類static final讀設定 | usePowerChangeDirection註解與實作意圖；onPlace只向父類傳新state的落盤；設定載入/重載是否生效 | T-008、T-020、T-029、T-030、T-041、T-042 |
| U-08 | 狀態預設與相位 | B-09重複defaultState；B-11每tick排程；direction enum含UP/DOWN | 計時軌最終direction預設、繼承shape/powered/facing/triggered值；訊號重啟相位與去重 | T-010、T-011、T-019、T-036、T-040、T-042 |
| U-09 | 扳手複合屬性 | B-15：changeLevel後仍以原state呼changeDirection | 計時軌點擊是否覆蓋升級；各屬性操作的期望優先序須調查，不能靜默改玩法 | T-035、T-036、T-038、T-040；若需修正超出範圍再列D6具體項 |
| U-10 | 車頭放置／碰撞／刪車 | B-16／B-17／B-08：shrink後讀名；父類碰撞與remove | 最後一個命名物品、創造/生存扣量、父類燃料互動、乘客與容器掉落；碰撞活體分支實際效果 | T-013、T-048、T-051、T-052、T-062、T-063 |
| U-11 | 資源及未使用宣告 | B-03／B-25；WorldData.java；LINKABLE只define | wrench tag型別引用、額外loot、額外模型用途；WorldData歷史名稱不等於.dat；LINKABLE目標責任 | T-009、T-014、T-021–T-024、T-048、T-049、T-081 |
| U-12 | 量測門檻／NEW機制 | 全部功能尚未遊戲實測 | 時間容許誤差、速度量測與效能門檻、同步觀測窗口、NEW API具體格式／生命週期 | T-004、T-008–T-016、T-026、T-040、T-065、T-083、T-087 |

## 決策、推定與實測的界線

- 已定需求：D1 不做舊世界／NBT／票證轉換；D2 保留全部 ID；D3 啟用並保持原呼叫邏輯；D4 專用 BE、箱子 GUI、27格生成不消耗；D5 實際秒數＋讀回補償且離線／卸載暫停；D6 疑點確認後修正；D7 無外部模組；D8 1.0.0／All Rights Reserved／NeoForge 21.1.251。
- 舊來源不能保證 D5 實際保存點與卸載點完全一致。NEW 應量測活動時間及補償；缺鍵／未標髒等不能照抄為既定產品要求。
- 所有 OLD 遊戲結果均未取得；本報告沒有把建置成功當作舊功能已通過。T-005 的 NEW 框架 build 證據另存其目錄。
- 世界生成、自訂配方 serializer、外部模組整合未見本次需求；不因盤點而新增功能或API名稱。

## 完成條件逐項判定

| T-003 條件 | 本次交付與判定 |
| --- | --- |
| 指南 §3 全部功能有來源或缺口 | B-01–B-25 覆蓋入口、註冊、11方塊、13物品、BE／GUI、實體／編組、同步／渲染、區塊、配方／資源；原始檔與指紋可追溯 |
| 六疑點有分項差異及責任任務 | U-01–U-06 與後續調查→修正→回歸鏈；U-07–U-12 補充局部未決事項 |
| 未實測明確標記 | 全部舊行為為「依原始碼推定／待確認」，未提供假造 OLD 實測資料 |
| 不為參考重建 OLD | 未執行 OLD Wrapper／build；僅讀取 OLD |
| 交付可供案例設計使用 | 固定 B／U 編號、方向對照、來源清冊交由 T-004 建立案例；資料整理完成不等於行為驗收 |

據上述交付，T-003 可標 **已完成（來源參考整理）**；不關閉 U 項目，也不提前完成六個疑點調查任務。

