# T-018 案例操作

來源：TASK.md T-018 的工作與完成條件；T-004 C-039／C-040；T-017 差異；MIGRATION.md §3、§6 階段 1。以下是操作規格，**本包逐例實際結果未填**。使用者既有整項通過回報另於任務文件保留，不轉成新包測試結果。

場景：獨立 `client` 遊戲目錄及 `server` 安裝目錄，雙端同一份包內 JAR。client 建立 NEW 單人世界 `T018-v1-client`，創造模式、允許指令、overworld；server 使用新的 `T018-v1-server`，`server-ip=127.0.0.1`、`server-port=25591`、`online-mode=true`、`max-players=2`。server world 由 server.properties 的 `level-name` 指定；client／server 世界均與 OLD 隔離。沒有列車／編組，UUID／槽位／固定座標不適用；在出生點操作。

| 案例 ID／順序 | 操作 | 預期結果 |
| --- | --- | --- |
| T018-01（C-039.1／C-040.6） | 按 INSTALL 安裝固定版；client Mods 畫面查看 Simple Rail 名稱與 1.0.0，核對包內 `evidence/neoforge.mods.toml`；確認雙端安裝本包同一 JAR。 | simplerail／Simple Rail／1.0.0、All Rights Reserved；MC 1.21.1／NeoForge 21.1.251。啟動沒有缺失入口或重複註冊錯誤。 |
| T018-02（C-040.7） | 進入單人新世界，放置一個原版石頭作識別；儲存並返回標題畫面，再進入該 NEW 世界確認標記，最後正常關閉 client。 | client 可進入、保存新世界並正常停止；原版標記保留，不出現本模組載入致命錯誤。這不代替未實作功能的存讀驗收。 |
| T018-03（C-039.2） | 在上述允許指令的新世界搜尋創造分頁，確認沒有 Example Mod Tab；分別輸入 `/give @s simplerail:example_item`、`/give @s simplerail:example_block`。 | 沒有範例分頁／範例物品；兩個 give 都是不存在的物品 ID，不產生範例物件。沒有正式 Simple Rail 功能物件亦符合目前空框架範圍。 |
| T018-04（C-040.8） | 使用者啟動 dedicated server，等完成建立新世界；console 輸入 `list`、`save-all flush`，完成保存後輸入 `stop`。 | server 能建立、保存新世界並正常停止；沒有 client-only 類別載入、缺失入口或重複註冊錯誤。common 空框架載入不需要 client GUI。 |
| T018-05（C-039.3／C-040.9） | 使用者再次啟動上述 server，以 client 加入 `127.0.0.1:25591`；server console `op` 後接自己的玩家名稱。client 同 T018-03 查範例物品／分頁；放原版石頭，離線後 console 保存、停止。 | dedicated server registry 的範例物品 ID 也不存在；玩家可操作、保存並正常停服。雙端沒有本模組相關入口／同步／client-only 致命錯誤。 |

本框架沒有自訂 gameplay listener；原範例 setup／server 日誌已移除，不把缺少 HELLO 日誌當錯誤。本項不設定速度／計時／效能容差。`example_block` 的方塊／BlockItem 與分頁註冊移除也由包內 source.diff 和產物靜態檢查對照；不要假設某個不存在的 registry dump 指令可用。

選用觀測：各自 `logs/latest.log`、若有則 `logs/debug.log`／`crash-reports`；F2 圖片在 client 的 `screenshots`。可檢視 Mods、指令回應、原版標記與保存／停止輸出；無需提交附件或逐例資料，確認完成即可結案。失敗時回覆案例 ID 及看到的問題，修正／獨立程式複查後再由使用者重測受影響案例。
