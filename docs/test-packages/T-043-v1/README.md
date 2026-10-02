# T-043-v1：T-120 發射器來源疑點診斷包

**開發調查包已備；T-120 已由使用者確認人工驗證完成且未發現異常，R-04 獨立程式審查仍待執行。**[完成確認與後續結論](../../evidence/T-120/USER_CONFIRMATION.md)未提供逐案實際數值，原結果欄保持空白。這是為 T-043 建的隔離診斷 JAR，不是 T-044～T-046 正式發射器。它以 `simplerail:train_dispenser` 的方塊 ID 模擬 OLD 供電鄰居回呼，從**上方一個原版單箱**讀取 27 格樣板並記錄／生成原版車。`simplerail:locomotive_cart` 在此僅以原版爐車占位，log 只列第 0 格的 `link_plan`，沒有真正連結或專用發射器 BE／GUI。

| 固定項目 | 值 |
| --- | --- |
| 任務／案例 | T-043 → T-120；`T120-01`～`T120-08`，見 [CASES.md](CASES.md) |
| Minecraft／NeoForge／模組 | **1.21.1**／**21.1.251**／Simple Rail **1.0.0**，All Rights Reserved |
| Java／Gradle | Java 21（本次 Temurin 21.0.12.1）、Gradle 9.2.1、ModDevGradle 2.0.147 |
| NEW commit／工作差異 | `11916b69c3549504928f7cfa6790d59a2717b4b6` 加先前未提交 T-038／T-041／T-040 R1 產品差異，再以 T-043 證據目錄 fixture 覆蓋 `SimpleRail`、`ModBlocks`；**不能單靠 commit 重建 JAR**。產品與包指紋見 [scope.json](../../evidence/T-043/scope.json)、[manifest.json](manifest.json) |
| 固定 JAR | [mods/simplerail-1.0.0-T043-probe.jar](mods/simplerail-1.0.0-T043-probe.jar) |
| SHA-256 | `4026BB07B15FA97179ABADDB211CAADD20FC69B752ADCA9665D07CA91B07E41A` |
| 證據與審查 | [T-043 調查／build／非遊戲測試](../../evidence/T-043/README.md)；R-04 待審 |

先按 [INSTALL.md](INSTALL.md) 準備獨立測試世界，再依 [CASES.md](CASES.md) 操作；[results.json](results.json) 的實際結果保持空白。需要 cheats／伺服器 OP 才能使用 `/t043 scan`。客戶端與 dedicated server 安裝同一份診斷 JAR，勿與一般 Simple Rail JAR 同時安裝；本包修改同一註冊方塊的測試實作，僅供診斷世界使用。

Agent 沒有啟動 Minecraft；使用者已確認 T-120 未發現異常，但未回報個別案例數值。log、畫面與逐例數值不是人工結案條件；T-046 已據此及正式來源／固定 JAR 靜態證據條件式結案，沒有新增補丁。此包所得結果只檢驗**診斷來源模型**，不能直接宣稱 OLD 已實測、正式發射器已在遊戲驗收或 T-047／T-060 已通過。
