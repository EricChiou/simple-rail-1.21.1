# T-033 移除軌來源、API 與副作用契約

2026-09-29。對應 MIGRATION.md §3 destory_rail、§4.1／§4.4、§6 階段 3；T-003 B-08／U-06／U-10、T-004 C-011、T-010 A05／A09、T-013 移除／掉落對照。OLD 行為全部 **依原始碼推定／待確認**；OLD 原版父類的 remove 副作用沒有本輪來源／實測證據，不將 NEW 副作用倒填為 OLD 已驗證。

## 行為與指定 API

| 項目 | OLD 原始碼 | NEW 交付與界線 |
| --- | --- | --- |
| ID／基本行為 | [DestoryRail](sources/old/DestoryRail.java) extends BasePoweredRail；!needPower OR powered；普通 cart.remove，車頭 deleteTrain | same simplerail:destory_rail；普通原版各礦車透過 cart.discard。T-061／T-062 整列分支未實作，不新增車頭類或假刪編組接口 |
| 預設／設定 | [CommonConfig](sources/old/CommonConfig.java) destoryRailNeedPower=false；建構讀設定 | constructor need_power=false 並保留父類 shape=NS／powered=false／waterlogged=false；T-020 原 rail.destory_rail.needPower 鍵不變。server hook 一份當前 Snapshot，stored need_power 只供模型投影 |
| 放置／重載 | OLD 帶設定 state 交 onPlace 父類 | server 新放置投影快照；same block 不讀／重投影。[BaseRailBlock](sources/target/net/minecraft/world/level/block/BaseRailBlock.java)→updateDir(alwaysPlace=true)→[RailState](sources/target/net/minecraft/world/level/block/RailState.java).place 寫回。重載不掃世界；既有 need_power 可與規則不一致，待人工 |
| 執行端／重複移除 | OLD 無顯式判端／already-removed guard | 只在 ServerLevel 且 cart.isRemoved=false 執行；在讀設定之前排除其他端／已移除車。移除及效果只一次；這是 NEW 端權責與防重複適配，不將 U-06／U-10 視為全部結案 |
| 真正移除 | OLD cart.remove 的父類副作用未確認 | [Entity](sources/target/net/minecraft/world/entity/Entity.java) final discard→virtual remove(DISCARDED)→setRemoved；DISCARDED.shouldDestroy=true、shouldSave=false。setRemoved 呼叫自己 stopRiding、直接乘客 stopRiding、levelCallback.onRemove；不是 damage／kill／UNLOADED_TO_CHUNK |
| 一般車體掉落 | 不能從 OLD mod 直接 remove 推定全部車種掉落 | [VehicleEntity](sources/target/net/minecraft/world/entity/vehicle/VehicleEntity.java) destroy(Item) 才含車體物品生成。rail 不呼叫 hurt／destroy／spawnAtLocation／自訂 loot；此一般 discard 路徑沒有 rail-added 車體物品。不能據此宣稱實際世界完全沒有物品／其他同 tick 副作用 |
| 容器內容 | OLD 本輪未查原版容器父類 | [AbstractMinecartContainer](sources/target/net/minecraft/world/entity/vehicle/AbstractMinecartContainer.java).remove 在 server 且 reason.shouldDestroy 時先 [Containers.dropContents](sources/target/net/minecraft/world/Containers.java)，再 super.remove。箱子／漏斗車仍保留虛擬分派、內容 hook；不清空、不壓制掉落或補第二份。remove 方法本身沒有 doEntityDrops gate；實際堆疊／loot 解包／事件／gamerule 結果仍待人工 |
| 父類剩餘工作 | mod 回呼無法從源碼宣稱立即結束整個 tick | [AbstractMinecart](sources/target/net/minecraft/world/entity/vehicle/AbstractMinecart.java) 先移動／摩擦再 onMinecartPass，回呼後仍可動力加速。rail 不改速度／位置，不掃鄰車、不依軌向／來車方向觸發 |
| TNT 特別界線 | OLD 父類未查證 | [MinecartTNT](sources/target/net/minecraft/world/entity/vehicle/MinecartTNT.java).tick 在 super.tick 後仍檢 fuse／horizontalCollision，explode 分支未因本軌道 discard 自動 return。只確認 rail 不走 destroy(DamageSource) 的引信邏輯，不能聲稱到軌道即保證無爆炸；未新增抑制政策，針對性 T-034 案例仍待使用者 |
| 粒子 | OLD world.addParticle LARGE_SMOKE、一顆、零速度、rail+(0.5,0.75,0.5) | 目標 [Level](sources/target/net/minecraft/world/level/Level.java) 基底 addParticle 空方法；採 [ServerLevel](sources/target/net/minecraft/server/level/ServerLevel.java).sendParticles count=1／offsetXYZ=0／speed=0，正常 32 格接收範圍，不強制長距離。[ClientPacketListener](sources/target/net/minecraft/client/multiplayer/ClientPacketListener.java).handleParticleEvent count=1 時執行一次 addParticle，零 spread／speed。來源＋編譯，不是已實際顯示 |
| 聲音 | OLD playLocalSound GENERIC_BURN／BLOCKS／4.0F／4.0F，false distanceDelay | 目標 Level.playLocalSound 基底空方法，改 ServerLevel.playSound(null,x,y,z,GENERIC_BURN,BLOCKS,4,4)，繼承 overload→playSeededSound→server 廣播；不排除任何指定玩家。保留原聲音／分類／音量／pitch／座標，不模擬 client distanceDelay 或保證人人聽到 |
| 狀態／資源／保存 | 原六 selector、無專用 BE／NBT | need_power、父類 powered／shape／waterlogged；[48 狀態](state-coverage.json) 中 16 平軌唯一匹配原模型，32 非自然坡未映射。繼承共同速度／禁坡／實體破壞 false，只加 pickaxe 分類；blockstate 保存／既有同步，無自訂 packet／票證／舊 NBT 轉換 |

