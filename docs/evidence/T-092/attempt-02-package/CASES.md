# T-092 → T-023 案例草稿

**受阻，不開始人工測試。** 所有實際結果留白。case-index.json 逐項展開 SP／DS、13 物品、11 方塊與雙語；TABLES.md 保存完整名冊／25 設定／狀態域來源。以下是可審閱的步驟與事前預期，不是操作已成功。

## C-001：ID、分頁与取得

在新 SP 及 DS 世界，分別 `/give @s simplerail:<表中 ID> 1` 取得每一件，F3+H 確認 ID；創造模式的 Simple Rail 分頁逐項看 13 物品與 high_speed_rail 圖示，切兩語系檢查原名稱。只能用 13 既有物品，不新增 oneway_reverse_rail 或 wrench 方塊。查看 Mods 的版本、logo 及授權，並檢查 log 無範例／重複 registry／JSON 錯誤。

本包只對階段 2 已實作的 block／item 名冊作判定；車頭實體、2 舊 BE 與專用 dispenser BE 尚未註冊，C-001 最終完整 registry 要求交 T-048／T-037／T-041／T-044／T-081／T-125，不把本包 11／13 名冊冒充最終全 registry 通過。

## C-002：放置、狀態與預設

逐 11 方塊，在平台上單獨放置，F3 檢查實際 property／default。承接完成後，依 STATE-DOMAINS.json 的候選域，逐適用鍵值及各模型 selector 做受控設置與讀回；六向／0–9／布林／軌道形状都保留。不得以正常禁坡或水平放置為理由刪除斜坡／上下向。

**I-021-01：10 個骨架缺 property，9 種候選域有未覆蓋變體。現 JAR 不能執行本組完整驗收。** 每種方塊的正式預設、可控制狀態設置／保持方法，以及受鄰居回呼影響的值如何觀測，須由 state／模型承接任務定義；目前不可用不存在的 `/setblock ...[property=value]` 案例假裝已可選。保留 T-010／T-019 的候選預設與待確認差異，不自行決定 timer_holding 的舊疑點。

## C-003：COMMON 檔案與有效值

正式包交接後先以全新 game directory 起動，逐 25 鍵比 default-config-reference.toml，確認真正檔名 config/simplerail-common.toml。停止後備份，逐鍵寫合法下界／上界、布林兩值，再啟動觀察；運行中改檔與新啟動另列。boolean 不猜成数字，int 最大秒數不等待數十年，不用 ticks 替代 D5。

**I-092-02（局部觀測限制）：目前沒有讀取 CommonConfig.current 有效快照的遊戲診斷介面，功能消費者也未實作。** 檔案被寫回、監看事件或 `/reload` 成功不足以證明 handler 發布／server 使用正確值；有效值、即時 reload 及 client/server 不同配置的權威性案例尚無可操作的觀測方法。須在承接方案中定義只讀觀測，或由後續功能案例驗相應消費者；本輪不新增診斷程式或宣稱快照通過。可先審檔案生成的步驟，但不能因此結案整個配置案例。

## C-004：雙語、圖集、全部模型與 reload

在 English (US)／繁體中文切換後逐物品與分頁對 TABLES，9 軌道放在草地／石材平台上看透明孔洞及下方材質；用承接的受控狀態矩陣看供電／反向／0–9／方向與機器模型。F3+T 重載 client 資源，DS 同樣看 client logs；server `/reload` 另核資料。檢查沒有本模組 missing model/texture、未知 property、atlas、JSON 或 registry 錯誤。

原 PNG 與 UV 保留，build 不證明外觀。I-021-01 仍阻擋完整模型／預設矩陣；車頭 Java renderer／八向／六盒 UV 交 T-050／T-052，不用車頭 item 圖示替代實體外觀。

## 交接與修正

case-index 每例包括 ID、前置、步驟、預期與來源、局部限制及 null 實際值。解除 I-021-01／I-092-02 後需要**新的 JAR／來源指紋與新版包**，不能沿用此草稿 reference JAR 簽 T-023。先開發修正／非遊戲檢查，R-02 或 R-F 審程式與案例覆蓋，再交使用者操作；只有使用者確認可記人工結果，不要求附件。正式任務前置與 D1–D8 本輪不改。
