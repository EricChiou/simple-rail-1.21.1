# T-058-R3：OLD 停靠格跟車邏輯重測包

> 歷史快照：最新重測包為 [T-058-R4](../T-058-R4/README.md)；以下 R3 的整格間距及待測文字只記錄當時狀態。

任務 T-105 開發交付／T-058 使用者人工重測；案例 T058-R3-01～05、T058-FULL。**R-05／R-F 獨立程式審查、R3 使用者遊戲測試均待執行。** Minecraft `1.21.1`、NeoForge `21.1.251`、Simple Rail `1.0.0`、Java `21`。來源 commit `11916b69c3549504928f7cfa6790d59a2717b4b6` 加工作目錄未提交差異；[191 項來源／建置檔 SHA-256](source-manifest.json)固定本次內容，不能只以 commit 還原。

唯一安裝 JAR：[mods/simplerail-1.0.0.jar](mods/simplerail-1.0.0.jar)，SHA-256 `65003C9B336DCAF6ACECA1F3C1CD7E41BB0404E3F5405F17E4CC58C20BC2457B`。在 client 與 dedicated server 的 `mods` 目錄移除同 mod ID 舊版／診斷 JAR，只留此檔；多人測試兩端使用同一 SHA。請先備份 NEW 測試世界。此包不轉換 OLD 世界。

本版把 R2 的沿路徑 1.5 格倍數改回 OLD 來源的跨格停靠點：後一節沿用前一節的舊停靠格，移到格中心；車頭在格內 `0.2～0.8` 範圍時更新車廂位置，停車時也更新。這是**依 OLD 原始碼實作／待使用者遊戲確認**，不是 OLD 實測證明。R1 中間車永久摧毀斷尾、暫時卸載保留編組的行為保留；R1／R2 JAR 已由本包取代作為最新重測版。

依 [CASES.md](CASES.md) 操作；[results.json](results.json) 的 `actual` 全為 `null`，不代填。完成時你只需確認 T-058 是否通過即可結案，無須提供 log 或截圖；若有失敗，請回報案例 ID 與現象。選用資料：client／server `logs/latest.log`、按 `F2` 取得 `screenshots/` 截圖、短影片或 NEW 世界備份；log 可先遮掉私人資訊。

[R3 來源對照、NEW build 與純 JVM 檢查](../../evidence/T-058/fix-R3/README.md)已保存。Review Agent 僅審程式、資料與案例覆蓋，不啟動 Minecraft 或簽人工結果。
