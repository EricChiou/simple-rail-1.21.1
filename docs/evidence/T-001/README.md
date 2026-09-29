# T-001 證據：OLD／NEW Git 與工具鏈

- 執行日期：2026-09-26（Asia/Taipei，UTC+08:00）。
- 查詢時間：原始紀錄 C01–C23 自 07:59:53 UTC 起；C24 在 11:43:05 UTC 提交，C25–C28 在 11:44:50 UTC 提交。時間間隔不是建置耗時。
- 結論：**T-001 環境盤點完成**。不代表 OLD／NEW 建置、API 或遊戲驗收通過。
- 使用者已審閱 TASK.md，這一輪僅授權 T-001；未執行 T-002–T-088。
- [原始命令、版本輸出、時間、退出碼](commands.json)；[後續處理與依賴調整草案](FOLLOW_UP_DRAFT.md)。以下 C 編號對應原始紀錄。
- 查詢腳本以 PowerShell 執行。C13 的 0 表示盤點腳本完成，不代表其中每個候選工具都存在；沒有輸出的工具另列為未找到。

## Git 狀態與指南差異

| 項目 | OLD | NEW | 證據 |
| --- | --- | --- | --- |
| 路徑 | D:/workspace/java/simple-rail | D:/workspace/java/simple-rail-1.21.1 | C01、C07 |
| 分支 | main | main | C03、C09 |
| HEAD | 6698b1c5f494095a15b055c10045293e91540012 | 8bd977dbb9f9000411ae5f4d10750228e5f33560 | C02、C08 |
| 盤點開始時暫存變更 | 無 | 新增 MIGRATION.md，246 行 | C04、C06、C10、C12 |
| 盤點開始時追蹤檔未暫存變更 | 無 | 無 | C04–C05、C10–C11 |
| 盤點開始時未追蹤檔 | 無 | TASK.md | C04、C10 |
| 對照 MIGRATION.md | HEAD 相符；工作目錄仍乾淨 | HEAD 相符；指南初次盤點時乾淨，現在已有上述文件變更 | C01–C12 |

未執行 add、commit、reset、checkout 或清除工作目錄。本輪只更新 TASK.md 狀態及加入本證據目錄，不修改 MIGRATION.md、Java、Gradle 或資源。

結束查詢 C29–C32（11:50:22 UTC）顯示 OLD 仍乾淨；NEW 的 MIGRATION.md 仍為已暫存新增，且工作內容與 index 無差異。另觀察到 TASK.md 已變成 `AM`（已暫存版本加上本輪工作區修改），以及未追蹤的 REVIEW.md；這兩項 Git 狀態相較起始已有變化，本輪沒有執行暫存操作，也沒有讀寫 REVIEW.md。保留這些同步發生的工作狀態，不歸因為本輪工具鏈修改或予以還原。新增的三份 T-001 證據檔均為未追蹤文件。

## 工具鏈：宣告值與實際可用工具

| 項目 | OLD 宣告 | NEW 宣告 | 本輪實測／差異 |
| --- | --- | --- | --- |
| Minecraft／載入器 | 1.16.5／Forge 36.1.0 | 1.21.1／NeoForge 21.1.251 | 設定與指南相符；未解析載入器 artifact 或啟動遊戲 |
| Java toolchain | 8 | 21 | 預設 java／javac 均為 21.0.12.1；OLD 所需 Java 8 在本輪列明位置未找到，NEW 所需主版本可用 |
| Wrapper distribution | Gradle 6.8.1-all | Gradle 9.2.1-bin | OLD 只有宣告，所查快取未見 6.8.1；NEW 沙箱外 --version 回報 9.2.1，退出碼 0 |
| Gradle 外掛 | ForgeGradle 4.1.+ | ModDevGradle 2.0.147；Foojay resolver 1.0.0 | 宣告與指南相符；沒有解析外掛，4.1.+ 的實際選定版本仍待 T-002 |
| mappings | official 1.16.5 | Parchment 1.21.1／2024.11.17 | 宣告相符；下載與解析可用性未驗證 |
| 模組識別 | simplerail／1.16.5-0.3.25／ericchiu.simplerail | simplerail／1.0.0／com.ericchiu.simplerail | 宣告相符 |
| 授權宣告 | mods.toml：MIT | gradle.properties：All Rights Reserved | 沿用指南紀錄及 D8，不變更 |
| Gradle 啟動 Java | Wrapper 使用 JAVA_HOME，未設定時才用 PATH | 同左 | 目前 JAVA_HOME 與 PATH 首選均指向 JDK 21；OLD 的 Java 8 toolchain 宣告不等於 Wrapper 會自動用 Java 8 啟動 |
| 獨立 gradle 指令 | 不要求，使用 Wrapper | 不要求，使用 Wrapper | PATH 查詢未找到 gradle，不等於 Wrapper 不可用 |
| 設定／CI | 無 settings.gradle；Xmx3G，daemon=false | settings.gradle；Xmx1G，daemon／parallel／cache 開啟；CI 宣告 JDK 21＋build | 僅讀取宣告；CI 未執行 |

宣告依據是 C17／C18 中的 build.gradle、gradle.properties、Wrapper properties、模組描述檔、NEW settings.gradle／CI；Java 與 PATH 依據 C13–C16、C19–C20、C25–C26。

