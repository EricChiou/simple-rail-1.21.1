# T-021 模型、貼圖、語系與 pack 資源交付

2026-09-28。**開發完成；R-02 程式審查待審；人工遊戲未執行**。前置 T-019／T-009／T-015 開發成果已齊；R-01 既有審查不涵蓋本次差異。OLD build 由使用者先前驗證，本次流程不重跑。

## 交付與完成條件

- [114 個 OLD 資源的目標與全部 144 檔處置](resource-map.json)：12 blockstate、40 block model、14 item model、44 貼圖、2 語系、pack／logo 本輪遷移；29 data JSON 留 T-022，舊 Forge metadata 不複製。全部 ID／路徑保留，PNG 位元組不變。
- 九軌引用的 29 模型增加 minecraft:cutout；[新 atlas](../../../src/main/resources/assets/minecraft/atlases/blocks.json)接 43 個 plural blocks／items sprite。雙語各 15 key 保留原值，整理重複 _comment；額外 wrench blockstate／reverse item model 不新增物件。
- pack 保留 description、移除舊 format 6，採 NeoForge 21.1.251 optional-format 策略；原 logo.png 位於 JAR 根，NeoForge template 只開啟 logoFile，保留 D8。未實作車頭 renderer。
- [完整處置及 I-021-01 限制](RESOURCE_DECISIONS.md)、[全部文字差異](resource-text.diff)、[來源指紋](source-fingerprints.json)、[指定版依據／雜湊](source-references.json)。產品 resource tree 共 115 檔（114 遷移＋1 atlas）；沒有修改 Java／Gradle 或開始 T-022。

T-021 的來源去向、引用／雙語／數量與可建置資源交付條件已齊，僅更新開發完成；不簽功能／遊戲通過。**I-021-01：目前 10 個方塊骨架缺 selector 屬性，9 種方塊的候選全部狀態域有模型覆蓋缺口。T-092／T-023 尚不能交付無錯誤載入／變體驗收的包**。本輪保留原變體、不猜斜坡或上下向外觀；依 D6 記後續 state／模型承接與前置調整方向，正式編號／依賴未改，T-022 可獨立繼續。

## 實際命令與結果

| 命令 | 實際結果 | 證據 |
| --- | --- | --- |
| `powershell -NoProfile -ExecutionPolicy Bypass -File docs/evidence/T-021/migrate-resources.ps1` | 0；核對 144 OLD source hash，複製本輪來源並加 29 cutout；pack／atlas／lang／logo 接線另有文字差異 | [腳本](migrate-resources.ps1)、[UTC／範圍](migration-command.json) |
| `powershell -NoProfile -ExecutionPolicy Bypass -File docs/evidence/T-021/audit.ps1 -Attempt 01` | javac 0、java 1；PowerShell 未引用 -D 參數，JVM 誤解析 main 名稱，auditor 未啟動 | [命令](audit-commands-01.json)、[原 log](audit-run-01.log) |
| `powershell -NoProfile -ExecutionPolicy Bypass -File docs/evidence/T-021/audit.ps1 -Attempt 02` | javac 0、java 0；**2519 項靜態檢查、563 次引用／別名檢查、45 PNG 完整解碼通過** | [命令](audit-commands-02.json)、[完整 log](audit-run-02.log)、[逐項結果](audit-results.json)、[工具](audit/ResourceAudit.java) |
| `.\gradlew.bat build --offline --console=plain --no-configuration-cache` | 0，BUILD SUCCESSFUL；processResources／generateModMetadata／jar 實際執行，compileJava UP-TO-DATE | [命令／UTC](build-01.json)、[完整 log](build-01.log)、[腳本](build.ps1) |
| `powershell -NoProfile -ExecutionPolicy Bypass -File docs/evidence/T-021/record.ps1` | 版本／差異命令各自保存退出碼；git no-index 1 為預期存在新檔差異 | [命令與工具版本](commands.json)、[腳本](record.ps1) |
| `powershell -NoProfile -ExecutionPolicy Bypass -File docs/evidence/T-021/final-check.ps1` | 0，27 項文件／JAR／範圍自查通過；非 R-02。第二次只核對最後文件修訂，未重跑 build 或資源 auditor | [結果](final-check.json)、[腳本](final-check.ps1)、[首次命令](final-check-command-01.json)／[log](final-check-01.log)、[最終命令](final-check-command-02.json)／[log](final-check-02.log) |

auditor 用 Java 21 `--release 21 -proc:none -encoding UTF-8 -Xlint:all -Werror`；執行 classpath 只有自身及 Gson 2.10.1，Minecraft 1.21.1 client archive **僅 ZIP 讀取參數**，未加入 classpath或載入遊戲。Java ImageIO 只解碼 PNG、不編修圖片。保存 [classpath／archive hash](audit-classpath.json)、[563 引用](references.json)、[PNG 像素尺寸／雜湊](pngs.json)、[候選狀態覆蓋](state-coverage.json)。引用範圍含 parent 繼承、texture alias、faces 與 atlas 靜態可取得性，未執行 Minecraft codec／baking／stitching。

Gradle `test NO-SOURCE`，2519 項是獨立非遊戲 auditor 結果，不倒填為 Gradle 單元測試。Gradle 的未來版本棄用提示保留；初次 auditor 啟動失敗 log 保存，不將其改寫成功。沒有 runClient／runServer／GameTest／runData 或 OLD build。

## 固定產物與交接

Minecraft 1.21.1／NeoForge 21.1.251，mod 1.0.0／All Rights Reserved；實際 Java／javac 21.0.12.1、Gradle 9.2.1、ModDevGradle 2.0.147。HEAD `8bd977dbb9f9000411ae5f4d10750228e5f33560`＋既有 index／未提交差異；未 stage、commit、reset。原 index／T-001–T-020 歷史、人工確認與固定包不倒填。

[保存 JAR](artifacts/simplerail-1.0.0.jar)／[artifact.json](artifact.json) 的 SHA-256：`3FB257657741F7A0A50EE0879FC92C7F15EB51C1434F2FDBB1EE51AD0B5A96AD`；JAR 逐資源位元組與 metadata／logo／D8 驗證見 [最終自查](final-check.json)。此 JAR 是 build 證據，不是已準備好的 T-092 遊戲包。

使用者 T-023／T-125、renderer 後 T-052 的外觀、透明、UV、logo、pack reload 等要求保留；人工完成只需使用者確認，不要求附件。本輪不把 T-018／T-089 舊人工結果套到此新 JAR，也不自簽 R-02。下一個優先開發任務 **T-022**，尚未開始；需先處理 I-021-01 才能交付相應功能人工包。證據目錄仍受現有 docs/ ignore 規則管理，未改 .gitignore。
