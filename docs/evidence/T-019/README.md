# T-019 註冊骨架交付

2026-09-28。**開發完成；R-02 程式審查待審；本項未執行人工遊戲**。前置 T-017／T-008／T-010 開發交付及 T-004 已齊；R-01 通過只適用原有框架／研究／固定包，不延伸到本次程式差異。

## 交付與明確界線

- [ModBlocks](../../../src/main/java/com/ericchiu/simplerail/registry/ModBlocks.java)：11 方塊，以普通 Block 暫時承接 ID。
- [ModItems](../../../src/main/java/com/ericchiu/simplerail/registry/ModItems.java)：11 同 ID／同方塊 supplier 的 BlockItem、wrench 及 locomotive_cart，共 13。
- [ModCreativeTabs](../../../src/main/java/com/ericchiu/simplerail/registry/ModCreativeTabs.java)：新分頁 `simplerail:tab`，保留舊翻譯鍵，圖示 high_speed_rail，明列 13 物品；[common 入口](../../../src/main/java/com/ericchiu/simplerail/SimpleRail.java) 接三個 registry 到 mod bus。
- [ID 名冊／BlockItem 配對／分頁順序與 18 項靜態檢查](checks.json)、[完整屬性及未實作清單](state-contract.md)、[來源指紋](source-fingerprints.json)、[本次產品差異](source.diff)。destory_rail 未更名；reverse 模型與 wrench blockstate 未新增註冊。

**骨架尚無軌道、紅石、扳手右鍵、車頭生成、專用 BE／27 格 GUI、計時、存讀、同步或票證功能；尚未宣告自訂方塊 state。** 名稱／完整值域與候選 default 以屬性表交付；待各既有後續任務實作，保留 T-010 未決項。T-020 正式設定、T-021／T-022 資源及全部功能／測試包均未開始。不要拿此 JAR 驗收正式玩法或將普通 Block 的形狀當需求。

## 實際驗證

| 命令／範圍 | 退出碼及結果 | 證據 |
| --- | --- | --- |
| `.\gradlew.bat build --offline --console=plain --no-configuration-cache` | 0，BUILD SUCCESSFUL；compileJava／jar 實際執行 | [命令與 UTC](build-01.json)、[完整 log，UTF-16LE](build-01.log)、[記錄腳本](build.ps1) |
| `powershell -NoProfile -ExecutionPolicy Bypass -File docs/evidence/T-019/verify.ps1` | 0，18 項靜態核對通過 | [命令](verify-01.json)、[log](verify-01.log)、[檢查腳本](verify.ps1)、[逐項結果](checks.json) |
| `powershell -NoProfile -ExecutionPolicy Bypass -File docs/evidence/T-019/final-check.ps1` | 最終退出 0；126 編號、九階段／覆蓋／依賴無循環／引用／範圍及原 index／歷史證據核對通過 | [最終結果](final-check.json)、[腳本](final-check.ps1)、final-check 各次命令及 log |

build 使用已允許的既有 Gradle 快取（離線），沒有 OLD build、下載舊工具鏈、runClient／runServer／GameTest／runData。`test NO-SOURCE`，不能稱單元測試通過；Gradle 有未來 Gradle 10 相容性提示，不宣稱零警告。靜態工具比對 T-010 固定 OLD I18n.java 的 11＋2 ID、實際產品宣告及 JAR 結構／D8 metadata；未載入 Minecraft、實例化 registry 或輸出 runtime dump。

最終文件自查的前兩次退出 1，原因是查核腳本的 PowerShell JSON array 包裝及 git no-index「有差異」退出碼處理，並非產品 build 失敗或歷史檔遭更動；失敗 log／命令、第一次結果與原腳本均保存。修正查核工具後退出 0，確認 R-01 manifest 的 158 份既有證據雜湊不變。沒有因工具修正重建產品或重跑遊戲。

固定環境為 Minecraft 1.21.1、NeoForge 21.1.251、Java 21（Temurin 21.0.12.1）、Gradle 9.2.1、ModDevGradle 2.0.147，mod 1.0.0／All Rights Reserved。HEAD `8bd977dbb9f9000411ae5f4d10750228e5f33560` 加既有 index 與本次未提交差異；[原有 index 清單](preexisting-index.txt)保留，未 stage、commit 或 reset。工具命令／版本見 [commands.json](commands.json)。

NEW JAR：[保存的產物](artifacts/simplerail-1.0.0.jar)；SHA-256：`7AEB033B7B5949E89005DC8B65DF73D93272BCCB430D81F80DE516248ECF9C9D`。保存 [JAR 名冊](jar-contents.txt)、[metadata](neoforge.mods.toml)及 [註冊 bytecode](registry-bytecode.txt)。JAR 是本項建置證據，不是 T-092 使用者測試包；不覆寫 T-090-v1／T-091-v1 原包或替其重填人工結果。

## 完成條件判定與交接

| T-019 條件 | 實際判定／界線 |
| --- | --- |
| 11 方塊、13 物品及全部既有 ID 一致 | 靜態 ID／數量／唯一性與全部 BlockItem 配對通過；不宣稱 runtime registry 已測 |
| destory_rail 保留、reverse 不另註冊 | 通過靜態契約檢查 |
| 分頁 high_speed_rail 圖示、全部物品 | 程式定義及編譯符合；實際 GUI／可取得性待使用者 T-023 |
| 可編譯骨架、registry 對照與屬性表 | build 退出 0，交付 checks.json／state-contract.md；未實作項目明列 |

開發條件與證據齊備，僅更新 T-019 為開發完成。R-02 獨立審查檢查 deferred 時序、完整 ID、屬性邊界與後續資源契約；使用者 T-023 等依後續固定包確認遊戲結果，不要求提交證據。D1–D8 不變，OLD build 由使用者先前驗證，本次流程不重跑。下一個優先開發任務是 T-020，本輪未開始；T-021／T-022 的技術前置亦已齊，但不提前執行。

本證據目錄沿用原 `docs/` ignore 規則，未修改 .gitignore；產品及三份規劃文件仍可由 git diff 審閱，原有 staged 差異未重設。
