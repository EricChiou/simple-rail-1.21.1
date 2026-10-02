# T-058 R3：恢復 OLD 來源的停靠格跟車邏輯

> 歷史快照：最新使用者決策與 NEW 修正在 [R4](../fix-R4/README.md)；本節 R3 的整格間距及驗證結果不代表 R4。

OLD 來源：`D:\workspace\java\simple-rail\src\main\java\ericchiu\simplerail\entity\LocomotiveCartEntity.java` 的 `tick`、`posChanged`、`updateCartsStopPos`、`needMoveCarts`、`moveCarts`（也保存於 [R2 OLD 快照](../fix-R2/old-LocomotiveCartEntity.java)）。來源對照屬**依原始碼推定／待確認**；未重跑 OLD build 或 OLD 遊戲。使用者 [R3 決策](USER_REPORT.md)取代 R2 的 1.5 倍數間距需求。

NEW `LocomotiveCartEntity` 現在於車頭跨入新方塊時，將上一方塊交給第一節，並將每節舊停靠格從尾往前傳給下一節。車頭有速度時，只有 x/z 位於目前方塊 `0.2～0.8` 時才將已載入車廂 `moveTo` 到其停靠格中心並清零動量；車頭靜止時持續執行。`TrainFormation.advance` 保持倒序傳遞；R1/R2 `TrainTrail` 路徑類與 `TrainPath` 寫入／讀回已移除，`TrainSchema` 改為 3。NEW 測試世界的舊 `TrainPath` 欄位在讀回時忽略；`Train`、`TrainStops`、`PrevPos` 仍照 NEW 格式讀寫。D1 不要求 OLD 存檔轉換。

本次**只恢復跟車定位及時機**，不是完全回退 OLD 編組：OLD 對 `getEntity(UUID)==null` 截斷和 `isOnGround()` 清空編組的路徑不恢復，因 T-055 的晚載入安全性及 T-058 中間車永久摧毀需求需要分辨暫時卸載。NEW 每維度 owner、UUID 存檔及摧毀事件仍保留。OLD 原始碼沒有 1.2 或 1.5 格固定間距常數，平直段相鄰**停靠格中心**通常相距 1 格；車頭相對第一節的即時視覺間隙會隨格內位置變化，彎坡須以遊戲觀察。

| 非遊戲驗證 | 實際結果 | 證據 |
| --- | --- | --- |
| `javac -encoding UTF-8 -d docs/evidence/T-058/fix-R3/classes src/main/java/com/ericchiu/simplerail/entity/TrainFormation.java docs/evidence/T-058/fix-R3/OldStopPropagationTest.java`；`java -cp docs/evidence/T-058/fix-R3/classes OldStopPropagationTest` | 編譯／執行退出 0；18 項斷言通過，含跨格、轉彎、斷尾、缺停靠格保留 UUID | [結果](pure-jvm-result.json)、[測試碼](OldStopPropagationTest.java)、[輸出](pure-jvm-test.log) |
| `.\gradlew.bat build --offline --no-configuration-cache --console plain` | 首次沙箱因 `C:\.gradle` 鎖檔權限退出 1，未編譯；使用既有快取重跑退出 0，`compileJava`／`jar` 執行，Gradle `test NO-SOURCE` | [首次錯誤摘要](build-attempt-01.txt)、[最終 build log](build.log)、[退出碼](build-result.json) |
| `jar tf build/libs/simplerail-1.0.0.jar` | 含 `LocomotiveCartEntity`／`TrainFormation`，無 `TrainTrail` | JAR 清單抽查；R3 包雜湊見下 |

[T-058-R3 固定重測包](../../../test-packages/T-058-R3/README.md)供使用者操作。**尚未執行 Minecraft 測試**；R-05／R-F 獨立程式審查待執行，T-058 保持未通過／未結案。R1/R2 證據、JAR 與結果表都是當時快照，不能當作 R3 驗收結果。
