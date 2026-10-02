# T-041 `signal_timer` 開發交付

> 後續使用者確認（2026-09-30）：[T-101 親自完成、T-042 人工測試通過並結案](../T-040-T-042-T-101-user-confirmation/README.md)。本頁其餘「未執行」為 T-041 開發當時快照；沒有收到 T-101 製包指紋或 T-042 逐例相位數值，R-04 仍待獨立審查。

2026-09-30。**開發完成；R-04 獨立程式審查待審；T-101 開發製包與 T-042 使用者遊戲驗收未執行。** 前置 T-011、T-019、T-020 的開發交付已存在。本項未執行 OLD build、Minecraft、GameTest 或使用者人工案例；OLD 脈衝是**依原始碼推定／待確認**。

## 範圍與指定版 API

- 產品差異：新增 `src/main/java/com/ericchiu/simplerail/block/SignalTimerBlock.java`、`blockentity/SignalTimerBlockEntity.java`、`blockentity/SignalTimerTiming.java`；只在 `registry/ModBlocks.java` 將既有 `simplerail:signal_timer` placeholder 接正式方塊，在 `registry/ModBlockEntities.java` 加入同名 BLOCK_ENTITY_TYPE。既有 `registry/ModItems.java` 同名 BlockItem 與資源 ID 不變。此工作目錄另有先前 T-038 及證據／文件差異；`git diff HEAD` 不能全歸給 T-041。
- 指定版 Minecraft **1.21.1**／NeoForge **21.1.251** 本地來源 `build/moddev/artifacts/neoforge-21.1.251-sources.jar`，SHA-256 `236151EDEC930A89E78054FCB5551323761F801778305F290D0B74238C33693E`。T-011 已保存 `EntityBlock.java`、`BlockBehaviour.java`、`LevelAccessor.java`、`LevelTicks.java`、`LevelChunkTicks.java`、`ChunkSerializer.java` 等 [指定版來源](../T-011/sources/target/)；本項另保存 [PoweredBlock](PoweredBlock-1.21.1.java)（SHA-256 `EE2B83709F2AD5E7C0DD6764809A3201B6369189419369A631C9333D2DF70778`）與 [SavedTick](SavedTick-1.21.1.java)（SHA-256 `77E6541A6AD9769C38AD7CF6592038735D598B9202BE9F50836325EE7550F695`）。
- `BlockBehaviour.java:254,387,420,435` 分別有信號源、排程 tick、弱訊號、強訊號回呼；`PoweredBlock` 只提供信號源及弱訊號 15，新方塊以 `Block` 覆寫同等來源語意和依 LEVEL／POWERED 輸出。`EntityBlock.java:15–19` 提供 BE 與 ticker；`LevelAccessor.java:48–49` 排程含 `TickPriority.VERY_HIGH`；`LevelTicks.java:203–205` 供查詢待執行 tick；`LevelChunkTicks.java:58–75` 對相同位置／方塊去重。`ChunkSerializer.java:169–171,413–416` 寫讀 `block_ticks`，`SavedTick.java:64–77` 以相對 delay 保存並在 unpack 時以當前 gameTime 還原。這些是來源與編譯依據，**不是重新載入實測**。
- OLD [方塊](../T-011/sources/old/block/SignalTimerBlock.java) 的 `getSignal` 只在 LEVEL>0 且 POWERED 輸出 15，方塊 tick 切換狀態，升緣後排 10 tick；OLD [方塊實體](../T-011/sources/old/tileentity/SignalTimerTileEntity.java) 每 tick 對 LEVEL>0 要求排程 `設定秒數×20−10`。OLD 行為未由遊戲重現，尤其同 tick 去重、切換級數及重啟相位不能由上述程式直接當成實測。

## 正式排程與狀態規格

| 條件／事件 | T-041 伺服端行為 | 可觀察輸出 |
| --- | --- | --- |
| 初始／LEVEL=0 | 預設 LEVEL=0、POWERED=false；若舊待執行 tick 或手動狀態使 POWERED=true，ticker／方塊 tick 清回 false，不再排新 tick | 無論 POWERED 暫存值為何，LEVEL=0 的 `getSignal` 恆為 0 |
| LEVEL=1–9，無待執行 tick | 方塊實體 ticker 用當下 `CommonConfig.current().signalIntervalSeconds(level)`，低電位排 `max(1, 秒數×20−10)`；高電位補排 10 tick，優先序 VERY_HIGH | ticker 不直接改訊號 |
| 低電位 tick | 方塊改 POWERED=true，`Block.UPDATE_ALL` 通知鄰居；排 10 tick | 弱訊號 15，強訊號依 OLD 父類預設仍為 0 |
| 高電位 tick | 方塊改 POWERED=false，通知鄰居；用當下正式設定排下一個低電位間隔 | 弱訊號 0；兩個升緣之間在一般設定下為設定秒數×20 ticks |
| Client／BE 型別錯誤 | `getTicker` 回傳 null；`serverTick` 亦檢查 `ServerLevel`，不在 client 排程或讀 COMMON 作遊戲決策 | 方塊狀態由伺服端同步；未另增封包 |

