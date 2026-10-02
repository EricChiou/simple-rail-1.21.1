# R-03 獨立程式審查（2026-09-29～30）

**指定開發範圍通過：T-025、T-027、T-029、T-031、T-033、T-035。沒有新增 S0–S3 審查發現。** 一併完成本範圍的 R-F：T-026 R1 高速升坡、R2 坡底移動保護，以及 T-030 R1 未供電滑行修正，均通過程式／資源／回歸覆蓋審查。

T-029／T-035 的通過限於已交付原碼相容邏輯與已授權修正，**不表示 U-07 電力翻向意圖、U-09 複合屬性覆寫意圖已定案**。未實作 owner、非自然狀態模型及最終整合仍按原任務處理；不宣稱所有後續功能或最終候選通過。

六項人工 T-026／T-028／T-030／T-032／T-034／T-036 維持使用者通過結案；T-094～T-099 維持「已結案（使用者接手）」。本次不製作或要求六包的交付證據，不代跑遊戲、不补造受測產物或逐例結果。

## 獨立性與固定輸入

本審查者未實作上述受審產品變更。本輪只新增 review 工具、隔離測試與報告，並同步 TASK／REVIEW／MIGRATION；沒有修改產品、開發證據、固定包、人工確認或 Git index，沒有 stage／reset／commit。

受審 HEAD：`11916b69c3549504928f7cfa6790d59a2717b4b6`，開始時工作區乾淨。現行產品逐檔符合 [T-030 R1 source-fingerprints](../T-030/fix-R1/source-fingerprints.json)；當前整合 JAR 使用其固定產物：

**`3AB3E37EF4AA21342011332E9531088DB36D121A1F6C9C9823DD6B3259538594`**。

版本：Minecraft 1.21.1、NeoForge 21.1.251、Simple Rail 1.0.0、Java 21、All Rights Reserved。原 Gradle build 與當時 `8bd977d`＋差異保持歷史，不把最新 Git commit 倒填為原產物的建置 commit。

| 固定開發產物 | SHA-256 |
| --- | --- |
| T-025 | `2C72767500EDCF8F693FAB2EA874F77F52F3A949BBDF9F0DA10D20C008702BC0` |
| T-026 R1 | `8455CC5DE6FE2C7E5953E6A8F0D4A4E419A40489B954C8B0B1216304C5CEA599` |
| T-026 R2 | `C3507DB669B28D719B7DDC8FC0EA35F0F733D8931153DD31FD38741068131C6C` |
| T-027 | `DE13BF73E4A79E32A656CEEBD052C61E042B342D8886050AC71330E6EDF78D35` |
| T-029 原交付 | `7EE7F6853662572F1D1D073F72EE49E4F44413B2D6CEBB839D5BDFAF36941A7C` |
| T-031 | `D0ECA101CA8A9B72173E9B340206B1DDB7FCB3FE1B7834DDD2F5BA56E3E19B7E` |
| T-033 | `336FAFDF1237127E613E3B300BCD9263191A377284A8EB7B7BA77DE124A24473` |
| T-035 | `7328D1A4078043DD7D17C1731C1D661B81538395A53BA1A1FFA54F90336E89C8` |
| T-030 R1／當前整合 | `3AB3E37EF4AA21342011332E9531088DB36D121A1F6C9C9823DD6B3259538594` |

[reviewed-inputs.json](reviewed-inputs.json)保存 766 份受審程式、來源、契約、原測試、歷史產物與確認資料的指紋；[test-inputs.json](test-inputs.json)另保存實際重新編譯的 API／替身／測試输入。指定 API 依本地固定版原始碼與 class bytes，不用新版文件猜介面。

## 逐項審查

