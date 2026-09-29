# T-029 oneway_rail 原碼分支實作交付

日期：2026-09-29。**T-029 開發完成（原碼相容）；U-07 意圖仍待確認；R-03 待審；T-030 人工／T-096 包未執行。** 前置 T-025／T-010／T-020 開發輸入已齊，本輪只執行 T-029，不宣稱功能已完成全部交付或舊疑點已全部修復。

## 產品與完成判定

新增 [OnewayRail](../../../src/main/java/com/ericchiu/simplerail/block/OnewayRail.java)，ModBlocks 同 oneway_rail ID 改為具體類別，pickaxe tag 僅附加本 ID。reverse／need_power／use_power 保留名稱與值域；無設定的固定 constructor default，不在註冊期間讀 ConfigValue。server 放置讀一份已載入快照並交父類寫入，same block 更新及 reload 不改寫既有 state；過車讀當前快照，依 OLD 條件與方向表寫向量。

[來源／設定／狀態／回呼／U-07／未驗證範圍](RAIL_CONTRACT.md)逐項對照，並交付 [32 組分支矩陣](behavior-matrix.json)。usePowerChangeDirection 的名稱／註解與程式／模型不一致，已提出釐清但尚無決策，先沿用原碼，不猜測紅石 XOR 或自行修資源；該意圖及相應人工期望仍待確認。

自身完成條件：真實指定 API build 可建置、全部自訂状态／共用設定／放置與過車介面均有固定來源與對照、差異和測試／build／JAR 證據保存。這只判定原碼相容開發完成，**不消除 U-07、不簽 R-03、不代填 T-030**。HighSpeedRail／HoldingRail／共用基底／Gradle／其餘資源不改，D1–D8 不變；沒有 OLD build 或資料轉換。

## 實際命令與證據

| 實際命令 | 結果 | 保存證據 |
| --- | --- | --- |
| powershell -NoProfile -ExecutionPolicy Bypass -File docs/evidence/T-029/build.ps1 | NEW build 退出 0；Gradle test NO-SOURCE | [命令／退出碼](build-01.json)、[log](build-01.log) |
| powershell -NoProfile -ExecutionPolicy Bypass -File docs/evidence/T-029/hooks-test.ps1 | Java 21 隔離 javac／java 各退出 0，3,097 判定通過、32 分支列；不載入真實 Minecraft | [命令／範圍](hooks-test.json)、[測試原碼](OnewayRailHooksTest.java)、[log](hooks-test-01.log)、[18 替身指紋](test-double-fingerprints.json) |
| powershell -NoProfile -ExecutionPolicy Bypass -File docs/evidence/T-029/audit.ps1 | 退出 0，178 靜態／範圍／JAR 核對通過（含 149 個資源逐檔相同） | [結果](audit-results-01.json)、[log](audit-01.log)、[API bytecode](OnewayRail-bytecode.txt)、[192 組狀態表](state-coverage.json) |
| git diff --check；git diff HEAD --binary；新增 HoldingRail／OnewayRail 的 no-index diff | 前兩者 0，未追蹤檔 no-index 1 為有差異的預期；當前完整產品來源可追溯，未 stage／reset／commit | [來源差異](source.diff)、[全部來源指紋](source-fingerprints.json)、[範圍核對](audit-results-01.json) |
| powershell -NoProfile -ExecutionPolicy Bypass -File docs/evidence/T-029/doc-check.ps1 | 退出 0，18 項文件／任務／依賴／階段／覆蓋／歷史／Markdown／產品與 index 保留核對通過 | [結果](doc-check.json)、[log](doc-check-01.log) |

固定版本：Minecraft 1.21.1、NeoForge 21.1.251、Simple Rail 1.0.0、All Rights Reserved；Java toolchain 21、隔離測試 Temurin 21.0.12.1+1、Gradle 9.2.1、ModDevGradle 2.0.147、Parchment 2024.11.17。HEAD 8bd977dbb9f9000411ae5f4d10750228e5f33560 加未提交來源，不虚構 commit；Gradle 有未來 10 相容性提示。

[固定 JAR](artifacts/simplerail-1.0.0.jar) SHA-256：**7EE7F6853662572F1D1D073F72EE49E4F44413B2D6CEBB839D5BDFAF36941A7C**，見 [metadata](artifact.json)。原固定 JAR／包不覆寫，本 JAR 不是已人工驗收候選；沒有執行 Minecraft／GameTest／runData 或 OLD。

## 審查及尚待工作

R-03 審 server guard／單份快照、constructor 邊界、父類 alwaysPlace 落盤、全域設定與 stored flags 分離、來源方向／未啟用倍率與父類剩餘分支、U-07 模型差異及 C-009 覆蓋。開發不自簽；全部遊戲由使用者操作確認，附件選用。

T-096 操作包、T-030 實際遊戲、U-07 意圖決策及相關期望仍待執行／確認。I-021-01 其他狀態／模型、I-092-02 全設定觀測、T-092 受阻仍保留。下一個可獨立功能開發 T-031，本輪未開始其他任務。
