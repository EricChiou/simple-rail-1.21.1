# T-006 NEW client 啟動基線證據

判定：**已完成（僅既有框架 client 啟動）**。測試時間為 2026-09-26 23:53 至 2026-09-27 00:05（Asia/Taipei），原始時間另見 [launch.json](launch.json)。T-005 前置已完成；未執行 OLD build、功能移植、T-089 或 API 研究任務。

## 受測版本與啟動

- NEW：`D:/workspace/java/simple-rail-1.21.1`，HEAD `8bd977dbb9f9000411ae5f4d10750228e5f33560`。OLD 僅引用 T-003 的 HEAD `6698b1c5f494095a15b055c10045293e91540012`，本次未啟動。
- 實際載入：Minecraft 1.21.1、NeoForge 21.1.251、Simple Rail 1.0.0；[模組清單](mod-list.txt)、[模組畫面](mod-list.png)。Java 21.0.12.1 Eclipse Adoptium，Gradle 9.2.1，ModDevGradle 2.0.147。啟動 log 與 T-005 解析版本共同構成版本依據。
- 實際命令：`gradlew.bat runClient --console=plain --info --no-configuration-cache -I docs/evidence/T-006/runtime.init.gradle`；由 `powershell.exe -NoProfile -ExecutionPolicy Bypass -File docs/evidence/T-006/launch.ps1 client` 啟動並擷取串流。工作目錄為 NEW。
- 測試專用 [init script](runtime.init.gradle) 僅隔離 `run/T-006`／`run/T-007` 及接通 server stdin，未修改專案 Gradle 檔案。runClient 載入開發輸出 classes/resources，並非發行 JAR 驗收。
- 首次在沙箱外經允許啟動 GUI／準備資產；啟動命令退出 **0**，`BUILD SUCCESSFUL in 12m 29s`。本輪未重跑 `build` 任務或 OLD build。

## 實際操作與完成條件

| 完成條件 | 實際結果與證據 |
| --- | --- |
| 進入標題畫面、載入 simplerail | [主選單](main-menu.png)、mod-list.png 與完整 debug.log；只有 minecraft、neoforge、simplerail 三個模組 |
| 建立並進入 1.21.1 新世界 | 獨立執行目錄原無 saves；建立 `T006-new-world`。[建立設定](world-settings.png) 顯示創造／普通／允許指令；[首次遊戲內截圖](world-entry.png) 與 00:01:05 Dev 登入座標 `(-101.5, 68, 3.5)`；維度 overworld |
| 正常退出、保存世界 | 最終向 PID 20076 的 Minecraft 視窗送出標準 `WM_CLOSE`；00:05:45 `Stopping!`／`Stopping server`，00:05:46 `All dimensions are saved`；Gradle 與啟動輔助程序退出 0。沒有強制終止 |
| 無本模組致命載入錯誤 | 完整 debug.log 未出現 ERROR／FATAL 等級行；實际成功登入與正常退出。存在非致命模型警告，見下文，不宣稱零警告 |

[GUI 操作紀錄](gui-actions.log) 為實際送出的操作，不保證每次按鍵／點擊都觸發預期畫面；`world-debug.png` 實際是暫停選單，`pause-menu.png`／`exit-menu.png` 實際是遊戲畫面，均未冒充 F3 證據。最初點擊視窗關閉按鈕沒有結束程序，後續標準關閉事件才完成退出。

同一程序 log 記錄 00:01 與 00:02 兩次进入同名世界；第二次位置 `(4.5, -60, 9.5)`，截圖地形也與首次不同。中間建立／切換細節未由連續操作證據確認；**不將兩次登入視為同一世界存讀回歸**。保留各次原始畫面及最後關閉時的世界快照，T-081–T-084 仍未執行。車輛 UUID／編組在此框架啟動測試不適用。

## 原始證據與限制

- [stdout.log](stdout.log)、[stderr.log](stderr.log)、[完整遊戲 logs](logs/debug.log)；跨午夜的 `2026-09-26-1.log.gz` 及 latest.log 一併保存。摘要 [key-events.txt](key-events.txt) 不取代原始 log。
- [設定](config/options.txt)、[最終世界快照](T-006-world.zip)、[世界檔案指紋](world-manifest.json)、[Git／退出碼／世界雜湊](verification.json)、[12 項來源指紋核對](source-check.json)。所有產品來源與 T-005 指紋一致，`git diff HEAD -- src build.gradle settings.gradle gradle.properties gradle gradlew gradlew.bat` 空白。
- [警告摘錄](warnings-errors.txt)：simplerail 的 `example_block` blockstate／item model 與 `example_item` item model 缺失，重載資源時重複出現。保留為 T-017 移除範例、T-018 重驗及 T-021／T-023 資源驗收輸入；本輪未修正。
- 另有原版命令歧義、union 資源 URL、聲音、shader sampler 警告與 Gradle deprecation 提示。僅確認這次未阻斷啟停，不延伸為所有環境安全或全部資源正確。
- 首版基線及需求未改；11 方塊／13 物品遷移、T-089 連線、指定 API 查證、存讀回歸及獨立審查仍未完成。

證據蒐集：`powershell.exe -NoProfile -ExecutionPolicy Bypass -File docs/evidence/T-006/collect.ps1` 最终退出 0。首輪退出 1 是輔助腳本將 JSON 陣列再包一層造成比較錯誤；修正證據腳本後 12 項逐檔一致，並非產品來源曾改動。初版 launcher 以獨佔寫入開 stdout/stderr，執行途中無法讀取；退出後完整串流已取得，server 改用可共讀串流。上述只涉及證據工具。
