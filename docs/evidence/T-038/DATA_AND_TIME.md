# T-038 計時軌道契約與 NEW 資料格式

目標為 Minecraft 1.21.1、NeoForge 21.1.251、Simple Rail 1.0.0。這是已編譯的程式設計與非遊戲驗證；正式遊戲保存、卸載、計時誤差與停車放行仍待使用者 T-040／T-083 驗收。OLD 行為只依原始碼推定／待確認。

| 範圍 | T-038 實作 | 來源／保留限制 |
| --- | --- | --- |
| ID | 方塊／物品 `simplerail:timer_holding_rail` 不變；新增同名 BLOCK_ENTITY_TYPE，分屬 registry | D2；OLD `TileEntities.TIMER_HOLDING_RAIL`；[ModBlockEntities.java](../../../src/main/java/com/ericchiu/simplerail/registry/ModBlockEntities.java) |
| 等級與方向 | `level` 0–9，`direction` 六向，預設 level=0／NEW `Direction.DOWN`；`shape`／`powered` 沿用 BasePoweredRail，禁止坡形仍沿既有基底規則 | 進入新等待時以礦車 `getMotionDirection()` 記方向；既有 U-08／U-09 及扳手複合覆寫意圖仍待確認；不在本任務改扳手 |
| 配置 | level=0 不建立等待，保留原 1.2 移速分支；level=1–9 在**新礦車**開始等待時讀一次 `CommonConfig.current().holdingWaitSeconds(level)` 的伺服器快照 | T-020 正式設定預設 5／10／15／20／25／30／40／50／60 秒，範圍 0..2147483647；設定 reload 只影響後來的新等待，活動中的剩餘時間不重算 |
| 礦車邏輯 | 新 UUID：記當前方向、停止並置於方塊位置、開始實際時間等待；同 UUID 未到期：持續停止；到期：依記錄方向 0.4 放行，保留已到期 UUID 以防重新開始；下一個 UUID 另起等待 | OLD TimerHoldingRail.java 的分支順序與倍率。因基底仍繼承 powered rail，父類移動／供電效果須在 T-040 遊戲驗收 |
| 時間來源 | 伺服器 `System.nanoTime()`；開始／恢復時建立單一基準，讀值以經過奈秒換算剩餘毫秒；不用 tick 次數累積 | 以 `(long)seconds * 1000L` 覆蓋設定上限，避免 I-037-03 的 int 溢位；JVM 測試含最大值與千次半毫秒讀取 |
| 保存／讀回 | 保存時計算當刻剩餘毫秒，序列化不重設活動計時；固定版 ChunkEvent.Unload 在 save 前呼叫暫停並直接將事件 chunk 標 unsaved；新資料讀回保持暫停，首個伺服器 tick／同車過軌才恢復 | 對應 I-037-02／04／05。每個活動 tick 剩餘變化時 `Level.blockEntityChanged(pos)` 標記待存，不發每 tick 鄰居更新；新 UUID 用 `setChanged()`。實際 IO 與 unload/stop 次序需 T-040／083 使用者觀察。沒有新增車頭票證或改 D3 |
| 客戶端 | 軌道效果／計時只在邏輯伺服器處理，方塊狀態的 level／direction 同步沿原生 block state；計時 BE 本身沒有 GUI、亦未設同步封包 | T-038 不簽署多人／渲染同步；後續 T-040／T-050／T-052 檢查 |

NEW 方塊實體 NBT 路徑固定為 `holding_timer` compound：`version` 為 int `1`；有活躍或已到期的礦車時，`cart_uuid` 為四 int UUID tag，`remaining_ms` 為 long，合法範圍 `0..2147483647000`。沒有礦車時只寫 `version=1`。`remaining_ms=0` 加 UUID 意味該車已到期，再次過軌可放行；不能將 UUID 丟掉並重置等待。缺版本、缺鍵、錯型、未知版本、負值或超過上限的資料讀回為 idle，避免例外。`level`、`direction` 是方塊狀態，隨 NEW 世界原生方塊狀態存讀；沒有把 OLD `save_time`／`go_time` 視為新版格式，**不做舊世界或舊 NBT 轉換**。

已有 `assets/simplerail/blockstates/timer_holding_rail.json` 按 `level=0..9` 與兩個水平 `shape` 共 20 個選擇子；`powered`／`direction`／`waterlogged` 在該資源的條件中省略，維持原資源的共用外觀策略。BasePoweredRail 不允許坡形，所以本任務未增斜坡模型，符合先前僅高速軌道成坡的決策。資源本輪未修改，實際 baking／外觀由使用者後續驗收；I-021-01／I-092-02 的其他方塊缺口仍留追蹤。

剩餘毫秒序列化捨去不足 1 ms；世界活動受伺服器 tick 與停車回呼排程影響。「剩餘約 3 秒時卸載／關服、讀回仍約需 3 秒」的正式量測點與容許誤差依 T-004 M-01 **待技術定義**，不可把本項 JVM 精度當作遊戲驗收。若使用者發現保存、方向、powered rail 繼承行為或資源顯示差異，依 T-039／T-040 條件式處理。

**T-040 扳手換級的具體待決：** 現行 [Wrench.java](../../../src/main/java/com/ericchiu/simplerail/item/Wrench.java) 從同一個初始 state 先寫 cycleLevel，再寫 rotate(direction)。計時軌道曾有水平記錄方向時，rotate 會用原 level 覆蓋剛換級的值；方向為 UP／DOWN 時 rotate 不生效，才不會覆蓋。這是既有 U-09 複合覆寫原碼事實，未經使用者決定不在 T-038 改成順序累積寫入。T-040 的「扳手換級」分項因此須先處理 U-09 或取得明確驗收期望；不阻擋本項計時與資料實作。
