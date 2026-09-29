# T-020 正式設定、載入與重載契約

2026-09-28。產品使用 COMMON，明訂 NEW 檔名 `config/simplerail-common.toml`（由 FML 管理的 config 目錄）；OLD 檔名未實測，不宣稱檔案相容，也不加入舊設定轉換器。OLD 行為均為**依原始碼推定／待確認**。

## 全部鍵、預設及範圍

依據 OLD `CommonConfig.java`／`constants/Config.java`，25 個設定鍵全數保留。`signal_timer_block` 群組仍位於 `rail` 下；`destory_rail` 與 `disableLoadingChunk` 不改名。秒數允許含 0 的 0–2147483647；不是任意 long，也不縮減舊上限。

| 路徑 | 預設 | 值域／單位 |
| --- | --- | --- |
| `cart.locomotive.disableLoadingChunk` | true | boolean；**true＝啟用**，沿用舊碼語意，D3 基線保持啟用 |
| `rail.high_speed_rail.maxSpeed` | 0.8 | double，0.4–2.0（含端點）；是 rail speed 上限設定，非實測速度 |
| `rail.oneway_rail.needPower` | true | boolean |
| `rail.oneway_rail.usePowerChangeDirection` | false | boolean；不從名字推定會自動切 reverse |
| `rail.eject_rail.transportDistance` | 3 | int，1–100（含端點） |
| `rail.eject_rail.needPower` | true | boolean |
| `rail.destory_rail.needPower` | false | boolean |
| `rail.timer_holding_rail.lv1` | 5 | int，0–2147483647 秒，實際時間 |
| `rail.timer_holding_rail.lv2` | 10 | 同上 |
| `rail.timer_holding_rail.lv3` | 15 | 同上 |
| `rail.timer_holding_rail.lv4` | 20 | 同上 |
| `rail.timer_holding_rail.lv5` | 25 | 同上 |
| `rail.timer_holding_rail.lv6` | 30 | 同上 |
| `rail.timer_holding_rail.lv7` | 40 | 同上 |
| `rail.timer_holding_rail.lv8` | 50 | 同上 |
| `rail.timer_holding_rail.lv9` | 60 | 同上 |
| `rail.signal_timer_block.lv1` | 5 | int，0–2147483647 秒，後續訊號排程換算用 |
| `rail.signal_timer_block.lv2` | 10 | 同上 |
| `rail.signal_timer_block.lv3` | 15 | 同上 |
| `rail.signal_timer_block.lv4` | 20 | 同上 |
| `rail.signal_timer_block.lv5` | 25 | 同上 |
| `rail.signal_timer_block.lv6` | 30 | 同上 |
| `rail.signal_timer_block.lv7` | 40 | 同上 |
| `rail.signal_timer_block.lv8` | 50 | 同上 |
| `rail.signal_timer_block.lv9` | 60 | 同上 |

[預設 TOML](simplerail-common.toml)由本項獨立 JVM 測試呼叫實際 ModConfigSpec.correct＋NightConfig TomlWriter 產出並讀回。這是 spec 產生的預設參考，不是 Minecraft／FML 啟動後生成的實測檔。

## 實作的載入邊界

1. common mod 入口注入 `IEventBus` 與 `ModContainer`；接 Loading／Reloading／Unloading 三個 mod bus handler，註冊 `ModConfig.Type.COMMON`／SPEC／固定檔名。使用 T-008 固定的 FML 4.0.44 介面。
2. 靜態初始化只建立 spec／ConfigValue；不在 registry 或建構子呼叫 ConfigValue.get／CommonConfig.current。載入前 `active` 為 null；提早讀 current／publish 會明確拒絕，不把預設冒充已載入值。
3. 事件必須同時符合 spec identity、COMMON type 與 mod ID。FML 原始碼 `ModConfig.setConfig` 先 acceptConfig，再在 config lock 下派發事件；Loading／Reloading handler 讀取全部 25 值，建立兩個不可變九等級 List 與一個 Snapshot，最後一次 volatile assignment 發布。使用者程式每次操作只取得一次 Snapshot，避免把兩版設定混用。
4. Reloading 不保證遊戲執行緒，handler 不存取 level／entity、寫方塊、排程 tick、增刪票證、改 deadline、開 GUI 或送網路封包。Unloading 清空 active；下次載入再發布，避免沿用失效快照。
5. COMMON 是每個程序的本地設定，不自動同步。單人 client／integrated server 共用同一程序；多人以 **logical server** 的快照決定行為。client 不用自己的設定替 server 決定速度、生成、計時或票證；正式 blockstate／實體同步交既有功能任務，不新增設定同步協議／SERVER config／外部整合。

