# T-007 NEW dedicated server 啟停證據

判定：**已完成（僅既有框架 server 啟停）**。2026-09-26 23:58:35–23:59:51（Asia/Taipei）；實際起訖與退出碼見 [launch.json](launch.json)。前置 T-005 已完成；未執行 T-089 client 連線。

## 版本與命令

NEW `D:/workspace/java/simple-rail-1.21.1`，HEAD `8bd977dbb9f9000411ae5f4d10750228e5f33560`；OLD 僅引用 T-003 HEAD `6698b1c5f494095a15b055c10045293e91540012`，本次未啟動或建置。Java 21.0.12.1 Eclipse Adoptium、Gradle 9.2.1、ModDevGradle 2.0.147；實際 [模組清單](mod-list.txt) 為 Minecraft 1.21.1、NeoForge 21.1.251、Simple Rail 1.0.0。

實際命令為 `gradlew.bat runServer --console=plain --info --no-configuration-cache -I docs/evidence/T-006/runtime.init.gradle`，由 `powershell.exe -NoProfile -ExecutionPolicy Bypass -File docs/evidence/T-006/launch.ps1 server` 擷取輸出並轉送 stdin。專案現有 server run 帶 `--nogui`。使用 [測試 init script](../T-006/runtime.init.gradle) 的 `run/T-007`，只綁定 `127.0.0.1:25575`；新世界 `T007-new-world`，view/simulation distance 5、max players 2、online-mode true。

使用者本輪明確回答「同意，僅設定本次測試目錄」，因此只在此目錄寫入 `eula=true`；保存 [eula.txt](config/eula.txt)、[server.properties](config/server.properties) 與生成設定。沒有 client 加入，未替使用者接受其他目錄條款。

## 完成條件核對

| 條件 | 實際結果 |
| --- | --- |
| 新世界與 server 完成啟動 | 23:58:54 `No existing world data, creating new world`；23:59:00 `Done (5.127s)!` |
| 正確模組版本、common 可在 server 執行 | debug.log 模組清單僅三項；23:59:00 simplerail `HELLO from server starting`；無 client-only 類別載入致命錯誤 |
| 可回應指令及保存 | [stdin-sent.log](stdin-sent.log)：送出 `list`、`save-all flush`；23:59:22 回應玩家 0/2、`Saved the game` 與全部維度已保存 |
| 正常停止 | 送出 `stop`；23:59:49 停止／保存玩家與世界，23:59:50 全維度保存完成；runServer 與輔助程序退出 0，`BUILD SUCCESSFUL in 1m 14s` |

## 證據及未驗證範圍

[stdout.log](stdout.log)、[stderr.log](stderr.log)、[debug.log](logs/debug.log)、[latest.log](logs/latest.log)、[關鍵事件](key-events.txt)、[警告摘錄](warnings-errors.txt)、[最終世界快照](T-007-world.zip)、[世界指紋](world-manifest.json)、[來源核對](source-check.json)、[Git／命令退出码及雜湊](verification.json)。來源／Gradle／src 資源的 12 項指紋與 T-005 一致，證據蒐集命令見 T-006，最終退出 0。

log 有原版命令參數歧義、union 資源 URL 與 Gradle deprecation 提示；未發現 ERROR／FATAL 等級行。這不是零警告聲明，也不是功能或 client 連線驗收。server 使用開發輸出，未做發行 JAR 安裝驗收、重啟讀回、負载、模組功能、OLD 測試或 T-008–T-016 API 研究。車輛／座標／編組在本次無玩家框架啟停不適用。R-01 仍須按 REVIEW.md 完成其他範圍與獨立審查。
