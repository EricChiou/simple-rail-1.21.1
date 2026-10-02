# T-064 權責條件式修正

狀態：**已完成一個來源可確認的修正；其餘執行期分項受阻於 T-122，任務不結案；R-05 待審**。

2026-10-02 的[來源續查與建置嘗試](CONTINUATION-2026-10-02.md)另記；本段為初次修正時的證據，不將後續失敗的 build 嘗試寫成通過。

**後續狀態更新：** [T-122 使用者確認](T-122-USER-CONFIRMATION.md)全項已驗證、未發現異常；本檔首段的「待 T-122／不結案」是確認前快照。T-064 開發分項已依條件式規則結案，R-05 與 T-065 仍待辦。

T-063 指出發射器生成的車頭在東西向軌道上，初始 `FACING` 未在 `addFreshEntity` 前設定；手持放置路徑已有這一步。NEW `TrainDispenserBlock` 現依軌道 `RailShape` 在 server 設 `Facing8`，再加入世界，讓初始同步值與放置方向一致。變更只涉及首次朝向，不增加自訂封包或 client 寫入。OLD 構造函式讀直軌方向的行為仍是依原始碼推定／待確認。`LocomotiveCartEntity.tick` 後續依動量更新的既有 server-only 責任未改。

驗證：本輪共用 [NEW build log](../T-059/build.log) 退出 0，`compileJava`／`jar` 成功，`test NO-SOURCE`。固定 JAR 與產品檔 SHA-256 見 [manifest](../../test-packages/T-122-v1/manifest.json)。未啟動遊戲，未看到使用者 T-122 的雙 client 結果；其他是否存在重複回呼、生成、刪除或視覺不同步**待確認**，不能依靜態 guard 推定全數沒有問題。使用者回報問題後，再針對受影響案例修正、交獨立 Review Agent 複查並請使用者重測。
