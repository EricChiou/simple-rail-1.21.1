# T-058-R1：扳手編組與車距重測包

> 歷史包：使用者確認 R1 的 1.2 格倍數間距太近；最新待驗收版本為 [T-058-R2](../T-058-R2/README.md)，本包不再作新驗收基線。

任務 T-105 開發交付／T-058 使用者人工重測；案例 T058-R1-01～05、T058-FULL。**使用者尚未重測，R-05／R-F 獨立程式審查待執行。** Minecraft `1.21.1`、NeoForge `21.1.251`、Simple Rail `1.0.0`、Java `21`。來源 commit `11916b69c3549504928f7cfa6790d59a2717b4b6` 加工作目錄未提交差異；[192 項來源與建置檔 SHA-256](source-manifest.json)固定本次內容，不能只以 commit 還原。

唯一安裝 JAR：[mods/simplerail-1.0.0.jar](mods/simplerail-1.0.0.jar)，SHA-256 `FDD36DCF9EA508C9E0BBFB6F24F1FD09C3D47D7402988B8BAD39599238B8FE05`。在 client 與 dedicated server 的 `mods` 目錄移除同 ID 舊版／診斷 JAR，只留此檔；多人測試兩端使用同一 SHA。測試前備份 NEW 測試世界。這不是 OLD 世界轉換包。

按 [CASES.md](CASES.md) 在遊戲操作，預期結果已寫明；[results.json](results.json) 的 `actual` 全為 `null`，不代填。完成時你只需確認 T-058 是否通過即可結案，無須提供 log 或截圖；若仍失敗，請回報案例 ID 與現象。選用資料：client／server `logs/latest.log`，按 `F2` 保存 `screenshots/` 截圖，或短影片；存讀案例可附世界備份。log 可先遮掉玩家名稱、IP 等私人資訊。

[R1 根因、程式差異與非遊戲檢查](../../evidence/T-058/fix-R1/README.md)已保存。R-05／R-F 只審程式、資料與案例覆蓋，不啟動 Minecraft，也不簽署人工結果。