獨立 JVM 測試實際執行 spec 校正／接受與產品 publication／clear path，未派發 FML 事件；事件過濾、入口注入及接線是來源／編譯／靜態核對，遊戲啟動與檔案監看／reload 執行緒實際效果仍待使用者測試。

## 後續消費者生效規則（尚未實作）

| 設定／需求 | 後續實作契約與限制 | 承接 |
| --- | --- | --- |
| 速度、單向啟用判斷、彈出距離／啟用、刪車啟用 | 下一次 server 回呼讀當次 Snapshot；OLD oneway／eject／destory 過車判斷直接讀 config，不擅改成以可能過時 state 作唯一依據 | T-025／T-029／T-031／T-033 |
| need_power／use_power 狀態投影 | registry default 不讀未載入 COMMON；使用固定 spec 預設作可建構 state。後續 server 新放置時取已載入快照投影；reload 不批次重寫既有方塊。OLD onPlace 傳新 state 給父類是否確實保存仍待對應功能驗收；已有 state 與配置可能不同，不能當已修復 | T-019 屬性表、T-029／T-031／T-033、T-023／T-030 |
| `disableLoadingChunk` | true 使用原版啟用分支；新快照供下一次既有區塊事件查詢。保留 boolean domain 不代表改 D3 基線。即使設定改 false，也不在 reload 新增解除既有票證政策或擴成 5×5 | T-076／T-077，疑點 T-075／T-078 |
| holding lv1–9 | `holdingWaitSeconds(level)` 回傳原始秒數；每次開始新等待取當次值，已進行等待不因 reload 重設 deadline／縮短或增加剩餘時間。D5 卸載／離線暫停與讀回補償保持；不改成 tick 計時 | T-037–T-040／T-083 |
| signal lv1–9 | `signalIntervalSeconds(level)` 回傳秒數；訊號排程另用 `SIGNAL_TICKS_PER_SECOND=20`、`SIGNAL_PULSE_TICKS=10`。下一次建立排程才取新值，不在 reload handler 刪改已排定 tick／相位 | T-041／T-042 |
| level=0、非法 level | spec 只有 lv1–9；快照 accessor 只接受 1–9。level=0 原有停用／不處理語意必須由各功能自行分支，不新增 lv0 設定 | T-037／T-041 |

上述為 T-020 的消費者交接契約，不宣稱骨架已接上功能。註冊 class 及所有 T-021 以後功能本輪不修改。已保留的 ID 不因設定文件而更名。

## 邊界與待技術驗證

- 非法型別及越界值由 NeoForge 21.1.251 的 ModConfigSpec 校正；指定來源的 numeric Range 是夾到合法上下界，錯型別回預設。不是 Agent 自訂轉換器。本項測試實際驗證上下界、拒絕超界及框架校正。
- 框架產生的最大 int 範圍註解顯示 `> 0`，但實際 validator 接受 0；本表及邊界測試的包含端點規格為準，不修改框架 formatter 或將此註解推為排除 0。
- 保留 int 最大秒數的合法值，不在此做 `int × 1000` 或 `int × 20`。後續 holding 毫秒換算與 signal 的 `秒×20−10`、負延遲、int 排程上限與很大值仍按 T-037／T-039／T-041 查證；本輪不提前修整計時演算法或虛構大值遊戲結果。
- 配置重載不影響已取得的快照，兩個 List 防禦複製；並發與 volatile 的設計可審，但本項沒有檔案監看、遊戲執行緒或多 client 的 runtime 測量。
- 所有檔案生成／新啟動、合法配置兩端差異、即時 reload 的實際生效與各功能需重做的案例，交 C-003、T-092／使用者 T-023 及各功能包；3 秒卸載／關服後仍約 3 秒的 D5 案例不刪減，誤差仍待技術定義。
