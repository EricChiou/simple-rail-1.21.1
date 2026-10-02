# T-052 R2：改用一般礦車父類、禁止乘坐

狀態：**開發修正與非遊戲核對完成**；R-05／R-F 獨立程式複查與使用者 T-052 重測待執行。[使用者 R1 速度仍失敗及 R2 決策原文](USER_REPORT.md)已保存。R1 JAR／證據保留作歷史，不覆寫也不推定外觀曾通過。

`LocomotiveCartEntity` 現直接延伸 `net.minecraft.world.entity.vehicle.Minecart`。車頭不再覆寫 `getMaxSpeed`、`getMaxCartSpeedOnRail`、`applyNaturalSlowdown`、軌道移動或礦車種類，因而沿用一般礦車的速度上限、阻力及供電軌道加速規則。`interact` 不呼叫 `Minecart.interact` 的 `startRiding`，回傳 `PASS`；`canAddPassenger` 回傳 false，阻止正常乘坐。實體／物品 ID `simplerail:locomotive_cart`、車頭模型、`FACING`／`LINKABLE`、有序編組、NEW 資料欄位、單一掉落及拾取物品仍在。R1 已移除的 renderer 額外熔爐方塊分支保持移除。

行為差異：熔爐父類專屬的煤／木炭補燃料、推力、`Fuel`／`PushX`／`PushZ` 保存不再由車頭提供；一般礦車的 `getMinecartType()` 為 `RIDEABLE`，但本車頭不能乘坐。使用者這次要求「速度機制跟一般礦車保持一致，只是互動模式改成不能坐上去」，因此不保留 R1 的混合式燃料推進。此處不做 OLD 世界／NBT 轉換。既有 R1 測試世界若含熔爐父類欄位，這些欄位在 R2 不再使用；實際讀回及其餘自訂資料仍需使用者遊戲驗證，不宣稱已通過。

指定版來源：[普通 `Minecart`](../../T-013/sources/target/net/minecraft/world/entity/vehicle/Minecart.java)、[`AbstractMinecart`](../../T-013/sources/target/net/minecraft/world/entity/vehicle/AbstractMinecart.java)、[`Entity.canAddPassenger`](../../T-013/sources/target/net/minecraft/world/entity/Entity.java)；改動只在 [`LocomotiveCartEntity.java`](../../../../src/main/java/com/ericchiu/simplerail/entity/LocomotiveCartEntity.java)。`.\gradlew.bat build --offline --no-configuration-cache --console plain` 退出 0，[完整 log](build.log) 為 `BUILD SUCCESSFUL`；Gradle `test NO-SOURCE`。[固定 JAR bytecode 稽核](audit.json)退出 0，確認父類為 `Minecart`、沒有自訂速度／軌道移動覆寫、不能正常乘坐、renderer 沒有原版熔爐繪製呼叫，且自訂掉落／拾取／編組入口保留。這些不是 Minecraft 實測。

[T-052-R2 固定重測包](../../../test-packages/T-052-R2/README.md)的 JAR SHA-256 `7FBBD041165C15EF21397FEE7648EECCE7BC4713F440D197951311A7E7CB64DA`。HEAD `11916b69c3549504928f7cfa6790d59a2717b4b6` 加未提交產品差異，R1／R2 來源指紋見 `audit.json`；不能只由 commit 重建。T-052 整項仍需使用者重測 R2 速度、不能乘坐、外觀及原全部案例；獨立審查不能代簽遊戲結果。
