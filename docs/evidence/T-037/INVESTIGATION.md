# T-037 計時資料保存與邊界調查

2026-09-30。OLD 為 Forge 1.16.5 原始碼參考，**依原始碼推定／待確認**，本輪沒有執行 OLD 或 Minecraft。NEW 為 Minecraft 1.21.1／NeoForge 21.1.251；14 份 API 來源取自本機固定版 sources JAR，來源 SHA-256 與檔案指紋見 [collection.json](collection.json)、[input-fingerprints.json](input-fingerprints.json)。plain JVM 測試使用真實 NEW `CompoundTag`，沒有 Minecraft bootstrap、世界或服務器。

## 分項結論與缺口

| ID／範圍 | 可追溯來源與假說 | 已確認證據 | 尚未確認／下游 |
| --- | --- | --- | --- |
| I-037-01 首次未使用、缺鍵 | [OLD BE](sources/old/TimerHoldingRailTileEntity.java) L15–16 初值 null；L28–36 只保存非 null UUID／期限；L40–44 卻無條件 getUUID 並以缺省 long 補償 | 讀寫條件不對稱為來源事實；真實 NEW 空 CompoundTag 的 getUUID 在 JVM 產生 NullPointerException，缺 long 回 0；候選 guard 對空／不完整／錯型／越界資料回 idle | 不把 NEW 例外類型套成 OLD 實測。OLD CompoundNBT 具體執行與遊戲後果未驗。T-038 定義 NEW schema，T-039 檢查防護；T119-01／02 人工 |
| I-037-02 setters 與保存標記 | OLD BE L47–53 只有賦值，沒有 setChanged；[OLD rail](sources/old/TimerHoldingRail.java) L78 先 setBlock(direction)，L81–82 才設 UUID／期限 | setter 沒有保存標記已確認。NEW [BlockEntity](sources/target/net/minecraft/world/level/block/entity/BlockEntity.java) L191–200 → [Level.blockEntityChanged](sources/target/net/minecraft/world/level/Level.java) L984 → chunk unsaved；[ChunkMap.save](sources/target/net/minecraft/server/level/ChunkMap.java) L769–795 可跳過乾淨區塊 | 方向變化／其他世界活動可能順帶標髒，不能聲稱 OLD 每次都遺失。T119-03 比較乾淨區塊 dirty=false／true；世界干擾時記未建立條件，不記「未重現」。正式保存頻率與成本留 T-038 |
| I-037-03 秒數上限溢位 | OLD rail L86–118 的 int holdingTime 及 LVn * 1000；[CommonConfig](sources/old/CommonConfig.java) L105–122 容許 0..2147483647 | 同樣 Java int 運算在 JVM 重現：2147483 秒→2147483000 ms；2147484 秒→-2147483296 ms；最大值→-1000 ms。轉 long 後最大值為 2147483647000 ms | 確認算術缺陷，不等於 OLD 遊戲已測。T-038 用 long 計算，T-039 驗新實作；T119-04 檢查命令／序列化接線，不需等候 68 年 |
| I-037-04 保存途中到卸載的時間差 | OLD BE L43：新期限 = 舊期限 + (讀回時間 − 保存時間) | 代數及 JVM 例子：期限 110000、保存 104000、卸載 107000、讀回 120000 ms，重載剩 6000，真正卸載剩 3000；差為保存後尚活動的 3000 ms | 是否確實漏掉末次保存取決於標髒／生命週期，OLD runtime 未確認。T119-05／06／07 觀察 NEW；T-038／039 不能只存一次起始資料，也不能把離線時間扣除 |
| I-037-05 卸載與回呼先後 | NEW ChunkMap L532–548、L769–795；[LevelChunk](sources/target/net/minecraft/world/level/chunk/LevelChunk.java) L616–621；[IBlockEntityExtension](sources/target/net/neoforged/neoforge/common/extensions/IBlockEntityExtension.java) L61–71 | 此固定版本來源路徑為 ChunkEvent.Unload → save（視 unsaved）→ ServerLevel.unload → clearAllBlockEntities/onChunkUnloaded。ChunkDataEvent.Save 在序列化後、非同步 IO 完成前；BE onChunkUnloaded 太晚，不能回改已生成的那份資料 | 來源順序不是 Minecraft 實跑證據；T119-06 確認實際路徑。不得把序列化 log 等同磁碟耐久寫入；必須正常存讀觀察。候選在讀回後首個 server tick 恢復，真正載入／停用邊界待 T-038／040／083 |

