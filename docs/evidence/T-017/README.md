# T-017 正式入口與 client／common 邊界證據

執行範圍：NEW `D:/workspace/java/simple-rail-1.21.1`，HEAD `8bd977dbb9f9000411ae5f4d10750228e5f33560`，2026-09-28（Asia/Taipei）。前置 T-005／T-008 已有各自證據。本項只整理空功能框架；沒有啟動 Minecraft，也沒有執行 T-018、T-089 或功能遷移。

## 差異與移除清單

- `src/main/java/com/ericchiu/simplerail/SimpleRail.java`：保留 `@Mod`、`simplerail` ID 及可注入的模組事件匯流排建構子；移除範例方塊、物品、創造分頁的註冊，範例 common setup、創造分頁／server 事件監聽及範例設定註冊。後續功能任務再接各自 listener／registry。
- `src/main/java/com/ericchiu/simplerail/SimpleRailClient.java`：保留 `Dist.CLIENT` 限定的入口；移除範例設定畫面與 client setup 日誌。common 入口不引用 client 類別或 client API。
- `src/main/java/com/ericchiu/simplerail/Config.java`：移除全部模板設定，原檔沒有產品設定。
- `src/main/resources/assets/simplerail/lang/en_us.json`：移除模板物件與設定畫面翻譯，保留合法空 JSON；正式語系由 T-021 及後續任務移植。
- 移除前查詢 `rg -n -i 'example_|intermod|imc|Config\.' src/main`：只找到上述模板註冊／設定／翻譯；**未找到原有自送 IMC 程式**，因此無可刪的 IMC 呼叫。保留既有 `gradle.properties` 與模組 TOML 模板的有效 D8 值，未修改 Gradle。

差異原文見 [source.diff](source.diff)。`git diff --check` 退出碼 0，見 [command-checks.json](command-checks.json)。預先存在的 `.gitignore`、MIGRATION.md、REVIEW.md、TASK.md 工作樹／索引狀態未重設或暫存。

## 建置與靜態檢查

| 命令 | 結果與證據 |
| --- | --- |
| `.\gradlew.bat build --offline --console=plain --no-configuration-cache`（沙箱） | 退出 1；Gradle Wrapper 不能建立工作區外快取鎖檔，未進入編譯。[命令資料](build-01.json)、[原始 log](build-01.log) |
| 同命令（允許沙箱外重試） | 退出 0；`BUILD SUCCESSFUL`，`compileJava`、`processResources`、`jar` 已執行。[命令資料](build-02.json)、[原始 log](build-02.log) |
| `powershell -NoProfile -ExecutionPolicy Bypass -File docs/evidence/T-017/verify.ps1` | 退出 0；入口 ID／事件匯流排注入、client dist 邊界、無範例註冊／設定／翻譯、JSON 有效、JAR 類別及 D8 metadata 全部靜態檢查為 true。[腳本](verify.ps1)、[結果](checks.json) |
| `git -c core.safecrlf=false diff --check -- src/main/java/com/ericchiu/simplerail src/main/resources/assets/simplerail/lang/en_us.json` | 退出 0；無差異空白錯誤。[命令資料](command-checks.json) |

產物為 `build/libs/simplerail-1.0.0.jar`，SHA-256 `537780CB1E3C2B532AF7F22BEC1AA306C0966AFD6C571CC5D2936275B66C3A36`；[JAR 目錄](jar-contents.txt)只有兩個模組 class，沒有 `Config.class`；[產物 metadata](jar-metadata.toml)仍宣告 `simplerail`、`1.0.0`、`All Rights Reserved`、NeoForge `[21.1.251,)`、Minecraft `[1.21.1]`。Gradle 的 `test` 為 `NO-SOURCE`，不能記為自動化測試通過。TOML 仍有模板說明註解，非啟用的範例註冊；正式資源與發行整理屬後續任務。

## 完成條件與限制

T-017 的三項完成條件有對應證據：build 退出 0；產品來源沒有 `example_block`／`example_item`／`example_tab` 註冊；common 入口沒有對 client-only 類別的直接依賴。**開發完成，R-01 獨立程式審查待審，人工遊戲未執行**。編譯與 JAR 靜態內容不證明 runtime mod 載入或實際兩端啟動；T-018 依 T-091 測試包交由使用者驗證，T-089 連線另待 T-090 與使用者回報。T-019 的註冊與其他功能尚未開始。
