# T-090-v1：T-089 單 client 連線操作包

包製作日期：2026-09-28（Asia/Taipei）。用途：NEW 正式空功能框架的單 client 連線，對應 TASK.md T-090 → T-089、MIGRATION.md §3 入口／網路與 §6 階段 1、REVIEW.md R-01／C-09。T-004 的 C-040 展開為 [CASES.md](CASES.md) 五個子案例。

本包已完成 build 與靜態封裝檢查；**R-01 獨立程式審查待審，未簽程式審查通過**。此包沒有 Agent 遊戲執行結果。T-089 已依使用者先前確認結案，不要求重測或補交資料；本次製作是補齊 T-090 開發交付，不把先前回報填入本包的逐例結果或推定受測 JAR 身分。

## 固定版本與檔案

| 項目 | 固定值 |
| --- | --- |
| Minecraft／NeoForge | 1.21.1／21.1.251 |
| Simple Rail／授權 | 1.0.0／All Rights Reserved |
| runtime Java | Java 21，64 位元；本次 build 為 Temurin 21.0.12.1+1 |
| 建置工具／mappings | Gradle 9.2.1、ModDevGradle 2.0.147、Parchment 1.21.1／2024.11.17 |
| HEAD | 8bd977dbb9f9000411ae5f4d10750228e5f33560；包含未提交產品差異，不是 clean commit |
| JAR | `mods/simplerail-1.0.0.jar` |
| JAR SHA-256 | `537780CB1E3C2B532AF7F22BEC1AA306C0966AFD6C571CC5D2936275B66C3A36` |

[manifest.json](manifest.json) 記錄版本、任務、審查狀態與案例；[evidence/source.diff](evidence/source.diff) 保存相對 HEAD 的產品差異，[evidence/source-fingerprints.json](evidence/source-fingerprints.json) 記錄產品輸入指紋。[evidence/build-01.log](evidence/build-01.log) 及 [evidence/commands.json](evidence/commands.json) 保存實際命令／版本／退出碼；build 退出 0，`test NO-SOURCE`，不是自動化程式測試通過。JAR metadata 與內容目錄另在 evidence 內。`files-manifest.json` 可核對包內檔案雜湊。

## 操作與回報

使用 [INSTALL.md](INSTALL.md) 安裝固定版 client／server，再照 [CASES.md](CASES.md) 執行。安裝與遊戲操作均由使用者自行執行；本包不含遊戲、NeoForge installer、既有世界或已同意的 EULA 檔案，不需要 OLD build 或外部模組。

`results.json` 的實際結果欄為空。日後若選擇操作此包，只需回覆「T-089 完成／通過」或具體失敗項；版本、log、畫面及逐例資料皆可選擇提供，無需提交證據。這份包不要求重開已結案的 T-089；不涵蓋雙 client、列車、GUI、計時、票證或候選發行驗收。
