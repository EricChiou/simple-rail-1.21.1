# T-030 未供電單向軌道滑行修正 R1（2026-09-29）

使用者回報與授權原文：

> 我在執行**T-030對oneway\_rail的驗收，希望修改一件事，目前oneway\_rail未通電時會跟動力鐵軌未通電時一樣快速減緩礦車速度，希望改成跟一般鐵軌一樣不會對礦車有煞車作用。**

I-030-01：依此需求，單向軌道未供電時不套用原版動力鐵軌的額外煞車；規則未啟用時不再乘 1.2 補償，保留一般軌道自然摩擦。原啟用條件、reverse 方向與供電加速保持。needPower=false 或 usePowerChangeDirection=true 的原啟用規則仍可驅動未供電單向軌道；本次不是把全部未供電情境改成停用方向規則。U-07 電力翻向／模型意圖仍待確認。

**R1 開發修正完成；T-030 人工測試中、待使用者重測；R-03／R-F 待審。** 不登錄遊戲通過，不重跑 OLD，也不開啟 Minecraft／GameTest。

## 原因、實作與範圍

固定版 [AbstractMinecart 來源](../../T-029/sources/target/net/minecraft/world/entity/vehicle/AbstractMinecart.java) 的 moveAlongTrack 對非 activator 的 PoweredRailBlock，在 powered=false 時先套小於 0.03 停止／其餘水平速度乘 0.5，再移動、自然摩擦及呼叫 onMinecartPass。舊 callback 的乘 1.2 無法恢復已歸零的速度，也不能抵消前段制動。

保留 OnewayRail 的 PoweredRailBlock 繼承、紅石傳遞與全部 blockstate；移除未啟用 callback 倍率。新增一個範圍限定的 Mixin，僅在 moveAlongTrack 的 isActivatorRail 分類判斷，讓未供電 OnewayRail 略過動力軌道煞車分支。這不是把方塊改成 activator：tick 中真正啟動 TNT／乘客／漏斗車的 activator 判斷不修改；供電的單向軌道及其他 PoweredRailBlock 均保持原分類與物理路徑。

