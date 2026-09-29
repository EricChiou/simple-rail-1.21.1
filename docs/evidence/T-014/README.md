# T-014 實體生成、追蹤與資料同步 API 查證

日期：2026-09-27。狀態：**開發交付完成；R-01 程式審查待審；人工遊戲測試未執行**。本項只查證 OLD FACING／LINKABLE 與生成接線在 Minecraft 1.21.1＋NeoForge 21.1.251 的去向，提供指定版**可編譯候選**與可交使用者操作的同步測例規格。OLD 行為均為**依原始碼推定／待確認**；不重跑 OLD build，不啟動 NEW client／server，不增加自訂網路頻道。

## 版本、來源與執行證據

- NEW HEAD `8bd977dbb9f9000411ae5f4d10750228e5f33560`；OLD 參照 HEAD `6698b1c5f494095a15b055c10045293e91540012`（T-003 來源盤點；本輪未建置 OLD）。指定版來源封包 `build/moddev/artifacts/neoforge-21.1.251-sources.jar`，SHA-256 `236151EDEC930A89E78054FCB5551323761F801778305F290D0B74238C33693E`。[來源名冊](source-manifest.json)固定 21 個 1.21.1／NeoForge 來源與 5 個 OLD 來源及逐檔雜湊，OLD 五檔與 T-003 名冊核對相同。來源收集命令 `& ([scriptblock]::Create((Get-Content -Raw -Encoding UTF8 docs/evidence/T-014/collect.ps1)))` 退出 0，[結果](collection.json)。
- 官方指定版 [registries 文件](https://docs.neoforged.net/docs/1.21.1/concepts/registries/)用於註冊背景；舊 `EntityDataSerializers.registerSerializer` 能否沿用、封包接線與方法簽名均以本地 NeoForge **21.1.251** 來源為準，沒有借用較新版文件推定 API。
- [最小探針](probe/T014Probe.java)以[獨立 JavaCompile 任務](probe.init.gradle)執行 `.\gradlew.bat compileT014Probe --offline --console=plain --info --no-configuration-cache -I docs/evidence/T-014/probe.init.gradle`。[首次嘗試](compile-01.json)因沙箱對 `C:\.gradle\...zip.lck` 無寫入權退出 **1**，[log](compile-01.log)保留；經允許沙箱外[第二次](compile-02.json)退出 **0**、`BUILD SUCCESSFUL`，[完整 log](compile-02.log)保留。使用 Java 21.0.12.1、`--release 21 -Xlint:deprecation -Werror`；[classpath](compile-classpath.txt)、[compiler](compiler.txt)、[3 個 major 65 class](compiled-classes.json)、[指紋與範圍](verification.json)均留存。探針未載入或執行，**不是產品 build、封包收發或遊戲驗收**。
- [任務／依賴／來源／文件自查](final-check.json)僅為本 Agent 靜態自查，不是 R-01 獨立審查。12 個產品基線檔與 T-009 相同，產品 Java／Gradle／資源無差異。

下列 `M/` 代表 `sources/target/net/minecraft/`，`N/` 代表 `sources/target/net/neoforged/neoforge/`，`O/` 代表 `sources/old/`；完整原始路徑及雜湊見[來源名冊](source-manifest.json)。

## 舊欄位用途與新版去向

| 舊欄位／接線 | OLD 可見用途（非舊版實測） | 指定版依據與候選 | 後繼責任／未驗證 |
| --- | --- | --- | --- |
| `FACING` | `O/entity/LocomotiveCartEntity.java:42–43,68–72,161–196,218–219,247–285`：自訂 enum serializer、預設 NORTH、位置／動量更新八向、`Facing` 字串存讀；`O/render/LocomotiveCartRender.java:99–120` 實際讀它決定車頭模型角度 | `M/network/syncher/EntityDataSerializers.java:44,79` 內建 `BYTE`／`BOOLEAN`；`M/network/syncher/SynchedEntityData.java:75–125,170–186` 提供 `define`／`set`／dirty 與非預設值。探針以明訂 0–7 編碼的 `EntityDataAccessor<Byte>` 傳八向，保留字串 `Facing` 供 NEW 自身存讀；client 只讀同步值，server tick 才寫 | T-049 正式定義 enum↔byte、初始朝向、同步與重連；T-050 renderer 引用 getter；T-052／T-065 使用者驗 8 向及雙端，錯值預設／記錄策略待定 |
| `LINKABLE` | `O/entity/LocomotiveCartEntity.java:44–45,68–72` **只**定義為 `BOOLEAN=true`；全文來源搜尋未見 get／set、NBT、實際連結條件讀取。連結資格走 `O/link/LinkageManager.java` 的 UUID map，非此欄位 | 探針仍以內建 `EntityDataSerializers.BOOLEAN` 定義預設 true，給 T-049 一個可編譯的保留途徑；`M/server/level/ServerEntity.java:83,255–256` 非預設值才在初始追蹤封包中附送，因此預設 true 由 client 相同定義取得。**不聲稱**此欄位已有玩法功能 | T-049 可在審查後保留恆 true 或移除無讀取欄位；兩種都須在欄位／測例表說明。若產品賦予可變語意，須另定誰寫／誰讀及實測，不能憑名稱擅加新玩法 |
| 舊 enum serializer | `O/setup/SimpleRailDataSerializers.java:10–50` 自訂 `IDataSerializer<FacingDirection>`、寫／讀 enum；`O/SimpleRail.java:52` 呼叫 `DataSerializers.registerSerializer`，只供 `FACING` 使用 | `M/network/syncher/EntityDataSerializers.java:130–145` **明確禁止**模組再呼叫 `registerSerializer`（會拋 `UnsupportedOperationException`）；如確需 typed enum，須走 `N/registries/NeoForgeRegistries.java:34,49` 的 `ENTITY_DATA_SERIALIZERS` registry，並有穩定新 ID／兩端註冊。首選 `BYTE` 已可表示八向且編譯，故本輪**不新增 serializer ID** | T-049 判斷是否有 byte 方案不能滿足的需求；不可複製 OLD `setup()`，不可在 client/server 定義不同 accessor 順序。自訂 registry 替代方案未編譯、未選用 |
| 生成封包／client factory | `O/entity/LocomotiveCartEntity.java:63–64,89–92` 有 Forge 舊 `SpawnEntity` 建構子與 `NetworkHooks.getEntitySpawningPacket`；`O/registry/Entities.java:18–24` 設 `setCustomClientFactory`、tracking 8 | `M/world/entity/Entity.java:3428–3430` 已有 `getAddEntityPacket(ServerEntity)`，`M/client/multiplayer/ClientPacketListener.java:481–503` 由封包 EntityType `create(level)` 並 `recreateFromPacket` 建 entity；`M/world/entity/Entity.java:3562–3573` 設位置、ID、UUID。探針的 `(EntityType, Level)` 工廠及繼承封包方法編譯，沒有舊式零參數覆寫或 client factory | T-019／T-048 註冊並在 client／server 實際載入；T-049 核對 spawn packet／data bundle；本探針不能證明實際 handshake。未選用 `IEntityWithComplexSpawn` 或自訂 payload |
| 追蹤中更新／重新加入 | OLD FACING 在 tick 設值，執行端判斷不足（`O/entity/LocomotiveCartEntity.java:115–136,259–285`） | `M/server/level/ServerEntity.java:239–256,325–331` 初次／重新配對時依序加入 spawn packet、非預設 synced data，之後 `packDirty()` 送變更；`M/client/multiplayer/ClientPacketListener.java:558–565` `assignValues` 到 client。`M/server/level/ChunkMap.java:1110–1122,1320–1343` 依範圍與 chunk tracking 建立／移除配對 | T-049 保持 FACING server-authoritative，不在 client tick 回寫；T-052／T-065 使用者測加入、重連、出入追蹤範圍。實際延遲與渲染切換仍未測 |
| 實體數／UUID／名稱／編組 | OLD 原碼有車頭 UUID 和名稱，編組 `Train` 存車頭但未見同步到 client 的獨立欄位（T-013 來源參考） | `ClientboundAddEntityPacket` 含 ID、UUID、EntityType、位置／動量（`M/network/protocol/game/ClientboundAddEntityPacket.java:35–110`）；`M/world/entity/Entity.java` 原版自訂名及實體生成／保存路徑，名稱後續由既有 entity-data 接線處理。T-013 的編組 UUID 清單是 server 權威與持久資料，**本輪不把整列 UUID 廣播到 client** | T-049 若畫面或互動確需編組詳情，須先列消費端、最小資料與同步途徑；目前不推定要新增頻道。T-052／T-065 核對兩端可觀測數量、UUID、名稱及朝向 |

`EntityType.Builder#clientTrackingRange(8)` 在 OLD 是宣告；指定版 `M/world/entity/EntityType.java:1189–1205,1359–1367` 與 `M/server/level/ChunkMap.java:1110–1122,1320–1343` 顯示目標將該值乘 16 後仍與玩家 view distance 取較小者，並要求相關 chunk 已被追蹤。故測例只能記錄**實際配對邊界**，不可武斷寫「距離 128 格必定切換」。`EntityType.Builder` 的預設 update interval 為 3（同檔 1250–1260），實際伺服器封包時序及 M-04 容許窗口仍**待技術定義**。

## 同步資料流與端權責

| 時點 | server 權威動作 | client 預期／證據 |
| --- | --- | --- |
| 註冊與生成 | 保留 ENTITY_TYPE ID `simplerail:locomotive_cart`；以 `(EntityType, Level)` 工廠建立，先設定朝向與名稱、再 `addFreshEntity`。`ServerEntity` 建立時記非預設 entity data 快照 | 由 `ClientboundAddEntityPacket` 建同型別 client entity，先有 UUID／位置；未收到資料前預設 NORTH／LINKABLE=true |
| 首次加入／重新配對 | `ServerEntity#sendPairingData` 先送 add packet，再送非預設 data；相同方案應適用新加入、重新連線與再次進入追蹤範圍 | `ClientPacketListener#handleAddEntity` 建 entity；`handleSetEntityData` 再套 FACING；兩端 renderer 只讀最終值。短暫預設畫面是否可見待實測 |
| 方向變更 | 只在 server tick 判斷動量、`entityData.set(FACING, byte)`；相同值不標 dirty；車頭 NBT 保存方向字串 | `ServerEntity#sendDirtyEntityData` 廣播 `ClientboundSetEntityDataPacket`；client `assignValues`，不得在 client tick 另算方向蓋掉 server 值 |
| 暫離／重連 | 追蹤解除後仍以同 server entity／新世界存檔為權威；再次配對按目前非預設值重送。卸載恢復靠車頭保存 `Facing`，不靠先前 client 寫入 | 重新生成 client 實體，核對 UUID、方向與名稱；無殘留舊實體或雙重生成 |

`LINKABLE` 目前只有預設 true，沒有 OLD 可見的消費端；若保持不變，`getNonDefaultValues()` 不會為它送額外初始值。測試包若無可觀測欄位或診斷資訊，不能由 GUI 猜出其網路值；T-049 應審查其去留與靜態覆蓋。指定版 [SynchedEntityData 原始碼](sources/target/net/minecraft/network/syncher/SynchedEntityData.java) 也顯示 accessor 順序／serializer ID 錯配會在 decode／define 階段出錯，不能靠編譯證明 client／server runtime 一致。

## 交使用者的 C-025／C-024 操作規格（尚未執行）

此規格只是 T-049／T-103 等後續**固定版本測試包**的輸入，不是目前可直接執行的包；包仍須含 commit、JAR SHA-256、版本、啟動命令與取證方式，且先有獨立程式審查。M-04 三端時鐘對齊、追蹤事件判定與可接受延遲窗口須**待技術定義**並於正式測試前固定，不能看到結果後補門檻。

| 案例 | 使用者操作（在固定 JAR 的 dedicated server） | 事前預期與需回傳證據 |
| --- | --- | --- |
| C-025/A 初次與新玩家 | client A 放置一台有名稱車頭，記 server 世界與車頭 UUID；client B 首次加入相同維度並靠近 | server、A、B 只各見同一 UUID 一台車頭，名稱與可見朝向一致；三端版本／JAR SHA-256、登入及生成時間、原始 log、對齊截圖／錄影 |
| C-024/B 八向變更 | 依已定路線／可重現輸入逐一造成 E、W、N、S、NE、NW、SE、SW，車頭運動後停止；A、B 同時觀察 | 每向對照 renderer 方向表，伺服端方向權威且兩端最終一致；每向時間、座標、UUID、畫面、server 事件或事先設計的診斷讀值。模型／UV 另由 T-015／T-050 承接 |
| C-025/C 重新連線 | A 保持在場，B 斷線；A 改變車頭方向或狀態，B 重連 | B 收目前狀態，不沿用斷線前舊方向；UUID／實體數量與 server、A 一致；三端登入／離線時間、log、前後畫面 |
| C-025/D 追蹤範圍進出 | B 逐步離開直到確認車頭不再被 B 追蹤，記位置／時刻，再返回；A 留在原地 | B 重新看到相同 UUID、名稱與現時朝向，無複製或殘留；實際觸發邊界與兩端畫面／log 記錄，不預填 128 格為門檻 |
| C-025/E 雙端操作 | A、B 分別依已完成的 T-051／T-057 玩家入口執行放置、連結或改向；缺入口者列受阻，不虛構可測結果 | server 只接受預定一次的生成／扣物／連結，兩端最後一致；保存逐步物品、車頭與車廂 UUID、三端 log。疑點 U-06 的實際重現／修正另由 T-063–T-065 |

人工結果欄全部**留白**；只有使用者提供的逐例觀察才能填寫「通過／不通過／受阻」。T-089 單 client 連線基線、T-090 包及後續候選程式審查均仍待執行，不能用 T-006／T-007 的歷史 Agent 啟停紀錄代替雙 client 驗收。

## 完成條件與未驗證範圍

| T-014 條件 | 已保存證據 | 判定 |
| --- | --- | --- |
| FACING／LINKABLE／舊 enum serializer 逐一有去向及來源 | 上述 OLD／指定版對照、26 個來源快照，明列 built-in BYTE／BOOLEAN、舊直接註冊會拋例外、LINKABLE 尚無玩法消費端 | **來源與設計完成**；T-049 定產品取捨 |
| 生成與初始資料可編譯 | 探針 `(EntityType, Level)`、`defineSynchedData(Builder)`、8 向 byte、server set、NBT 字串、繼承 `getAddEntityPacket(ServerEntity)`；compile-02 退出 0、3 個 class major 65 | **最小編譯完成**；未執行握手／renderer |
| 新加入／重連／追蹤重入方案可操作 | C-025／C-024 表、三端證據欄、實際配對前提及 M-04 待定門檻 | **測例規格完成**；尚無固定 JAR 或使用者遊戲結果 |

未驗證：真實 registry 載入、server/client accessor 一致性、初始封包順序在畫面上是否產生瞬間錯向、兩端移動與八向顯示、名稱／UUID、重連、追蹤重入及 U-06 重複執行。T-049 實作前須明確決定 `LINKABLE` 的去留與 M-04 量測門檻；T-050／T-052／T-063–T-065／T-084 使用者案例和 R-01 程式審查仍待進行。本探針不宣稱 1.21.1 遊戲語意、模組 build 或人工測試已通過。
