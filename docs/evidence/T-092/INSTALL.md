# Windows 安裝與操作準備（僅由使用者執行）

**先讀包內 README 的交接狀態。T-092-v1-draft 是受阻審查草稿，reference/ 的 JAR 不供 T-023 安裝或驗收；以下步驟供完成承接後的新包使用。T-093-v1 已製作，仍待 R-02 且 T-024 的前置 T-023 尚未通過，現在不開始人工測試。** 開發 Agent 未執行任何安裝或遊戲操作。

版本固定 Minecraft 1.21.1、NeoForge 21.1.251、Simple Rail 1.0.0、Java 21，僅放本模組。不要匯入 OLD 世界；新建單人世界 T023-SP／T024-SP，dedicated server 世界 T023-DS／T024-DS。以包版本另建獨立遊戲目錄，不覆寫原有遊戲或存檔。

## Client

已有指定版獨立安裝可直接使用。否則關閉 Launcher，下載 [21.1.251 官方 installer](https://maven.neoforged.net/releases/net/neoforged/neoforge/21.1.251/neoforge-21.1.251-installer.jar)，以 Java 21 開啟選 Install client；Launcher 的新 profile 選該版本，Game Directory 指向獨立 client 目錄。將正式包 mods/ 的唯一 JAR 複製至該 client/mods，啟動前確認沒有其他 Simple Rail JAR／模組。步驟依 [NeoForge 官方 client 文件](https://docs.neoforged.net/user/docs/client/)（2026-09-28 查閱）；文件查閱不是本包啟動驗證。

單人新建平坦創造世界，開啟指令。合成及正常挖掘案例再切生存；各案例的指令在玩家聊天輸入，DS 需管理者權限。選 Overworld 的空地，石材平台約 x=0..40、z=0..40、y=64；測試方塊放 y=65。每次只放一個被測方塊，不讓相鄰軌道修改狀態；不要把這個隔離場景當成接軌驗收。

## Dedicated server 與 client 連線

正式交接後，使用新 server 目錄；installer 放在其上一層。由使用者在 PowerShell 執行：

```powershell
New-Item -ItemType Directory server
Set-Location server
java -version
java -jar ..\neoforge-21.1.251-installer.jar --installServer
```

將正式包 mods/ 的 JAR 複製至 server/mods，使用 `.\run.bat --nogui` 首次建立設定。EULA 由使用者自己決定／設定，包不含 eula=true，也不沿用 T-007 單一測試目錄的授權。官方流程見 [NeoForge server 文件](https://docs.neoforged.net/user/docs/server/)；文件內其他版號範例不得取代本包固定版。

停服後設 server.properties：`level-name=T023-DS` 或 `T024-DS`，`server-ip=127.0.0.1`、`server-port=25595`、`online-mode=true`、`max-players=2`，該 port 必須未被占用，必要時另選並讓 client 使用同值。保持命令方塊停用即可。再次由使用者執行 `.\run.bat --nogui`，用同版本 client 連入 `127.0.0.1:25595`；server console `op <自己的玩家名>` 提供案例指令權限。不要公開連線位址。停止用 console `save-all flush`、`stop`；client 正常離開，勿直接關閉 Java 程序。

## 可選紀錄與回報

`Get-FileHash .\mods\simplerail-1.0.0.jar -Algorithm SHA256` 可比對 manifest。client／server 各自的 logs/latest.log、選用 debug.log／crash-reports，client F2 圖片在 screenshots；F3+H 可看物品 ID，F3 可看指向方塊的實際狀態，F3+T 重新載入 client 資源，`/reload` 重載 server 資料，兩者不能互相取代。

COMMON 在每個 game directory 的 config/simplerail-common.toml；SP 與 DS 各自看自己的檔，修改前保留副本。不要把 world/serverconfig、client 端值或 `/reload` 成功當作 COMMON 快照已生效的證明；有效值觀測限制見 T-092 CASES。

回覆「T-023／T-024 完成／通過」，或列失敗案例與實際現象即可；results.json、版本證明、log／畫面均選用，不是人工結案條件。Agent 不會預填結果。本包不驗軌道速度、扳手、計時、GUI、車頭／編組或票證功能；它們保留在原後續任務。
