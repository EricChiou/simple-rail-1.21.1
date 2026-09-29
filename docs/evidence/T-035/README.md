# T-035 扳手屬性操作交付

2026-09-29。**原碼相容開發完成；U-09 複合操作意圖待確認；R-03 待審；T-036 人工／T-099 包未執行**。只執行 T-035，未啟動 Minecraft、GameTest、client／dedicated server，未開始編組連結或其他任務。OLD build 由使用者先前驗證，本次流程不重跑；所有舊行為為「依原始碼推定／待確認」。

## 自身完成條件與交付

| 要求 | 實際交付與證據 | 範圍 |
| --- | --- | --- |
| wrench 互動／tag／操作條件 | [Wrench](../../../src/main/java/com/ericchiu/simplerail/item/Wrench.java)、[来源／API／規則](WRENCH_CONTRACT.md)、[11 方塊屬性／承接表](property-tag-map.json) | rails 點擊格無車才改 reverse／level／direction；machines 不受車阻擋，改 facing／level；非適用方塊／屬性不寫入 |
| 等級／轉向規格 | [24 單屬性列](operation-matrix.json)、[U-09 靜態重現與未知](U09-source-reproduction.json) | level 0–9／9→0；水平 N→E→S→W→N，up/down 不變；複合屬性保留原碼覆寫順序，並非授權的修正 |
| stack／工具能力／ID | ModItems 原 wrench ID 改 typed factory，保留 stacksTo(1)／COMMON／fireResistant；宣告 DEFAULT_HOE_ACTIONS | 不實作 HoeItem 耕地，不消耗／傷害物品，不改 11 方塊／13 物品、資源／tag／設定／Gradle |
| 真實 API 可建置 | [命令／時間／退出碼](build-01.json)、[完整 log](build-01.log)、[bytecode](Wrench-bytecode.txt)、[固定來源 manifest](source-manifest.json) | NEW build 退出 0；Gradle test **NO-SOURCE**，不是自動遊戲測試通過 |
| 非遊戲操作驗證 | [真實產品 hook 與 fixture](WrenchHooksTest.java)、[命令／退出碼／30 替身範圍](hooks-test.json)、[結果](hooks-test-01.log) | javac／java 各退出 0；388 案例、1,575 判定。包含 tag、車有無、null player、各 scalar 值／缺屬性／錯型／錯範圍、client guard、U-09 來源相容寫回。沒有實際 Minecraft state／世界／FML／封包 |
| 固定產物／範圍 | [差異](source.diff)、[產品／Gradle 指紋](source-fingerprints.json)、[204 靜態核對](audit-results-02.json)、[JAR](artifacts/simplerail-1.0.0.jar)、[版本／SHA-256](artifact.json) | 149 既有資源逐一 JAR 比對、22 指定來源快照核對；舊 T-027／T-029／T-031／T-033 固定 JAR 保留、index 未改，無 stage／reset／commit。初次 203 核對另存，後增舊 T-033 JAR 核對並改善一項命名，不修改產品或重跑 build |

T-035 可建置、每類屬性操作／邊界／規格與 tag 對照、差異／build log 交付已齊備，僅標 **原碼相容開發完成**。U-09 意圖未定，不稱複合覆寫已修正或驗收完成。level／facing 的真實方塊整合仍需其擁有者實作，未將 fixture 當成上線方塊；R-03／T-036／T-099 未完成。文件／126 編號／九階段／依賴／覆蓋／Markdown 自查見 [doc-check.json](doc-check.json)。

固定 JAR SHA-256：`7328D1A4078043DD7D17C1731C1D661B81538395A53BA1A1FFA54F90336E89C8`。HEAD `8bd977dbb9f9000411ae5f4d10750228e5f33560`，含未提交差異，須合併 source.diff／指紋追溯。版本固定 MC 1.21.1、NeoForge 21.1.251、Simple Rail 1.0.0、Java toolchain 21、Gradle 9.2.1、ModDevGradle 2.0.147、Parchment 2024.11.17、All Rights Reserved。

## 未決與交接

U-09 已向使用者提出「累積修改後一次寫回／保留原碼覆寫」選擇，**尚未收到回覆**。目前沿原碼，不將沉默當授權：rail 同时有 reverse／level／水平 direction 時，最後 direction 寫回覆蓋前兩項；machine 同时有 facing／level 時，level 寫回覆蓋 facing。靜態 fixture 重現不等於 OLD 遊戲已測，使用者意圖與受影響人工預期仍待確認。U-09 後續修正／回歸按 D6 與使用者決策，U-07 亦仍待確認。

目前真實 holding_rail 的 direction、oneway_rail／eject_rail 的 reverse 可承接；timer_holding_rail、Y 路口、train_dispenser、signal_timer 仍為缺對應屬性的骨架。level／facing 分支已以 fixture 驗證，但其 owner 實作分別留 T-038／T-041／T-044／T-068／T-070，不在本項提前遷移；機器 GUI／扳手優先序留 T-044 與後續整合。

T-036／C-012 人工未執行、T-099 完整包未準備。其既有 T-024 前置、未實作 owner、U-09 受影響預期與 R-03 閘門保持，不宣稱已 ready；使用者確認即可人工結案，附件選用。下一個可獨立開發／調查 T-037 尚未開始。D1–D8／T-026 結案、原整合缺口與其他未驗證標記保留。