LEVEL 1–9 的預設秒數為 5、10、15、20、25、30、40、50、60；對應低電位排程為 90、190、290、390、490、590、790、990、1190 ticks，高電位均 10 ticks。現有設定容許 0 秒：OLD 會給負 delay，實際遊戲結果未測；NEW 將低電位至少排 **1 tick**，避免非正延遲，故 0 秒為 1 tick 低＋10 tick 高，這是明示的邊界決策，T-042 應驗證或提出修正。秒數乘法用 `long` 避免 `int` 溢位，若低間隔超過 `Integer.MAX_VALUE` ticks 則飽和到該值；這不是對極大設定保持精確週期的宣告，極大設定的產品期望**待技術定義**。一般預設及可表示的設定維持 10 tick 脈衝與 `秒數×20−10` 低電位公式。

BE 不寫自訂 NBT，LEVEL／POWERED 由 BlockState 保存，後續邊緣由 block tick 排程；ticker 只在缺少待執行 tick 時補排。依指定版來源，已保存的 `block_ticks` 可能帶剩餘 delay 讀回，ticker 不主動覆寫它；若沒有 tick，從讀回的 POWERED 狀態重建 10 tick 或低電位間隔。設定 reload 在**下一次重新排程**時生效，現有已排 tick 不立即改期。級數修改時現有 tick 亦不立即清除。關服、真卸載、世界時間與讀回先後可能影響相位，**是否精確延續或重設、是否少／多一個脈衝均待 T-042 使用者實測**，不可把來源推論記為相位驗證。此 tick 計時與 D5 計時停車軌的實際秒數／離線暫停完全分開。

## 已執行驗證與證據界線

| 命令／結果 | 保存證據 | 範圍 |
| --- | --- | --- |
| `./gradlew.bat build --offline --console=plain --no-daemon`；沙箱內退出 **1** | [當次終端錯誤節錄](new-build-sandbox-failure.txt)：Wrapper 無法在 `C:\.gradle\wrapper\dists\gradle-9.2.1-bin\...` 建立 `.zip.lck` | 編譯前環境限制，不是產品失敗；沒有把它記成通過 |
| 同命令，允許使用既有快取後退出 **0**；為保存 log 再跑同命令退出 **0** | [完整 up-to-date build log](new-build.log) | 第一次成功有 `:compileJava` 執行，但只保留終端輸出；保存的第二次 log 為 up-to-date |
| `./gradlew.bat build --offline --console=plain --no-daemon --rerun-tasks`，退出 **0** | [完整強制重編 log](new-build-rerun.log)；`:compileJava`、`:jar`、`BUILD SUCCESSFUL`，5 tasks executed | Java 21.0.12.1／Gradle 9.2.1；普通 `:test NO-SOURCE`，不可寫成 Gradle 單元測試通過 |
| `powershell -NoProfile -ExecutionPolicy Bypass -File docs/evidence/T-041/run-timing-test.ps1`，退出 **0** | [命令及退出碼](timing-results.json)、[編譯 log](timing-compile.log)、[測試 log](timing-test.log) | 直接編譯生產 `SignalTimerTiming.java`，以僅含常數的明示替身測 250,009 項邊界／單調性；**不載入 Minecraft**，不證明世界排程與紅石外觀 |

固定 NEW JAR `build/libs/simplerail-1.0.0.jar` SHA-256 `46D87F63981BC6C6F715B3DBD5622193E4D08BC5AE80D558FC3F5F663C2AABC6`，受測工作目錄 HEAD `11916b69c3549504928f7cfa6790d59a2717b4b6` **加上未提交的既有 T-038 產品差異及本項差異**；不能單用 commit 指認 JAR。本項未製作 T-101 使用者測試包，未取得 T-042 紅石／存讀／重啟人工結果，R-04 也尚未獨立簽署。對應 MIGRATION.md §3 `signal_timer`／`SignalTimerTileEntity`、§4.2、§6 階段 4；D1–D8 不變。