| 任務／程式 | 結論與核對要點 |
| --- | --- |
| T-025：BaseRail／BasePoweredRail | 通過。共同速度從單份 COMMON snapshot 讀取；父類 cart cap／摩擦仍生效，設定值不是保證位移。兩基底 canMakeSlopes=false、canEntityDestroy=false；powered 基底傳 true，不誤當 activator。codec 工廠與繼承 shape／powered／waterlogged 對應指定 API；不在建構時讀配置 |
| HighSpeedRail／T-026 R1 | 通過。僅高速覆寫成坡；四方向升坡×兩供電模型使用指定版 raised template、原 sprite 與 cutout。六 shape×powered×waterlogged 共 24 狀態都有唯一 selector。沒有把高速例外套用其他四軌或兩基底 |
| HighSpeedRail／T-026 R2 | 通過。getRailMaxSpeed 依軌向及有號水平動量選鄰格；目前沿自身升坡前進時查高一格。下一軌道必須有 rail tag 且為 BaseRailBlock、getRailDirection 與前進升坡相符、車身未抬過支撐，才取支撐近端距離減半寬與 clearance 的上限；float 向上捨入時 nextDown。沒有改寫方向／座標／動量，也沒有全域固定降速。平面、無鄰軌、交叉坡向、已抬高、零速與 null query 保持原設定上限 |
| T-027：HoldingRail | 通過。server 未供電時，非零向量先存 getMotionDirection，再歸零／移至方塊底部中心並保留旋轉。updateState 先父類寫 POWERED，再读回確認仍是本方塊，只在 false→true 對單格 AABB 所有礦車放行 direction×0.4；巢狀通知讀 true 不重推，失去電力不推。六向屬性保留，正常進車方向為水平；狀態沿既有方塊保存／同步 |
| T-029：OnewayRail | 原碼相容範圍通過。active＝usePowerChangeDirection OR powered OR !needPower，方向僅取 reverse 與軌向；過車讀當前快照，不拿 stored need_power／use_power 代替規則。constructor 固定預設；新放置 server 投影交 BaseRailBlock→RailState(alwaysPlace=true) 寫回；same-block 更新不重新投影。原未啟用 ×1.2 已依 T-030 R1 授權移除 |
| T-030 R1：AbstractMinecartMixin | 通過。只 redirect 固定 moveAlongTrack 的唯一 PoweredRailBlock.isActivatorRail 呼叫；handler 接 receiver 與完整外層 BlockPos／BlockState。僅未供電 OnewayRail 令該局部分類略過動力煞車，tick 的真正 activator 分支不改；供電單向與其他動力軌保留原分類。JSON 在 common mixins，TOML 登錄，JAVA_21、required、require／expect／allow=1；沒有新增外部依賴。原方向啟用條件保留，不把未供電概括成永遠停用方向規則 |
| T-031：EjectRail | 通過。server gate、當次 snapshot、powered OR !needPower；先複製直接乘客再一次 eject，避免原清單變化影響迭代。全部 detach 後歸零並定位；玩家走同世界 teleportTo 的位置封包路徑，其他乘客 moveTo。NS／EW、reverse、正負座標與距離 1／3／100 對上 OLD 公式，包括負向 X−d−0.5 的非中心對稱式。沒有新增避障、換維度、票證或改礦車本體動量 |
| T-033：DestoryRail | 通過。只在 ServerLevel 且未移除車執行，依當前 needPower／POWERED gate；discard 保留虛擬 remove 副作用，一次粒子／聲音，座標、種類、數量與 4／4 音量／pitch 對上來源。普通車體 destroy 掉落與容器內容掉落明確分開；不自行清空容器／重複掉落／加整列刪除或 TNT 保險政策 |
| T-035：Wrench | 原碼相容範圍通過。從方塊 StateDefinition 取真正 Property 實例，檢查型別／level 0–9 domain，避免依同名新 Property 讀 reference-keyed state。rails 須點擊格無車；machines 無該限制。reverse 切換、level 循環、四水平順時針、垂直不動；client 不寫、null player 不解參考；保留結果／HOE abilities／不消耗。U-09 的逐次初始 state 寫回如實保留，未冒充累積修正 |

