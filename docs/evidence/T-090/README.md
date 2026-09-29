# T-090 開發交付：單 client 連線固定版本包

2026-09-28（Asia/Taipei）；NEW `D:/workspace/java/simple-rail-1.21.1`，HEAD `8bd977dbb9f9000411ae5f4d10750228e5f33560`，包含 T-017 未提交產品差異。前置 T-006、T-007、T-004 各自歷史證據保留。只完成 T-090／T-091，未修改產品 Java／Gradle／資源，未重跑 OLD、安裝環境或啟動 Minecraft。

**T-090 開發完成；R-01 獨立程式審查待審。** [T-090-v1 ZIP](../../test-packages/T-090-v1.zip) 與 [包內說明](../../test-packages/T-090-v1/README.md)已製作，對應 T-089、T-004 C-040、MIGRATION.md §3 入口／網路、§6 階段 1，R-01／C-09。五個具體案例涵蓋同版雙端、登入、新世界基本操作、離線／重連、正常保存停服；結果欄空白。使用者先前 T-089 完成確認有效且已結案，不要求重測或補證，也不把先前回報綁定此包。

## 命令、產物與完成條件

| 項目 | 實際結果／證據 |
| --- | --- |
| 工具版本 | `java -version`、`javac -version`、`.\gradlew.bat --version --offline --console=plain` 均退出 0；Java／javac 21.0.12.1，Gradle 9.2.1；[命令與退出碼](commands.json)及三份 version log 已保存 |
| NEW build | `.\gradlew.bat build --offline --console=plain --no-configuration-cache` 退出 0，[原始 log](build-01.log)；沿用前次已確認的 Wrapper 工作區外鎖檔需求，經允許使用既有快取。`jar UP-TO-DATE`；`test NO-SOURCE`，沒有自動化程式測試通過結果 |
| 固定 JAR | `simplerail-1.0.0.jar`；SHA-256 `537780CB1E3C2B532AF7F22BEC1AA306C0966AFD6C571CC5D2936275B66C3A36`，與 T-017 相同；包內 D8 metadata、JAR 兩個入口 class／無 Config.class 已靜態核對 |
| 封裝命令 | `powershell -NoProfile -ExecutionPolicy Bypass -File docs/evidence/T-090/package.ps1` 最終退出 0；[腳本](package.ps1)、[成功命令](package-03.json)、[成功 log](package-03.log)；初次 PowerShell UTF-8 BOM 解析失敗及 ZIP 分隔符檢查失敗均未宣稱成功，紀錄見 [package-commands.json](package-commands.json)、package-01／02.log，失敗封裝保留於 attempt-02-package／ZIP |
| 封裝靜態檢查 | [packages.json](packages.json)：兩包各 16 檔、5 案例；逐檔 hash、ZIP 內每檔內容、複製 JAR、一致版本、空結果欄與產品輸入指紋均檢查通過。未執行遊戲 |
| 完整交接 | 包內 manifest、完整產品差異／來源指紋、build／版本 log、JAR metadata／目錄、安裝啟動步驟、場景／預期、選用 log／F2 方法及確認格式均已提供；無未知必要遊戲規格阻擋此框架案例。R-01 待審獨立記錄，正式審查通過前不簽為已審交接 |

ZIP SHA-256 `B871DC2B375DD72654EE0B2A48C8CE68CBB92B8750B7A726D41E62B6DE7F6CE8`。包內 `files-manifest.json` 不包含自身雜湊，外部 ZIP 雜湊涵蓋完整包。來源資料保存於 [source.diff](source.diff)、[source-fingerprints.json](source-fingerprints.json)。包固定後不覆寫，後續變更使用新包版本。沒有重填 T-018／T-089 結案結果，沒有執行 T-019。證據及包受既有 `.gitignore` 的 `docs/` 規則排除，保存於本機工作區；未變更索引或忽略規則。

安裝說明來源（2026-09-28 查閱）：[官方 client 安裝](https://docs.neoforged.net/user/docs/client/)、[官方 server 安裝](https://docs.neoforged.net/user/docs/server/)、[官方 Java 需求](https://docs.neoforged.net/user/docs/)、[21.1.251 官方 Maven 目錄](https://maven.neoforged.net/releases/net/neoforged/neoforge/21.1.251/)。文件提供操作依據，不是本輪已安裝或遊戲驗證的證據。