| 實際工具／環境 | 查詢結果 | 退出碼／證據 |
| --- | --- | --- |
| Git | 2.55.0.windows.5；C:/Program Files/Git/cmd/git.exe | 0，C13–C14 |
| PowerShell | 5.1.26100.9444 | 0，C13 |
| 預設 java | Temurin 21.0.12.1+1-LTS | 0，C15 |
| 預設 javac | 21.0.12.1 | 0，C16 |
| 另一套已找到的 Java | Temurin 25.0.4.1+1-LTS；未拿來代替 OLD／NEW toolchain | 0，C20 |
| OS／架構 | Windows 11／amd64；Gradle 回報 Windows 11 10.0 amd64 | 0，C24–C25 |
| JAVA_HOME | C:/Program Files/Eclipse Adoptium/jdk-21.0.12.101-hotspot/ | C13、C26 |
| GRADLE_USER_HOME 環境變數 | 未設定 | C13、C26 |
| 沙箱內 Java user.home | C:/ | 0，C25 |
| NEW Wrapper 實際版本 | Gradle 9.2.1；Launcher JVM 21.0.12.1；Daemon JVM 顯示同套 JDK 路徑 | 0，C24；此為 --version 輸出，不是 daemon／build／遊戲已啟動的證據 |

Java 8 的查找範圍：PATH、JAVA_HOME、常見 Program Files JDK 目錄、USERPROFILE/.jdks、USERPROFILE/.gradle/jdks、C:/.gradle/jdks，以及兩個 JavaSoft 登錄根目錄。C19／C26 保存具體位置與輸出；**未找到不等於已掃描整台電腦並證明不存在**。非標準目錄的 Java 8 路徑仍可在後續環境處理中補充。

## Wrapper 查詢結果與環境限制

1. **C23，NEW：** `.\gradlew.bat --version`，沙箱內退出碼 **1**。錯誤為無法建立 `C:\.gradle\wrapper\dists\gradle-9.2.1-bin\…\gradle-9.2.1-bin.zip.lck` 的父目錄。C25 顯示沙箱內 Java `user.home=C:\`，可說明其目標快取路徑。
2. **C24，NEW：** 經允許在沙箱外執行同一條 `--version` 命令，退出碼 **0**，回報 **Gradle 9.2.1**。原始失敗保留，不改寫為第一次即成功；此結果也不代表沙箱內的鎖檔問題已修好。
3. **OLD：** `.\gradlew.bat --version` **未執行，退出碼不適用**。C19／C26 所查快取只見使用者目錄中的 `gradle-9.2.1-bin`，未見 `gradle-6.8.1-all`；為維持本輪盤點範圍，沒有觸發 OLD Wrapper 下載、安裝 JDK、切換 JAVA_HOME 或嘗試建置。OLD 實際可啟動的 Gradle 版本仍未驗證。
4. C26 在沙箱內未見 `C:/.gradle`，但看得到 `C:/Users/Kinoko/.gradle/wrapper/dists/gradle-9.2.1-bin`。沙箱外成功的實際 user.home／快取選擇未另外量測，不能把沙箱內外環境當成完全相同。

本輪沒有執行 build、tasks、dependencies、javaToolchains、runClient、runServer 或資料產生任務，沒有解析 ForgeGradle／NeoForge API。OLD 的 Java 8 與 distribution 缺口是**就緒風險**，不是已執行 T-002 的 build 失敗結果。

## 未修改程式碼、Gradle 與資源的核對

以 Git 追蹤的 src/、gradle/、build.gradle、settings.gradle、gradle.properties、gradlew／gradlew.bat 路徑排序，將「路徑＋檔案 SHA-256」合併後計算 aggregate SHA-256。C21／C22 為前值，C27／C28 為 Wrapper 查詢後值；實際命令均保留於 commands.json。

| 專案 | 檔案數 | 前後相同的 aggregate SHA-256 |
| --- | --- | --- |
| OLD | 192 | 148DAC137A1750F09FA59CABEA18532EBE38AE047E5D99E9BEE47CC8CB9D80D5 |
| NEW | 12 | DF9C031FC6857183D8D0569D629F7E7B52D3DE294E64668EF261E18CE8102749 |

Wrapper JAR 指紋（只記錄本地檔案，不宣稱已做供應來源驗證）：

- OLD：E55E7E47A79E04C26363805B31E2F40B7A9CC89EA12113BE7DE750A3B2CEDE85。
- NEW：7D3A4AC4DE1C32B59BC6A4EB8ECB8E612CCD0CF1AE1E99F66902DA64DF296172。

## 完成條件判定

| T-001 完成條件 | 判定與依據 |
| --- | --- |
| OLD／NEW 的 Git 路徑、HEAD、分支與變更狀態有記錄 | 已記錄，C01–C12；原有文件變更未被重設 |
| 宣告 toolchain／Wrapper／外掛／mappings 與實際工具均有記錄 | 已記錄，C13–C20、C23–C26；明確區分宣告與實測 |
| 與指南不符或缺少工具逐項標明 | 已標明文件 Git 狀態變化、OLD Java 8／6.8.1 未在查找範圍找到、預設啟動 JDK 21、沙箱鎖檔限制及未解析版本 |
| 命令、退出碼、輸出與時間保存 | commands.json 保留 C01–C33；C23 失敗及 C24 成功都保存，C29–C33 為結束核對；未執行的 OLD Wrapper 沒有虛構退出碼 |
| 不把盤點當建置驗收 | OLD／NEW build、API、client／server 驗收全部未執行 |

據此 T-001 可標為「已完成（環境盤點）」；缺少 OLD 工具不阻止完成盤點，但會影響後續任務的就緒程度。T-002／T-003／T-007 及其他任務維持待執行；相關草案未套用到正式前置條件。

C33 確認正式任務仍為 88 項，只有 T-001 為已完成、其餘 87 項待執行，T-007 前置仍為 T-005、T-006；文件表格／反引號／空白檢查通過。這是文件核對，不是任何遊戲或建置驗收。
