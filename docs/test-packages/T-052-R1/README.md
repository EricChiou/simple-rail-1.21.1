# T-052-R1：車頭外觀與速度重測包

> **已由 [T-052-R2](../T-052-R2/README.md) 取代；勿用此 R1 JAR 做新一輪驗收。** R1 速度仍過慢，原包與空白結果保留作歷史。

任務／案例：T-052，T052-R1-01～04 及原 T-052 全項回歸。**人工結果待使用者填寫；R-05／R-F 程式複查待執行。** Minecraft `1.21.1`、NeoForge `21.1.251`、mod `simplerail 1.0.0`、Java 21。HEAD `11916b69c3549504928f7cfa6790d59a2717b4b6` 加未提交來源差異，逐檔指紋見 [audit.json](../../evidence/T-052/fix-R1/audit.json)。

唯一安裝 JAR：[mods/simplerail-1.0.0.jar](mods/simplerail-1.0.0.jar)，SHA-256 `5E4858167925DE9B22161781AE89649BDA87948E285F3AA5CCFAF008777898BD`。請在 client 與 dedicated server 的 `mods` 目錄移除舊版同 ID JAR，兩端都放入此固定 JAR；建立新的測試世界或先備份既有測試世界。T-054 診斷包也是相同 mod ID，**不得與此包同時安裝**。本包沒有診斷 `/t054` 指令。

[CASES.md](CASES.md) 列出操作步驟、事先預期及需要回傳的實際現象；[results.json](results.json) 的 actual 均為 `null`。請先在相同軌道與相同載客條件下比較車頭與普通礦車，並以雙 client 連 dedicated server 再確認兩端外觀／速度。若失敗，回報案例 ID 與實際現象即可；client／server `logs/latest.log`、畫面截圖或影片可選附，若要取 log 可搜尋 `simplerail`、`ERROR`、`Exception`。依既定規則，人工驗收由使用者確認即可結案，無須提交附件；未收到確認前 Agent 不填結果。

[失敗回報、原因、修正及 build／bytecode 證據](../../evidence/T-052/fix-R1/README.md)。固定 JAR 只經 NEW build 和非遊戲靜態核對，尚未啟動 Minecraft；獨立 Review Agent 複查程式後，再以此包進行 T-052 重測。
