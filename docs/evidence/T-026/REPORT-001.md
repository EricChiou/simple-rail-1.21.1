# T-026 使用者問題回報 001

收錄日期：2026-09-28。**人工測試不通過；待需求釐清、根因調查及修正後重測。** 回報者為使用者，Agent 沒有啟動 Minecraft 或重現遊戲；不要求補交附件。未收到其餘測例結果，不填其他案例通過。

## 使用者原文

> 我執行**T-026 驗收高速軌道與共用基底規則，發現以下問題**
>
> 1. 沒有像原版動力鐵軌一樣的斜坡模式
> 2. 平面高速鐵軌銜接斜坡動力鐵軌或一般鐵軌有時會發生速度礦車銜接異常，導致礦車行進方向被改變

此確認足以登錄人工失敗。受測 JAR、遊戲環境、速度設定、供電、坡底／坡頂、行進方向及發生頻率未提供，均為待確認；不得自行綁定 T-025 JAR 或補造 log／截圖／量測。T-094 仍待執行，R-03 仍待審，不因已收到使用者回報而改成完成。

## I-026-01：高速軌道斜坡需求與原規格不同

- 已確認來源：[BasePoweredRail](../../../src/main/java/com/ericchiu/simplerail/block/base/BasePoweredRail.java) 的 canMakeSlopes 回 false；[HighSpeedRail](../../../src/main/java/com/ericchiu/simplerail/block/HighSpeedRail.java) 沒有覆寫。OLD 兩基底也回 false，MIGRATION.md §3／T-025／T-026 均列禁坡。OLD 行為仍是「依原始碼推定／待確認」，不是本輪舊版實測。
- 這解釋目前不會自動成坡的實作，但使用者現在期待斜坡；**新需求範圍待確認**：僅高速軌道例外、全部基底改變，或維持禁坡只修銜接。沒有擅改已定指南。
- 若採高速例外，須同步需求／測例及高速自己的成坡 hook、四升坡雙供電模型；不能只改共用基底或只加 JSON。其他特殊軌道是否可成坡不可由此推定。
- 固定版 RailState 在 connectTo／place 的升坡分支檢查 canMakeSlopes；PoweredRailBlock 的宣告域已有兩平軌＋四升坡，禁坡不會移除宣告域。現有高速 JSON 僅平軌，沿用 I-021-01 的未覆蓋模型問題；不可把使用者說無斜坡直接冒充已重現缺模型錯誤。

## I-026-02：高速平軌與原版斜坡銜接後改向

- **使用者觀察已登錄，根因待確認；未修復／未重測。** 本項違反 T-026 的原版銜接預期，不因第一項需求歧義而忽略。
- 目前高速只繼承 PoweredRailBlock，三個共用 hook 之外沒有 onMinecartPass、getRailDirection 或礦車速度向量補丁；不得說成某段自訂方向演算法已被證實錯誤。
- 指定版 [RailState](../T-025/sources/target/net/minecraft/world/level/block/RailState.java) 會查看鄰格及上下格並重算連接／shape；[AbstractMinecart](../T-025/sources/target/net/minecraft/world/entity/vehicle/AbstractMinecart.java) 的 moveAlongTrack 依 shape 投影速度、處理坡度、碰撞移動及跨格位置，再執行 rail 回呼。getMaxSpeedWithRail 取軌道速度與車輛上限較小值；高速配置不是實測速度。
- 待區分：軌道狀態改成另一軸、碰撞／未供電制動／上坡回滾，或高速跨格與坡頂／坡底交接異常。以上是調查方向，**不是已驗證根因**；也不把方向改變合理化為原版必然行為。
- 需要的最小文字資訊：坡底或坡頂（或兩者）、上／下坡、速度設定、相關軌道供電、反轉或轉到另一軸。沒有要求使用者提供證據或重建 OLD。
- 後續回歸至少包含：東西／南北兩軸、正反行進、坡底／坡頂、原版一般／動力軌、供電／未供電，以及設定 0.4／0.8／2.0；先定義正常制動／回滾與異常改向的判定，再由使用者重測。必要修正經程式 R-F／R-03 複查，實際遊戲結果僅依使用者確認。

## 本輪範圍與證據

本輪只做回報收錄、既有固定版本來源追蹤及文件狀態同步。沒有改 Java／Gradle／資源、執行 build／OLD／Minecraft／其他功能任務或簽 Review。T-025 原開發交付及證據保留，當時的「人工未測」是歷史；最新 T-026 已有本次失敗回報，功能未交付完成。

[收錄 metadata](report-001.json)、[文件／依賴與產品未變核對](report-001-check.json)不代表遊戲證據。來源參照使用已保存的 Minecraft 1.21.1＋NeoForge 21.1.251 原檔；方法與流程為來源分析，沒有宣稱重新完成 API 任務或 runtime 驗證。
