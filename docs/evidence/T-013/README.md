# T-013 車頭、車廂運動與保存 API 查證

日期：2026-09-27。狀態：**開發交付完成；R-01 程式審查待審；人工遊戲測試未執行**。本項只對照 OLD 來源與 Minecraft 1.21.1／NeoForge 21.1.251 指定版來源，提出可編譯的車頭、放置、運動、保存與編組資料邊界。OLD 行為均屬**依原始碼推定／待確認**；不重跑 OLD build，不讀取或轉換舊世界／舊 NBT。探針只在本證據目錄，未加入產品 sourceSet 或 JAR，沒有執行。

## 版本、命令與證據範圍

- NEW HEAD `8bd977dbb9f9000411ae5f4d10750228e5f33560`；OLD 參照 HEAD `6698b1c5f494095a15b055c10045293e91540012`（沿 T-003 來源清單；不代表本輪 OLD build）。目標來源封包 `build/moddev/artifacts/neoforge-21.1.251-sources.jar`，SHA-256 `236151EDEC930A89E78054FCB5551323761F801778305F290D0B74238C33693E`。[來源名冊](source-manifest.json)固定 25 個指定版來源、6 個 OLD 來源及逐檔雜湊；OLD 六檔與 T-003 來源清單核對相同。
- 官方 1.21.1 [registry 規格](https://docs.neoforged.net/docs/1.21.1/concepts/registries/)和[物品資料元件規格](https://docs.neoforged.net/docs/1.21.1/items/datacomponents/)用於版本背景；精確的類別、覆寫簽名、父類欄位與生命週期以本地 21.1.251 來源快照為準。來源收集命令 `& ([scriptblock]::Create((Get-Content -Raw -Encoding UTF8 docs/evidence/T-013/collect.ps1)))` 退出 0，[紀錄](collection.json)。首次收集腳本路徑寫錯 `ServerLevelAccessor`，當時退出 1 且未產生 manifest；修正後完整收集退出 0，不將首次誤記為成功。
- [編譯探針](probe/T013Probe.java)與[獨立 Gradle 任務](probe.init.gradle)使用 `.\gradlew.bat compileT013Probe --offline --console=plain --info --no-configuration-cache -I docs/evidence/T-013/probe.init.gradle`。[第一次](compile-01.json)受沙箱外 `C:\.gradle\...zip.lck` 權限限制退出 **1**，[原始 log](compile-01.log)保留；經允許沙箱外[第二次](compile-02.json)退出 **0**、`BUILD SUCCESSFUL`，[完整 log](compile-02.log)保留。Java 21.0.12.1、`--release 21 -Xlint:deprecation -Werror`；[classpath](compile-classpath.txt)、[compiler](compiler.txt)、[4 個 major 65 class](compiled-classes.json)、[指紋與未變更範圍](verification.json)均留存。只做最小 JavaCompile，**不是模組 build、實體載入、遊戲或資料讀寫測試**。
- [任務、依賴與證據自查](final-check.json)僅為文件／雜湊檢查，不是獨立程式審查。產品 Java、Gradle、資源的 12 個基線檔與 T-009 一致；`git diff HEAD --name-only -- src build.gradle settings.gradle gradle.properties gradle gradlew gradlew.bat` 為空。

下列 `M/` 為 `sources/target/net/minecraft/`，`N/` 為 `sources/target/net/neoforged/neoforge/`，`O/` 為 `sources/old/`；[名冊](source-manifest.json)提供完整路徑與 SHA-256。

## 逐行為 API 對照與後繼責任

| T-013 行為 | OLD 來源與推定 | 指定版候選與證據 | 後續工作／待確認 |
| --- | --- | --- | --- |
| 車頭父類及 ID | `O/entity/LocomotiveCartEntity.java:40–60` 繼承 `FurnaceMinecartEntity`，建構子忽略傳入 `type` 而使用靜態 `CART_TYPE`；`O/registry/Entities.java:18–24` ID `simplerail:locomotive_cart`、0.98×0.7、tracking 8 | `M/world/entity/vehicle/MinecartFurnace.java:24–40` 的 `(EntityType<? extends MinecartFurnace>, Level)`，`M/world/entity/EntityType.java:1389` Builder `build(String)`；探針 `Locomotive::new` 與 `.sized/.clientTrackingRange` 編譯，建構子使用實際傳入型別 | T-019／T-048 正式 registry、尺寸與載入；不因構造錯誤變更 ID。client factory／spawn 封包屬 T-014，不由本編譯推定 |
| 手持放置 | `O/item/LocomotiveCart.java:29–60` 允許自訂與原版 rail tag，中心 +0.0625、坡 +0.5；舊碼先 `shrink(1)` 再讀名稱，最後 1 件命名行為未實測 | `M/world/item/MinecartItem.java:86–120`、`M/world/level/block/BaseRailBlock.java:180`、`M/world/item/ItemStack.java:758–760`、`M/core/component/DataComponents.java:70`；探針用 `UseOnContext`、兩種 tag、`BaseRailBlock#getRailDirection`、`ServerLevel#addFreshEntity`，在消耗前取 `CUSTOM_NAME` | T-051 定義消耗、創造模式、放置失敗與雙端副作用；T-052 由使用者測名稱／座標／尺寸。探針**沒有**呼叫 `shrink`，不代表規格已改成免費放置 |
| 運動與跟車 | `O/entity/LocomotiveCartEntity.java:115–138,297–366` 以 `prevPos`、`stopPos`、中心區間控制移動，`moveTo` 後清速度 | `M/world/entity/Entity.java:1445–1465` 提供 `moveTo`，`M/world/entity/vehicle/AbstractMinecart.java:253–335,378–483` 仍有軌道移動與碰撞流程；探針只編譯伺服端 `ServerLevel#getEntity(UUID)`、`moveTo`、`setDeltaMovement(Vec3.ZERO)` | T-053–T-055 才實作節拍／次序／跟車。探針的每 tick resolve／move 是**簽名示意**，不能直接視為 OLD 運動等價 |
| 碰撞 | `O/entity/LocomotiveCartEntity.java:140–145,199–215` 只對玩家調父類 `push`；玩家不碰撞，其他礦車同速，運動時其他活體 `kill` | `M/world/entity/vehicle/AbstractMinecart.java:146,679–742` 的 `canCollideWith`／`push` 及 `M/world/entity/Entity.java:333–339` 的 `kill`／`discard`；探針覆寫前兩者驗簽 | T-048／T-052／T-062 釐清觸發端、乘客／活體安全與原運動效果；探針未複製殺死活體分支，不能稱碰撞已移植 |
| 動力父類欄位 | OLD `getMinecartType=FURNACE`、`isPoweredCart=false`（`O/entity/LocomotiveCartEntity.java:94–111`），但仍繼承爐車 | `N/common/extensions/IAbstractMinecartExtension.java:72–74` 的預設 `isPoweredCart` 由 minecart type 判斷，須覆寫 false；`M/world/entity/vehicle/MinecartFurnace.java:54–57,85–117,121–158` 仍保有 `fuel`、`xPush`／`zPush`、燃料互動、自然減速及保存欄位 `Fuel`／`PushX`／`PushZ`。探針覆寫 `isPoweredCart` 編譯 | T-048 必須逐項決定是否沿用父類燃料互動與推力，不能以 false 推論完全沒有爐車動力；T-052 由使用者測速度／燃料。未定玩法標**待確認** |
| 破壞／掉落／刪除 | `O/entity/LocomotiveCartEntity.java:75–87,236–245,288–290` 依 `doEntityDrops` 生單一車頭物品並保名；`deleteTrain` 直接移除已持有車廂 | `M/world/entity/vehicle/VehicleEntity.java:30–63,98–102` 的 `destroy(DamageSource)`→`destroy(getDropItem())` 已含一份掉落與 custom name；`M/world/entity/Entity.java:333–359,3890–3906` 區分 KILLED／DISCARDED 與 UNLOADED_TO_CHUNK；覆寫 `getDropItem`、`getPickResult`、`destroy` 均編譯 | 探針 `Items.MINECART` 只佔位，T-048 必須換回 `simplerail:locomotive_cart` 且避免雙重掉落；`VehicleEntity#hurt` 的創造模式 `discard` 可繞過 `destroy`，T-048／T-061 需處理真正移除時的編組清理。T-062 人工核對掉落、名稱、乘客及容器 |
| UUID 查找與生命週期 | `O/link/LinkageManager.java:13–73` 全域 static map 沒維度鍵；`O/entity/LocomotiveCartEntity.java:297–307,334–340` 查無車廂就丟棄／截斷 | `M/server/level/ServerLevel.java:1326–1327` 的 `getEntity(UUID)` 經 `LevelEntityGetter` 查目前可見者；`M/world/level/entity/PersistentEntitySectionManager.java:145–185,227–236,305–310` 隱藏／卸載會移出索引，`Entity.RemovalReason.UNLOADED_TO_CHUNK` 設為可保存。`isLoaded(UUID)` 只看當時 `knownUuids`，不能查整個磁碟世界 | T-053／T-054／T-055 以車頭持久有序 UUID 清單為權威，查不到只標 pending；實際刪除／解除連結才移除。T-056／T-082／T-084 由使用者測晚載入、跨維度及重啟。避免再次做 OLD 的「查不到即刪」；具體刪除認定仍**待確認** |
| 新世界存讀 | `O/entity/LocomotiveCartEntity.java:148–197` 寫 `Train` UUID 字串 List、`Facing` 八向字串；`prevPos`／`stopPos` 沒自訂保存 | `M/world/entity/Entity.java:1730–1800,1840–1896` 保存／讀回 UUID、位置、速度、自訂名並呼叫子類 `addAdditionalSaveData`／`readAdditionalSaveData`；`M/world/entity/vehicle/MinecartFurnace.java:145–158` 又保存推力／燃料。探針呼叫 `super`，以 `CompoundTag`／`ListTag`／`StringTag` 編譯 `Train`、`Facing` 及新候選 `PrevPos`／`TrainStops` | T-053 固定**只用於 NEW 新世界**的資料 schema、缺鍵／錯鍵政策和 stop 位置還原。`Train` 順序與八向 Facing 不得丟失；不需兼容 OLD NBT。T-082 驗兩次重啟；單次編譯不證讀回正確 |

新版未見可直接沿用的舊 `getCartItem`／`getPickedResult` 簽名；指定版 `AbstractMinecart#getPickResult`（`M/world/entity/vehicle/AbstractMinecart.java:917–925`）和 `VehicleEntity#getDropItem` 承接 pick／drop，不能依 `FURNACE` 類別默認產出爐車物品。`O/setup/SimpleRailDataSerializers.java` 的 FACING／LINKABLE 同步及實體初始封包完整接線由 T-014 查證；本項只承諾持久化朝向的資料責任，不把探針的本地 `Facing8` 欄位當成已完成同步。

## 資料所有權與載入狀態方案

| 資料／狀態 | 權威位置及候選生命週期 | 無法查到車廂時 |
| --- | --- | --- |
| 車頭 UUID、維度 | Vanilla Entity `UUID` 及所屬 `ServerLevel`；每個車頭資料只與該世界的實體關聯，不使用跨維度 static map 作持久權威 | 車頭未載入也不應由其他維度的掃描清掉；索引策略交 T-053／T-054 |
| 有序車廂 UUID | 車頭自訂保存資料 `Train` 的順序清單；增減需顯式連結／解除、永久移除處理，保存時不從目前已載入 cache 重新生成 | 標 `pending/unresolved`，保留位置和 UUID，後續區塊載入可再查；不當成已刪除 |
| 車廂實體引用 | 只放在各 `ServerLevel` 的 transient resolve/cache，且每次使用先驗 `!isRemoved`、型別及 level；緩存失效時重查 | 移除 transient 引用，不變更持久 UUID 清單 |
| 朝向 | 車頭 `Facing` 八向；伺服端運動更新，保存與讀回用固定字串／enum 對照。client 同步另 T-014 | 未知值／缺鍵的預設與錯誤記錄由 T-053 固定；探針預設 NORTH 只是候選 |
| 上次位置／各車 stop 位置 | NEW 新世界候選 `PrevPos` 與依車 UUID 鍵控的 `TrainStops`，避免車廂晚載入時槽位與 stopPos 錯配；可改用有來源的重建規則，但須先定義跨區塊恢復情境 | 位置不存在時不可憑空 teleport；只等待定位或採 T-053 明定的安全恢復方式 |
| 真正刪除 | `KILLED`／`DISCARDED` 的 `shouldDestroy()` 與顯式 unlink／deleteTrain 可作事件線索；`UNLOADED_TO_CHUNK` 的 `shouldSave()` 意味卸載並非刪除 | 無法由 `getEntity(UUID)==null` 或 `PersistentEntitySectionManager#isLoaded(UUID)==false` 證明永久刪除。刪除證據來源、跨維度與車廂個別移除政策屬 U-01／T-054 |

建議 T-053 實作先確立 `Train`、`Facing`、stop 位置與版本欄位的 NEW schema 和不變式，再寫編組管理器；T-054 調查已列 U-01 的晚載入／跨維度問題，再在確認後由 T-055 修正與 T-056 人工回歸。`PrevPos`／`TrainStops` 是**候選新資料鍵**，不是舊 NBT 相容要求，也不是本輪已實作的格式。

## 本項完成條件與限制

| 條件 | 可覆核證據 | 判定 |
| --- | --- | --- |
| 父類、放置、命名、運動、碰撞、刪除、掉落、UUID、保存逐項有指定版依據與候選方法 | 逐行為表、31 個來源快照、[探針](probe/T013Probe.java)與 [compile-02](compile-02.json)／[log](compile-02.log)；4 個 class major 65 | **來源及簽名候選完成**，不代表遊戲語意等價 |
| UUID 次序、朝向、暫存位置與父類欄位責任明確 | 上述資料所有權表、`Train`／`Facing`／`PrevPos`／`TrainStops` 候選、父類 `Fuel`／`PushX`／`PushZ` 路徑 | **設計完成**；schema、燃料政策與實際重建交 T-048／T-053 |
| 未載入與已刪除分開 | `ServerLevel#getEntity`、`PersistentEntitySectionManager` 及 `RemovalReason` 來源；探針 `null` 不清單 | **設計完成**；無全世界刪除判定 API 的假定，晚載入仍待使用者實測 |

未驗證：產品 entity registry／放置與損耗、命名、父類燃料動作、碰撞、掉落、編組移動與多輪存讀、跨維度、晚載入及多人同步。這些分別由 T-014、T-019、T-048、T-051–T-056、T-061–T-062、T-082／T-084 和使用者人工案例承接。R-01 程式審查也尚未執行；不得將本探針當成已移植或人工測試結果。
