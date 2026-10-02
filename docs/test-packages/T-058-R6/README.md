# T-058-R6：1.3 格倍數車距重測包

> 歷史快照：最新重測包為 [T-058-R7](../T-058-R7/README.md)；以下 R6 的 1.3 格預期及待測文字只記錄當時狀態。

任務 T-105 開發交付／T-058 使用者人工重測；案例 T058-R6-01～05、T058-FULL。**R-05／R-F 程式審查和 R6 人工遊戲驗收均待執行。** Minecraft `1.21.1`、NeoForge `21.1.251`、Simple Rail `1.0.0`、Java `21`。來源 commit `11916b69c3549504928f7cfa6790d59a2717b4b6` 加未提交差異；[192 項來源／建置檔 SHA-256](source-manifest.json)固定內容，不能只由 commit 還原。

唯一安裝 JAR：[mods/simplerail-1.0.0.jar](mods/simplerail-1.0.0.jar)，SHA-256 `C6D5DFA8A41C79CEB49F5B0D78934CD107870FA3057F7C4374C39099A39BF7AA`。client 與 dedicated server 的 `mods` 目錄請移除同 mod ID 的舊版／診斷 JAR，只留此檔；多人兩端使用相同 SHA。測試前請備份 NEW 世界。本包不轉換 OLD 世界。

R6 沿車頭跨格記錄的路線設定第 1、2、3 節目標為 1.3／2.6／3.9 格；原有跨格停靠格定位是路線不足時的過渡。這是 NEW 的新數值，不宣稱 OLD 有此數值。中間車永久摧毀斷尾、暫時卸載保留編組的修正維持。[R6 來源、build 與非遊戲測試](../../evidence/T-058/fix-R6/README.md)可供程式審查。

請按 [CASES.md](CASES.md) 操作；[results.json](results.json) 的 `actual` 均為 `null`，不代填。你只需確認 T-058 是否通過即可結案，不必提供證據；若仍有問題，請回報案例 ID 與現象。可選資料：client／server `logs/latest.log`、按 `F2` 取得 `screenshots/` 截圖、影片或 NEW 世界備份；可先遮掉私人資訊。Review Agent 只審程式與案例覆蓋，不啟動遊戲或簽人工結果。



