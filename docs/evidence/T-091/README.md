# T-091 開發交付：正式框架固定版本包

2026-09-28（Asia/Taipei）；前置 T-017 開發已完成。**T-091 開發完成；R-01 獨立程式審查待審。** [T-091-v1 ZIP](../../test-packages/T-091-v1.zip) 與 [包內說明](../../test-packages/T-091-v1/README.md)已製作，對應 T-018、T-004 C-039／C-040、MIGRATION.md §3 入口／生命週期、§6 階段 1，R-01／C-01／C-09。

本項與 T-090 共用同一次 NEW 離線 build；[命令／退出碼](../T-090/commands.json)、[build 原始 log](../T-090/build-01.log)、[封裝成功命令](../T-090/package-03.json)及[來源指紋](../T-090/source-fingerprints.json)保留，未虛構第二次獨立 build。工具命令與 build 退出 0，Java／javac 21.0.12.1、Gradle 9.2.1、ModDevGradle 2.0.147、MC 1.21.1、NeoForge 21.1.251、Parchment 1.21.1／2024.11.17。`test NO-SOURCE`，不稱自動化程式測試通過；未啟動 Minecraft、installer 或 OLD。

包內使用正式空框架 `simplerail-1.0.0.jar`，SHA-256 `537780CB1E3C2B532AF7F22BEC1AA306C0966AFD6C571CC5D2936275B66C3A36`；與 T-017／T-090 相同。HEAD `8bd977dbb9f9000411ae5f4d10750228e5f33560`，工作差異／指紋附在包內，並非 clean commit。D8 metadata、兩個入口 class、無範例設定 class、ZIP 逐檔 hash、複製 JAR 及未填結果均由封裝腳本檢查，[packages.json](packages.json)記錄兩包成功結果；封裝失敗嘗試由 T-090 保存，不混為通過。

五個案例完整涵蓋 metadata／入口、client 新世界操作／保存／停止、範例物品／分頁清除、dedicated server 新世界／保存／停止、server registry 與 client-only 載入邊界。包含安裝與啟動步驟、獨立 NEW 場景、逐例預期、選用 log／F2 方法、確認格式，以及空白 `results.json`。沒有計時／速度門檻適用於這些框架案例，未預填未知 API 或 runtime 結果。R-01 審查待審獨立標示；完成條件為本項開發包交付，不等於程式審查或新包人工測試通過。

ZIP SHA-256 `491357371F052A18637E7AC7157B2C78EB8F13C857D1153C8B1EDD6523EE3D1A`；16 檔、5 案例。T-018 的使用者先前確認與結案保留，不要求重測或補證，不自行將其綁定此包。產品程式、Gradle、資源指紋未改；本輪只完成 T-090／T-091，沒有開始 T-019。包固定後不覆寫；既有 `docs/` 忽略規則保留，檔案在本機工作區。
