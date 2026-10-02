# T-123-v1：三種路口暫存生命週期測試包

本包由開發 Agent 為 T-072 製作，**不含人工遊戲測試結果**。Minecraft 1.21.1、NeoForge 21.1.251、Java 21、Simple Rail 1.0.0；來源 commit `11916b69c3549504928f7cfa6790d59a2717b4b6` 加未提交產品差異，不能僅由 commit 重建。[manifest](manifest.json) 列本輪關聯檔案 SHA-256，[全部 199 個產品輸入指紋](source-inputs.json)供核對。[安裝 JAR](mods/simplerail-1.0.0.jar) SHA-256 `D49799ECCBFC19E722EC9E68ADC2B05C7BB5F7A0C9DA39A85E83468BC349CD45`。

使用獨立的新測試世界，`mods` 只放此一份 Simple Rail；dedicated server 和所有 client 均用相同 JAR。PowerShell 可執行 `Get-FileHash mods/simplerail-1.0.0.jar -Algorithm SHA256` 核對。需要 OP／server console 權限。依 [CASES.md](CASES.md) 的 6 類情境，在 `cross_rail`、`y_cross_rail`、`y_cross_right_rail` 各執行一次，共 18 個案例。fixture 是固定座標的軌道／礦車配置、Minecraft 原生 `/data get block` 和 `/tick freeze`／`/tick step` 操作，不向產品加入診斷命令或外部模組；Minecraft 官方[快照說明](https://feedback.minecraft.net/hc/en-us/articles/20707371679117-Minecraft-Java-Edition-Snapshot-23w43a)列出 `/tick freeze` 與 `/tick step <time>`，具體伺服器權限／行為仍以使用者的 1.21.1 實際執行為準。

server／client 的 `logs/latest.log` 與 F2 的 `screenshots/` 可輔助定位。若發現問題，請提供案例 ID 與實際現象；依既定人工規則，直接確認「T-123 完成／通過」亦可結案，log／截圖不是必要前置。`results.json` 的 `actual` 全為 `null`，只有使用者回報能填入。R-06 程式審查待審；NEW build／JVM 表格測試僅代表非遊戲證據，見 [T-072](../../evidence/T-072/README.md)。T-073 已修來源可確認的暫存結構缺口，實際跨維度、重載與並行效果仍由本包驗證。
