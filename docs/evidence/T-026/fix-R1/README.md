# T-026 修正 R1：僅高速軌道支援斜坡

日期：2026-09-28。**斜坡例外已實作並完成 NEW build／非遊戲核對；R-03／R-F 待審，人工未重測。T-026 仍人工不通過，未結案。** 坡底反轉的實際根因及本版是否消除該回報，仍待使用者確認。

## 使用者已定決策與場景

> 1. 確認修改為僅高速軌道支援斜坡，其他軌道保持原規格
> 2. 發生在由坡底往上坡、有供電、任何速度都有可能、方向是反轉

第一項為對指南「共用基底禁坡」的明確高速例外，D1–D8 不變；其他軌道仍禁坡。第二項為使用者實際觀察，不是 Agent 重現。坡底兩相鄰方塊的 Y 是否相同、第一格斜坡的原版種類、受測 JAR 及實際速度未提供；不要求證據、不補造資料。[最初回報](../REPORT-001.md)及當時待確認文字保留為歷史。

## 實作與來源核對

- 只在 [HighSpeedRail](../../../../src/main/java/com/ericchiu/simplerail/block/HighSpeedRail.java) 覆寫 canMakeSlopes=true；BaseRail／BasePoweredRail 仍 false。速度設定、動力 true、實體破壞 false、state domain／default／waterlogging／ID 均不改。
- 高速 blockstate 增加四升坡×供電兩值；四個 raised model 使用固定版原版 template_rail_raised_ne／sw，沿用原貼圖與 cutout。[九個原版模型來源指紋](model-sources.json)保存旋轉與幾何依據；未使用 AI 圖像或改 PNG。
- [24 個宣告組合](state-coverage.json)全部有 selector：六 shape×powered 兩值×waterlogged 兩值。這是靜態覆蓋，不是 Minecraft baking／畫面測試。I-021-01 的高速模型子項已補齊，其他方塊仍有缺口，T-092／T-023 不整體解鎖。

## 坡底反轉的來源分析與限制

固定 1.21.1／21.1.251 的 RailState.place／connectTo 只有在 canMakeSlopes=true 時，才把低處軌道轉成通往高一格相鄰軌道的升坡。舊高速為 false，會保留平軌；本次恢復高速在這種幾何上的原版成坡能力。

AbstractMinecart.moveAlongTrack 先依 shape 移動；Entity.move 的水平碰撞會把受阻軸速度清零，隨後動力軌低速啟動分支可能根據旁邊導電實心方塊，把車推向另一側。**若坡底先前缺少有效升坡、撞到高處支撐方塊，這條來源路徑可解釋「有供電且反轉」；尚未證明使用者路線確實走了此路徑。** 同 Y 的高速平軌→原版升坡、低處高速→高一格軌道必須分開測，不能把本次成坡修正當所有反轉都已修復。

沒有加入強制改方向、改礦車 class、全域事件／mixin、補推力、限速或傳送補丁。這些會掩蓋正常煞車／上坡低動能回滾，缺少根因證據時不應猜測。若有效坡型的同 Y 接口仍反轉，I-026-02 保持未解決，依新回報继续調查；不宣稱 bug 已修好。

上述來源見 [T-025 RailState](../../T-025/sources/target/net/minecraft/world/level/block/RailState.java)、[AbstractMinecart](../../T-025/sources/target/net/minecraft/world/entity/vehicle/AbstractMinecart.java)及本次[既有固定 Entity 來源副本](sources/Entity.java)。來源分析與 non-game 驗證不代替遊戲結果。

## 實際命令與產物

