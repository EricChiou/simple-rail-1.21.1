# T-045 原版礦車生成開發交付

2026-09-30。**開發完成；R-04 獨立程式審查待審；T-120／T-047 使用者遊戲測試未執行。** 本項把 T-044 的專用 27 格方塊實體接到原版礦車生成，只支援目前可取得的原版 `MinecartItem`；自訂車頭生成與連結仍歸 T-048／T-059。沒有執行 T-046 條件式修正、T-047 人工驗收、OLD build 或 Minecraft／GameTest。OLD 的執行期行為仍標**依原始碼推定／待確認**。

## 來源行為對照

| 分項 | OLD 原始碼推定 | 此次 NEW 實作 | 尚待確認 |
| --- | --- | --- | --- |
| 觸發 | `TrainDispenserBlock.java:51–60`：伺服端每次收到仍有電的 `neighborChanged` 即掃描；不呼叫原版沿觸發父類 | [TrainDispenserBlock](../../../src/main/java/com/ericchiu/simplerail/block/TrainDispenserBlock.java)只在 `ServerLevel.hasNeighborSignal(pos)` 時立即掃描；覆寫父類 `tick`／`dispenseFrom`，不使用 `TRIGGERED` 4 tick／九格消耗路徑 | 真正鄰居事件次數、重複生成與供電時序由 T120-01／02；未加節流或新消耗政策 |
| 槽位與阻擋 | `:64–87` 固定 0–26；每槽先查位置有無礦車，命中便中止，即使該樣板槽空白；空槽無阻擋時繼續 | [正式掃描器](../../../src/main/java/com/ericchiu/simplerail/block/TrainDispenserScan.java)固定要求 27 槽，先 occupancy 再 visit；方塊於 visit 才讀專用 BE `getItem(slot)` | 真實 AABB、移動後占位與後續車數由 T120-03／04、T-047 |
| 位置 | `:128–143`：E `(x+1.5,y,z+i+0.5)`、W `(x−0.5,y,z−i+0.5)`、N `(x+i+0.5,y,z−0.5)`、S `(x−i+0.5,y,z+1.5)` | 掃描器按四方向與槽索引計算；NEW `AABB(BlockPos.containing(...))` 查 `AbstractMinecart`，之後 `AbstractMinecart.createMinecart`／`ServerLevel.addFreshEntity` | 軌道支持、生成實體的位置與碰撞由 T120-05、T-047；非遊戲測試不代替世界觀察 |
| 原版車種 | `:76–84,146–165`：箱／爐／漏斗／TNT，其餘 `MinecartItem` 回落普通車；OLD 用裸字串，NEW `Item.toString()` 不等價 | 用 `Items.CHEST_MINECART`、`FURNACE_MINECART`、`HOPPER_MINECART`、`TNT_MINECART` 物品身分對應 `AbstractMinecart.Type`，其他 `MinecartItem` 回落 `RIDEABLE`；不加入外部模組整合 | 實際類型、命令方塊礦車 fallback 是否符合玩法由 T120-06／T-047；OLD 的字串執行結果未實測 |
| 第 0 格車頭 | 任意槽舊車頭可生成，但只在槽 0 作連結目標 | `simplerail:locomotive_cart` 暫不生成也不代用爐車；其他原版礦車仍按槽位生成。**此為 T-048／T-059 尚未實作的明示缺口** | T120-07 的診斷替身不當作正式編組；真正第 0 格車頭／連結留 T-060 等使用者案例 |
| 27 格樣板 | `:64–93` 只讀舊容器，不縮減或移除物品 | 只讀專用 BE；不呼叫 `shrink`／`removeItem`／`setItem`。新版 `createMinecart` 以 `ItemStack.EMPTY` 建全新車，避免意外把樣板自訂資料套到車上，符合 OLD 的直接建構方式 | 實際不消耗、GUI 同步與 NEW 新世界讀回由 T-047／T-082；樣板自訂名保存與生成車命名是不同要求 |

OLD 來源快照、I-043-01～07、指定版 NEW API 與 T120-01～08 案例見 [T-043 調查](../T-043/INVESTIGATION.md)。`MinecartItem` 的 type 欄位在指定版來源並非公開；使用物品身分映射避免複製 OLD 裸字串 switch。來源 archive `neoforge-21.1.251-sources.jar` SHA-256 `236151EDEC930A89E78054FCB5551323761F801778305F290D0B74238C33693E`，Minecraft 1.21.1、NeoForge 21.1.251、Java 21、Gradle 9.2.1。需求 D1／D2／D4／D7 不變。

## 實際命令、測試與固定產物

- `powershell -NoProfile -ExecutionPolicy Bypass -File docs/evidence/T-045/test-scan.ps1`：`javac --release 21` 編譯**正式** `TrainDispenserScan.java` 與 [獨立測例](tests/TrainDispenserScanTest.java)，再執行 `java -cp docs/evidence/T-045/classes evidence.t045.TrainDispenserScanTest`；[命令與退出碼](test-scan.json)均 0，[log](test-scan.log)為 **15 項通過**。核對四方向槽 0／26 座標、被占位槽先停止、27 槽次序、重呼叫無掃描器閘與拒絕九格。這是純 JVM 幾何／走訪，不載入 Minecraft，也不覆蓋真實物品分類／生成。
- 初次 `powershell -NoProfile -ExecutionPolicy Bypass -File docs/evidence/T-045/build.ps1` **退出 1**：修改掃描器後，方塊程式仍讀 `Position` 私有欄位 `x`；[失敗摘要](build-01.json)及[部分原始 log](build-01.log)保留。改為 record 存取方法後 [第二次 build](build-02.json)退出 0；再按 OLD 不傳樣板資料元件的語意將實體建構輸入固定為 `ItemStack.EMPTY`，最終 [第三次 build](build-03.json)退出 **0**，[最終完整 log](build-03.log)顯示 `BUILD SUCCESSFUL`。普通 Gradle `test NO-SOURCE`；首次失敗不冒充成功。
- 執行 `powershell -NoProfile -ExecutionPolicy Bypass -File docs/evidence/T-045/audit.ps1` 退出 0，[九項稽核與 class 差異](audit.json)通過。對 [T-044 固定 JAR](../T-044/artifacts/simplerail-1.0.0.jar) 比較，內容差異限 `TrainDispenserBlock`（含編譯器 switch class）與新增 `TrainDispenserScan` 三個 class；專用 BE、其他 class、資源內容不變。T-044 JAR SHA-256 `9B0107CA2DA90AA98946E12DB51A6508E7A927479A6F50D6305B1BA2E288C35A`。
- 最終 [T-045 固定正式 JAR](artifacts/simplerail-1.0.0.jar) SHA-256 `61B933A80F9B984E9AF35D7E55713803DF36328371D6B08CC02A63ADCEDA6C1E`；HEAD `11916b69c3549504928f7cfa6790d59a2717b4b6` 加既有未提交 T-038／T-041／T-040 R1／T-044 差異及本項兩份產品 Java，不能只由 commit 重建。

**判定界線：** 已有可編譯的原版車種／位置／觸發映射與無扣物實作；R-04 尚未審，T-120 原診斷案例與 T-047 正式世界驗收均沒有使用者結果。重複鄰居更新是否發生、碰撞與真正生成數、命令方塊車 fallback 的玩法期望、車頭及編組、GUI／存讀仍待對應任務。T-046 只針對後續確認的問題修正；本項不宣稱疑點 5 整體結案。
