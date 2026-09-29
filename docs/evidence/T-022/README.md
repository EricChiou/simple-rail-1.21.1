# T-022 配方、掉落表與標籤交付

2026-09-28。**開發完成；R-02 程式審查待審；人工遊戲未執行**。前置 T-019／T-009 開發證據已齊；R-01 原範圍不簽本次差異。OLD build 由使用者先前驗證，本次流程不重跑。

## 交付與完成判定

- [29 檔來源→目標／ID／雜湊](data-map.json)：13 shaped 配方、11 方塊 loot＋額外車頭 loot、4 tag。移到單數目錄，保留 destory_rail 及全部 ID。
- 13 配方只改 result.item→id，材料／排列／count 保留；destory_rail=3，其餘=1。tag 保留 rails 9／machines 2／wrench 1 與 minecraft:rails 的 replace=false。
- [資料與掉落契約](DATA_CONTRACT.md)：wrench 為 item TagKey；額外車頭表保留 entity type／blocks ID，僅移除不相容爆炸條件，不自動掛接。後續 T-048 的 Java destroy 為正常車頭掉落承接，T-052／T-062 再驗無重複／遺失。
- [來源／完整差異](source.diff)、[17 個指定來源](source-references.json)、[產品指紋](source-fingerprints.json)、[typed tag bytecode](tags-bytecode.txt)保存。沒有修改既有 Java、Gradle、client 資源或 metadata；只新增 ModTags 與 data 資源。準備次序的界線見 [紀錄](preparation-order.md)。

來源清冊、ID／材料／排列／產量、tag 型別／成員／合併及額外 loot 責任均已交付，引用核對與 NEW build 通過，符合本項開發完成條件。**不宣稱遊戲資料載入、合成／掉落或獨立審查通過**。I-021-01 保留，這個 JAR 尚不是可交接的 T-092 功能測試包。

## 實際命令與結果

| 命令 | 實際結果 | 證據 |
| --- | --- | --- |
| `powershell -NoProfile -ExecutionPolicy Bypass -File docs/evidence/T-022/prepare.ps1` | 0，保存文件／index／既有輸入與指定來源 | [腳本](prepare.ps1)、[原 index](index-before.diff)、[準備次序](preparation-order.md) |
| `powershell -NoProfile -ExecutionPolicy Bypass -File docs/evidence/T-022/migrate-data.ps1` | 0，29 OLD 檔與 T-009 manifest SHA-256 核對後遷移 | [腳本](migrate-data.ps1)、[UTC／範圍](migration-command.json)、[映射](data-map.json) |
| `powershell -NoProfile -ExecutionPolicy Bypass -File docs/evidence/T-022/audit.ps1` | javac 0、java 0；**393 項通過、0 失敗，85 次引用** | [命令／退出碼](audit-commands-01.json)、[編譯 log](audit-compile-01.log)、[完整 log](audit-run-01.log)、[逐項結果](audit-results.json)、[工具](audit/DataAudit.java) |
| `.\gradlew.bat build --offline --console=plain --no-configuration-cache` | 0，BUILD SUCCESSFUL；compileJava／processResources／jar 實際執行 | [命令／UTC](build-01.json)、[完整 log](build-01.log)、[腳本](build.ps1) |
| `powershell -NoProfile -ExecutionPolicy Bypass -File docs/evidence/T-022/record.ps1` | 0；各子命令退出碼保存，no-index 1 代表新檔有差異 | [腳本](record.ps1)、[命令](commands.json)、[bytecode](tags-bytecode.txt) |
| `powershell -NoProfile -ExecutionPolicy Bypass -File docs/evidence/T-022/final-check.ps1` | 首次退出 1：沿用工具的映射檔名未更新，實際核對尚未完成；修正後結果見最終紀錄。非 R-02 | [腳本](final-check.ps1)、[結果](final-check.json)、[首次命令](final-check-command-01.json)／[log](final-check-01.log)、[最終命令](final-check-command-02.json)／[log](final-check-02.log) |

auditor 使用 Java 21 `--release 21 -proc:none -encoding UTF-8 -Xlint:all -Werror`，runtime classpath 僅自身及本地 Gson 2.10.1；Minecraft client JAR 只作 ZIP 輸入，[classpath／archive hash](audit-classpath.json)可追溯。未載入 Minecraft 類別、未執行 codec／registry／reload、GameTest、runClient／runServer／runData 或 OLD build。Gradle `test NO-SOURCE`，393 項是獨立檔案契約結果，不能當作 Gradle 單元測試或遊戲測試。build 的 Gradle 10 棄用提示保留。

文件核對腳本的產生工具首次因 PowerShell 以非 UTF-8 解讀中文而退出 1；[原稿](generate-check-attempt-01.ps1.txt)、[失敗重現命令](generate-check-command-01.json)／[log](generate-check-01.log)保存。補 UTF-8 BOM 後 [重試命令](generate-check-command-02.json)／[log](generate-check-02.log)退出 0；另校正前版 artifact 欄位及 metadata 指紋比較，保存 [最終產生命令](generate-check-command-03.json)／[log](generate-check-03.log)。這些只產生證據工具，沒有重跑產品 build／auditor，也不是產品 build 失敗。

首次 final-check 在讀取舊工具的 resource-map.json 檔名時退出 1；T-022 的實檔為 data-map.json。原 [失敗工具](final-check-attempt-01.ps1.txt)保存，檔名修正的 [產生命令](generate-check-command-04.json)／[log](generate-check-04.log)可追溯；沒有為通過檢查修改產品資料。

## 固定產物與後續

Minecraft 1.21.1／NeoForge 21.1.251／mod 1.0.0／All Rights Reserved；Java／javac 21.0.12.1 為本輪實際命令，Gradle 9.2.1／ModDevGradle 2.0.147 沿用未變的工具鏈，Gradle 版本紀錄見 [T-021](../T-021/gradle-version.log)。HEAD `8bd977dbb9f9000411ae5f4d10750228e5f33560` 加既有 staged 與本輪未提交差異，未 stage／commit／reset。

[保存 JAR](artifacts/simplerail-1.0.0.jar)／[artifact.json](artifact.json) SHA-256：`3D4BFC8926509DCE28C6DE11E8198D3639EB288E1EB29FAD89D3AEC9C1C6BBD3`。原 T-019–T-021 產物、R-01 固定包及人工確認不覆寫；本輪只執行 T-022。下一個優先功能開發任務 T-025，尚未開始；T-092／T-023 仍待 I-021-01 整合承接與 R-02，T-024 的合成／掉落也待固定包及使用者確認。人工完成只需使用者確認，不要求附件，不把舊 T-018／T-089 回報套到新 JAR。
