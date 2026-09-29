# T-031 下車軌來源、API 與行為契約

2026-09-29。OLD 行為全部為 **依原始碼推定／待確認**，沒有 OLD 實測。對應 MIGRATION.md §3 eject_rail、§4.4 設定、§6 階段 3；TASK.md T-031／T-032／T-097；T-003 B-07、T-004 C-010、T-010 A11／A16。指定 API 來源保存在 [manifest](source-manifest.json)，不是宣稱所有 1.21.1 API 或 runtime 已驗證。

## 來源與目標對照

| 項目 | OLD 來源 | NEW 交付／來源及限制 |
| --- | --- | --- |
| 基底／ID | [EjectRail](sources/old/EjectRail.java)、[BasePoweredRail](sources/old/BasePoweredRail.java) | 繼承既有 BasePoweredRail，factory 仍 simplerail:eject_rail；原 BlockItem／loot／recipe／models 保留。共同速度、禁坡、不可被實體破壞由基底繼承，powered 父類語意不改 |
| 屬性／預設 | reverse、need_power；OLD 註冊建構讀設定 | NEW reverse=false／need_power=true 固定預設，保留父類 powered=false／shape=NS／waterlogged=false；不在建構讀未載入設定。server 新放置投影載入快照交父類，同 ID 狀態改變或重載不重投影 |
| 放置寫回 | OLD 傳帶 need_power 的新 state 給父類 | [BaseRailBlock](sources/target/net/minecraft/world/level/block/BaseRailBlock.java) onPlace→updateState→updateDir(alwaysPlace=true)→[RailState](sources/target/net/minecraft/world/level/block/RailState.java) place 寫 state；不是直接另加 setBlock 或掃世界。實際更新／存讀仍待人工 |
| 設定 | [CommonConfig](sources/old/CommonConfig.java) 距離預設 3、範圍 1–100、needPower=true | 沿用 T-020 ejectRailTransportDistance／ejectRailNeedPower，當次 CommonConfig.current() 一份不可變快照。callback 以 config.ejectNeedPower 判斷，**不以 stored need_power 判斷**；重載既有模型投影可與規則不同，待人工核對 |
| 觸發 | client return；未供電且需供電 return；空乘客 return | 同條件，client 在讀設定前返回。powered OR !needPower 才查乘客；無乘客不 detach、不定位。不因來車方向或速度改分支 |
| 乘客分離 | OLD 每位迭代呼叫一次 cart.ejectPassengers，重複清空全部乘客 | NEW `List.copyOf` 保存直接乘客清單，再對非空清單呼叫一次 ejectPassengers，最後逐位定位。與 OLD 正常分離後的最終落點一致；不保留重複空 ejection／重复 zero write 次數，不宣稱舊碼有已重現的迭代 bug |
| 下車 API | AbstractMinecartEntity.getPassengers／ejectPassengers、Entity.moveTo | [Entity](sources/target/net/minecraft/world/entity/Entity.java) getPassengers 回 immutable 清單，ejectPassengers 反向呼叫 stopRiding；removePassenger 更換清單。[LivingEntity](sources/target/net/minecraft/world/entity/LivingEntity.java) stopRiding 後有原版 dismountVehicle，故最終側邊定位放在全部 detach 之後 |
| 玩家同步適配 | OLD 一律 passenger.moveTo | [ServerPlayer](sources/target/net/minecraft/server/level/ServerPlayer.java) moveTo 僅 super.moveTo＋connection.resetPosition；teleportTo(double,double,double) 呼叫 connection.teleport，保留旋轉。[ServerGamePacketListenerImpl](sources/target/net/minecraft/server/network/ServerGamePacketListenerImpl.java) teleport 設等待確認位置、absMoveTo、送 ClientboundPlayerPositionPacket。NEW 玩家使用該同世界 overload，其他乘客仍 moveTo；不使用 ServerLevel overload／額外 POST_TELEPORT 票證。來源＋真實編譯確認簽名與路徑，沒有實際封包／多人成功結果 |
| 回呼順序／車速 | 舊碼只歸零乘客，不更改車體向量 | [AbstractMinecart](sources/target/net/minecraft/world/entity/vehicle/AbstractMinecart.java) 原版煞車／移動／摩擦先於 onMinecartPass，powered 加速可能在其後。EjectRail hook 不停車、不更改車體方向，不把「hook 不寫車體」等同最终車速不變 |
| 外觀／保存 | 原 12 selector、無 BE／自訂 NBT | [96 狀態枚舉](state-coverage.json) 中 32 平軌狀態各唯一匹配原 selector；64 非自然升坡狀態未映射，遵守只有高速有坡，未加下車軌斜坡。屬性沿既有 blockstate 保存／更新，沒有自訂 packet 或設定同步；baking／world／codec runtime 未測 |

## 精確落點

令軌道整數座標為 `(X,Y,Z)`，距離為 `d`；只有觸發且有乘客時使用。所有乘客先離车，動量設 `Vec3.ZERO`，保留旋轉，Y 維持 **Y**。

| shape | reverse | x | y | z |
| --- | --- | --- | --- | --- |
| north_south | false | X − d − 0.5 | Y | Z + 0.5 |
| north_south | true | X + d + 0.5 | Y | Z + 0.5 |
| east_west | false | X + 0.5 | Y | Z − d − 0.5 |
| east_west | true | X + 0.5 | Y | Z + d + 0.5 |

负向不是「軌道中心減 d」。例如 `(0,64,0)`／d=3／NS／reverse=false，OLD 公式是 `(-3.5,64,0.5)`。未補避障／支撐／落地高度或朝來車方向偏移。距離 100 可能落入未載入區塊或障礙，實際結果待 T-032，未擅加票證或新安全政策。

## 測試範圍與未確認事項

[48 列矩陣](behavior-matrix.json)＝2 軌向 × 2 reverse × 2 powered × 2 needPower × 3 距離，每列 `gameResult=null`。隔離測試再涵蓋 stored need_power 相同／相異、4 來車向量、2 正負座標／高度、0／1／3 直接乘客；共 2,304 次 hook，23,821 判定。模擬 eject 時清空原可變清單，驗證快照保留全部乘客；模擬 detach 時換設定快照，驗證同次定位不混設定；涵蓋 constructor、client guard、server 新放置、same block 與重載距離。

20 個本地替身明列於 [test-double-fingerprints.json](test-double-fingerprints.json)。三乘客是防禦性清單測試，**不是已在原版礦車搭載三人**；ServerPlayer 替身只記 teleportTo 分派，沒有真实連線。CommonConfig 替身不驗 FML 載入事件；PoweredRail／Level 替身不驗真實鄰居更新、碰撞或存讀。NEW build 補足真實類別／泛型／overload 可編譯證據，Gradle test 為 NO-SOURCE。

仍待使用者 T-032／後續保存整合驗收：玩家 client 位置確認與多人端一致、非玩家下車／原版 dismount 副作用、落點障礙與距離边界、空車、4 來車方向／2 軌向、needPower 重載對既有 state／模型的影響、共用速度與原版銜接、新世界存讀。取消 dismount 的事件或非標準嵌套乘客不由隔離測試推定支援；D7 不加入外部模組整合。R-03 只審差異／邏輯／覆蓋／保存同步，不代跑或簽人工通過。U-07 仍屬 T-029 待確認，本項未替使用者決定。
