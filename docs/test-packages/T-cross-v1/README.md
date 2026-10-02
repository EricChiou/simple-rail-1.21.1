# T-cross-v1：T-069／T-071 人工測試包

Minecraft **1.21.1**、NeoForge **21.1.251**、Java **21**、Simple Rail **1.0.0**。固定 JAR 位於 `mods/simplerail-1.0.0.jar`；commit、JAR SHA-256 與未提交差異見 [manifest.json](manifest.json)、[product.diff](product.diff)，所有來源指紋見 [source-inputs.json](source-inputs.json)。這個包同時交付 T-110／T-111；R-06 尚未獨立審查，全部人工結果待使用者。

使用獨立的新世界。將該 JAR 放入相同 NeoForge 版本的 client／dedicated server 的 `mods`，移除該測試環境其他版本的 Simple Rail；由使用者自行啟動兩端。兩個舊 Y 方塊／物品 ID 已移除，沒有舊世界或舊測試存檔轉換；歷史 T-123-v1 的三種路口 JAR 不可混用。

取得：`/give @s simplerail:t_cross_rail`、`/give @s simplerail:wrench`。以 [CASES.md](CASES.md) 進行 T-069 轉向及 T-071 紅石／貼圖驗收；`direction=north` 表示由南向北進入主幹，左右按車前進方向判斷。對方向的目前解讀為主幹分流、分支回主幹，仍可依使用者回覆調整。

T-123／T-074 的後續生命週期場景見 [LIFECYCLE.md](LIFECYCLE.md)，覆蓋現有十字及 T 型兩種路口；這些案例未執行，也不因 T-069／T-071 通過而自動結案。

如需核對版本，在包目錄執行 `Get-FileHash mods/simplerail-1.0.0.jar -Algorithm SHA256`。兩端 `logs/latest.log` 可用於排查，F2 截圖在 client `screenshots/`。使用者只要回報任務／案例 ID 與通過或異常現象即可；log、截圖、JAR 指紋皆非人工結案必要附件。初始 [results.json](results.json) 全空白，開發 Agent 不代填。
