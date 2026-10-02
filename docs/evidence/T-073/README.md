# T-073 路口暫存隔離與恢復

**已確認結構問題的開發修正完成；R-06 待審；T-123／T-074 人工遊戲驗收未執行。** 修正准入依 [T-072](../T-072/README.md) 的 OLD 原始碼靜態證據，沒有把未實測 OLD 後果寫成實測缺陷。

| 已確認的結構缺口 | NEW 最小改動與資料生命週期 |
| --- | --- |
| Block 實例 `Map<BlockPos, CartData>` 跨世界共用 | `ModBlockEntities.JUNCTION_RAIL` 為三種路口註冊 NEW 專用 BE；每次從當前 `ServerLevel` 的該座標取得，世界／維度與方塊生命週期自然隔離。 |
| 同位置僅容一車 | BE 以 UUID→`Passage` 暫存；第一次過車 `put`，第二次同 UUID `take`；另一車不覆寫前車。 |
| 暫存不落盤／重啟遺失 | `PendingPassages` NBT 保存 UUID、方向、目的格、速度與旋轉；每次 `put`／`take` 呼叫 `setChanged()`。讀入時跳過缺欄、非法方向與非正數／非有限速度，不做 OLD NBT 轉換。 |
| 破壞／卸載生命週期 | BE 由方塊位置擁有，方塊移除時 BE 移除；chunk 卸載時持久資料隨 chunk 保存並可重讀，不建立跨世界靜態快取，也不改 D3 票證政策。 |

未改左／右 Y 各自方向表或十字出口，路徑由[來源矩陣與 96 項 JVM 斷言](../T-066-070/ROUTES.md)覆蓋。NEW [最終 build log](../T-066-070/build-final.log)退出 0，Gradle test `NO-SOURCE`。`PendingPassages` 真正存讀、兩車物理碰撞、卸載後第二次過車是否觸發，仍須 [T-123 使用者案例](../../test-packages/T-123-v1/CASES.md)；不能以編譯或欄位存在宣稱遊戲驗收完成。
