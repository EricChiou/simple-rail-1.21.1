# R-01 獨立程式審查紀錄

**結論：程式審查通過；未發現本次範圍內的阻擋問題。** 日期：2026-09-28（Asia/Taipei）。本結論只適用下列版本、API 研究／框架差異及操作包案例覆蓋，不代表功能移植完成或新增人工遊戲通過。

## 範圍與獨立性

- 審查 ID：R-01；依據 REVIEW.md §1–7、§23–24，TASK.md T-005–T-018、T-089–T-091，MIGRATION.md §3–6／D1–D8。
- 開發者：各 T 證據記錄的先前開發 Agent。獨立審查者：本次 Codex review session，未實作受審產品差異或 API 探針；本次只新增審查工具／證據與更新狀態文件，未修產品或受審探針。
- 直接閱讀：T-017 相對 HEAD 的 Java／資源差異、T-008–T-016 全部探針、API 對照與下游限制、T-009 檔案檢查工具、T-090／T-091 安裝／案例／manifest／結果模板。指定版來源用於核對入口、回呼、保存、容器、同步、模型及票證關鍵路徑。
- T-006／T-007 僅核對歷史證據範圍；不重簽當時遊戲結果。T-018／T-089 保留使用者人工通過與結案，不要求重測、版本或附件，也不把先前確認綁定本次 JAR。

## 受審版本

| 項目 | 本次固定身分 |
| --- | --- |
| NEW HEAD | `8bd977dbb9f9000411ae5f4d10750228e5f33560`，含既有未提交產品差異，非 clean commit |
| 產品差異／來源 | [T-090 source.diff](../T-090/source.diff)、[11 項產品輸入指紋](../T-090/source-fingerprints.json)；本次重新核對全部相同 |
| 平台／工具 | Minecraft 1.21.1、NeoForge 21.1.251、FML 4.0.44；Java 21.0.12.1、Gradle 9.2.1、ModDevGradle 2.0.147、Parchment 1.21.1／2024.11.17 |
| 模組 | `simplerail`／Simple Rail 1.0.0／All Rights Reserved |
| 現行框架 JAR SHA-256 | `537780CB1E3C2B532AF7F22BEC1AA306C0966AFD6C571CC5D2936275B66C3A36` |
| T-090-v1 ZIP SHA-256 | `B871DC2B375DD72654EE0B2A48C8CE68CBB92B8750B7A726D41E62B6DE7F6CE8` |
| T-091-v1 ZIP SHA-256 | `491357371F052A18637E7AC7157B2C78EB8F13C857D1153C8B1EDD6523EE3D1A` |
| T-005 歷史 JAR SHA-256 | `D6BB8A92830EDDE583838496D471E9F201BE0D16694D0B487D06D46D21D9FE94`，另存基線，不混同現行框架 |

metadata 宣告 NeoForge `[21.1.251,)`、Minecraft `[1.21.1]`；審查只鎖定 21.1.251，不將允許載入範圍當成其他版本已驗證。

## 檢查與命令結果

| 檢查 | 結果及證據 |
| --- | --- |
| 來源可追溯性 | T-008–T-016 合計 497 筆快照（含重複來源），全部核對快照 SHA、原 archive SHA／entry 內容或 OLD 原始檔 SHA；8 組 compile classpath 各 84 筆全部一致。[檢查腳本](review-check.ps1)、[27 組結果](checks.json) |
| 最小編譯重查 | 使用各任務記錄的同一 javac／classpath，`--release 21 -encoding UTF-8 -Xlint:deprecation -Werror -proc:none`；T-008、T-010–T-016 八組探針及 T-017 現行產品 Java 共 9 次退出 0，產生 29 個 class。[腳本](compile-check.ps1)、[命令參數與退出碼](compile-results.json)；逐次 `T-xxx-javac.args`／log 保存於本目錄 |
| 原 Gradle build 證據 | 核對 T-005 build-attempt-02、T-017 build-02、T-090 build-01 的命令／成功 log／退出 0；後者與 T-091 共用一次 build。全部保留 `test NO-SOURCE` 邊界。本次沒有重跑 Gradle build，也沒有將 javac 重編稱為 Gradle build 或功能測試 |
| 固定包／JAR | 兩包各 16 檔，逐檔 manifest SHA、ZIP 與磁碟內容一致；兩份 JAR 與現行 build JAR 一致；各 5 案例 ID 與 manifest 對應，人工確認、實際版本及逐例結果仍空白。現行 JAR 僅兩個入口 class，無 Config.class／探針。[checks.json](checks.json) |
| 入口 bytecode | `javap -v -p -classpath build/libs/simplerail-1.0.0.jar com.ericchiu.simplerail.SimpleRail com.ericchiu.simplerail.SimpleRailClient` 退出 0；major 65、`simplerail` annotation、client 的 `Dist.CLIENT` 與 common 無 client API 引用已核對。[bytecode](entry-bytecode.txt)、[metadata](jar-metadata.toml) |
| T-009 非遊戲證據 | 閱讀 ResourceAudit.java 與既有 audit-commands-2／static-audit：144 資源、98 JSON／mcmeta、45 PNG 標頭、13 配方、266 引用，failures 空、退出 0。來源快照本次重新核對；未重跑 auditor，也未執行 Minecraft codec／resource reload |
| 工具初次失敗 | 本次自製檢查腳本初次遇 PowerShell 5 JSON 陣列包裝造成路徑轉換失敗；初次 javac 呼叫的 stderr 被 PowerShell NativeCommandError 中斷，沒有取得編譯器完整診斷／退出碼。改正陣列處理及以 ProcessStartInfo 擷取 stdout／stderr 後上述檢查、9 次 javac 均成功。這是審查工具的失敗，不推定產品或 JDK 缺陷；未改受審程式 |

