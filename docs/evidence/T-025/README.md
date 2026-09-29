# T-025 開發交付與證據

2026-09-28，僅執行 T-025。**開發完成；R-03 程式審查待審；人工遊戲未執行。** 自身條件是可編譯的兩種共用基底／高速軌道及明確速度、禁坡與實體破壞實作，不含 T-026 人工验收／T-094 包製作。對應 MIGRATION.md §3／§6 階段 3。

## 工作差異與版本

新增 BaseRail、BasePoweredRail、HighSpeedRail；ModBlocks 僅將 high_speed_rail 改成正式延遲工廠，其餘十個註冊維持。两基底每次讀一次速度快照、禁坡／實體破壞回 false；動力基底傳 true。沿用父類 shape／powered／waterlogged、紅石與動力，不照搬 T-010 探針其他 shape 限制。

新增 vanilla mineable/pickaxe 附加 tag，只分類已實作高速軌道以替代 OLD harvestTool(PICKAXE)，不新增工具掉落限制。既有模型／配方／loot／語系／貼圖／Gradle／metadata 均未變。三份規劃文件同步交付，舊證據及凍結包不重寫。

| 項目 | 實際輸入／產物 |
| --- | --- |
| OLD／NEW | D:/workspace/java/simple-rail／D:/workspace/java/simple-rail-1.21.1 |
| NEW HEAD | 8bd977dbb9f9000411ae5f4d10750228e5f33560，加未提交產品差異；無新 commit |
| 工具／映射 | Temurin 21.0.12.1+1、Gradle 9.2.1、ModDevGradle 2.0.147、Parchment 2024.11.17／1.21.1 |
| 目標 | Minecraft 1.21.1、NeoForge 21.1.251、simplerail 1.0.0、All Rights Reserved |
| 固定 JAR | [artifacts/simplerail-1.0.0.jar](artifacts/simplerail-1.0.0.jar) |
| SHA-256 | 2C72767500EDCF8F693FAB2EA874F77F52F3A949BBDF9F0DA10D20C008702BC0 |

[產物](artifact.json)、[行為對照](RAIL_CONTRACT.md)、[13 個來源指紋](source-references.json)界定版本與證據。OLD 均為「依原始碼推定／待確認」。**OLD build 由使用者先前驗證，本次流程不重跑。**

## 實際命令與結果

| 命令 | 退出碼／結果 | 證據 |
| --- | --- | --- |
| git rev-parse HEAD；git status --short；git diff --cached --binary | NEW 成功，index 未改。status 在產品編修後、build 前取得，不冒充初始無變更狀態 | [HEAD](head.txt)、[status](git-status-before.txt)、[編修前產品指紋](inputs-before.json)、[index](index-before.diff) |
| git -C D:/workspace/java/simple-rail rev-parse HEAD | 首次 1，OLD ownership 拒絕；非 build 失敗 | [原始失敗](old-head-attempt-01.log) |
| git -c safe.directory=D:/workspace/java/simple-rail -C D:/workspace/java/simple-rail rev-parse HEAD | 重試 0，單次覆蓋，無 Git config／OLD 變更 | [命令／退出碼](preparation.json)、[OLD HEAD](old-head.txt) |
| java -version | 0，Temurin 21.0.12.1+1 | [版本](java-version.log) |
| powershell -NoProfile -ExecutionPolicy Bypass -File docs/evidence/T-025/build.ps1；內部 .\gradlew.bat build --offline --console=plain --no-configuration-cache | 0，NEW BUILD SUCCESSFUL；test NO-SOURCE，無單元測試執行 | [完整 log](build-01.log)、[命令／時間／退出碼](build-01.json) |
| powershell -NoProfile -ExecutionPolicy Bypass -File docs/evidence/T-025/audit.ps1 | 0，40／40 靜態核對通過 | [log](audit-01.log)、[結果](audit-results-01.json)、[內部命令](audit-commands-01.json) |
| javap -c -p -s -v -classpath build/classes/java/main 四個類別 | 各 0，反組譯而不載入 Minecraft | [BaseRail](BaseRail-bytecode.txt)、[BasePoweredRail](BasePoweredRail-bytecode.txt)、[HighSpeedRail](HighSpeedRail-bytecode.txt)、[ModBlocks](ModBlocks-bytecode.txt) |
| git -c core.safecrlf=false diff --check | 0 | [log](diff-check.log) |
| git diff HEAD --binary；逐 untracked source 用 git diff --no-index --binary -- NUL | HEAD diff 0；no-index 1 代表差異，非編譯失敗；包含先前未提交範圍 | [完整差異](source.diff)、[本輪註冊差異](T-025-registration.diff)、[產品指紋](source-fingerprints.json) |
| powershell -NoProfile -ExecutionPolicy Bypass -File docs/evidence/T-025/final-check.ps1 | 首次 1：檢查工具誤讀陣列 Count，而非各階段 count 欄位；修正工具後退出 0，不更改任務／依賴／產品以迎合檢查 | [初次 log](final-check-01.log)、[原始失敗結果](final-check-attempt-01.json)、[最終 log](final-check-02.log)、[最終結果](final-check.json) |

40 項是非遊戲靜態契約自查，不是單元／遊戲測試或獨立 Review。未呼叫 rail hook、執行 codec、初始化 registry／世界、載入資源包或量測速度。JAR 的 145 個來源資源、rail class 與 D8 metadata 已核對。本 JAR 是開發證據，非已交接 T-094 包或候選發行版。

## 自身完成条件及限制

| T-025 要求 | 判定 |
| --- | --- |
| 兩種基底／高速軌道可編譯 | NEW build 0，class／JAR 保存 |
| 回呼／狀態對上 API，速度／坡度／破壞規則明確 | [對照](RAIL_CONTRACT.md)及 bytecode；父類預設／域為來源推論，非 runtime 結果 |
| 不改其他軌道玩法 | 既有產品指紋只 ModBlocks 改變，其餘註冊／資源不變 |
| 差異／build log／行為對照完整 | 來源、Git diff、原始 log、產物／雜湊保存 |
| 狀態與歷史不冒充通過 | [最終核對](final-check.json)；僅 T-025 開發完成，R-03 待審、人工未測 |

I-021-01 仍在，高速平軌 selector 已接上但 16 個宣告升坡組合仍缺模型；I-092-02 全設定有效值／reload 觀測未齊。未改正式依賴或先修模型。速度三點、禁坡、事件、供電／連接與 cutout 待使用者 T-026；誤差待 T-094 定義。T-092 仍受阻、T-023／T-024 未交接；舊包與 T-018／T-089 確認不能套到新 JAR。

下一個優先功能開發 T-027；T-094 亦有開發輸入，本輪均未執行。R-03 另由獨立審查者記錄；T-026 由使用者操作確認。未重跑 OLD／Minecraft／其他任務，無 stage／reset／commit。