審查已對照各任務固定 OLD 程式及目標 BaseRailBlock／RailState／PoweredRailBlock／AbstractMinecart、Entity／ServerPlayer／移除父類與 StateHolder。OLD 行為仍為來源推定，不重跑 OLD。

## 既有未決事項與驗證邊界

- **U-07**：設定名稱暗示電力翻向，但原程式是無條件啟用方向規則，原模型又依 powered 切換且忽略 reverse。現行程式保留原碼，T-030 R1 僅處理未供電煞車。通過原碼相容審查不替使用者決定 XOR 或改模型。
- **U-09**：rail 同有 reverse／level／direction 時，最後 direction 寫回可覆蓋前兩項；machine 同有 facing／level 時，level 可覆蓋 facing。這是已登錄且保留的原碼資料流，不是本輪新發現或已修復。後續意圖決策及複合 owner 整合仍待處理，六項人工通過不等於授權新需求。
- **I-021-01**：本輪確認高速 24 組全覆蓋。其他已實作軌道的自然平軌皆唯一匹配，但保留的非自然 ascending domain 仍缺模型：holding 96／144、oneway 128／192、eject 64／96、destory 32／48。詳見 [重新枚舉](state-coverage.json)。不因禁坡刪域，也不將自然狀態通過寫成全部 bake 無警告；其餘骨架與最終模型整合繼續依原任務。
- **I-092-02／COMMON**：已實作消費者每次讀有效 snapshot，放置 state 是當時投影，reload 不批次改既有 world。timer／signal／票證及全部有效值觀测不由 R-03 一次簽完，保持 R-02 的界線。
- **真正 runtime**：隔離替身不驗 Minecraft 通知、yaw／flipped 時序、碰撞形狀、客戶端封包、Mixin weaving 或世界存讀。HoldingRail 低速方向與父類制動、容器內容、TNT 同 tick、玩家定位等均列入既有人工／整合測例；不由局部函式通過推定全部實際結果。
- **後續 owner**：timer level／direction、signal level、dispenser facing／GUI、兩 Y 路口 direction、扳手編組與整列移除仍屬 T-038／T-041／T-044／T-048 以後／T-053 以後／T-061／T-068／T-070 等原範圍。本次不新增功能或提前結案。

上述限制不撤銷使用者結案、不要求補交附件、不重開六項製包。D1–D8 均保持：不做舊資料轉換、不改 ID／destory 拼字、不改 D3 票證政策、不侵入 D4／D5 尚未實作內容；僅使用者已授權的高速升坡及單向滑行作行为例外，無外部模組。

## C-007～C-012 與修正回歸覆蓋

