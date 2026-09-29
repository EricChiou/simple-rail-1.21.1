# T-020 正式設定與載入時機交付

2026-09-28。**開發完成；R-02 程式審查待審；人工遊戲未執行**。前置 T-019／T-008／T-004 的開發交付已齊；R-01 通過範圍不延伸至本次差異。OLD build 由使用者先前驗證，本次流程不重跑。

## 交付

- [產品 CommonConfig](../../../src/main/java/com/ericchiu/simplerail/config/CommonConfig.java)：25 個 legacy 鍵、原預設／範圍、COMMON 型別與固定檔名、Loading／Reloading／Unloading 接線、不可變快照及 loaded guard。
- [入口](../../../src/main/java/com/ericchiu/simplerail/SimpleRail.java)增加 ModContainer 注入及設定註冊；三個原 registry 接線保留，不在建構／註冊階段讀配置。
- [全部設定與生效契約](config-contract.md)、[spec 產生並讀回的預設 TOML](simplerail-common.toml)、[精確 T-019→T-020 差異](source.diff)、[完整來源指紋](source-fingerprints.json)。T-019 前入口重建後與當時 SHA-256 相符，再產出差異；原 staged／未提交 T-019 差異保留，不 reset、stage 或 commit。
- [指定版來源索引／雜湊](source-references.json)：NeoForge 21.1.251 ModConfigSpec、FML 4.0.44 ModContainer／ModConfig／ModConfigEvent，以及本次固定 loader sources archive 提取的 [IConfigSpec](sources/IConfigSpec.java)／[LoadedConfig](sources/LoadedConfig.java)。其餘 archive 與 classpath 依 T-008 固定證據，本次沒有猜 API。

COMMON 不自動同步；邏輯 server 使用當次快照決定功能。reload handler 只讀配置／原子發布快照，不修改世界、deadline、排程或票證；卸載清空快照。保留 true＝載入啟用的舊鍵語意，不新增解除政策或改 5×5。holding 秒數與 signal 秒數／20 ticks 換算／10 ticks 脈衝分開，沒有在本項實作計時或處理舊 overflow 疑點。

## 實際命令與結果

| 命令 | 退出碼／範圍 | 證據 |
| --- | --- | --- |
| `.\gradlew.bat build --offline --console=plain --no-configuration-cache` | 0；NEW compileJava／jar 實際執行，BUILD SUCCESSFUL | [命令／UTC](build-01.json)、[完整 log](build-01.log)、[build.ps1](build.ps1) |
| `powershell -NoProfile -ExecutionPolicy Bypass -File docs/evidence/T-020/test.ps1`（初次） | 1；test javac 的 deprecated valueMap＋-Werror、快取 read／close 限制；未執行測試 | [初次命令](test-commands-01.json)、[原 log](test-compile-01.log)、[初次工具](test-attempt-01.java.txt) |
| `powershell -NoProfile -ExecutionPolicy Bypass -File docs/evidence/T-020/test.ps1 -Attempt 02` | javac 0、java 0；**159 個設定契約檢查通過** | [命令](test-commands-02.json)、[編譯 log](test-compile-02.log)、[執行 log](test-run-02.log)、[逐項結果](test-results.json)、[測試原始碼](test/ConfigContractTest.java) |
| `powershell -NoProfile -ExecutionPolicy Bypass -File docs/evidence/T-020/record.ps1` | 版本、javap、差異命令有各自退出碼；git no-index 的 1 表示存在預期差異 | [完整命令／版本](commands.json)、[腳本](record.ps1)、[bytecode](config-bytecode.txt) |
| `powershell -NoProfile -ExecutionPolicy Bypass -File docs/evidence/T-020/final-check.ps1` | 文件／範圍／歷史／來源的最終靜態核對 | [結果](final-check.json)、[腳本](final-check.ps1)、final-check 命令與 log |

`build` 的 Gradle test 仍為 **NO-SOURCE**；159 項是另行 javac／java 執行的非遊戲測試，不倒填成 Gradle 單元測試。成功 javac 用 `--release 21 -proc:none -Xlint:deprecation -Werror`，改用 entrySet 而非抑制棄用警告；成功 java 有 terminal capabilities 警告，build 有未來 Gradle 10 相容性提示，不宣稱零警告。

文件自查初次退出 1，唯一未通過項是 README 引用尚未生成的 final-check.json；當次 report／命令／log 留存，生成後再核對引用與最終文件。這不表示 build／設定測試失敗，不補造人工或獨立審查結果。

測試只初始化 ConfigSpec／NightConfig 及產品快照，不啟動 Minecraft 或 FML launcher，不載入世界／mod、呼叫 client／server main／GameTest 或派發生命週期事件。ILoadedConfig 是 sealed，測試以 reflection 建立實際 package-private LoadedConfig 的記憶體 fixture，內容先校正、沒有 file path／ModConfig；不呼叫其 save。事件過濾與入口接線是來源／編譯／bytecode／靜態核對，不冒充 FML 實測。

該獨立 JVM 的 Log4j 在測試執行時間產生工作目錄 debug.log／空 latest.log，已以原檔移入 [standalone-logs](standalone-logs)，[時間／原路徑／SHA-256](standalone-logs.json)另存；這些是配置範圍／校正的工具 log，不是 Minecraft 啟動證據。未更改 .gitignore 或刪除既有 log。

## 建置與完成判定

目標 Minecraft 1.21.1、NeoForge 21.1.251、mod 1.0.0／All Rights Reserved；實際 Java／javac 21.0.12.1、Gradle 9.2.1、ModDevGradle 2.0.147。HEAD `8bd977dbb9f9000411ae5f4d10750228e5f33560`＋既有 index／本次未提交差異，固定 [JAR](artifacts/simplerail-1.0.0.jar)／[artifact.json](artifact.json)：SHA-256 `166E7B63AC9E56A83CEFD23448B458F0E221D7059825BDACFE9A541898A9C467`。這是建置證據，不是 T-092 正式測試包。

| T-020 完成條件 | 實際證據／限制 |
| --- | --- |
| 全群組、預設、範圍及有效值可讀 | 25 路徑／預設全對照、兩端合法 bounds／超界／校正、TOML round-trip、所有 snapshot 值及 reload 值通過測試 |
| 不在尚未載入時讀值 | 靜態初始化／註冊不讀 get；獨立 JVM 實際測 pre-load／post-unload current 拒絕、重新載入可讀 |
| 載入／重載策略與兩端用途明列 | 事件三重過濾、volatile immutable snapshot；所有消費者／state 投影／server 權威／現有等待與已排程處理明列 contract |
| 秒數與訊號 tick 分開、D3 不反轉 | snapshot 兩組秒數獨立，20／10 constants 保留；true→enabled／false→false，不增加票證動作；不實作時間換算或舊疑點修正 |
| 配置差異、預設及 build／邊界證據 | source.diff／TOML／原與成功命令 log／159 檢查結果／JAR 及來源雜湊齊備 |

開發條件齊備，僅更新 T-020 為開發完成；R-02 待獨立審查。COMMON 生成／檔案監看／實際事件、client/server 配置差異、新方塊 state 投影、等待／訊號生效及大秒數轉換仍待對應功能實作與使用者驗收（C-003、T-092／T-023、T-030、T-040、T-042 等），不宣稱已上線。D1–D8 及人工確認即可結案規則保留。

未改 Gradle／資源、未執行 OLD build、Minecraft 或 T-021 以後任務；既有 T-019／R-01／框架固定包與人工結果不覆寫。下一個優先開發任務 **T-021**，尚未開始。證據目錄沿用現有 docs/ ignore 規則，未改 .gitignore。
