# T-058 R2：1.5 格倍數的車廂間距

> 歷史快照：最新使用者決策與 NEW 修正在 [R3](../fix-R3/README.md)；本節 R2 的路徑數值及測試結果不代表 R3。

依[使用者 R2 回報](USER_REPORT.md)把 `TrainTrail.SPACING` 由 R1 的 1.2 改為 `1.5D`，第 1–3 節目標沿車頭歷史路徑分別為 **1.5、3.0、4.5 格**。R1 的永久移除斷開尾段、卸載保留、每維度 owner、有序 UUID、`TrainPath` 保存等程式未在 R2 重寫。[OLD／NEW 詳細對照](OLD_COMPARISON.md)確認這項間距與路徑算法**不是完全照 OLD**；OLD 行為依原始碼推定／待確認，OLD build 本流程不重跑。

| 實際命令／檢查 | 退出碼與結果 | 證據 |
| --- | --- | --- |
| `.\gradlew.bat build --offline --no-configuration-cache --console plain` | 初版與最終均 `0`、`BUILD SUCCESSFUL`；初版 `compileJava`／`jar` 執行，最終註解修正後 `compileJava` 執行、`jar UP-TO-DATE`；Gradle `test NO-SOURCE` | [最終 build log](build.log)、[初版 build log](build-before-comment-fix.log) |
| `javac -d docs/evidence/T-058/fix-R2/classes src/main/java/com/ericchiu/simplerail/entity/TrainTrail.java docs/evidence/T-058/fix-R2/TrainSpacingR2Test.java`、`java -cp docs/evidence/T-058/fix-R2/classes TrainSpacingR2Test` | 均 `0`；15 項斷言檢查 1.5／3.0／4.5、整列路徑就緒、直線車距、彎道、重載與長距離瞬移重置 | [純 JVM log](pure-jvm-test.log)、[測試碼](TrainSpacingR2Test.java) |
| `javap -classpath docs/test-packages/T-058-R2/mods/simplerail-1.0.0.jar -constants com.ericchiu.simplerail.entity.TrainTrail` | `0`，產物常數為 `SPACING = 1.5d` | 本次產物靜態核對 |
| `git diff --check` | `0` | 本次靜態檢查 |

[T-058-R2 固定重測包](../../../test-packages/T-058-R2/README.md) JAR SHA-256 `0B5545689A0745F2E0D2267847729CEA592DCF01EC85322A90FDFACC50EA2E17`；HEAD `11916b69c3549504928f7cfa6790d59a2717b4b6` 加未提交差異，來源／建置檔雜湊見包內 manifest。R1 JAR／案例與其 build／測試紀錄保留歷史，不再作新驗收基線。R-05／R-F 獨立程式複查、T-058 使用者遊戲重測仍待執行；沒有啟動 Minecraft，不能聲稱視覺間隔或斷鏈已通過。
