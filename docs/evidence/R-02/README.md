# R-02 獨立程式審查（2026-09-29）

**分項通過：T-019、T-020、T-021、T-022、T-093 的既有開發交付。** 沒有新增 S0–S2 問題；發現一項 S3 測試包說明錯誤，勘誤如下。T-092 原草稿已審閱，維持「已結案（使用者確認完成）」，不簽為正式新版包。T-023／T-024 維持使用者人工通過；不把其確認綁定到本次受審 JAR。

這是指定範圍的程式、資源與測例審查，不是所有未實作 state／模型、R-03／R-F 或最終候選放行。I-021-01／I-092-02 的既有技術限制仍按後續功能與整合任務追蹤，不重開使用者已結案任務。

## 審查發現與勘誤

### REV-R02-001：兩包的創造分頁順序寫錯（S3）

- 位置：[T-092 TABLES.md 第 25 行](../../test-packages/T-092-v1-draft/TABLES.md#13-物品與-11-方塊)、[T-093 TABLES.md 第 25 行](../../test-packages/T-093-v1/TABLES.md#13-物品與-11-方塊)。两份文字將 wrench、locomotive_cart 放在最後。
- 依據：[ModCreativeTabs.java](../../../src/main/java/com/ericchiu/simplerail/registry/ModCreativeTabs.java)第 20–32 行、[T-019 固定 source.diff](../T-019/source.diff)及 [state-contract.md](../T-019/state-contract.md)均明列兩者最先。此差異在固定包製作時已存在，並非後續 R-03 改動。
- 正確順序：**wrench、locomotive_cart、high_speed_rail、holding_rail、oneway_rail、eject_rail、destory_rail、timer_holding_rail、cross_rail、y_cross_rail、y_cross_right_rail、train_dispenser、signal_timer**。圖示仍為 high_speed_rail。
- 影響：照 TABLES 核對排序可能誤報；13 個 ID、物品數、圖示、翻譯及可取得性要求不受影響，原證據足以核對，符合 REVIEW §5 的 S3 定義。T-093 的配方／loot／tag 案例不因此失效。
- 處置／責任：本節作為兩固定包的外部勘誤；保留原 ZIP、manifest、TABLES 與雜湊。未來若開發 Agent 製作新版包，應使用上述來源順序；不因這項勘誤重開 T-092 或撤銷人工結案。[兩份差異摘錄](T-092-tab-order.txt)、[T-093 摘錄](T-093-tab-order.txt)可重查。

## 範圍、獨立性與版本

本審查者未實作 T-019–T-022／T-092–T-093 的產品或包交付。本次只新增審查工具／報告及更新三份進度文件，未修改產品、固定包、開發證據或人工結果，也未 stage、reset、commit。

開始讀取時 HEAD 為 `74bc923`，檢查期間工作區已有後續文件提交；最終靜態核對 HEAD 為 **`139985ffbc6827ccf585a98ff06773b30d8947bc`**。這些提交不是本審查建立。精確產品／包／來源雜湊見 [reviewed-inputs.json](reviewed-inputs.json)，不靠分支名稱推定內容。

T-019–T-022 的原交付基於 `8bd977d` 加當時差異。四個固定 JAR 都重新驗證 SHA-256：

| 交付 | SHA-256 |
| --- | --- |
| T-019 | `7AEB033B7B5949E89005DC8B65DF73D93272BCCB430D81F80DE516248ECF9C9D` |
| T-020 | `166E7B63AC9E56A83CEFD23448B458F0E221D7059825BDACFE9A541898A9C467` |
| T-021 | `3FB257657741F7A0A50EE0879FC92C7F15EB51C1434F2FDBB1EE51AD0B5A96AD` |
| T-022／兩包共同 JAR | `3D4BFC8926509DCE28C6DE11E8198D3639EB288E1EB29FAD89D3AEC9C1C6BBD3` |

| 固定包 | SHA-256 | 審查範圍 |
| --- | --- | --- |
| T-092-v1-draft.zip | `C7FD51E6A4E0536DA0D982933E0987B4200D607E3650143B91B7B4AD8E43127E` | 31 檔／156 個 SP、DS 草稿案例；reference JAR 不是正式可操作交付 |
| T-093-v1.zip | `9468FE025ECB382A5E0D6D9C837B396E7BCDDF954B391AB9A54C5B68C2AFFC82` | 31 檔／226 個 SP、DS 案例；資料驗收包製作通過，另附本報告 S3 勘誤 |

固定包製作時的待審／待人工文字保留為歷史，由本報告及 [使用者確認](../T023-T024-T092-user-confirmation/README.md)另行記錄最新狀態。包內 actualResult 保持空白。

## 逐項判定

| 任務／案例 | 判定與依據 | 實際邊界 |
| --- | --- | --- |
| T-019／C-001、C-002 | 註冊骨架通過。11 block、13 item、11 同 ID BlockItem、分頁 13 項唯一且完整；destory 拼字保留；reverse／wrench 資源未誤註冊。deferred supplier、圖示／內容回呼才取 holder；common 接三 registry，沒有 client-only 依賴或註冊前讀設定。完整狀態域與未實作 owner 明列 | 此任務交付骨架與狀態對照，未承諾所有後續方塊行為；不將骨架視為完整遊戲版本 |
| T-020／C-003 | 通過。25 原鍵／預設／範圍、true=載入啟用、兩組秒數、20／10 tick 常數保留；COMMON 不同步。事件核對 spec identity＋COMMON＋mod ID；FML setConfig 在鎖內先 acceptConfig 清 value caches 再派事件，產品讀全值後一次 volatile 發布；snapshot 及 List 不可變；載入 guard、重載與卸載路徑正確 | 159 項測試為普通 JVM 的實際 ConfigSpec／快照測試，不派 FML 事件；檔案監看、世界消費者、client/server 權威及時間換算仍依對應功能驗收 |
| T-021／C-004 | 資源遷移交付通過。144 舊檔去向可追溯；114 資源＋新 atlas，原 PNG、語系值與 ID 保留；29 模型只加 cutout，43 plural-path sprite、parent／texture alias、45 PNG 解碼及 metadata 處置符合固定來源 | 不簽 Minecraft bake／透明外觀；既有 I-021-01 的候選完整域缺口另列，不因 JSON 引用通過而消失 |
| T-022／C-005、C-006 | 通過。29 data 檔採 1.21.1 單數目錄；13 配方僅 result.item→id，ingredient.item、排列、材料、產量保留。11 block loot 與額外 cart entity 表分開；cart 表移除 ENTITY context 不接受的 survives_explosion，保留 ID／type／pool。四 tag 合併與型別正確 | 額外車頭表不是正常 Java destroy 的掛接；T-048／T-052／T-062 須驗真正掉落及避免雙重掉落 |
| T-093 | 包製作與測例覆蓋通過，附 S3 勘誤。兩端各涵蓋 13 配方原排列／平移／鏡射、損傷鎬材料、11 方塊鎬／手／loot mine／真爆炸、tag 全成員／負例／原版保留與 reload | loot mine 明確不等於真爆炸；爆炸只判 0–1 同 ID，不假定必掉或量測機率；不冒充車頭實體驗收 |
| T-092 | 草稿完整性與限制已審，不判新版包開發完成。取得名冊、雙語、候選 state、25 設定及 reload 的案例可追溯；無法操作的部分已有 I-021-01／I-092-02 | 依使用者確認結案，無需重製／補證；原 reference JAR 不因此變為無限制正式包 |
| T-023／T-024 | 維持使用者人工通過、已結案 | 審查者未啟動遊戲，不補造受測版本、逐例資料或新的人工結論 |

指定版 ModConfigSpec／FML、Ingredient／ShapedRecipePattern、LootTable／condition、資源 loader 等使用已有固定原始碼；其來源雜湊已重查。未以新版網頁文件替代固定版本。

## 現行產品差異與保留限制

相對 T-022 的既有輸入，目前只有四個路徑雜湊不同：ModBlocks、ModItems、high_speed_rail blockstate、NeoForge TOML。分別是後續功能類別接線、扳手接線、高速升坡與 Mixin 登錄；新增類別、四份升坡模型、Mixin JSON 及 pickaxe tag 屬後續交付。它們的行為／Mixin 安全性仍由 R-03／R-F 審查，本輪只核對 R-02 ID 與資料連接。

- CommonConfig、兩入口、ModCreativeTabs、ModTags 及原 29 data 檔均與 T-022 保存指紋／JAR 一致。另有第 30 份 `minecraft:mineable/pickaxe` tag，是 T-025 起逐次新增的五個已實作軌道、replace=false；已核對成員均存在，不套用舊「只有 29 檔」斷言到現行全部資源。
- I-021-01：固定 T-021／T-022 仍有 10 種 placeholder 缺 selector property、9 種候選域未完整覆蓋。現行已有五個功能軌道與高速坡面，不能繼續用這兩個數量描述現行版本。仍為普通 Block 的 timer_holding、兩 Y 路口、train_dispenser、signal_timer 的 selector 需要後續 StateDefinition；cross 的空 selector 不屬此問題。既有其他軌道的 ascending、六向 up/down 等候選模型邊界仍須由功能／最終整合處理，不刪域或猜外觀。
- I-092-02：固定草稿没有有效 COMMON 快照觀測入口。現行部分設定已有功能消費者，但不等於全部 25 鍵、timer／signal／票證已具可觀測實作；保留原功能任務的 reload／兩端案例，不用 `/reload` 或檔案寫回當成快照生效證明。
- D1 無 OLD 世界／設定轉換；D2 全 ID 保留；D3 不翻轉歷史 true 語意、不新增票證政策；D4、D5 的容器與計時設計留原 owner，未提前簽實作；D6 高速升坡例外與其他軌道禁坡不變；D7–D8 固定 MC 1.21.1／NeoForge 21.1.251／mod 1.0.0／All Rights Reserved，無外部模組。

上述技術限制不撤销 T-023／T-024 使用者結果，也不重開 T-092。R-03／R-F、未實作功能與最終整合仍待各自審查；本報告不宣稱整體功能交付完成。

## 本次實際驗證

| 驗證 | 結果 | 證據 |
| --- | --- | --- |
| 固定 T-021 資源 auditor 重新 javac／java | 2,519 項、563 引用、45 PNG，0 失敗 | [resource/audit-results.json](resource/audit-results.json)、[log](resource-run.log) |
| 固定 T-022 data＋現行 registry 身分 auditor | 393 項、85 引用，0 失敗 | [data/audit-results.json](data/audit-results.json)、[log](data-run.log) |
| 現行 CommonConfig＋原契約 fixture 重新 javac／java | 159 項，0 失敗 | [config/test-results.json](config/test-results.json)、[log](config-run.log) |
| 本審查新增雜湊、ID、BlockItem、ZIP／manifest、測例覆蓋核對 | 389 項，0 失敗 | [checks.json](checks.json)、[verify.ps1](verify.ps1) |

執行工具：[run-checks.ps1](run-checks.ps1)。[初次命令](commands-attempt-01.json)／[後續命令](commands.json)保存 executable、完整引數、cwd、UTC、退出碼；[classpath 雜湊](classpath-hashes.json)固定編譯輸入。ResourceAudit／DataAudit 的 JVM 只載 Gson，Minecraft JAR 僅作 ZIP 資料；config JVM 只執行 ConfigSpec／NightConfig，不呼叫 Minecraft 或 FML launcher。

首次 data auditor 對現行資源套用歷史 29 檔斷言，因 R-03 新增 pickaxe tag 退出 1（其餘 393 判定通過）；[原 log](data-run-attempt-01.log)、[原結果](data/audit-results-attempt-01.json)、[原 runner](run-checks-attempt-01.ps1.txt)保留。之後改用固定 T-022 JAR 的 29 份資料，另逐檔證明其與現行一致；未刪產品標籤或改正確性斷言。DataAudit 副本僅擴充註冊 regex 接受後續 registerBlock／registerItem；原 auditor 不改。

四項原 NEW Gradle build log／退出碼／JAR 重新核對，但本輪不重跑 Gradle，`test NO-SOURCE` 不稱 Gradle 單元測試通過。Config JVM 有 terminal capabilities 警告。沒有 OLD build、Minecraft client／server／GameTest、世界操作、正式新包或新人工結果。

[最終文件與保全核對](final-check.json)另有 9 項通過：274 份受審輸入未變、報告引用有效、126 任務／直接依賴／九階段不變、後續 TASK 與 REVIEW §1–45 歷史保留、diff 格式及 index 未改。只有報告、工具與三份進度文件為本輪新增差異。
