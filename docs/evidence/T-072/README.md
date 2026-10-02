# T-072 疑點 3：路口暫存作用範圍調查

**開發來源調查與 T-123 最小重現包完成；R-06 待審；T-123 使用者結果未執行。** OLD 未執行 build 或遊戲，下述後果均為「依原始碼推定／待確認」。[固定 JAR／來源指紋](../../test-packages/T-123-v1/manifest.json)、[操作包](../../test-packages/T-123-v1/README.md)；NEW [最終 build log](../T-066-070/build-final.log)退出 0，Gradle test `NO-SOURCE`。

| 子疑點 | OLD 原始碼靜態證據與假說 | NEW 設計／待實測缺口 |
| --- | --- | --- |
| 不同維度同座標 | 三個 `block/{CrossRail,YCrossRail,YCrossRightRail}.java` 各有實例欄位 `Map<BlockPos, CartData>`；鍵只有座標。註冊後同 Block 實例可供多世界使用，故暫存可互相覆蓋。 | 每個放置位置有 `JunctionRailBlockEntity`，由 `ServerLevel.getBlockEntity(pos)` 取得；世界／維度資料分離。T123-01 查實際隔離。 |
| 同程序世界切換 | 舊欄位生命週期跟 Block 實例，不與世界卸載綁定；原碼未見世界卸載清空。 | NEW 不用靜態／Block 實例 map；T123-02 需在同 JVM 切換世界驗殘留。 |
| 破壞／重放 | 三個 OLD 類別的 `destroy` 與 `removedByPlayer` 只 `remove(pos)`；可能同座標誤刪另一世界的值。 | NEW 以方塊實體生命週期管理；破壞時 BE 隨方塊移除，重放是新 BE。T123-03 驗證。 |
| 卸載與晚載入 | OLD 無 chunk unload 清理或保存；Map 可能殘留舊 `CartData`，也可能在程序重啟後全失。 | NEW BE NBT 保存 `PendingPassages`，卸載使 live BE 離開世界，重載再讀；T123-04／05 驗實際序列化與回呼。 |
| 中途存檔重啟 | OLD `CartData` 僅記憶體，沒有 NBT 存讀；第一次過車後速度變 0，重啟時無來源速度／目的地可恢復。 | NEW 保存 UUID、出口、速度、旋轉；來源與編譯確認欄位，實際停在第一段的礦車能否於讀回後觸發第二段待 T123-05。 |
| 兩車同時通行 | OLD 同位置 Map 只能存一個 UUID；另一車第一次回呼覆寫前車記錄，可能卡車或改道。 | NEW 每 BE 用 UUID→Passage 保存多車，第二段只取自己的值；實際碰撞與先後仍待 T123-06。 |

上述 OLD 資料結構與覆寫路徑是可由原始碼確認的設計缺口，執行期重現頻率、NEW 世界保存與遊戲後果**尚未實測**。T-073 僅對這些已確認的結構缺口做最小處理；T-123 的 `actual` 全部為空白。區塊票證及其他路口行車問題不由本項推定通過。

[最終交接包檢查](package-verify-final.txt)退出 0：18 個空白結果、199 個輸入指紋、JAR／manifest／結果表 SHA-256 一致，ZIP 含 `mods/` 路徑。此前 [初版檢查](package-verify.txt)的 JAR 指紋僅是 T-073 NBT 欄位完整性修正前的歷史快照，不能當成本包最後版本；最終 SHA 以 [manifest](../../test-packages/T-123-v1/manifest.json) 為準。
