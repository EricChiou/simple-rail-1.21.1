# 安裝及資料取得

以下步驟全部由使用者執行；開發／Review Agent 不啟動 Minecraft 或 dedicated server。

1. 使用既有 Minecraft 1.21.1＋NeoForge 21.1.251、Java 21 的獨立 client／server 環境；先正常關閉遊戲及 server。只放 Minecraft＋NeoForge＋Simple Rail，不裝其他模組。
2. 取本包 mods/simplerail-1.0.0.jar，複製到 client 和 server 各自 mods。移出原 Simple Rail JAR，避免同時放兩份；名稱／mod 版本同為 1.0.0，應以本包 SHA-256 區分。可選用 PowerShell Get-FileHash -Algorithm SHA256 核對。
3. client 由 Launcher 選既有 21.1.251 profile。單人建立創造／可用指令的新世界 T026-R2-SP；dedicated server 用其既有 run.bat --nogui，由使用者自行处理 EULA，在独立測試目錄建立 T026-R2-DS，client 連入。包不含 eula=true，不沿用 Agent 舊測試目錄授權。
4. 配置三點於真正執行遊戲邏輯的程序調整：單人為該 client；多人為 server 的 config/simplerail-common.toml。在 [rail.high_speed_rail] 段把 maxSpeed 分別設為 0.4／0.8／2.0。每次正常停機後修改值並重啟，先排除即時 reload 未驗證因素。server/client 本地 COMMON 不自動同步，不能用 client 值替代 server 設定。
5. 依 CASES.md 建造實際連續軌道、供電及坡底；確認目標 shape 後再放空的一般原版礦車。不要匯入 OLD 世界、不使用未實作的車頭或其他特殊軌道。可額外在自己的 NEW 備份世界重鋪原問題接口，觀察是否仍反轉；不宣稱此舉是資料轉換。
6. 停服使用 server console 的 stop，client 正常退出。需要保存可選用平常的正常存檔流程；人工確認即可結案，不要求提交存檔。

選用資料取得：F3 的目標方塊資訊查看 shape／powered；F2 畫面通常存於該 client 遊戲目錄 screenshots；client/server 的 logs/latest.log 可保留本模組相關錯誤。錄影可觀察反轉前後方向。結果只需文字，所有資料為選用；沒有 log 不推定未完成，也不能由靜態 log 宣稱人工通過。
