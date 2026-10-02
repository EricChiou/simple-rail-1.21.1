# T-058 R5：車距改為 1.4 格倍數

> 歷史快照：最新使用者決策與 NEW 修正在 [R6](../fix-R6/README.md)；以下 R5 的 1.4 格數值與測試結果不代表 R6。

[使用者最新決策](USER_REPORT.md)將第 1、2、3 節目標由 R4 的 1.25／2.5／3.75 格改為沿路線 1.4／2.8／4.2 格，後續為 `1.4 × 節序`。產品只修改 `TrainBlockRoute.SPACING` 與其註解；跨格記錄、格內更新時機、彎坡插值、路線不足時整列回退到停靠格中心、`TrainRoute` NEW NBT、永久移除斷尾及卸載保留等 R4 邏輯未改。`MAX_SEGMENT=2.5` 是辨識路線不連續的單段門檻，**不是車距**，故維持原值。OLD 沒有固定 1.4 數值；OLD 遊戲行為仍「依原始碼推定／待確認」。

| 非遊戲驗證 | 實際結果 | 證據 |
| --- | --- | --- |
| `javac -encoding UTF-8 -d docs/evidence/T-058/fix-R5/classes src/main/java/com/ericchiu/simplerail/entity/TrainFormation.java src/main/java/com/ericchiu/simplerail/entity/TrainBlockRoute.java docs/evidence/T-058/fix-R5/BlockRouteSpacingTest.java`；`java -cp docs/evidence/T-058/fix-R5/classes BlockRouteSpacingTest` | 編譯／執行退出 0；22 項斷言通過，含直線 1.4 倍數、彎坡、保存與瞬移回歸 | [測試碼](BlockRouteSpacingTest.java)、[結果](pure-jvm-result.json)、[輸出](pure-jvm-test.log) |
| `.\gradlew.bat build --offline --no-configuration-cache --console plain` | 退出 0；`compileJava` 與 `jar` 執行，Gradle `test NO-SOURCE` | [build log](build.log)、[退出碼](build-result.json) |
| 固定來源與 JAR | [R5 包](../../../test-packages/T-058-R5/README.md)保存來源雜湊與 JAR SHA-256 | [來源 manifest](../../../test-packages/T-058-R5/source-manifest.json) |

R4 與更早包保留歷史，不當作最新驗收版。**R-05／R-F 獨立程式審查與 T-058 R5 使用者 Minecraft 測試均待執行；build 與純 JVM 通過不代表遊戲間距已驗證。**
