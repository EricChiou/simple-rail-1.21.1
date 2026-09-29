# T-027 holding_rail 停車／放行交付

日期：2026-09-29。**T-027 開發完成；R-03 程式審查待審；T-028 人工未執行；T-095 全量包未執行。** 只實作本任務，不宣稱停車軌功能已完成全部交付驗收。前置 T-025／T-010／T-020 的開發輸入已齊；T-026 使用者通過保留。

## 實作與完成判定

新增 [HoldingRail](../../../src/main/java/com/ericchiu/simplerail/block/HoldingRail.java)，註冊同 holding_rail ID；方向保存於 direction blockstate，未供電歸零並停在方塊底部中心。父類處理電力後讀回狀態，在 false→true 時把單格 AABB 的所有礦車依保存方向×0.4 放行。修改只在 server；共用速度／禁坡／實體破壞、原版 powered 性質及同步管線繼承，pickaxe tag 僅附加本 ID。

[來源行為／指定版 API／時序差異／未測範圍](RAIL_CONTRACT.md)明列 OLD 源碼推論與 NEW 適配。沒有舊世界轉換、外部模組、票證／計時／車頭變更；D1–D8 不變。產品僅新增一類、修改 ModBlocks 與 pickaxe tag，其他資源與 Gradle 不動。

T-027 自身完成條件已具備：實際 API 編譯／NEW build 通過；狀態、共用設定、過車／紅石回呼均有固定來源與差異對照；保存程式差異、build、固定 JAR／指紋與非遊戲核對。人工與獨立程式審查仍待执行，不以本項 build 代替 T-028。

## 命令、實際結果與證據

| 實際命令 | 结果 | 證據 |
| --- | --- | --- |
| powershell -NoProfile -ExecutionPolicy Bypass -File docs/evidence/T-027/build.ps1 | NEW build 退出 0；Gradle test NO-SOURCE，未執行 Gradle 單元測試 | [命令／時間](build-01.json)、[log](build-01.log) |
| powershell -NoProfile -ExecutionPolicy Bypass -File docs/evidence/T-027/hooks-test.ps1 | 隔離 javac／java 各退出 0，85 項判定通過；實際產品 hook 原始碼搭配本機測試替身，未載入真實 Minecraft | [測試](HoldingRailHooksTest.java)、[生成替身與命令](hooks-test.ps1)、[結果 metadata](hooks-test.json)、[log](hooks-test-01.log)、[替身指紋](test-double-fingerprints.json) |
| powershell -NoProfile -ExecutionPolicy Bypass -File docs/evidence/T-027/audit.ps1 | 最終退出 0，175 靜態／JAR／範圍核對通過，含 149 資源逐檔與來源相同 | [結果](audit-results-01.json)、[log](audit-02.log)、[實際 bytecode](HoldingRail-bytecode.txt)、[144 狀態表](state-coverage.json) |
| 初次 audit.ps1 | 退出 1：ID 比較的 PowerShell -join 優先順序產生字串而非 bool，工具中止；修工具分開比較後通過，產品無修改 | [原腳本](audit-attempt-01.ps1)、[原 log](audit-01.log) |
| git diff HEAD --binary；git diff --no-index --binary -- NUL HoldingRail.java | 前者 0，新增檔 no-index 1 為有差異的正常結果；未 stage／reset／commit | [完整產品來源差異](source.diff)、[指紋](source-fingerprints.json)、[範圍核對](audit-results-01.json) |
| powershell -NoProfile -ExecutionPolicy Bypass -File docs/evidence/T-027/doc-check.ps1 | 退出 0，18 項文件／編號／依賴／階段／覆蓋／歷史／Markdown／產品及 index 核對通過 | [結果](doc-check.json)、[log](doc-check-01.log) |

建置版本：Minecraft 1.21.1、NeoForge 21.1.251、mod 1.0.0、All Rights Reserved；Java toolchain 21、隔離測試 Temurin 21.0.12.1+1、Gradle 9.2.1、ModDevGradle 2.0.147、Parchment 2024.11.17。HEAD 8bd977dbb9f9000411ae5f4d10750228e5f33560，工作樹未提交，不虛構新 commit。Gradle 有未來 10 版相容性提示，不宣稱零警告。

[固定 JAR](artifacts/simplerail-1.0.0.jar) SHA-256：**DE13BF73E4A79E32A656CEEBD052C61E042B342D8886050AC71330E6EDF78D35**，見 [產物 metadata](artifact.json)。舊固定 JAR／包不覆寫，本固定 JAR 尚非已人工驗收的候選版本。沒有額外執行 build／遊戲／OLD／runData 或 T-095 封裝。

隔離測試原 metadata 描述誤寫 16 個替身，依實際生成的 15 個 Java 檔校正描述，[原 metadata](hooks-test-original-metadata.json)保留；没有重跑測試或修改 85 項判定結果。

## 待審與下一步

R-03 應審六向狀態／預設、parent→readback→rising edge 時序、重入與 stale state、單格多車範圍、server guard、保存／同步設計及 C-008／T-028 覆蓋。開發不自簽 Review、不代跑 Minecraft；現有人工通過紀錄不跨版本改寫。

T-095 依本來源／JAR與 T-028 規格製作固定操作包，T-028 由使用者執行；本輪未開始。下一個可獨立功能開發為 T-029，也未開始。I-021-01 其他狀態／模型及 I-092-02 設定觀測缺口保留，T-092 仍受阻，T-023／T-024 不整體解鎖。
