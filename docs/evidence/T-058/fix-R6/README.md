# T-058 R6：車距改為 1.3 格倍數

> 歷史快照：最新使用者決策與 NEW 修正在 [R7](../fix-R7/README.md)；以下 R6 的 1.3 格數值與測試結果不代表 R7。

[使用者最新決策](USER_REPORT.md)將第 1、2、3 節目標由 R5 的 1.4／2.8／4.2 格改為沿路線 1.3／2.6／3.9 格，後續為 `1.3 × 節序`。產品只修改 `TrainBlockRoute.SPACING`；跨格記錄、格內更新時機、彎坡插值、路線不足時整列回退到停靠格中心、`TrainRoute` NEW NBT、永久移除斷尾及卸載保留等 R5 邏輯未改。`MAX_SEGMENT=2.5` 是辨識路線不連續的單段門檻，**不是車距**，故維持原值。OLD 沒有固定 1.3 數值；OLD 遊戲行為仍「依原始碼推定／待確認」。

| 非遊戲驗證 | 實際結果 | 證據 |
| --- | --- | --- |
| `javac -encoding UTF-8 -d docs/evidence/T-058/fix-R6/classes src/main/java/com/ericchiu/simplerail/entity/TrainFormation.java src/main/java/com/ericchiu/simplerail/entity/TrainBlockRoute.java docs/evidence/T-058/fix-R6/BlockRouteSpacingTest.java`；`java -cp docs/evidence/T-058/fix-R6/classes BlockRouteSpacingTest` | 最終編譯／執行退出 0；22 項斷言通過，含直線 1.3 倍數、彎坡、保存與瞬移回歸。首次測試沿用 R5 的四格「路線不足」前提，因 3.9 格已可覆蓋而退出 1；改為先用三格驗證回退，再加入第四格驗證目標，未改產品邏輯。 | [測試碼](BlockRouteSpacingTest.java)、[最終結果](pure-jvm-result.json)、[最終輸出](pure-jvm-test.log)、[首次失敗](pure-jvm-test-attempt-01.log) |
| `.\gradlew.bat build --offline --no-configuration-cache --console plain` | 退出 0；`compileJava` 與 `jar` 執行，Gradle `test NO-SOURCE` | [build log](build.log)、[退出碼](build-result.json) |
| 固定來源與 JAR | [R6 包](../../../test-packages/T-058-R6/README.md)保存來源雜湊與 JAR SHA-256 | [來源 manifest](../../../test-packages/T-058-R6/source-manifest.json) |

R5 與更早包保留歷史，不當作最新驗收版。**R-05／R-F 獨立程式審查與 T-058 R6 使用者 Minecraft 測試均待執行；build 與純 JVM 通過不代表遊戲間距已驗證。**
