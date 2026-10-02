# T-058 R4：以 R3 停靠格邏輯設定 1.25 格倍數間距

> 歷史快照：最新使用者決策與 NEW 修正在 [R5](../fix-R5/README.md)；以下 R4 的 1.25 格數值與測試結果不代表 R5。

[使用者決策](USER_REPORT.md)指定以目前車廂間隔邏輯為基礎，將第 1、2、3 節距離調為 1.25／2.5／3.75 格。R3 的 OLD 來源跨格停靠格更新和車頭移動時 x/z `0.2～0.8`、靜止時持續移車廂的時機保留。R4 新增 `TrainBlockRoute`：只在車頭跨格時記錄上一方塊的中心，從車頭當前實際位置沿這些中心點組成的路線插值，取第 n 節 `1.25 × n` 格目標。**這是 NEW 的新數值，OLD 沒有 1.25 固定間距；OLD 遊戲效果仍依原始碼推定／待確認。**

路線資料 `TrainRoute` 作為 NEW 車頭 NBT 保存，`TrainSchema=4`；原 `Train`、`TrainStops`、`PrevPos` 保留。R3 NEW 測試世界無 `TrainRoute` 時，用現有 `TrainStops` 依序播種已知路線，缺少的路線不臆造。路線長度不夠覆蓋**整列車**或跨格不連續時，所有已載入車廂暫用 R3 停靠格中心定位；累積足夠路線後整列改用 1.25 倍數目標。長距離瞬移清除過時路線；暫時卸載不刪 UUID，中間車永久移除切斷尾段。R1/R2 `TrainPath` 不讀；D1 不轉換 OLD 世界。

| 非遊戲驗證 | 實際結果 | 證據 |
| --- | --- | --- |
| `javac -encoding UTF-8 -d docs/evidence/T-058/fix-R4/classes src/main/java/com/ericchiu/simplerail/entity/TrainFormation.java src/main/java/com/ericchiu/simplerail/entity/TrainBlockRoute.java docs/evidence/T-058/fix-R4/BlockRouteSpacingTest.java`；`java -cp docs/evidence/T-058/fix-R4/classes BlockRouteSpacingTest` | 編譯／執行退出 0；22 項斷言通過，含直線 1.25 倍數、彎道、坡道、路線存讀、瞬移與初始車廂在前方 | [測試碼](BlockRouteSpacingTest.java)、[結果](pure-jvm-result.json)、[輸出](pure-jvm-test.log) |
| `.\gradlew.bat build --offline --no-configuration-cache --console plain` | 首次因 1.21.1 `ListTag` 無 `getLong(int)` 退出 1；改從 `LongTag` 讀值後最終退出 0，`compileJava`／`jar` 執行，Gradle `test NO-SOURCE` | [首次失敗 log](build-attempt-01.log)、[最終 build log](build.log)、[退出碼](build-result.json) |
| 固定 JAR 來源與內容 | [R4 包](../../../test-packages/T-058-R4/README.md)保存來源雜湊與 JAR；`TrainBlockRoute` 已進 JAR | [來源 manifest](../../../test-packages/T-058-R4/source-manifest.json) |

R3 及更早資料與測試包保留作歷史，不再當最新 T-058 驗收基線。**R-05／R-F 獨立程式審查和使用者 Minecraft 測試均待執行；不得從 build 或純 JVM 測試宣稱遊戲車距通過。**
