# 車頭無玩家時停止：區塊載入接線修正（2026-10-08）

使用者回報原文：「測試發現LocomotiveCartEntity並沒有持續load chunks，LocomotiveCartEntity需要即使附近沒有玩家也能自己持續load chunks」。修正前問題依使用者回報成立；未提供案例 ID、受測 JAR 雜湊或 log，不補造它們。

## 原因與授權範圍

目前產品 `LocomotiveCartEntity` 只有運動／編組 tick，入口未註冊區塊 controller 或車頭載入事件。T-016 曾完成的只是 API 查證探針，T-076 尚未實作，因此離開玩家範圍後沒有模組票證維持實體 tick。這是未接線的移植缺口，不是已存在票證的過期問題。

依本次使用者明確要求補齊這項功能；T-076 的中心票證實作已交付，T-075 完整疑點調查、T-113 完整包、T-124／T-077 人工仍各自待辦，不因本次局部修正自動結案。T-078／T-079 的政策決策不在本次擴充。OLD build 不重跑，D1–D8 不變。

## 來源／參數與未確認差異

來源為既有 OLD [ChunkEventManager.java](../T-016/sources/old/event/ChunkEventManager.java)、T-016 來源快照及本次從固定 `neoforge-21.1.251-sources.jar` 取出的 [API 快照與 SHA](api-manifest.json)。外部搜尋未用作精確版本證據，以本地指定版來源與成功編譯為準。

| 項目 | 來源與 NEW 實作 | 結論／尚待驗證 |
| --- | --- | --- |
| 啟用設定 | `CommonConfig.current().locomotiveChunkLoadingEnabled()`；歷史鍵 `cart.locomotive.disableLoadingChunk`，true 才啟用，預設 true | 保留原語意；false 不新增，不解除既有票證。設定改 true 後下一次跨 chunk 或實體讀回會申請。 |
| owner／維度 | `simplerail:locomotive` TicketController，mod bus 註冊；forceChunk 的 ServerLevel＋Entity UUID overload | 每車／每世界獨立；精確 API 已編譯，實際保存／跨維度待使用者。 |
| 範圍 | OLD radius=2 的 25 次呼叫都傳中心 `chunkX/chunkZ`，NEW 保留 | 沒有改成 25 個相異中心或 5×5。新版 TicketTracker 對相同 owner／中心去重為指定來源結論；實際 ticking 範圍及效能不在本次冒稱量測。 |
| 持續 tick | `add=true,ticking=true`；[TicketController](api/net/neoforged/neoforge/common/world/chunk/TicketController.java) 選 ENTITY_TICKING，[ForcedChunkManager](api/net/neoforged/neoforge/common/world/chunk/ForcedChunkManager.java) 加入 level 31 區域票證與持久集合 | [ServerLevel](api/net/minecraft/server/level/ServerLevel.java) 的空玩家判斷包含 `hasForcedChunks`；應持續實體更新是指定來源推論，無玩家過車仍待實測。重複呼叫返回 false 表示既有票證，不作失敗。 |
| 跨區塊 | EnteringSection、didChunkChange、server／有效車頭過濾；負座標用 `>>4` | 在移動回呼更新所在中心，忽略只有高度 section 改變。沒有改動車頭速度或編組間距。 |
| 初始／讀回 | EnteringSection 不在新生成時觸發；EntityJoinLevelEvent 只排入當前 ServerLevel 的 transient queue，LevelTickEvent.Post 再申請 | 指定版 Join 文件警告同步 chunk load 可死鎖，因此延後；確認 isAddedToLevel、未移除、仍在相同世界。讀回也覆蓋，未曾載入的遠端舊 NEW 車不主動掃描。這是補齊首次票證初始化，不新增周邊載入或釋放政策。 |
| 生命週期 | 移除 bootstrap queue 後再 drain，容許載入引發新 Join；世界 Unload 只清 transient queue，client 不碰 server queue | 無跨世界 queue 殘留；不在停車、刪車、設定關閉或 unload 解除持久票證。持久票證依 NeoForge 還原；孤兒／歷史中心累積仍留待 T-075／T-078，不稱已解決。 |

OLD 行為仍為「依原始碼推定／待確認」。NeoForge loader 的持久／空玩家判斷已讀取指定版來源，沒有啟動遊戲驗證上述 runtime 結果。

## 修改與自動化證據

產品只增加 `entity/LocomotiveChunkLoader.java`，並在 `SimpleRail.java` 接上 register；入口修改前快照見 `before/`。既有車頭 Java、Gradle、資源不改。

- `GRADLE_USER_HOME=C:\Users\Kinoko\.gradle; .\gradlew.bat --offline build`（PowerShell 以環境變數設定）：[初次 build](build.log)、[client unload guard 後最終 build](build-02.log) 均退出 0；編譯指定版 API、JAR 成功，Gradle `test NO-SOURCE`。
- [run-tests.ps1](run-tests.ps1) 用 Java 21 的 javac/java 編譯實際產品 Loader 與隔離 API 替身；[最終編譯](test-compile-02.log)／[測試](test-02.log) 均退出 0，1125 個斷言。覆蓋事件註冊、Join 無同步 load、延後初始／讀回、center 與負座標、add/ticking/UUID/世界、設定、client／普通車過濾、移除／未加入／換維度、queue 清理、嵌套 Join 不遺失、重複票證 false。替身的去重／保存不是實際 NeoForge 存讀測試，無 Minecraft／GameTest。
- `javap -classpath build/libs/simplerail-1.0.0.jar -c -p com.ericchiu.simplerail.SimpleRail com.ericchiu.simplerail.entity.LocomotiveChunkLoader` 退出 0，[反組譯](javap.log) 有入口 register 與 forceChunk 接線；不把此當作實际 server 啟動。

## 交接

[locomotive-chunks-R1 固定包](../../test-packages/locomotive-chunks-R1/README.md) 提供版本、commit、來源差異／指紋、JAR SHA、操作步驟與 8 個空白結果案例。优先重測 LC-R1-01 遠離玩家跨區塊、02 全員離線但 dedicated server 運作、03 遠端保存重啟。單人暫停或關閉 server 不屬持續運算；本修正也不新增車頭動力。

修正開發完成；R-06／R-F 獨立程式審查與所有本包人工驗收仍待執行。使用者確認即可結案，不要求附證據。既有人工通過任務與歷史結果不倒改。

最終 [製包](package.log)、[JAR class 核對](jar-check.log)、[交接核對](final-check.log) 均退出 0：包內兩個相關 class 與 Gradle 輸出一致、ZIP 與目录一致、202 項來源 SHA 一致、8 個人工結果留白；126 任務／九階段及依賴圖無缺號／循環。JAR SHA-256：`7E87FB1AB7800BD6035BDDC097A2339915536C0ED75686FCBBDB61AFF843A22E`。這是固定產物核對，不是 Minecraft 實測。
