# T 型路口合併（2026-10-02）

> 本頁是 v1 歷史證據。2026-10-03 使用者圖示已澄清固定 T 開口及內彎切換；現行規格／修正與交付見 [fix-R1](fix-R1/README.md) 及 T-cross-v2。下列暫定方向表不再作現行驗收依據。

使用者需求：將 `y_cross_rail` 與 `y_cross_right_rail` 合併為 `t_cross_rail`，斷電右轉、通電左轉，貼圖對應切換。此決策為 D2 的明確例外：移除兩個舊方塊／物品 ID，新增 `simplerail:t_cross_rail`；其他 ID（含 `destory_rail`）不變。沒有 OLD／NEW 舊測試世界轉換；請以新測試世界驗收。

**目前採用的方向解讀：** `direction` 是主幹來車的行進方向；分支來車返回主幹。這是尚未收到方向澄清回覆時採用的 T 型幾何規格，不冒稱使用者已逐項確認。放置時沿玩家水平朝向，可用扳手旋轉；只有四個水平狀態。第四側不是正常入口，若由該側來車，沿原行進方向回主幹、不反轉。平面軌道、不支援斜坡。

| direction／主幹行進方向 | 斷電出口（右） | 通電出口（左） | 兩側分支來車的出口（回主幹） |
| --- | --- | --- | --- |
| north | east | west | south |
| east | south | north | west |
| south | west | east | north |
| west | north | south | east |

`TCrossRail` 使用 `powered` 與 `direction` 選路及模型；`JunctionRoute` 以幾何規格取代 OLD 左右 Y 的不對称分支表。`JunctionRail` 的兩段過車、進入時固定目的地、保存與 UUID 暫存不變，因此中途切紅石會影響下一次進入，已暫存的車保持原出口。新模型沿用既有 `y_cross_right_turn_rail.png`／`y_cross_turn_rail.png`，沒有修改 PNG；保留舊材質／block model 資源供歷史追溯，產品不再註冊舊 Y 方塊或物品。

註冊／分頁／兩語系／兩組 rails tag／專用路口方塊實體有效方塊／配方／掉落均已接線。新清單是 **10 方塊、12 物品、8 軌道、12 配方**；T 型合成沿用原左 Y 配方：鐵粒、普通鐵軌、紅石由上而下各一，產 1。D1、D3～D8 不變。

驗證：

- [64 項純 JVM 路徑測試](routes-test.log)通過，32 T 路口分支＋32 十字回歸；`javac`／`java` 退出 0。[測試來源](TCrossRouteTest.java)採獨立明列的東西南北幾何預期。
- [NEW 離線 build](build-02.log)退出 0，編譯及 JAR 成功；Gradle `test NO-SOURCE`，不代表有 Gradle 單元測試。[首次沙箱 build](build-01.log)於 Wrapper 快取鎖檔存取被拒，退出 1；第二次使用同一既有快取、允許存取後離線完成。
- [79 項資源／註冊／JAR 靜態核對](resources-test.log)通過：8 個方向／供電變體、旋轉、cutout、PNG 引用、新 ID 數量、配方／掉落、JAR 無舊 Y class／註冊資源殘留，打包 JSON 與來源 SHA 一致。這不是遊戲模型烘焙或 registry 實測。
- 新 enum 值域與放置 API 依既有固定 1.21.1 來源 `T-010/sources/target/.../EnumProperty.java:89`、`BaseRailBlock.java:137` 及本次成功編譯核對；未宣称查證其他 API。

變更前產品檔見 `before/`；固定產物、commit＋所有未提交產品差異與來源指紋見 [測試包](../../test-packages/T-cross-v1/README.md)。R-06 程式審查、T-069／T-071 人工驗收與新版 T-123 生命週期仍待執行。沒有啟動 Minecraft、重跑 OLD build 或替使用者填遊戲結果。

[最終交接核對](final-check.log)退出 0：ZIP 每個項目與交付目錄 SHA 一致、199 項來源指紋一致、83 個人工案例 `actual` 留白、126 個任務／九階段／無不存在前置或循環。固定 JAR SHA-256：`546C30E3150A874CDA77897574C86ADAEF3233B23BCDC1280BFD6344EAD3DF19`。製包途中曾被 Git 換行警告中斷，初版 ZIP 使用反斜線路徑，後續又缺少載入 Compression assembly；各次輸出保留於 `package*.log`，最後 `package-04.log` 與完整 ZIP 核對均成功。這些是交付脚本修正，不是遊戲測試結果。

