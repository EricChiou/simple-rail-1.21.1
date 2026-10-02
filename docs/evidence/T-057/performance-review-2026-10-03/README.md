# T-057 連結車廂效能專項檢查（2026-10-03）

**結論：現行連結／跟車流程有可重現的效能擴充問題，主要在連結後持續執行的路線計算，其次是連結時重複複製整列清單。不能據此宣稱目前遊戲已掉 TPS，亦不能保證某個車廂數一定安全。**

本次是使用者指定的效能檢查，不是整個 R-05／R-F 簽核，也沒有修改產品或撤銷 T-058 人工通過。未啟動 Minecraft、server 或 GameTest。所有新檔只在本目錄，原開發紀錄保持不變。

## 版本與範圍

檢查目前工作區的 Wrench → LocomotiveCartEntity.linkNewCart → TrainFormation／TrainOwnershipData，以及 tick → moveLoadedCarts → TrainBlockRoute，另追蹤存讀、斷尾、移除和回饋成本。Minecraft 1.21.1／NeoForge 21.1.251；HEAD `11916b69c3549504928f7cfa6790d59a2717b4b6` 加現有未提交差異。現行來源／JAR／API archive 雜湊见 [inputs.json](inputs.json)，不可只用 HEAD 重建。

- 現行 Wrench SHA-256 `96767E7D4F0434AE8D537E4BE0D9AEF7464BF246921D8A50E0DC0E7467568389` 與原 T-057 交付相同。
- TrainFormation／TrainBlockRoute 與 T-058 R7 manifest 相同，間距為 1.35。現行 LocomotiveCartEntity 已有 T-061 整列移除等後續變更，與 R7 全檔雜湊不同；本報告以現行方法為準，不把全部成本歸咎 T-057 新增。
- T-057 原本只新增扳手互動。下述路線平方成本來自後續 T-058 路線跟車，清單成本則來自 T-057 呼叫的共同編組方法。原 41 項功能斷言沒有測量這些負載。

## 已確認發現

### PERF057-01：每次跟車更新重掃路線，CPU 與暫時配置接近平方成長（優先改善）

位置：[LocomotiveCartEntity.java](../../../../src/main/java/com/ericchiu/simplerail/entity/LocomotiveCartEntity.java) 第 200–220 行、[TrainBlockRoute.java](../../../../src/main/java/com/ericchiu/simplerail/entity/TrainBlockRoute.java) 第 60–85 行。

`readyFor(head, N)` 先呼叫 `target(head, N)` 掃到最後一節；隨後每節已載入車廂又呼叫 `target(head, i+1)`，每次都從歷史路線第一格開始。每個走訪段都建立 Point 並計算平方根；沒有共用掃描游標、累積長度索引或目標快取。

在所有 N 節已載入、路線足夠且直線格距為 1 時，每次更新的精確段數為：

`ceil(1.35 × N) + Σ(i=1..N) ceil(1.35 × i)`

這是約 `0.675 × N² + O(N)`，不是每節只算一次。**64 節 2,926 段，128 節 11,380 段，256 節 44,879 段，512 節 178,232 段。** 下方純 JVM 以實際產品方法及計數容器驗證，並測得相應配置量。

觸發條件是 `motion.equals(Vec3.ZERO) || isNearBlockCenter()`（車頭第 191 行）。因此靜止且路線足夠的列車仍可每 tick 完整重算，即使車頭、路線及編組完全未變；不是只有過彎／跨格才算。測試以相同 head 連續呼叫，結果相同、走訪次數也完全相同，沒有快取。

影響是長列車或多列停放列車持續占用 server 執行時間與 GC 配置頻寬。若路線不足，`readyFor=false`，各車不再呼叫 target，成本降為 `O(L+N)`；若部分車未載入，只替已載入車算 target，但 readyFor 仍按完整編組長度檢查。路線保留上限 8,192 格，因此一般式是 `O(L + Σ各已載入車走訪段數)`、上界 `O(NL)`，不能宣稱任意長度都無上限平方成長。

**改善方向：** 一次由前到後沿弧長掃描，同時計算所有序位目標，將整批工作降到 `O(L+N)`；以原始 double 座標計算中間段，避免每段 Point 配置。須保留「完整路線不足就整列 fallback」、彎坡、1.35 間距及目前更新時機。若快取靜止目標，仍須處理新連結／斷尾／路線變動、車廂受推移動與晚載入；不可只因車頭速度 0 就略過所有車廂定位。

### PERF057-02：新增／重複連結都複製整列 UUID，批量新增累積為平方成本（次優先）

位置：[LocomotiveCartEntity.java](../../../../src/main/java/com/ericchiu/simplerail/entity/LocomotiveCartEntity.java) 第 98–111 行、[TrainFormation.java](../../../../src/main/java/com/ericchiu/simplerail/entity/TrainFormation.java) 第 17–24 行。

