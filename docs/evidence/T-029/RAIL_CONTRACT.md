# T-029 單向軌道來源、設定／狀態與未確認差異

日期：2026-09-29。OLD 均 **依原始碼推定／待確認**，未重跑 OLD build／遊戲。[來源指紋](source-manifest.json)保存 OnewayRail、設定／屬性原檔與固定 Minecraft 1.21.1／NeoForge 21.1.251 來源。本次只實作可追溯的原碼分支，不宣稱已釐清 U-07 的產品意圖或全部 API。

## 原码分支及方向表

啟用条件為當前設定 usePowerChangeDirection OR 方塊 powered OR NOT 當前設定 needPower。僅 needPower=true、usePowerChangeDirection=false、powered=false 時未啟用；運動非零則完整 XYZ 向量乘 1.2，零向量保持零。不把這個乘數稱為實際加速：父類先有未供電制動、移動與摩擦。

| shape | reverse | 啟用時 hook 寫入的向量 | 方向 |
| --- | --- | --- | --- |
| north_south | false | (0,0,-0.4) | 北 |
| north_south | true | (0,0,+0.4) | 南 |
| east_west | false | (+0.4,0,0) | 東 |
| east_west | true | (-0.4,0,0) | 西 |

[32 組來源矩陣](behavior-matrix.json)列出 shape×reverse×powered×兩設定，遊戲結果全部 null；active branch 忽略來車方向，可從零向量啟動。與 OLD 一樣，其餘強制寫入的 shape 走非 NS 的 X 分支，不將其改成新斜坡玩法。共用禁坡保留，正常放置僅有 NS／EW。

## U-07：明列差異，尚未作產品語意決策

OLD 設定註解為「Use power to change oneway rail direction」，實際 [OnewayRail](sources/old/OnewayRail.java) 只讓規則無條件啟用；方向由 reverse 決定，沒有 powered XOR reverse。既有 use_power=true selector 在 powered=false／true 之間切換普通 powered／reverse powered model，忽略 reverse。來源可確認分支／模型差異，**使用者意圖、實際箭頭畫面／電力翻向期望仍待確認**。

本轮已提出選項釐清；截至交付未收到語意決策。先沿用原碼分支與原資源，不擅自按照名稱更改方向或修貼圖，這不是宣稱使用者已批准某個新需求。U-07 保留待確認；若之後決定紅石翻向，需先記錄 reverse／powered 的真值規則與資源一致性，再另版修改／複查／驗收。T-030 中依賴該意圖的案例不能直接推定通過。

## NEW 實作、指定 API 與保存範圍

| 項目 | 交付與依據 | 已知／未測界限 |
| --- | --- | --- |
| 註冊／codec | ModBlocks 同 oneway_rail factory 換 OnewayRail；MapCodec<PoweredRailBlock> 與 simpleCodec 建構工廠，真實 Gradle 編譯成功 | 不新增 oneway_reverse_rail ID，不改原 BlockItem、其他方塊／物品 |
| 屬性／預設 | 三 BooleanProperty：reverse、need_power、use_power；父類 defaultBlockState 上設 false／true／false；shape／powered／waterlogged 保留父類預設 | 建構與 static 欄位不讀未載入設定；[BooleanProperty](sources/target/net/minecraft/world/level/block/state/properties/BooleanProperty.java)、PoweredRailBlock／T-020 載入邊界為依據 |
| 放置投影 | 新方塊 server onPlace 讀一份 CommonConfig.current，套 need_power／use_power 再交父類 | [BaseRailBlock](sources/target/net/minecraft/world/level/block/BaseRailBlock.java) onPlace→updateState→updateDir→[RailState](sources/target/net/minecraft/world/level/block/RailState.java) place(alwaysPlace=true) 使用傳入 state 並 setBlock(...,3)，來源可確認落盤管線，不虛構遊戲保存結果 |
| 同方塊更新／重載 | same block onPlace 不讀設定／不重新投影，reverse／其他狀態保持；每次 server 過車讀當前完整快照一次 | OLD 行為也直接讀全域兩設定。重載既有軌道可改規則，既有 need_power／use_power 仍是舊投影，模型可能與規則不同；不自動改寫世界、不建索引／tick掃描器。T-030／T-096 必須測該差異 |
| 過車／父類 | server guard，啟用依上表寫 0.4 向量；未啟用非零乘 1.2；共用速度／禁坡／實體破壞與 powered true 繼承 | [AbstractMinecart](sources/target/net/minecraft/world/entity/vehicle/AbstractMinecart.java) 先制動／移動／摩擦再 onMinecartPass，之後仍有供電加速；0.4 是 hook 向量，不是最終 tick 速度或位移。實際車速、接口及來車方向由使用者驗 |
| client／同步／保存 | client 不讀本類設定或修改車速；放置投影僅 server，父類 client 路徑仍保留；使用 blockstate 及既有礦車同步 | COMMON 每程序本地，不自動同步；多人真正行為採 server 值。無 BE／NBT／自訂 packet／外部模組／旧世界轉換，真實畫面、同步、新世界存讀仍待後續人工任務 |
| 工具與資源 | pickaxe tag 僅追加 oneway_rail；原 16 selector、模型／貼圖／配方／掉落不改 | 舊 BasePoweredRail 的 pickaxe 分類接續，未加 requiresCorrectToolForDrops；不暗改 U-07 模型 |

## 狀態／測試覆蓋

宣告 shape 6×reverse 2×need_power 2×use_power 2×powered 2×waterlogged 2，共 192。正常平軌 64 組各符合一個原 selector；128 升坡值域组合非自然放置、原資源未覆蓋。[完整狀態／selector 表](state-coverage.json)不等於模型 baking／畫面通過；I-021-01 其他缺口／T-092 不整體解除。

隔離測試將 **實際 OnewayRail 產品原始碼** 配 18 個測試替身另編譯，不載入真實 Minecraft／ConfigSpec。3,097 判定涵蓋 32 分支列×四種互相矛盾的 stored flags×六種向量（四水平、零、含 Y），驗當前快照／四方向／未啟用全軸乘數／零值／無位置與世界修改；另驗未載入建構、四組放置投影、同方塊不改投影、快照重載立即生效、client 不讀未載入設定。

替身父類模擬一次写入，不能證實真正 RailState／紅石／重入、registry／saving、ConfigSpec 監看事件、影像或多人結果。真實 API 編譯与固定父類來源另列，不能用隔離結果冒充 runtime。沒有執行 T-030／T-096 或其餘六疑點修正。

## T-030／T-096 後續輸入

C-009 的兩軌向×四來車×reverse×powered×needPower×usePowerChangeDirection 全矩陣保留，先用上表分支期望，U-07 意圖部分待確認。包須提供目前設定與 stored state 相異的重載／存讀場景、同方塊 reverse 操作、新放置投影、未啟用 ZERO／非零、空軌／有車、單人／dedicated server 与設定三點／原版接口。區分 hook 後向量與最終位移，不用配置值宣稱實測速度。T-096 製作完整包、R-03 審程式／覆蓋、使用者 T-030 實測；本項不開始或代填結果。
