# T-057 扳手相鄰礦車連結：開發證據

2026-10-01。Minecraft 1.21.1、NeoForge 21.1.251、`simplerail` 1.0.0。任務對應 MIGRATION.md §3 扳手／車頭與編組、§6 階段 5。T-035／T-053 已有開發交付；本頁只記錄 T-057 的開發與非遊戲驗證，R-05 程式審查及 T-058 使用者遊戲驗收仍待執行。

## 來源、差異與決策

OLD [Wrench 原始碼快照](old-Wrench.java) SHA-256 `766CEE80AF12F582A9C64DD05C9BE02F7BAF36BE5ED63E03C11F98EA62930A0A`，來源 `D:\workspace\java\simple-rail\src\main\java\ericchiu\simplerail\item\Wrench.java`。OLD 行為均為**依原始碼推定／待確認**，沒有重跑 OLD build 或遊戲實測。[NEW 互動差異](interaction.diff)對照 `src/main/java/com/ericchiu/simplerail/item/Wrench.java`；改後該檔 SHA-256 `96767E7D4F0434AE8D537E4BE0D9AEF7464BF246921D8A50E0DC0E7467568389`。基準 HEAD `11916b69c3549504928f7cfa6790d59a2717b4b6` 加工作目錄既有未提交差異；不可只憑 HEAD 重建。

| 條件／情況 | OLD 原始碼 | T-057 NEW 設計 |
| --- | --- | --- |
| 選兩格 | 點擊格為第一格。玩家面東／西時以點擊位置 z 小數 `<0.5` 取北、`>0.5` 取南；面南／北時以 x 小數 `<0.5` 取西、`>0.5` 取東；恰好 `0.5` 為同格。各格以整格 AABB 查 `AbstractMinecart`。 | 保留此幾何與第一格、第二格順序；同格只掃描一次。client 仍只回 SUCCESS，不更改編組。實際實體 AABB 交界及四方點擊待 T-058。 |
| 找車頭 | 先依第一格車清單、再第二格，透過全域 `LinkageManager.getLocomotiveUuid` 找已在表中的車頭。 | 先辨認載入中的 `LocomotiveCartEntity`，再透過**當前維度** `TrainOwnershipData.ownerOf` 找已連結車廂的載入中車頭；兩格順序不變。車頭未載入、無車頭皆不連結。其他車頭不當作車廂，避免產生巢狀編組。 |
| 加車與次序 | 對第一格所有車、再第二格所有車呼叫 `linkNewCart`，舊全域索引檢查重複。 | 依同序呼叫現有 `linkNewCart`；該方法檢查同世界、未移除、不是自身、LINKABLE、既有 UUID／其他車頭所有權。成功時 `TrainFormation.add` 依序追加 UUID，重複／已屬其他編組則不變。單格多車的內部次序依 `getEntitiesOfClass` 傳回順序，未另假定生成順序。 |
| 回饋 | OLD 對每次呼叫（即使拒絕連結）做煙粒子／CHAIN_HIT。 | 只有真正新增車廂才由伺服器廣播一個煙粒子與 CHAIN_HIT，避免重複／無效點擊有假成功回饋；`playSound(null, …)` 讓點擊玩家也可接收。實際顯示／聽感待 T-058。 |
| 原扳手操作 | 點擊格沒有車且屬 rails 才改 reverse／level／direction；machines 可改 facing／level。 | 保留 T-035 與 T-040 已有狀態更新程式，只將既有第一格車清單作為 rails 的無車 guard；有車不改 rails。機器操作與 U-09 原有限制不動。 |

沒有加入外部模組、改註冊 ID 或舊 NBT 轉換。OLD 的全域 static map 不搬入 NEW，沿用 T-053 的每維度所有權資料。多車頭同格、車輛跨格 AABB、同時多人操作與實際可點擊性屬 T-058 使用者驗收範圍，不能由編譯判定通過。

## 命令與結果

| 實際命令 | 退出碼／範圍 | 證據 |
| --- | --- | --- |
| `.\gradlew.bat build --offline --no-configuration-cache --console plain` | `0`，`compileJava` 執行，`BUILD SUCCESSFUL`；Gradle `test NO-SOURCE` | [完整 build log](build.log) |
| `javac -d docs/evidence/T-057/classes src/main/java/com/ericchiu/simplerail/entity/Facing8.java src/main/java/com/ericchiu/simplerail/entity/TrainFormation.java docs/evidence/T-048-055/TrainFormationTest.java` | `0` | [純 JVM 編譯／執行 log](formation-test.log) |
| `java -cp docs/evidence/T-057/classes TrainFormationTest` | `0`，41 項斷言；含有序追加、重複拒絕及晚載入保留 | [純 JVM 編譯／執行 log](formation-test.log) |
| `git diff --check` | `0` | 本次執行結果；沒有修改遊戲資源或 Gradle |

第一次 JVM log 因 PowerShell 原生輸出編碼混用而不易閱讀，原檔留於 [attempt-01](formation-test-attempt-01.log)；使用 UTF-8 重跑且兩條命令均退出 0。build 產物 `build/libs/simplerail-1.0.0.jar` SHA-256 `3B5F5BB513097B9F51D38A4C5542E490982432EADD4DC57298A91B0BE72242A2`，僅為本次 build 識別，**尚非 T-105 固定人工測試包**。沒有啟動 Minecraft、執行 GameTest 或代填 T-058 結果。
