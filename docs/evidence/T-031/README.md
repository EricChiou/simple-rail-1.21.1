# T-031 eject_rail 乘客下車交付

2026-09-29。**開發完成；R-03 待審；T-032 人工／T-097 包未執行**。只执行 T-031，沒有啟動 Minecraft、GameTest、client、dedicated server 或 OLD build。OLD build 由使用者先前驗證，本次流程不重跑；本文舊行為均為「依原始碼推定／待確認」。

## 交付與自身完成條件

| 條件 | 實際交付／證據 | 判定範圍 |
| --- | --- | --- |
| 紅石條件、反向與距離 | [EjectRail](../../../src/main/java/com/ericchiu/simplerail/block/EjectRail.java)、[來源／設定／狀態／回呼契約](RAIL_CONTRACT.md)、[48 列行為表](behavior-matrix.json) | server hook 依當前設定與 POWERED 決定下車，NS／EW 與 reverse 決定側邊位置；距離 1／3／100。不是遊戲觀察 |
| 註冊與資源 | 同 ID eject_rail 換 factory；附加 vanilla pickaxe tag；原模型、配方、loot、11 方塊／13 物品 ID 不變 | 本輪只新增 EjectRail，修改 ModBlocks 與 pickaxe tag；Gradle／其他功能不變 |
| 指定 API 可編譯 | [實際命令／時間／退出碼](build-01.json)、[build log](build-01.log)、[編譯 bytecode](EjectRail-bytecode.txt)、[固定來源 manifest](source-manifest.json) | NEW Minecraft 1.21.1／NeoForge 21.1.251 真實 API build 退出 0；Gradle test **NO-SOURCE**，不能称為自動遊戲測試通過 |
| 回呼與邊界非遊戲檢查 | [實際產品 hook 測試程式](EjectRailHooksTest.java)、[命令／退出碼／範圍](hooks-test.json)、[結果](hooks-test-01.log) | 20 個明示本地替身，javac／java 各退出 0；48 行為列、2,304 次回呼、23,821 判定。沒有載入真實 Minecraft／ConfigSpec；ServerPlayer 替身只核對 API 分派，沒有傳真實封包 |
| 差異與固定產物 | [完整未提交差異](source.diff)、[來源指紋](source-fingerprints.json)、[191 靜態核對](audit-results-01.json)、[固定 JAR](artifacts/simplerail-1.0.0.jar)、[版本／SHA-256](artifact.json) | 149 資源逐一對應 JAR 位元組；舊 T-027／T-029 固定 JAR 未改；index 前後未變，無 stage／reset／commit |

T-031 自身「程式可建置、狀態／設定／回呼對上來源規格、差異與 log／行為表齊備」已達成，更新為開發完成。這不等於 R-03 程式審查通過、人工功能驗收或整體交付完成。文件／126 編號／依賴／九階段／覆蓋／Markdown 自查另見 [doc-check.json](doc-check.json)。

固定 JAR SHA-256：`D0ECA101CA8A9B72173E9B340206B1DDB7FCB3FE1B7834DDD2F5BA56E3E19B7E`。HEAD `8bd977dbb9f9000411ae5f4d10750228e5f33560`；目前產品含未提交差異，**HEAD 不能單獨代表此 JAR**，須合併 source.diff 與指紋追溯。版本固定為 MC 1.21.1、NeoForge 21.1.251、Simple Rail 1.0.0、Java toolchain 21、Gradle 9.2.1、ModDevGradle 2.0.147、Parchment 2024.11.17、All Rights Reserved。

## 後續驗收邊界

T-097 尚未執行，本項固定 JAR 是開發證據，不將其稱為已審核的人工測試包。T-032／C-010 要由使用者親自確認兩軌向、四方向、reverse／needPower／電力、距離 1／3／100、空車、乘客、共用速度／原版接口及兩端；落點碰撞、玩家位置封包確認、存讀及設定重載相異投影也待實際驗收。使用者確認即可結案，不強制附件，不代填結果。

沒有新增尋找安全落點、避障、Y 墊高、換維度、區塊票證、外部模組整合或舊 NBT 轉換。D1–D8、T-026 結案、U-07 意圖待確認與 I-021-01／I-092-02／T-092 缺口維持；本項只解決 eject_rail 自身的 factory／屬性承接，不解除全量整合閘門。下一個可獨立功能開發 T-033 尚未開始。
