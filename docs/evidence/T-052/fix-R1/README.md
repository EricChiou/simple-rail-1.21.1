# T-052 R1：熔爐覆蓋與車頭速度修正

> R1 歷史快照。使用者確認 R1 速度仍過慢，已要求改為一般礦車父類；請使用[現行 R2](../fix-R2/README.md)及其固定重測包。R1 的燃料保留設計已被取代。

狀態：**開發修正與非遊戲驗證完成**；R-05／R-F 獨立程式複查待執行，T-052 使用者重測待執行。原始失敗及 T-103 完成確認見 [USER_REPORT.md](USER_REPORT.md)。使用者受測舊 JAR／版本未提供，不能把先前保存的 T-048 JAR 雜湊倒填為實際受測版。

| 問題與指定版來源 | 本次最小修正 | 待使用者重測 |
| --- | --- | --- |
| `MinecartFurnace.getDefaultDisplayBlockState` 回傳熔爐；本專案 `LocomotiveCartRenderer` 又呼叫 `getDisplayBlockState`／`renderSingleBlock`，在六盒車頭外加畫原版熔爐。OLD 自訂 renderer 只畫自訂模型。 | 移除 renderer 的 display block 分支，保留自訂模型、八方向、軌道插值、坡度、受損姿態及名稱繪製。沒有修改 entity display NBT 或貼圖。 | T052-R1-01：所有八方向、靜止／行進均無額外原版熔爐；自訂模型的爐體仍存在。 |
| `MinecartFurnace.getMaxCartSpeedOnRail()` 固定 `0.2f`，父類 `getMaxSpeed()` 陸地 `4/20`；一般礦車的 NeoForge 預設軌道 cap `1.2f`，原版普通軌道本身再限制 `0.4`。無推力時熔爐父類先乘 `0.98`，再施加一般礦車阻力。 | 車頭回到一般礦車的軌道 cap `1.2f` 與離軌 `8/20`；沒有燃料推力時按一般礦車的有乘客 `0.997`／空車 `0.96` 滑行；有推力時仍呼叫熔爐父類，保留原燃料／推力資料與行為。 | T052-R1-02～04：原版供電軌道可達一般礦車速度、無燃料滑行及燃料分支；高速度軌仍按軌道上限運作。 |

指定版 API／程式依據：既有 [`MinecartFurnace.java`](../../T-013/sources/target/net/minecraft/world/entity/vehicle/MinecartFurnace.java)、[`AbstractMinecart.java`](../../T-013/sources/target/net/minecraft/world/entity/vehicle/AbstractMinecart.java)、[`IAbstractMinecartExtension.java`](../../T-013/sources/target/net/neoforged/neoforge/common/extensions/IAbstractMinecartExtension.java)；OLD `D:\workspace\java\simple-rail\src\main\java\ericchiu\simplerail\render\LocomotiveCartRender.java` 為唯讀對照。正式修改僅 `LocomotiveCartEntity.java` 與 `LocomotiveCartRenderer.java`；來源前後 SHA、HEAD 與固定 JAR SHA 見 [audit.json](audit.json)。

驗證：`.\gradlew.bat build --offline --no-configuration-cache --console plain` 退出 0，[完整 build log](build.log) 顯示 `BUILD SUCCESSFUL`，Gradle `test NO-SOURCE`；`powershell -NoProfile -ExecutionPolicy Bypass -File docs/evidence/T-052/fix-R1/audit.ps1` 退出 0，從**固定 JAR bytecode** 核對 `1.2f`、普通礦車阻力／燃料分支及 renderer 無方塊繪製呼叫。兩者都不是 Minecraft 遊戲結果。

[T-052-R1 重測包](../../../test-packages/T-052-R1/README.md)的正式 JAR SHA-256 `5E4858167925DE9B22161781AE89649BDA87948E285F3AA5CCFAF008777898BD`。HEAD `11916b69c3549504928f7cfa6790d59a2717b4b6` 加未提交產品差異，不能只由 commit 重建。待獨立 Review Agent 複查後交使用者；不變更 OLD、D1–D8、ID、Gradle 或資源檔。T-052 其他原定雙 client、掉落、命名、碰撞與材質案例仍需使用者確認。