已審 TASK 各人工範圍、開發契約及矩陣，並讀既有 [R2 局部案例](../../test-packages/T-026-R2-v1/CASES.md)及 [T-030 R1 六組回歸](../T-030/fix-R1/README.md#交由使用者繼續-t-030)。它們是來源／案例輸入，不重新要求六個已接手的完整包。

| 案例 | 保留的必要覆蓋 |
| --- | --- |
| C-007／T-026 | 共同三個設定值、車種 cap 與實測速度分開；四坡向、兩供電模型、一般／動力／高速接口、連續升坡、坡頂／下坡、載人／空車、自然回滾、平直與實體破壞；R2 的重複篩查不當統計根因證明 |
| C-008／T-028 | 四向進車、存方向／停中心、上升沿放行、斷電／重複通知、空軌／多車／外格、低速、存讀、原版接口、兩端 |
| C-009／T-030 | 兩 shape×四來車×reverse×powered×兩設定；當前配置與 stored flags 不同、reload／新放置、零速；R1 一般滑行對照、閾值前後、其他軌道煞車／加速及 tick activator 不受影響、雙端 Mixin 載入 |
| C-010／T-032 | gate／reverse／距離 1、3、100／兩 shape／四向、空乘客、玩家與非玩家、落點障礙、位置確認、兩端、存讀／reload |
| C-011／T-034 | 四 gate、一般車與容器／乘客／TNT，車體與內容掉落分開、無關鄰車、重複移除、煙霧／聲音、同 tick 副作用、兩端、存讀／reload；整列刪除另驗 |
| C-012／T-036 | tag、有車／無車／包圍盒、reverse、0–9 循環、水平／垂直方向、缺／錯型 property、主副手／蹲下／GUI 整合、保存同步、U-09 與真實 owner 不由 fixture 冒充完成 |

使用者確認来源：[T-026](../T-026/REPORT-003.md)、[T-028](../T-028/README.md)、[T-030／032／034／036](../T030-T036-user-confirmation/README.md)。本報告不把任何確認綁定上述固定 JAR，也不改包內空白結果。

## 本次實際執行

| 檢查 | 結果／範圍 |
| --- | --- |
| 全部現行產品 Java 對真實固定 API 重新 javac | 退出 0；`--release 21 -proc:none`，未執行這批 Minecraft 相關 class |
| HoldingRail 實際 hook＋15 替身 | 85 判定通過 |
| 最新 OnewayRail／Mixin 局部函式＋18 替身 | 3,097＋150 判定通過，32 分支列／72 滑行模型案例；未 weaving |
| EjectRail 實際 hook＋20 替身 | 23,821 判定，48 行為列／2,304 回呼通過 |
| DestoryRail 實際 hook＋26 替身 | 8,173 判定，四條件列／640 初始回呼通過 |
| Wrench 實際 hook＋30 替身 | 1,575 判定／388 案例通過；U-09 原碼覆寫如預期保留 |
| R2 原純數值掃描 | 64,008 判定通過；原模型 5,840 次碰撞條件，不是遊戲機率 |
| 本審查新增 HighSpeedRail 實際 hook＋12 替身 | 288 判定通過；四方向、正負座標、平軌／連續升坡、三配置、null／零速／已抬高／無軌／錯坡向／tag 不足等分支 |
| Mixin 固定目標 class bytes audit | 11 判定通過；唯一呼叫、handler descriptor、注入約束、tick 分離及無補償乘數 |
| 原 JAR／build、來源／archive、現行輸入／資源、metadata、模型域 | 468 項靜態核對通過 |

可重跑工具：[run-tests.ps1](run-tests.ps1)、[highspeed-test.ps1](highspeed-test.ps1)、[HighSpeedReviewTest.java](HighSpeedReviewTest.java)、[verify.ps1](verify.ps1)。實際 executable／引數／cwd／UTC／退出碼見 [commands.json](commands.json)、[高速編譯](highspeed/compile.json)／[高速執行](highspeed/run.json)；[checks.json](checks.json)有逐項靜態判定，所有執行 log 另存本目錄。

審查工具有兩次初始問題，均未改產品：高速替身誤用 record 的 private x／z，而實際 Vec3 是 public 欄位，編譯退出 1；改正替身後通過，[原 log](highspeed/compile-attempt-01.log)與 [原腳本](highspeed-test-attempt-01.ps1.txt)保留。靜態工具初次把 T-027／T-029 的 array manifest 當成 object manifest，Join-Path 收到 Object[] 而中止；[原腳本](verify-attempt-01.ps1.txt)保留，按兩種實際格式解析後 468 項通過，沒有放寬 hash 判定。

九份原 NEW Gradle build 證據均核對成功，`test NO-SOURCE` 仍不稱 Gradle 測試通過；本輪未重跑 Gradle／OLD、未啟動 client／server／GameTest／世界。R-F 通過僅限本報告三個修正範圍，後續任何新修正仍須自己的複查。

[最終文件與保全檢查](final-check.json)九項通過：受審輸入未變、報告引用有效、126 任務與依賴／九階段保留、後續 TASK 與 REVIEW 歷史保留、diff 格式及 index 未改。審查於 9 月 29 日開始，9 月 30 日（Asia/Taipei）完成。
