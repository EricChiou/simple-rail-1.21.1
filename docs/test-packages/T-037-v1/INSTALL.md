# 安裝與啟動：由使用者操作

使用獨立 Java 21／Minecraft 1.21.1／NeoForge 21.1.251 實例，模組目錄只放本包 `mods/simplerail-1.0.0-T037-probe.jar`。不要同時保留另一份 simplerail JAR；模組畫面名稱應有 `[T037 diagnostic]`。使用 NEW 新建世界，不匯入 OLD 世界／NBT。包不含遊戲、installer 或 EULA 同意檔。

## Client／單人

可使用已有的固定版 NeoForge Launcher profile，將 Game Directory 設為新的獨立目錄。若尚未安裝，使用 NeoForge 21.1.251 官方 installer 的 Install client，再選 Minecraft Launcher 對應 profile。關閉遊戲後，把本包 JAR 複製至該獨立目錄的 `mods`，由 Launcher 啟動。建立創造模式、允許指令、超平坦新世界 `t037-sp-v1`；先做 SP 案例。

## Dedicated server／連線 client

使用另一個獨立目錄；需要新安裝時，把指定 NeoForge installer 放在其父目錄，在 server 目錄由使用者執行：

```powershell
java -version
java -jar ..\neoforge-21.1.251-installer.jar --installServer
```

把同一診斷 JAR 放入 server/mods，client/mods 也用同一檔。執行 `./run.bat --nogui`；若因 EULA 停止，只在你自己同意 Minecraft EULA 後設定該目錄 eula.txt。先前 T-007 的單一測試目錄同意不套用本包。

停服時設定 server.properties：`level-name=t037-ds-v1`、`gamemode=creative`、`level-type=minecraft:flat`、`server-ip=127.0.0.1`、`server-port=25567`、`online-mode=true`、`view-distance=4`、`simulation-distance=4`。用新世界名稱，保留其他原生值。重新執行 `./run.bat --nogui`，在 console 輸入 `op 你的帳號`，client 加入 `127.0.0.1:25567`。此為本機專用測試；其他玩家不要停留在測試區塊。

正常停服用 console `stop`，不要強制終止程序。`save-all flush` 與 `stop` 是 dedicated server 命令；單人改用「儲存並退出」及重新進入，不在單人照抄這兩個指令。聊天指令加 `/`，server console 不加 `/`。

## 觀察與選用資料

遊戲中的 `/t037 status 10000 64 10000` 顯示 remaining_ms／paused／markDirty／chunkUnsaved／arm。卸載時不要遠端查狀態或用命令載入該座標。若出現「未載入」應維持卸載，不另加 /forceload。

以各 game directory 的 `logs/latest.log` 搜尋 `[T037]` 可看 START／SERIALIZE／CHUNK_DATA_SAVE／CHUNK_UNLOAD／BE_UNLOADED／LOAD／FIRST_TICK／EXPIRED。SERIALIZE 也可能由 `/data` 等讀取觸發；CHUNK_DATA_SAVE 是已序列化、不是 IO 完成證明。正常重載看到資料才是本包存讀觀察。可用 F2 留圖、錄影或碼表量測；`crash-reports` 可供失敗排查，均不要求提交。

人工結果只須確認任務完成或回報失敗。首次啟動／命令失敗屬診斷包缺陷，回報即可，不自行當作 OLD bug 或 T-038 失敗。
