# T-026 修正 R2：上坡接口的單 tick 移動保護

日期：2026-09-28。[使用者後續回報](../REPORT-002.md)確認 **I-026-01 高速斜坡子項人工通過；I-026-02 仍約 10% 偶發反轉，包含高速接自身**。不要求附件，不指定使用者未提供的受測 JAR／方向矩陣。T-026 整項仍人工不通過、未結案；R-03／R-F 待審。R2 的遊戲修復效果待重測。

## 來源判斷與範圍

固定版 AbstractMinecart.moveAlongTrack 只按本 tick 起點軌道的 shape 抬高車身，再呼叫 moveMinecartOnRail 水平移動；速度 hook 在這次移動前查詢。平軌高速跨入下一格有效升坡時，車身可能在下一 tick 抬升之前碰到坡頂支撐。Entity.move 清掉碰撞軸速度，下一 tick 上坡的 getSlopeAdjustment（預設 0.0078125）可使零速度轉為下坡方向。因此已有正確斜坡仍能倒退，不需要混用不同 rail class；R1 缺坡型推論不足以解釋全部回報。

數值反例：東向平軌 x∈[0,1)、升坡 x∈[1,2)、完整坡頂支撐 x∈[2,3)，礦車中心起於 0.8、水平速度 0.8，寬 0.98f。原水平移動將中心送到 1.6，車身前端約 2.09，會撞支撐並清零；下一坡度作用可產生负速度。R2 的該步上限約 0.709999，使中心落在 1.509999 以內，保留前進動量且已進入升坡格，下一 tick 正常抬升。

這是 **原始碼＋獨立數值模型重現的碰撞路徑**，不是啟動 Minecraft 重現使用者場景。沒有量測實際反轉機率；模型在設定 0.4 的標準寬度情況沒有此類碰撞，不能據此宣稱所有速度／所有回報均由同一根因造成。純平坦直線是否反轉、低設定下的具體路徑仍待確認。若 R2 後仍反轉，繼續調查具體場景，不加無條件方向鎖。

來源指紋见 [primary-sources.json](primary-sources.json)：[AbstractMinecart](../../T-025/sources/target/net/minecraft/world/entity/vehicle/AbstractMinecart.java)、[Entity](../../T-010/sources/target/net/minecraft/world/entity/Entity.java)、[IBaseRailBlockExtension](../../T-010/sources/target/net/neoforged/neoforge/common/extensions/IBaseRailBlockExtension.java)、本次從指定 sources.jar 擷取的 [EntityType](EntityType.java)。坡度常數另由 [IAbstractMinecartExtension](../../T-010/sources/target/net/neoforged/neoforge/common/extensions/IAbstractMinecartExtension.java)第 120–121 行確認，指紋見 [追加來源](slope-source.json)。EntityType 確認普通礦車寬 0.98f；API 成功編譯只涵蓋本次使用的方法，不宣稱整個 1.21.1 API 均已驗證。

## 產品差異與行為界限

- HighSpeedRail 覆寫 getRailMaxSpeed：仍先讀共用即時設定；只在移動方向的下一格是同方向升坡且車身尚未抬到其支撐上方時，計算「支撐近端距離−車身半寬−1e-6」作本 tick 最大移動距離。
- 使用下一軌道的 getRailDirection，適用一般／動力／高速軌；連續升坡按目前坡型找高一格下一軌。反向與南北向對稱處理；已抬高、平直、下坡及無鄰接升坡的路徑回傳原上限。與下一坡不對齊的路線不猜測連接。
- 純幾何 helper RailAscentMovementLimit 不依賴 Minecraft。float 上限若向上捨入，使用 Math.nextDown 避免越過安全界線。這是上坡接口的局部移動限制，**不保證每 tick 都可達設定速度**；無全域固定降速，保留原設定範圍。
- 不改寫礦車方向／速度向量／座標，不補推力、不改車種、不加 event／mixin／票證／保存資料。兩個基底、其他特殊軌道、全部資源及 Gradle 都不改；高速成坡例外保留。D1–D8 不變。

## 實際驗證與保存證據

