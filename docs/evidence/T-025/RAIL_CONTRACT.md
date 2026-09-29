# T-025 軌道基底與高速軌道對照

日期：2026-09-28。對應 MIGRATION.md §3 共用基底／high_speed_rail、§6 階段 3；TASK.md T-025。OLD 沒有在本輪實測，以下舊行為均為**依原始碼推定／待確認**。NEW 表格只描述已編譯實作與指定版來源，不宣稱遊戲驗收通過。

OLD 相對路徑根為 D:/workspace/java/simple-rail/src/main/java/ericchiu/simplerail/；NEW 為 src/main/java/com/ericchiu/simplerail/。[13 個固定來源及 SHA-256](source-references.json)包含三個 OLD 原檔及 Minecraft 1.21.1＋NeoForge 21.1.251 合併來源；亦參照 [T-010](../T-010/README.md)與 [T-020 設定契約](../T-020/config-contract.md)。

| 規則 | OLD 來源與推定 | NEW 交付／指定版依據 | 證據範圍與後續 |
| --- | --- | --- | --- |
| 一般基底 | block/base/BaseRail.java 繼承 RailBlock，未覆寫 flexible／shape domain | NEW 同名類繼承 RailBlock，保留父類彎軌、連接、預設、waterlogged | 編譯／bytecode；目前不新增此基底的方塊 ID，後續路口仍依自身需求實作 |
| 動力基底 | block/base/BasePoweredRail.java 呼叫 PoweredRailBlock(properties, true) | NEW 同名類保留 true，固定來源確認為動力軌而非 activator | build／bytecode；加速、未供電制動、紅石傳遞留給父類，實際效果待 T-026 |
| 高速軌道 | block/HighSpeedRail.java 只有繼承與建構，無其他政策 | NEW HighSpeedRail 繼承 BasePoweredRail；ModBlocks 延遲工廠，方塊／BlockItem ID 不變 | 其他十個方塊註冊不改；既有 BlockItem supplier 不需重寫 |
| 共用速度 | 兩 OLD 基底都讀 highSpeedRailMaxSpeed.floatValue() | 兩 NEW 基底每次 getRailMaxSpeed(BlockState, Level, BlockPos, AbstractMinecart) 只取一次 CommonConfig.current() 快照，將 railMaxSpeed double 轉 float | 無靜態速度快取、無建構／註冊時讀設定；沿用 T-020 預設 0.8／包含上下界 0.4–2.0，不宣稱 FML reload 已實測 |
| 實際速度與執行端 | OLD 實際速度未測 | AbstractMinecart.tick 的 server 分支進 moveAlongTrack；getMaxSpeedWithRail 取 rail hook 與車輛 cap 較小值，另受供電、摩擦、乘客、水等父類條件影響 | 不覆寫礦車運動，不新增 client 設定同步。hook 查詢程序本地快照；vanilla 移動由 logical server 決定。配置值不等於實際速度，T-026／T-094 先定量測／容差後由使用者測 |
| 禁坡 | 兩 OLD 基底 canMakeSlopes 均 false | NEW BlockGetter 簽名回 false；RailState 成坡分支檢查此值 | 禁止自動成坡，不刪 ascending 合法值，不追加 isFlexibleRail=false／isValidRailShape 限制。正常放置及鄰居更新待 T-026 |
| 實體破壞 | 兩 OLD 基底 canEntityDestroy 均 false | NEW BlockGetter hook 回 false | 僅拒絕實體破壞 hook，不宣稱玩家、爆炸、指令或移除支撐都不能破壞；實際事件與掉落交 T-026／T-024 |
| 方塊與工具屬性 | noCollission、strength(0.7F)、SoundType.METAL、harvestTool(PICKAXE) | 延用 railProperties；新增 data/minecraft/tags/block/mineable/pickaxe.json，replace=false，只加 high_speed_rail；PickaxeItem／DiggerItem 固定來源確認分類路徑 | 既有 minecraft:rails 九成員不改，不取代 vanilla 成員，不新增 requiresCorrectToolForDrops／採掘等級。其他軌道於自身實作承接工具分類，挖掘／掉落待人工測 |
| codec | OLD 無 1.21.1 MapCodec 契約 | 三類各有 simpleCodec(自身建構子)，回傳泛型遵循 RailBlock／PoweredRailBlock 父類 | build／javap constructor handle 確認，高速 codec 不退化成共用父類；未執行 codec 或新增 BLOCK_TYPE registry ID，載入／資料往返待後續驗證 |
| 狀態與預設 | OLD 高速沿用 PoweredRailBlock，無額外屬性 | 父類 shape／powered／waterlogged，預設 north_south／false／false；straight shape 兩平軌＋四升坡，其餘各兩值 | 24 個宣告組合源自固定來源，未初始化 Minecraft stateDefinition。既有 JSON 匹配 8 個平軌組合，16 個升坡組合未覆蓋 |

## 整合限制與人工交接

- **I-021-01 未解除。** 高速正式繼承狀態補上其 JSON selector 所需屬性，但父類仍宣告升坡域，既有 JSON 無升坡模型；其他方塊狀態／模型問題亦保留。未改 JSON、刪域、猜測升坡外觀或把禁坡當完整模型覆蓋。這是來源推論，不是已重現的遊戲 log；T-092／T-023 全量可操作包仍受阻。
- **I-092-02 未整體解除。** 已有速度消費者可供後續 T-026 觀察，但本輪未交付全部 25 設定的有效快照／重載觀測方案；T-092 草稿不能直接解鎖。server／client 不同設定與 reload 生效未測。
- **R-03 待審；人工未執行。** 審查者核對自身 codec、動力 true、一次快照、繼承域與資源缺口，不啟動 Minecraft。T-094 另製作 T-026 固定包：四方向、供電、原版銜接、速度三點、禁坡、實體破壞及後續 cutout；量測誤差待技術定義。本輪不填結果或執行這些任務。
- D1–D8 不變：不做舊世界／NBT 轉換，不更名 destory_rail，不動票證、計時、27 格發射器、外部整合或 D8；未修六項舊疑點。

## T-025 自身完成判定

兩種基底／高速工廠已實作，三個 hook 簽名與繼承狀態可追溯；[NEW build](build-01.json)退出 0，[40 項非遊戲靜態核對](audit-results-01.json)通過，差異、JAR、來源／指紋保存。只更新 T-025 為「開發完成」，不把模型缺口、審查、速度量測或其他軌道宣稱完成。