`LV1..LV9` 在 OLD rail 靜態初始化時讀設定，預設 5／10／15／20／25／30／40／50／60 秒；靜態快取與即時 reload 的差異留 T-038 明確定義並接 T-020 設定。level=0 的原碼不停止、同 UUID 期限到才釋放、新 UUID 重設方向與期限均是來源參考。雙 defaultState 及 U-09 扳手覆寫為既有相關疑點，不在 T-037 自行修正；供電父類效果與所有實際礦車行為留 T-038／040。

## 最小候選與測試邊界

[TimerState](fixture/evidence/t037/TimerState.java) 用可注入單調奈秒時鐘量測實際經過時間，沒有以 tick 次數扣秒；保存剩餘毫秒，讀回先暫停、首個有效 tick 才 resume。實測 7 秒無呼叫仍扣 7 秒、離線一小時與讀回尚未 tick 的 20 秒均不扣、重載保留約 3 秒、重複存讀、最大值及 1,000 次半毫秒觀察。這是診斷候選的 JVM 判定，非正式遊戲停車。

[TimerRecordCodec](fixture/evidence/t037/TimerRecordCodec.java) 使用 NEW `t037_data` 內的 UUID／remaining_ms，驗證型別、UUID 長度與範圍。正式新資料格式仍由 T-038 決定；本包沒有舊 NBT 轉換，也沒有模擬可匯入 OLD 世界。

[TimerProbe](fixture/evidence/t037/TimerProbe.java) 只接合成計時器、命令與生命週期 log。dirty=true 為觀察用「每次剩餘值改變時 setChanged」策略，可能產生額外鄰居通知；不能據此宣稱正式策略效能合格。dirty=false 故意省略標髒，供控制比較。arm save／unload 把指定邊界的剩餘值設為 3000 ms，以便重現短剩餘存讀；這是人工注入的控制實驗，不能證明自然礦車恰在剩 3 秒時保存正確。unload 使用事件的 chunk.setUnsaved(true)，不在卸載事件重新請求 chunk，不改票證。

fixture 以同名入口／ModBlocks 的兩份影本覆蓋診斷 JAR 內 class；正式 src 沒有改動。影本差異見 [入口](overlay-entry.diff)、[registry](overlay-registry.diff)。所有既有方塊／物品 ID 保留；BE 使用既有 timer_holding_rail ID。沒有新外部模組或正式車頭／GUI／發射器移植。

## T-038／T-039 的准入與人工依賴

| 後續工作 | 本次提供的依據 | 判定界線 |
| --- | --- | --- |
| long 秒→毫秒；NEW 空／錯型資料安全處理 | I-037-01／03 的來源、真實 NEW NBT 與 JVM 運算 | 可進行開發；T-039 須對正式程式證明已避開或另作最小修正，不直接沿用 fixture 通過 |
| 狀態更新須保存；末次序列化要反映當時剩餘 | I-037-02／04／05 | 可設計 T-038；不要在 BE onChunkUnloaded 才補那次保存。實際 dirty／卸載／IO 接線仍需 T-119 與正式 T-040／083 |
| 活動／卸載／離線邊界、存讀誤差與系統時鐘 | D5、T-011 候選、T-004 M-01 | fixture 避免系統牆鐘跳動的計算已可測；生產策略、效能與正式約 3 秒容許誤差仍待技術定義，不能標 D5 已通過 |
| OLD 遊戲後果與其他疑點 | 未取得 OLD runtime 結果 | 保持依原始碼推定／待確認，不阻擋無關 NEW 開發；不重建 OLD、不要求新舊世界轉換 |

覆蓋對應：MIGRATION §4.2、§4.3(4)、D5／D6、§6 階段 4；T-004 C-014 → T119-01／02／04，C-015 → T119-06，C-016 → T119-07，C-036 的計時子集 → T119-01／03／05／06／07。正式 C-012／013 的停車放行、0–9 級、扳手／供電、C-036 全模組整合不由本包代驗，仍在 T-040／083 等原任務。
