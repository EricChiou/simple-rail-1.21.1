# T-058 R1：中間車廂斷鏈與車距修正

> 歷史開發快照：R1 的 1.2 格倍數已由[使用者指定的 R2 1.5 格倍數](../fix-R2/README.md)取代。本頁 build／測試與 JAR 僅對 R1 有效。

2026-10-01。依[使用者首次回報](USER_REPORT.md)修正兩項缺陷；此頁僅記開發與非遊戲結果，**T-058 仍未通過**，R-05／R-F 獨立程式複查待執行。OLD 原始碼的跟車行為只可稱「依原始碼推定／待確認」，沒有重跑 OLD build 或驗證 OLD 遊戲。

| 現行根因 | R1 修正 | 保留的界線 |
| --- | --- | --- |
| 車頭的有序 UUID／stop 清單遇 `server.getEntity(id)==null` 僅略過，無法分辨永久摧毀與 chunk 卸載。摧毀中間車後，後段 ID 留在清單。 | [TrainCarRemovalHandler](../../../../src/main/java/com/ericchiu/simplerail/entity/TrainCarRemovalHandler.java)監聽 ServerLevel 的 `EntityLeaveLevelEvent`，只在 `RemovalReason.shouldDestroy()` 時依 [TrainFormation.disconnectFrom](../../../../src/main/java/com/ericchiu/simplerail/entity/TrainFormation.java)從被毀車起切下整個尾段，逐一釋放 [TrainOwnershipData](../../../../src/main/java/com/ericchiu/simplerail/entity/TrainOwnershipData.java) 的 owner。車頭暫未載入時記 `Cuts` 待辦，車頭下一次 tick 先處理再恢復索引。 | `UNLOADED_TO_CHUNK` 等非永久移除不切斷，不把暫時查不到實體等同死亡；不改 T-061 尚待實作的整列 destory_rail 規格。 |
| 舊跟車只在車頭跨 block 時把 `PrevPos`／`TrainStops` 逐格往後傳，`moveTo` 至格中心；相鄰中心約一格，視覺近乎貼合。 | [TrainTrail](../../../../src/main/java/com/ericchiu/simplerail/entity/TrainTrail.java)記錄車頭實際世界位置形成有限長路徑；每節依編組次序取沿路徑後方 `1.2 × 序號` 格的點，每 tick 由[車頭](../../../../src/main/java/com/ericchiu/simplerail/entity/LocomotiveCartEntity.java)移到該點、清零自身速度。車頭起步且首車位於後方時，最多一次依現有車位補路徑尾端；完整尾段路徑尚不足時暫不對編組車廂執行 `moveTo`，待車頭走出足夠距離再同步牽引，避免只移前車而撞上尾車。 | `TrainPath` 納入 NEW `TrainSchema=2` 存讀；原 `Train` UUID、`TrainStops`、`PrevPos` 保留。缺路徑時從車頭實際位置重新記錄，不能拿不明方向的停靠格當成歷史路徑。**不做 Minecraft 1.16.5 舊 NBT 轉換**。1.2 格是開發採用的可調中心距，實際視覺與彎道由使用者重測。 |

`TrainOwnershipData.Cuts` 對車頭暫未載入的永久斷鏈保存待辦；同維度資料只在車頭恢復時處理。車頭永久刪除仍清理其 owner 與待辦。D1–D8、全部既有註冊 ID 與「無外部模組」不變。

## 驗證與限制

| 命令 | 退出碼／結果 | 證據 |
| --- | --- | --- |
| `.\gradlew.bat build --offline --no-configuration-cache --console plain` | `0`，最終 `compileJava` 執行、`BUILD SUCCESSFUL`；Gradle `test NO-SOURCE` | [最終 build log](build.log)；[第一次成功 build](build-fix-R1.log)為修正中快照 |
| `javac` 編譯 `TrainFormation.java`、`TrainTrail.java`、[TrainBreakAndTrailTest.java](TrainBreakAndTrailTest.java)，再 `java -cp ... TrainBreakAndTrailTest` | 編譯與執行均 `0`；17 斷言：中段／首段切斷、去重、路徑不足保持、直線 1.2 格、轉彎、重載與瞬移重置 | [最終純 JVM log](pure-jvm-test-final.log) |
| 既有 `TrainFormationTest`，以 `javac`／`java` 重跑 | 均 `0`，41 斷言 | [編組回歸 log](formation-regression.log) |
| `git diff --check` | `0` | 本輪最終靜態檢查 |

第一次新增測試將「路徑不足時單節可先走」誤設為安全條件，實際會讓首節靠近靜止尾節；[失敗 log](pure-jvm-test-attempt-01.log)保留。修正為完整路徑可用才由編組邏輯移整列，隨後兩次測試均退出 0。[固定 T-058-R1 測試包](../../../test-packages/T-058-R1/README.md)的唯一 JAR SHA-256 為 `FDD36DCF9EA508C9E0BBFB6F24F1FD09C3D47D7402988B8BAD39599238B8FE05`，來源指紋與空白人工結果表均在包內；基準 HEAD `11916b69c3549504928f7cfa6790d59a2717b4b6` 加未提交差異。沒有啟動 Minecraft／GameTest；chunk 卸載、破壞事件時序、實際車距與多人同步仍待使用者遊戲測試，不能由 build 或純 JVM 斷言宣稱通過。


