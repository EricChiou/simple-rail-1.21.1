# T-037 調查與最小重現包：計時資料保存與邊界

2026-09-30。**開發完成；R-04 程式審查待審；T-119 人工待執行。** 本項交付來源調查、指定版 API／plain JVM 證據及可操作的診斷包；沒有修改正式 Java、資源或專案 Gradle 設定，沒有開始 T-038／039，也沒有執行 Minecraft／OLD build。D1–D8 保留。

## 結果與完成條件

| 本項條件 | 交付／判定 | 限制 |
| --- | --- | --- |
| 每個疑點有來源、假說、證據或明確缺口 | [INVESTIGATION.md](INVESTIGATION.md) 五個子項：首次／缺鍵、setter 標髒、int 上限、保存到卸載落差、NEW 回呼順序 | OLD 全部依原始碼推定／待確認；不能宣稱 OLD 遊戲已重現 |
| NEW 最小 fixture 及非遊戲驗證 | [fixture](fixture/)、[tests](tests/)、外部 [init script](probe.init.gradle)；固定版 API 編譯、真實 NEW CompoundTag、1,049 判定通過 | 不是正式計時 rail；無 Minecraft bootstrap／server／client／GameTest |
| 固定版本可操作包 | [T-037-v1 操作包](../../test-packages/T-037-v1/README.md)、[ZIP](../../test-packages/T-037-v1.zip)，7 組／13 個 SP／DS 案例變體與空白 results.json | R-04 待審；未代使用者填結果；正式 M-01 約 3 秒誤差待技術定義 |
| 修正依據與條件阻礙 | 調查表逐項映射 T-038／039、T119-01–07；包的 arm 為可重現邊界控制實驗 | 靜態確認的 long／缺鍵／保存標記可進行後續開發；真實保存／卸載／正式礦車驗收仍待對應人工任務 |
| 範圍及文件一致性 | [audit.json](audit.json) 核對產品指紋、JAR／ZIP、原編號／前置／九階段、空白人工結果與文件連結 | 自查不等於獨立程式審查 |

主要發現：OLD int 秒乘 1000 在 2147484 秒起溢位；首次不寫 UUID、讀回卻無條件讀取；setters 沒有 setChanged，但方向 setBlock／其他活動可能掩蓋風險，不能聲稱必定丟資料。補償公式恢復的是「保存時剩餘」，若至卸載還活動且未再保存，會延長重載等待。NEW onChunkUnloaded 位於該來源卸載路徑的 save 之後，不能在那裡才補改已序列化資料。

## 來源、版本與差異

OLD：`D:/workspace/java/simple-rail`，HEAD `6698b1c5f494095a15b055c10045293e91540012`；檔案快照的 SHA-256 為實際來源依據，不假設 OLD 工作樹無差異。首次 Git 查詢因 sandbox ownership 退出 128，改用單次 `git -c safe.directory=D:/workspace/java/simple-rail -C D:/workspace/java/simple-rail rev-parse HEAD` 退出 0，見 [collection.json](collection.json)、[old-head.json](old-head.json)；沒有寫全域 Git config。

NEW：`D:/workspace/java/simple-rail-1.21.1`，HEAD `11916b69c3549504928f7cfa6790d59a2717b4b6`。Minecraft 1.21.1、NeoForge 21.1.251、mod 1.0.0／All Rights Reserved、ModDevGradle 2.0.147、Parchment 1.21.1／2024.11.17、Gradle 9.2.1、Temurin 21.0.12.1+1。編譯器見 [compiler.txt](compiler.txt)，實際 `java -version` 退出 0 見 [java-version.log](java-version.log)。PowerShell 將 Java 的標準錯誤版本文字附為 NativeCommandError，實際程序退出仍為 0。

[input-fingerprints.json](input-fingerprints.json) 包含 4 份 OLD 模組來源、14 份 NEW API、診斷／測試／init 輸入指紋；NEW sources JAR SHA-256 `236151EDEC930A89E78054FCB5551323761F801778305F290D0B74238C33693E`。入口與 registry 的兩份影本差異各以 git diff --no-index 取得，退出 1 表示有差異，見 [入口](overlay-entry.diff)、[registry](overlay-registry.diff)。原產品 [product-before.json](product-before.json) 全部逐檔核對未變，index 差異前後也相同；沒有 stage／reset／commit。

## 實際命令、退出與產物

命令由 [build.ps1](build.ps1) 執行，原始逐次紀錄保留：

```powershell
.\gradlew.bat build t037Jar testT037 --offline --console=plain --no-configuration-cache -I docs/evidence/T-037/probe.init.gradle
```

| 次數 | 實際結果 | 原因／證據 |
| --- | --- | --- |
| 01 | 退出 1 | sandbox 無法建立既有 C:\.gradle Wrapper 快取鎖；[log](build-01.log)、[命令紀錄](build-01.json) |
| 02 | 退出 0；BUILD SUCCESSFUL | 允許快取權限後 NEW build／fixture JAR／plain JVM 1,049 判定通過；[log](build-02.log)、[紀錄](build-02.json) |
| 03 | 退出 0；BUILD SUCCESSFUL | 將 plain JVM 工作目錄改至 evidence，隔離程式庫的 log 輸出，再確認 1,049 判定；[log](build-03.log)、[紀錄](build-03.json)。未變的編譯任務 UP-TO-DATE 如實保留 |

普通 Gradle `test NO-SOURCE` 不是測試通過；本項獨立 `testT037` 才是實際非遊戲測試。log 包含 NEW_UNGUARDED_UUID=NullPointerException、三個溢位邊界及保存落差 6000 對 3000。Gradle 10 不相容棄用提醒與終端警告保留，不是本次 build 失敗。NBT 程式庫初始化會產生空 log，不代表 Minecraft 啟動；初次兩份空檔已移入 jvm-first-run-logs，後續 log 位於本 evidence 目錄。

封裝／自查工具的初次問題及實際退出碼見 [tooling-retries.json](tooling-retries.json)，原失敗 JSON 與反斜線 ZIP 草稿保留。最終 ZIP 使用標準正斜線 entry；自查核對產品、封裝、空白人工結果及文件連結通過。這些是工具修正，不是產品或遊戲測試失敗。

| 產物 | SHA-256 |
| --- | --- |
| [診斷 JAR](artifacts/simplerail-1.0.0-T037-probe.jar) | AAF9977E094981A481305DCDCF6C60694931FFD3483A29C9A6A5B31BB10415C7 |
| [原產品 JAR](artifacts/simplerail-1.0.0.jar)，與進入本任務時 R-03 固定整合版相同 | 3AB3E37EF4AA21342011332E9531088DB36D121A1F6C9C9823DD6B3259538594 |

診斷 JAR 與正常 JAR 獨立，不能共裝。診斷名稱帶 `[T037 diagnostic]`；新增 evidence class，不增加第三方 mod。JAR 差異僅兩份覆蓋 class、診斷 metadata、evidence class 及標準打包 manifest；其餘產品 class／資源逐項相同，核對見 audit.json。包與 ZIP 指紋見 [package.json](package.json)。

## 交接

T-037 自身開發條件齊備，疑點並未全部遊戲結案。R-04 應審 fixture、時間／資料設計、靜態證據與案例覆蓋，不啟動 Minecraft。T-119 的使用者確認即可人工結案，不要求附件；不把已有其他人工任務的通過套到本包。T-038 是下一可獨立開發項，尚未開始；T-039 須等正式實作再逐項判定，不以候選已測直接簽無須補丁。