所有新輸出都在 R-01 目錄，原始 T 證據、固定 ZIP／解壓包、產品程式與 Git 暫存區保留。`docs/` 仍受既有忽略規則排除，本報告及工具保存在本機工作區。

文件同步後以 [final-check.ps1](final-check.ps1) 核對 126 個任務標題／前置與 9 階段不變、REVIEW §8–24 原樣、文件連結存在、產品相對既有暫存區無新差異及 `git diff --check`，見 [最終結果](final-check.json)；受審輸入另固定於 [reviewed-inputs.json](reviewed-inputs.json)。文件工具初次因 Windows PowerShell 對無 BOM 中文腳本的解析失敗，改用 UTF-8 BOM 後成功；最終檢查初次把「階段總覽」誤計為第 10 階段，修正匹配為階段 0–8，失敗紀錄保存於 [final-check-attempt-01.json](final-check-attempt-01.json)，未改任務結構。

## 各項結論與關鍵來源

| 受審項目 | 核對結論與限制 |
| --- | --- |
| T-005／T-006／T-007 | T-005 建置基線身分與成功證據成立；T-006／T-007 是舊模板的 Agent 啟停紀錄，client 的範例模型警告、同名世界觀察限制及未驗連線均保留，不能替代現行 JAR 的人工結果 |
| T-008／T-017 | 通過。指定 FML `Mod.java` 明訂多入口；本次補核 [FMLJavaModLanguageProvider.java](FMLJavaModLanguageProvider.java) 的 `loadMod` 先按 mod ID／dist 過濾、再建立入口列表；`FMLModContainer` 接受 IEventBus 注入與零參數入口。common 無 client 類別引用，無重複註冊。刪除範例 Config／翻譯／物件符合空框架階段，沒有刪除已移植的正式 ID。[補充來源指紋](additional-source.json) |
| T-009 | 通過格式／ID 研究。Registries 的單數路徑、ItemStack 結果 `id`、ingredient／loot 的不同欄位、NamespacedDirectoryLister 三個欄位與圖集路徑均有來源。額外車頭 loot、wrench blockstate／tag、反向 item model 已明列去向，未新增註冊物件。實際資源移植與 codec 載入屬 R-02 |
| T-010 | 通過 API／完整狀態候選。PoweredRailBlock 雙參數 true、RailState 使用 isFlexibleRail、過車後仍可加速、完整 shape／六向／waterlogged、any() 不等於父類預設、useItemOn／useWithoutItem／item useOn 分支均與來源一致。探針的屬性聯集和固定數值不能當正式方塊實作 |
| T-011 | 通過編譯介面與資料邊界設計。ChunkMap 的卸載路徑先 Unload／save 再 ServerLevel.unload，證實 BE onChunkUnloaded 太晚；timer 的實際秒數、remaining_ms 與 signal 的 tick 排程分線。探針 saveAdditional 只寫上次 tick 剩餘值，尚非正式序列化時刻快照；此限制已在交付明列，T-038 必須落實，不能以本次通過簽 D5 功能完成 |
| T-012 | 通過專用 BE／GUI 候選。新增 train_dispenser BE ID 與既有方塊／物品分 registry；27 格 Container、ChestMenu.threeRows、0–26／27–53／54–62 索引及原版同步來源吻合。removeItemNoUpdate／直接修改標髒與父類 dispenseFrom 隔離限制已交 T-044–T-046；空生成方法僅屬探針 |
| T-013／T-014 | 通過資料責任與同步候選。ServerLevel UUID 查找只含當前可見實體，null 不清持久清單；父類 Fuel／PushX／PushZ、discard 與 destroy 路徑分列。FACING 0–7 編碼無重複且 server 寫入；內建 BYTE／BOOLEAN 避免舊 serializer 直接註冊錯誤，spawn／非預設資料／dirty 更新來源吻合。探針掉落、扣物、跟車、初始方向／LINKABLE 取捨仍按既定後續任務實作 |
| T-015 | 通過來源／模型規格與編譯候選。核對六盒尺寸、texOffs、mirror、96×64 與 layer／renderer 接線；指定 MinecartModel 建構子只保存 root，setupAnim 為空，探針自訂 cart 子樹可承接此基底。簡化 yaw 不等於完整礦車坡度／受損／插值；完整外觀由 T-050／T-052 承接 |
| T-016 | 通過 D3 呼叫候選。EnteringSection＋didChunkChange、ServerLevel、controller 登記、Entity→UUID、true／true 均與指定來源一致；保留 25 次相同中心呼叫，無新增 5×5 或解除政策。首次生成／重載觸發與真實 ticking、OLD 精確 binary 行為仍依原範圍待查，不能以 hasChunk 證明票證效果 |
| T-090／T-091 | 通過兩固定包的程式身分與案例覆蓋，詳下表；包內製作時的「待審」作歷史快照保留，由本報告以 ZIP SHA 提供獨立審查結論，無需改寫固定包 |