| 命令／檢查 | 結果 | 證據 |
| --- | --- | --- |
| powershell -NoProfile -ExecutionPolicy Bypass -File docs/evidence/T-026/fix-R2/build.ps1 | NEW build 退出 0；Gradle test NO-SOURCE | [實際命令](build-01.json)、[log](build-01.log) |
| Java 21 javac／java，單獨編譯 helper 與 AscentBoundaryTest | 各退出 0；64,008 判定通過；舊模型掃描 5,840 次碰撞條件，與使用者 10% 無關 | [測試原始碼](AscentBoundaryTest.java)、[命令／範圍](numeric-test.json)、[log](numeric-test-01.log) |
| powershell -NoProfile -ExecutionPolicy Bypass -File docs/evidence/T-026/fix-R2/audit.ps1 | 最終退出 0；166 靜態／產物核對，含 149 資源逐檔相同及 API bytecode | [最終結果](audit-results-02.json)、[log](audit-02.log)、[高速 bytecode](HighSpeedRail-bytecode.txt) |
| 初次 audit | 退出 1；165 通過，index 檔一份 UTF-8、一份 UTF-16 造成雜湊不同。文字相同；統一快照編碼後通過，未修改／重設 index | [原始腳本](audit-attempt-01.ps1)、[原始結果](audit-results.json)、[log](audit-01.log) |

數值掃描覆蓋設定 0.4／0.8／2.0、1000 個入格相位、載人步長係數與四方向的純量對稱；不是四方向 Minecraft 操作測試。可確定保護模型不碰支撐、不改移動正負、可進入下一坡且安全步長不變；不涵蓋實際世界碰撞形狀、多人同步或所有礦車類型。Gradle 沒有執行單元測試；獨立數值測試另列，不混用。

[固定 JAR](artifacts/simplerail-1.0.0.jar) SHA-256：**C3507DB669B28D719B7DDC8FC0EA35F0F733D8931153DD31FD38741068131C6C**。Minecraft 1.21.1、NeoForge 21.1.251、Simple Rail 1.0.0、Java Temurin 21.0.12.1+1、Gradle 9.2.1、ModDevGradle 2.0.147、Parchment 2024.11.17、All Rights Reserved。HEAD 8bd977dbb9f9000411ae5f4d10750228e5f33560，仍為未提交工作樹；[完整來源差異](source.diff)、[產品指紋](source-fingerprints.json)、[產物 metadata](artifact.json)可追溯。原 R1 及更早固定包／證據不覆寫。

## 交接與剩餘事項

提供 [T-026-R2-v1 局部重測包](../../../test-packages/T-026-R2-v1.zip)，只承接反轉修正及斜坡回歸，不是完整 T-094。R-03／R-F 待審，人工欄留白；開發不自簽、不代跑。使用者回報即可，不要求 log／截圖／逐例證明；包仍提供選用資料取得方式。

[封裝核對](package.json)退出 0，18 檔／七組案例，ZIP 逐檔相同；[文件／依賴／保留範圍核對](final-check.json)只屬非遊戲自查。ZIP SHA-256：3C169310EA0E8374785583D84BD4E9A1A165CD7C59E5DCF89C3E393FE0A58A9B。

文件核對最終退出 0、21 項通過，126 編號／九階段／依賴無缺號或循環、其他任務與歷史未改、Markdown 連結／表格／fence 有效。[初次結果](final-check-attempt-01.json)及 [log](final-check-01.log)保留：PowerShell 5 未辨識無 BOM 腳本的中文，兩項自查失敗；只將核對腳本改 UTF-8 BOM，依賴也重新按正確中文解析，[最終 log](final-check-02.log)通過。沒有因核對錯誤修改需求或放寬判定。

需確認原路線重跑、多次高速接自身、一般／動力軌接口、連續升坡與四方向；回歸正常低動能回滾、未供電制動及平直速度上限。I-026-01 的使用者通過紀錄保留，但不能作 R2 所有回歸已通過。I-021-01／I-092-02 其他整合缺口、T-092 受阻與 T-094／R-02 未完成不解除。本輪不開始 T-027 或其他功能、不重跑 OLD、不啟動 Minecraft／GameTest。