Mixin 設定於 simplerail.mixins.json，以既有 TOML 的 [[mixins]] 登錄；只使用 NeoForge 工具鏈已提供的 Mixin 0.8.7，不新增 Gradle 依賴或外部模組。單一目標 require／expect／allow=1，避免指定版本目標改變時無聲漏套用。官方依據：[NeoForge 1.21.1 模組檔案](https://docs.neoforged.net/docs/1.21.1/gettingstarted/modfiles/)、[Mixin Redirect 引數捕捉說明](https://github.com/SpongePowered/Mixin/blob/master/src/main/java/org/spongepowered/asm/mixin/injection/Redirect.java)；實際目標及簽名依本地 21.1.251 class bytes 核對。**尚未驗證真實 Mixin weaving、載入或遊戲效果**，由使用者重測承接。

只修改 OnewayRail.java、新增 AbstractMinecartMixin.java／simplerail.mixins.json，以及啟用 TOML mixin 宣告。ID、模型、其他軌道、共同基底、設定與 Gradle 不變。D1–D8 與僅高速支援斜坡保留；本次是使用者核准的單向軌道行為調整，原碼參考不改寫成新行為。

## 實際验证與固定 JAR

| 實際命令／檢查 | 結果與範圍 | 證據 |
| --- | --- | --- |
| powershell -NoProfile -ExecutionPolicy Bypass -File docs/evidence/T-030/fix-R1/build.ps1 -Attempt 2 | NEW build 退出 0；test NO-SOURCE，不是 Gradle 測試通過 | [命令／時間／退出碼](build-02.json)、[log](build-02.log) |
| powershell -NoProfile -ExecutionPolicy Bypass -File docs/evidence/T-030/fix-R1/hooks-test.ps1 -Attempt 3 | javac／兩個 java 均退出 0；實際產品 hook／redirect 配 18 個替身，3,097＋150 判定通過；32 分支列與 72 滑行模型案例 | [命令與退出碼](hooks-test.json)、[hook log](OnewayRailHooksTest-03.log)、[回歸 log](CoastingRegressionTest-03.log) |
| Temurin 21 javac／java InjectionTargetAudit | 均退出 0；11 個離線 class bytes 核對，固定目標唯一呼叫、handler 引數、範圍／注入約束及無補償倍率 | [命令／退出碼](audit.json)、[log](audit-01.log)、[核對原碼](InjectionTargetAudit.java) |

隔離測試沒有真正 Minecraft 父類、世界、同步、Mixin transformer 或車種副作用。低速、閾值 0.03 前後、兩軸、正反向的速度測例只證明來源模型和局部函式；不將它們寫成遊戲結果。其他動力軌／activator 分類在局部函式測試保持，實際遊戲仍需回歸。

首個 build 因沙箱無法寫 Gradle Wrapper 鎖檔退出 1，[log](build-01.log)／[紀錄](build-01.json)保留；允許後的離線重試退出 0。隔離編譯前兩次遇到沙箱在关闭既有 cache JAR 時的 AccessDeniedException；第二次 javac 雖回傳 0、測例也成功，但保留其 [診斷](hooks-compile-02.log)，不作最終乾淨編譯證據。改將既有 Mixin JAR 複製到本次隔離目錄後，第三次無該診斷且全部退出 0；沒有下載或升級依賴。

第二次回歸 log 的 modeledMotionCases 誤印為 144，實際迴圈為 72 案例／150 判定；第三次只修正印出的案例數，最終 log 記為 72，未放寬判定。[文件／JAR／範圍自查](delivery-check.json)15 項通過；[首輪自查](delivery-check-01.json)有兩個路徑比較失敗，原因是 Windows 反斜線與正斜線不同，僅正規化核對工具的路徑後通過。任務編號／依賴／九階段／覆盖／D1–D8／歷史／Markdown 與 Git index 保留，未由文件核對推定人工通過。

[R1 固定 JAR](artifacts/simplerail-1.0.0.jar) SHA-256：**3AB3E37EF4AA21342011332E9531088DB36D121A1F6C9C9823DD6B3259538594**。Minecraft 1.21.1／NeoForge 21.1.251／Simple Rail 1.0.0／Java 21／Gradle 9.2.1；HEAD 8bd977dbb9f9000411ae5f4d10750228e5f33560 加未提交來源，未虛構新 commit。原 T-029／T-035 JAR 與歷史證據不覆寫。

## 交由使用者繼續 T-030

T-096 仍由使用者接手，不重開 Agent 全量製包任務；本 R1 JAR 是修正產物。停止 client／server，備份 NEW 測試世界並以此 JAR 替換原 Simple Rail JAR，避免同時留兩份；多人兩端使用同版。依原啟動方式進入 NEW 世界，不匯入 OLD 存檔。

| 案例 ID | 操作／事先預期 | 人工結果 |
| --- | --- | --- |
| C-030-R1-01 | 預設 needPower=true、usePowerChangeDirection=false；等長平面一般軌與未供電單向軌，以同類礦車／相同乘客負載、起始速度比較。單向軌應自然滑行，不快速半速制動；原自然摩擦仍存在 | 待使用者確認 |
| C-030-R1-02 | 两軌向、reverse 雙值、兩來車方向，含極低速、較高速及停止礦車；未啟用時不額外改向、啟動或乘 1.2 | 待使用者確認 |
| C-030-R1-03 | 供電單向軌及 needPower／usePowerChangeDirection 原組合，檢查仍按既有 reverse 方向規則運作；U-07 方向意圖未決案例仍待確認 | 待使用者確認 |
| C-030-R1-04 | 原版動力軌未供電仍煞車，供電仍加速；高速／holding 等其他軌道重測受影響範圍，不能由本 R1 靜態測試推定既有人工結果適用新 JAR | 待使用者確認 |
| C-030-R1-05 | 單向軌紅石連續傳遞、軌道銜接、切換電力、保存重載、水浸狀態與多人同步，按 T-030 原範圍核對；一般車、TNT／漏斗／乘客車不應被單向軌當 activator 啟動 | 待使用者確認 |
| C-030-R1-06 | client 與 dedicated server 均須實際載入 R1，無 Mixin apply／injection error；原 T-030 完整組合、重載相異 stored flags、共用速度及原版接口仍需驗收 | 待使用者確認 |

只需回覆任務 ID 與通過／失敗確認，無須交版本證明或附件。若有問題，可選擇提供实际現象、設定與 latest.log／crash-report（client 為遊戲目錄 logs/latest.log，server 為伺服器目錄 logs/latest.log）。Agent 不代填結果、不要求追加證據；T-030 及 R-03／R-F 未通過。
