# T 型路口 R1：固定開口、切換內彎（2026-10-03）

依使用者更新的 [圖示](reference.png) 修正；不是把整個 T 型旋轉。圖示 SHA-256：`B07C530745980AD31E80892DD87EDC609E653D38D1B081983A30B6257D51C1E4`。這份規格取代 [v1](../README.md)「兩側分支皆回主幹」的暫定解讀；v1 原始證據／固定包保留，不倒填為新規格通過。

`direction=north` 時，T 固定為西／東／南三開口（圖的左／右／下）：

| 入口位置 | 斷電出口 | 通電出口 |
| --- | --- | --- |
| 左／西 | 右／東（直行） | 下／南（彎道） |
| 右／東 | 下／南（彎道） | 左／西（直行） |
| 下／南 | 右／東（彎道） | 左／西（彎道） |

主幹與被選分支雙向相通，另一側來車橫向直行。只有放置朝向／扳手旋轉整個 T；紅石只改 `powered`、內彎與選路。未連接第四側仍以原行進方向續行作防反轉回退，並非增加第四開口。其餘三朝向為整體旋轉；完整 32 組預期見 [CASES.md](../../../test-packages/T-cross-v2/CASES.md)。

## 產品修改

- `JunctionRoute.java`：主幹選左右，被選分支回主幹，另一側直行；十字維持直行。`JunctionRail` 兩階段過車／UUID 保存未改，仍在進入時固定目的地。
- `models/block/t_cross_right_rail.json`、`t_cross_left_rail.json`：相同 T 型外框及枕木，只鏡射內部彎軌。模型由 [generate-models.ps1](generate-models.ps1) 產生原生平面元素，取用既有 `cross_rail.png` 鋼軌／木材 UV；沒有修改或生成 PNG。這不是旋轉舊 Y 貼圖。
- `models/item/t_cross_rail.json`：使用預設斷電 T 型模型作物品圖。既有 8 個 `direction`／`powered` blockstate 變體及其旋轉值不變。
- [模型俯視向量預覽](model-preview.svg) 依同一組模型平面產生，方便比對固定外框與切換內彎；不是 Minecraft 截圖。遊戲中烘焙、貼合與物品顯示仍待使用者確認。

修改前的四個產品檔案保留在 `before/`。D2 的兩個 Y ID 合併例外、10 方塊／12 物品／8 軌道／12 配方維持；其他 D1–D8 要求及既有任務依賴不變。

## 已執行的開發驗證

| 命令／檢查 | 結果及證據 |
| --- | --- |
| `javac -d docs/evidence/T-cross-redesign/fix-R1/classes src/main/java/com/ericchiu/simplerail/block/JunctionRoute.java docs/evidence/T-cross-redesign/fix-R1/TCrossRouteTest.java` | 退出 0，[javac.log](javac.log)／[退出碼](javac-exit.txt)。 |
| `java -cp docs/evidence/T-cross-redesign/fix-R1/classes TCrossRouteTest` | 退出 0；明列表格的 32 項 T 型選路＋32 項十字回歸，[routes-test.log](routes-test.log)。純 JVM，不啟動 Minecraft。 |
| `GRADLE_USER_HOME=C:\Users\Kinoko\.gradle; .\gradlew.bat --offline build`（PowerShell 以環境變數設定） | 退出 0，[build.log](build.log)／[退出碼](build-exit.txt)；NEW 編譯與 JAR 成功，Gradle `test NO-SOURCE`，不冒稱 Gradle 單元測試通過。 |
| `powershell -NoProfile -ExecutionPolicy Bypass -File docs/evidence/T-cross-redesign/fix-R1/verify-resources.ps1` | 第二次退出 0，1919 項靜態斷言，[resources-test-02.log](resources-test-02.log)：固定外框相同、內彎鏡射、三開口邊界、平面／UV 有效與不透明、8 變體旋轉、物品引用、註冊／配方／掉落及 JAR 內容一致。PNG SHA 與 v1 相同。 |

第一次資源檢查的 PNG 指紋比對失敗，是 PowerShell JSON 陣列未展開導致找不到舊紀錄，實際 PNG SHA 一致；修正驗證腳本後重跑，原 [失敗 log](resources-test.log) 保留。嘗試用本機 headless Edge 預覽 SVG 未成功（第二次程序退出 `-2147483645`），沒有產出預覽截圖；不將它稱為視覺或 Minecraft 驗證。

## 交接與未完成項目

交付 [T-cross-v2](../../../test-packages/T-cross-v2/README.md)，保留 83 個空白人工案例：64 個方向／供電／單車編組組合、2 個銜接／扳手案例、5 個供電／顯示／同步案例、12 個十字＋T 生命週期案例。commit、未提交差異、來源指紋與 JAR SHA 見包內 manifest。

T-068／T-070 修正開發完成；T-110／T-111 更新包。R-06 仍待獨立程式審查，T-069／T-071／T-123 的人工結果仍待使用者；不因此執行或關閉其他任務。未啟動 Minecraft，未重跑 OLD build，未宣稱遊戲顯示／同步／行車通過。使用者確認即可人工結案，不要求附證據。

[最終交接核對](final-check.log)退出 0：固定 JAR／ZIP 每項內容一致、199 份來源指紋一致、83 個人工案例實際結果空白、126 任務／九階段／依賴無缺號或循環。JAR SHA-256：`C4E9F9B338A1EB4309236FC46A411ADB8EE0E3C40057942F5E9A40A8DD5E5C5B`。[製包命令腳本](package.ps1)與 [製包 log](package.log)保留，退出 0。Java 實際版本為 Temurin `21.0.12.1+1-LTS`，見 [版本輸出](java-version.log)，命令退出 0；PowerShell 把 Java 寫入 stderr 的版本文字包裝為 NativeCommandError，不是 Java 失敗。
