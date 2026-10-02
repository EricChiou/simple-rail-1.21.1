# T-040 R1：計時軌扳手換級重測包

> 後續使用者確認（2026-09-30）：[T-040 整項人工測試通過並結案](../../evidence/T-040-T-042-T-101-user-confirmation/README.md)。下列實際結果欄保留交付時空白；未提供受測 JAR 或逐例資料，不將本包 SHA-256 倒填為使用者測試版本。R-04／R-F 程式複查仍待執行。

**開發包已備；獨立程式複查與使用者遊戲重測均尚未執行。** 這份包針對 T-040 的扳手換級失效子例；T-040 其餘正式計時、保存、真卸載與停服案例仍須各自驗收。

| 固定項目 | 值 |
| --- | --- |
| 任務／案例 | T-040；`T040-R1-01` 水平經車後換級、`T040-R1-02` 9→0、`T040-R1-03` 車佔用邊界、`T040-R1-04` 單人／dedicated server 重測 |
| Minecraft／NeoForge／模組 | 1.21.1／21.1.251／Simple Rail 1.0.0 |
| Java／發行授權 | Java 21；All Rights Reserved |
| 固定 JAR | [mods/simplerail-1.0.0.jar](mods/simplerail-1.0.0.jar) |
| JAR SHA-256 | `E1C79C838055CEF0955E8B0CF46991DA51F24BBDDCA4FE2A1DA6C6891588EF39` |
| NEW commit／工作差異 | `11916b69c3549504928f7cfa6790d59a2717b4b6` 加未提交 T-038／T-041／本 R1；完整產品輸入 SHA-256 名冊見 [證據](../../evidence/T-040/fix-R1/product-inputs.json)，不能只用 commit 重建 JAR |
| Build／非遊戲測試 | [T-040 R1 開發證據](../../evidence/T-040/fix-R1/README.md)；build 退出 0，隔離回歸通過；Minecraft 未由 Agent 啟動 |
| 程式審查 | R-04／本 R-F 待獨立複查；本文件不代替審查結論 |

請在 Minecraft 1.21.1、NeoForge 21.1.251 環境中，只安裝**一份** Simple Rail JAR；將本包 JAR 放入 `mods`，不要同時保留舊版同 ID JAR。可先用 `Get-FileHash mods/simplerail-1.0.0.jar -Algorithm SHA256` 核對。請在單人世界與 dedicated server 各操作一次；dedicated server 的 server `mods` 與連線 client `mods` 需使用同一份 JAR。下列結果只由你填寫／確認，Agent 未操作。

| 案例 | 操作步驟 | 預期結果 | 實際結果（使用者） |
| --- | --- | --- | --- |
| `T040-R1-01` | 放置 `timer_holding_rail`，用扳手設到非零級；讓礦車經過並離開方塊。確認軌道格**沒有礦車佔用**後，記下方塊完整 state，再點一次扳手。 | `level` 從 n 變 n+1（9 則 0），不需拆除重放；若 `direction` 是水平向，按原扳手規則順時針旋轉。`powered`／`shape` 等其他屬性不被重設。 | 待填；使用者確認即可 |
| `T040-R1-02` | 先把經車後的同一計時軌設為 `level=9`，確認格內無礦車，再點一次扳手。 | `level=0`，方向若是水平向仍旋轉；之後再點可到 `level=1`。 | 待填；使用者確認即可 |
| `T040-R1-03` | 讓礦車停在計時軌格內時點扳手；待礦車離開後再點。 | **格內有車時仍不改** state（既有安全門檻）；離開後可正常換級。 | 待填；使用者確認即可 |
| `T040-R1-04` | 在單人和 dedicated server＋client 各做 `T040-R1-01`，記錄各自是否成功。 | 兩種環境都能於礦車離開後改級，client 顯示與 server 實際 state 一致。 | 待填；使用者確認即可 |

查看 state 可在視線對準軌道時使用 F3 顯示的目標方塊屬性，或選用其他你熟悉的方塊狀態檢查方式。若失敗，回覆案例 ID、是在單人還是 dedicated server、改前／改後的 `level` 與 `direction`，以及礦車是否仍佔用該格，便足以協助定位。log／截圖**不是人工結案必備**；若願意附上，client log 在實例 `logs/latest.log`、dedicated server log 在其 `logs/latest.log`，F2 截圖在 `screenshots/`。

本包不預填結果。只有你確認 T-040 全部必要案例通過後，T-040 才可結案；這次局部重測通過本身不等於 D5 全項通過。