`formation.carts()` 每次都 `List.copyOf(ArrayList)`。新增一節至 N 節編組時：先複製 N 個 UUID 才做 contains，`formation.add` 再做一次線性 contains，成功後又複製 N+1 個 UUID，只為取得 size。故一次成功新增光兩次快照就複製 **2N+1 個 UUID 元素**，另有兩次線性會員檢查。重複點擊既有車雖正確拒絕，仍先複製整列。

從空列逐節增加 K 節，依現行成功呼叫序列累計複製 **K² 個 UUID 元素**；1,024 節重現 1,048,576 個。此數不等於只有一個配置陣列或實際配置 bytes，List.copyOf 內部仍可能再複製／配置。大量礦車擠在兩個點擊格或反覆點選長列車時成本會放大。一般一兩節連結不是主要持續負載，但這些線性工作沒有必要。

同一 accessor 亦被 tick 的跟車快照、跨格時 `.size()`、初次 ownership reconcile 與保存使用。跟車快照可作有意義的迭代隔離，但只取 size／contains 時複製整列沒有收益。

**改善方向：** 提供不複製的 `size()` 與 `contains(UUID)`，以有序 List 加會員 HashSet 維護一致性；只在需要外部不可變快照時建立或快取 snapshot。不要直接用 stops.containsKey 取代會員資格：load 允許 UUID 存在而 stop 缺少，兩者不是同一集合。需回歸 add／remove／disconnectFrom／load 的順序、去重與晚載入保存。

## 其他路径核對

N 為單列編組數，L 為路線格數，K 為兩格查得的車數（含重疊），P 為玩家數，M 為維度所有權條目數。

| 路徑 | 成本與結論 |
| --- | --- |
| Wrench 查兩格 | 一次點擊最多兩次 AABB 實體查詢，中心恰為 0.5 時只查一次；依附近 entity sections／類型篩選，**不是掃整個世界**。附近實體密集仍會增加成本；跨格車可能出現在兩個結果清單，會重複嘗試但不重複連結。兩格候選無數量上限。 |
| 找車頭／找 UUID | ownership 為 HashMap 查詢；`ServerLevel.getEntity(UUID)` → LevelEntityGetterAdapter → EntityLookup.byUuid，為平均常數索引查找，沒有線性掃全世界或強制載入車廂 chunk。findLocomotive 最多走兩格候選；共同成本約 O(K)。 |
| 每次點擊連結 | 候選加入目前編組，清單工作約 O(KN+K²)，另加局部查詢與成功回饋；點空地也會查兩格並取得 ownership，但不建立輪詢工作。 |
| 粒子／聲音 | 每個真正新增車廂各發一次煙與聲音；無效／重複點擊不發成功回饋。指定 API 的 sendParticles 會走訪該維度玩家再做距離過濾，成功加入 A 節有 O(A×P) 的粒子接收檢查。批量操作可合併回饋，但不是每 tick 廣播此效果。 |
| ownership 存取／標髒 | `forLevel` 使用 DimensionDataStorage cache，穩態不是每 tick 讀檔；首次讀取已有大檔仍可能有讀取／解碼成本。claim 只有真正新增才 setDirty；setDirty 只是改旗標，不立即落盤。 |
| 正常跟車 | 每個符合更新條件的 tick 有 N 次 UUID 查找、快照及 stop 查詢，再加路線成本；每個找到的有效車還會 moveTo／setDeltaMovement。原版礦車仍有自己的 tick／碰撞成本，未被連結機制消除。 |
| 網路同步 | moveTo 會更新座標／旋轉／包圍盒相關狀態，但不是每次呼叫直接強制發一包；ServerEntity 有更新間隔、位移與 dirty 判斷。不能僅由 N 次 moveTo 推論 N 個實際位置封包，仍需多人量測。 |
| 跨格記路線 | ArrayList.addFirst 會搬移 O(L) 個引用；formation.advance 為 O(N)，且取 size 多一次快照。L 上限 8,192，非無限成長，但大量跨格可考慮環狀緩衝區。 |
| 存讀 | 每車頭保存／載入約 O(N+L)；所有權保存遍歷 M 加 pendingCut／pendingRemoval。保存也建立 NBT 物件；大量變更會增加下一輪保存負擔，並非每次連結完整同步寫檔。 |
| 移除／斷尾 | disconnectFrom 先 indexOf 再清尾，O(N)；多個 pending cuts 可有多次線性搜尋。releaseTrain 走訪整個維度 ownership，O(M)；現行 T-061 discardTrain 與其後 remove 可重走清理，批量移除是次要尖峰風險，不是 T-057 的每 tick 工作。 |
| 記憶體生命週期 | 沒有本輪確認的 static 世界引用洩漏；route cap 有效。未載入 UUID、pending removals 刻意保存至後續處理，量隨資料增長；不能把未載入誤當遺失直接清除來「優化」。本次配置量是短命垃圾，不等於永久洩漏。 |

