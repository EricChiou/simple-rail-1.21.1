# T-089 案例操作

來源：TASK.md T-089 的工作與完成條件；T-004 C-040；MIGRATION.md §3、§6 階段 1。以下是操作規格，**本包逐例實際結果未填**。使用者既有整項通過回報另於任務文件保留，不轉成新包測試結果。

場景：使用包根目錄下獨立 `client` 遊戲目錄及 `server` 安裝目錄；MC 1.21.1、NeoForge 21.1.251、同一份包內 Simple Rail JAR，無其他模組。server 新世界 `T089-v1-new-world`、overworld、`server-ip=127.0.0.1`、`server-port=25590`、`online-mode=true`、`max-players=2`；client 以自己的有效帳號登入。若採既有獨立安裝，使用相同版本與一個新的世界／未占用連線埠。此包沒有列車或編組；UUID、槽位和固定座標不適用，測試者以出生位置操作。

| 案例 ID／順序 | 操作 | 預期結果 |
| --- | --- | --- |
| T089-01（C-040.1） | 按 INSTALL 安裝同一 JAR；client Mods 畫面查看 Simple Rail 1.0.0，確認 MC／NeoForge profile；比對包內 metadata 與 server 所裝版本。 | 雙端 MC 1.21.1、NeoForge 21.1.251、simplerail 1.0.0 一致；只有所需平台與本模組。 |
| T089-02（C-040.2） | 由使用者啟動 server，看到完成啟動後，在 client 多人連線輸入 `127.0.0.1:25590`。 | client 進入 server 的新世界；server 可見該玩家加入，沒有本模組握手、同步或載入致命錯誤。 |
| T089-03（C-040.3） | 在出生點附近走動、跳躍並轉向；server console 輸入 `list`。 | 玩家能正常操作、未被踢出；server 列表包含同一玩家，畫面與世界正常更新。 |
| T089-04（C-040.4） | client 選擇離開伺服器，再以相同位址加入；可在此之前放置一個原版石頭方塊作重連辨識。 | 玩家能重新登入同一 server 世界，原版標記保留；無本模組相關握手／同步或重複載入錯誤。 |
| T089-05（C-040.5） | client 離線後，在 server console 輸入 `save-all flush`，完成後輸入 `stop`；等 console 正常結束。 | 世界正常保存、server 正常停止，無本模組相關保存／停止致命錯誤；此例不當成後續功能存讀回歸。 |

這五例是啟動／連線判定，不定義速度、計時或效能容差。失敗時可回覆案例 ID 及看到的問題；Agent 分析／修正後由獨立 Review Agent 複查程式，再由使用者重測受影響案例，不由 Agent 啟動 Minecraft。

選用觀測：client `client/logs/latest.log`、server `server/logs/latest.log`；`debug.log` 與 crash-reports 如有則在各自目錄。client 按 F2 的截圖在 `client/screenshots`；Mods 介面可自行擷取畫面。登入／重連時刻、console `list`／保存／停止輸出可自行記下；附件與逐例結果均無需回傳。確認完成即可結案。