## 案例與 D1–D8 覆蓋

| 需求／案例 | 覆蓋與邊界 |
| --- | --- |
| T-004 C-039 工具鏈／框架 | T-005／T-017／T-090 build 證據、包內版本／metadata／指紋與 T018-01／03／05；build 由開發證據承接，使用者不用重跑 Gradle |
| T-004 C-040 client／server／連線 | T089-01 同版、02 登入、03 基本移動、04 離線／重連、05 保存停服；T018-02 單人新世界／保存／退出、04 dedicated server 獨立啟停、05 server registry／client-only 邊界。兩包共 10 子案例，未混同單端啟停與連線 |
| D1／C-02 | 操作包使用獨立 NEW 世界；候選只設計 NEW 保存，無 OLD 世界／NBT／箱子／票證轉換。功能存讀另屬後續案例 |
| D2／C-01 | 正式 ID／完整 state 研究名冊保留；空框架只刪模板，11 方塊／13 物品仍未實作，不把缺少後續功能當本階段回歸 |
| D3／C-07 | 中心座標重複呼叫及未釋放現狀保留；不推定 5×5 或持續 tick 已測 |
| D4／C-04 | 專用 27 格 BE、箱子 GUI、不消耗樣板設計有來源；正式生成及雙端存讀尚未實作 |
| D5／C-03 | 實際秒數／讀回重設基準／離線不扣時間設計保留；訊號另按 tick。卸載約 3 秒測例與容差凍結仍由後續任務承接 |
| D6／C-05–C-08 | 六疑點、UUID 晚載入、路口／同步／票證政策仍按既定調查與修正鏈處理；沒有藉審查修改玩法或開始 T-019 |
| D7／D8／C-09 | JAR／Gradle 無新增外部模組整合，固定 1.21.1／21.1.251／1.0.0／授權；案例預期与結果分開，人工确认即結案規則保留 |

安裝說明另與 2026-09-28 查閱的 [NeoForge client 文件](https://docs.neoforged.net/user/docs/client/)、[server 文件](https://docs.neoforged.net/user/docs/server/)及 [21.1.251 Maven 目錄](https://maven.neoforged.net/releases/net/neoforged/neoforge/21.1.251/)核對。安裝方法與指定 installer 存在有官方依據；本次未下載或執行 installer，也沒有啟動 Minecraft client／server／GameTest。

## 問題、保留限制與交接

新 REV 阻擋問題：**無**；不建立假設性缺陷。已知下游技術待定事項（COMMON 策略、計時快照／容差、發射器觸發／標髒、燃料／永久移除判定、LINKABLE／初始方向、完整 renderer、controller ID／實際票證）均保留原承接任務，不被 R-01 通過消除。R-02–R-08、後續功能／最終候選人工驗收尚未通過。

T-008–T-017、T-090／T-091 共十二項改為「開發完成；R-01 程式審查通過」。T-005 基線證據已審；T-006／T-007 歷史與 T-018／T-089 使用者結案照舊。本報告不產生任何新的人工結果；使用者原文仍以 T-018／T-089 記錄為準。任務仍共 126 項、其餘 105 項待執行；下一功能任務為 T-019，本輪未開始。

後续若產品／API／依賴或候選 JAR 改變，依 REVIEW.md R-F 重新界定受影響差異與回歸；本結論不自動延伸到新版本。