以上目標來源固定到 Minecraft 1.21.1／NeoForge 21.1.251 merged archive，19 快照與 archive SHA-256 見 [manifest](source-manifest.json)。NEW build／bytecode 確認實際泛型與 overload；未聲稱全面 API 或遊戲驗證完成。

## 條件矩陣與測試界線

| 當前 needPower | powered | 未移除目標之預期 hook |
| --- | --- | --- |
| false | false | discard＋煙霧／聲音 |
| false | true | discard＋煙霧／聲音 |
| true | false | 保留目標，無效果 |
| true | true | discard＋煙霧／聲音 |

非 ServerLevel／已移除目標一律返回，不讀設定。移除效果座標固定為 `(X+0.5,Y+0.75,Z+0.5)`，與當前車輛浮點位置、軌向及速度無關。空軌沒有過車回呼／沒有本軌額外排程，不主動找車。

[四列矩陣](behavior-matrix.json) 全部 gameResult=null。實際產品 hook 隔離測試再覆蓋 2 平軌向、2 stored need_power、2 正負座標／高度、5 入速向量、一般／容器分派替身、有／無乘客；共 640 次初始回呼，另驗 already-removed 重複呼叫、constructor、client／非 ServerLevel、placement／same block、設定重載。8,173 判定通過；[26 個本地替身](test-double-fingerprints.json) 不載入真實 Minecraft、ConfigSpec／eventbus／loot／inventory 或網路。

容器替身只確認 virtual remove 呼叫一次，**不是內容實測**；乘客替身只模擬父類 detach，不驗原版玩家定位；ServerLevel 替身記錄聲音／粒子參數與順序，不送封包。isRemoved guard 限制重複呼叫，沒有以偽造掉落模型宣稱 duplication 實際已解決。

T-034／C-011 尚需使用者測 client 與 dedicated server：四 gate 組合、空軌、一般與原版各車種／容器、乘客、內容與車體物品分別核對、無關鄰車、同 tick 副作用、聲音／煙霧、共用速度／原版銜接；設定重載相異模型投影與新世界存讀也待驗收。T-098 包要按來源限定預期，不稱為 OLD 實測基線。人工確認即可結案，附件選用；R-03 只審程式／測例覆蓋，不代跑或簽署人工通過。

D1–D8、T-002 免執行、T-003 來源參考、T-026 使用者结案、T-029 U-07 待確認及原整合缺口保留。本項不實作整列刪除、票證釋放、外部模組或舊資料轉換。