指定版依據見 [API 快照](api/)：EntityGetter／EntitySectionStorage、EntityLookup、LevelEntityGetterAdapter、DimensionDataStorage、SavedData、Entity、ServerEntity、ServerLevel。快照取自本機固定 21.1.251 來源，不以其他版本介面推論。

## 已執行驗證與數值

執行 [run.ps1](run.ps1)：`powershell -NoProfile -ExecutionPolicy Bypass -File docs/evidence/T-057/performance-review-2026-10-03/run.ps1`，所有命令退出 0，見 [commands.json](commands.json)。

- 直接編譯當前 TrainFormation／TrainBlockRoute／Facing8，原編組 41 項與 R7 路線 22 項回歸通過。
- 新增 [PerformanceProbe.java](PerformanceProbe.java) 的 **1,081 項確定性檢查通過**：精確段數、相同靜止輸入重算、成功與重複連結快照元素數、批量 N² 複製、route 上限及不足回退。計數時只在獨立 JVM 以反射置換容器，實際產品方法未改；此替換**不參與計時**。
- 計時使用原 ArrayList 與原產品路線方法，3 個獨立 JVM、每尺寸至少 250 ms 暖機、7 組樣本、`-Xms256m -Xmx256m`。每組重複次數與原始值全保留於 timing-fork-1～3.log；摘要見 [timing-summary.csv](timing-summary.csv)。
- Java 21.0.12.1、Windows 11 amd64，JVM 可見 12 logical processors；CPU 行銷名稱的 CIM 讀取被拒，未升權，資訊見 [hardware.json](hardware.json)。結果屬本機非 JMH 微基準，不是專用伺服器硬體認證。

以下是 **readyFor 加全部 N 個 target** 的一次純路線更新。時間範圍為三個 JVM 各自七組樣本的中位數範圍，並非最小／最壞延遲；配置為 ThreadMXBean 所量得的本執行緒 bytes，包含實際 JIT 效果。未含 UUID 查找、formation snapshot、moveTo、原版車物理、網路與保存，也未執行 LocomotiveCartEntity.tick。

| 車廂數 | 段走訪／次 | 時間 µs／次 | 暫時配置 KiB／次 |
| ---: | ---: | ---: | ---: |
| 8 | 64 | 0.314–0.540 | 2.5 |
| 16 | 214 | 1.208–1.951 | 8.4 |
| 32 | 773 | 4.100–4.246 | 30.2 |
| 64 | 2,926 | 14.807–15.323 | 114.3 |
| 128 | 11,380 | 54.988–60.313 | 444.5 |
| 256 | 44,879 | 213.690–231.047 | 1,753.1 |
| 512 | 178,232 | 849.583–946.075 | 6,962.2 |
| 1,024 | 710,358 | 3,499.383–3,613.300 | 27,748.4 |

例如 128 節在「每秒 20 次符合跟車條件」的假設下，單列光此路線方法配置約 **8.68 MiB/s**；10 列約 86.8 MiB/s。這是依微基準的算術外推，**不是已量到 Minecraft GC 或 TPS**。32→128 節（4 倍）段走訪由 773→11,380（14.7 倍），可明確看出長列車成本不線性。

對少量短列車，單此路線微基準成本小，尚無證據宣稱必然卡頓；長列車、多列停放、大量批量連結則有明確優化理由。不能把大尺寸微基準全車已載入的前提套到預設載入距離下的任意世界。

## 後續驗證與處理順序

先處理 PERF057-01 的整列一次掃描及中間物件，再處理 PERF057-02 的 size／會員索引／快照；其後才按實際 profile 處理環狀路線、回饋合併與 owner→cars 反向索引。這是改善建議，本輪沒有實作修正或變更 1.35 車距、更新時機、D3 票證與未載入保存政策。

真正遊戲效能仍依既定分工由使用者執行。以下案例可作後續 T-126／專項測試輸入，不重開已通過的功能验收：

| 場景 | 要分開量的項目 |
| --- | --- |
| 8／32／64／128 節，1 列／多列 | 固定路線與載入條件；server tick 時間分布、CPU profile、配置與 GC 暫停，先約定允收門檻 |
| 靜止、直線移動、彎坡 | 路線已足夠與不足各測；靜止也要確認零速度分支，不能只測行駛 |
| 全車載入、部分未載入／晚載入 | 記實際載入數；確認查找與 fallback 行為，不能為測試改 D3 |
| 一般連結、重复點擊、兩格多車 | 分開看互動延遲與一次成功新增數；保留去重、順序及合法拒絕 |
| 保存重啟、大量拆車、多玩家追蹤 | 保存尖峰、清理成本、實際同步量；與 CPU 路線微基準分開 |

允收數值與玩家實際列車規模未提供，本報告不武斷設定「最多幾節／幾列」。產品／歷史證據未變與測試輸入核對見 [verification.json](verification.json)。