| 命令／核對 | 實際結果 | 證據 |
| --- | --- | --- |
| powershell -NoProfile -ExecutionPolicy Bypass -File docs/evidence/T-026/fix-R1/build.ps1；內部 .\gradlew.bat build --offline --console=plain --no-configuration-cache | NEW build 退出 0，test NO-SOURCE；沒有執行單元／遊戲測試 | [命令／時間／退出碼](build-01.json)、[完整 log](build-01.log) |
| powershell -NoProfile -ExecutionPolicy Bypass -File docs/evidence/T-026/fix-R1/audit.ps1 | 首次退出 1：30 個產品／資源契約通過，但 index 全快照不同 | [log](audit-01.log)、[原始結果](audit-results-01.json) |
| powershell -NoProfile -ExecutionPolicy Bypass -File docs/evidence/T-026/fix-R1/audit-followup.ps1 | 退出 0；核對 index 差異僅 MIGRATION／TASK／REVIEW，產品 staged 內容不變；31 個範圍契約通過 | [log](audit-02.log)、[結果／實際 index 漂移](audit-results-02.json) |
| javap -c -p -s -v -classpath build/classes/java/main 三個 rail 類 | 各 0；高速 hook true、兩基底 false；不載入 Minecraft | [高速](HighSpeedRail-bytecode.txt)、[動力基底](BasePoweredRail-bytecode.txt)、[一般基底](BaseRail-bytecode.txt)、[內部命令](audit-commands.json) |
| git -c core.safecrlf=false diff --check | 0；未發出 stage／reset／commit，保留當下 index | [log](diff-check.log) |
| powershell -NoProfile -ExecutionPolicy Bypass -File docs/evidence/T-026/fix-R1/package.ps1 | 首次 1：Windows ZIP 子目錄分隔使 11 項查找不匹配；改工具產生 portable 路徑後退出 0，18 檔／六組案例逐檔一致 | [初次 log](package-01.log)、[失敗 ZIP](package-attempt-01.zip)、[初次結果](package-attempt-01.json)、[最終 log](package-02.log)、[結果／ZIP 雜湊](package.json) |
| powershell -NoProfile -ExecutionPolicy Bypass -File docs/evidence/T-026/fix-R1/final-check.ps1 | 0，21 項文件／依賴／範圍／包核對通過，非程式審查或人工結果；文件更新後重查，最後只校正核對欄位名稱 | [初次 log](final-check-01.log)、[最終 log](final-check-03.log)、[結果](final-check.json) |

檢查期間觀察到三份規劃文件的 index 更新，不能宣稱整體 index 未變，也沒有重設回原快照。原始快照與失敗均保留；Agent 未執行 staging 命令。[產品指紋](source-fingerprints.json)顯示只改高速 Java／blockstate、加四個 model；JAR 149 個來源資源逐檔核對相同。

版本維持 Minecraft 1.21.1、NeoForge 21.1.251、mod 1.0.0、All Rights Reserved、Temurin 21.0.12.1+1／Gradle 9.2.1／ModDevGradle 2.0.147／Parchment 2024.11.17。HEAD 維持 8bd977dbb9f9000411ae5f4d10750228e5f33560，加[未提交完整來源差異](source.diff)，沒有新 commit。[固定 JAR](artifacts/simplerail-1.0.0.jar) SHA-256：**8455CC5DE6FE2C7E5953E6A8F0D4A4E419A40489B954C8B0B1216304C5CEA599**，另見[產物 metadata](artifact.json)。

## 程式複查與使用者重測

提供 [T-026-R1-v1 局部回歸包](../../../test-packages/T-026-R1-v1.zip)，供 R-03／R-F 審差異與測例，審查待完成。只涵蓋兩項回報的修正／診斷案例，**不是完整 T-094 交付或 T-026 通過**；T-094 仍待執行。案例／結果均預先分開，人工 actual 留白。新 JAR 不覆寫原固定包，也不沿用舊人工確認。

之後由使用者驗高速四方向斜坡與貼圖／供電、原版動力及一般斜坡接口、同 Y／高一格坡底、坡頂／下坡，以及原版對照；配置三點只是試驗參數，不宣稱實測速度。若反轉仍在，回報案例／場景即可，不需附件。OLD build 不重跑，Agent 未啟動 Minecraft／GameTest 或執行其他功能任務；D1–D8／其他基底不變。
