# Windows 安裝與啟動（由使用者操作）

此說明供 T-090-v1／T-091-v1 選用，不要求重跑已結案的人工任務。包只有 mod JAR 與文件；執行 Minecraft 由使用者負責。正式交接的 R-01 程式審查尚待完成。

## client

使用 Java 21、Minecraft 1.21.1、NeoForge **21.1.251**。已有同版本獨立安裝可直接使用；否則下載[指定版官方 installer](https://maven.neoforged.net/releases/net/neoforged/neoforge/21.1.251/neoforge-21.1.251-installer.jar)，以 `java -jar .\neoforge-21.1.251-installer.jar` 開啟並選 Install client。Minecraft Launcher 選對應 profile，將 Game Directory 設為本包解壓目錄下獨立的 `client`。關閉遊戲後，把包內 `mods/simplerail-1.0.0.jar` 複製至 `client/mods`，此目錄只放這份 mod。再由 Launcher 按 Play。[官方 client 步驟](https://docs.neoforged.net/user/docs/client/)。

## dedicated server

如需新安裝，將上述 installer 放在包根目錄，以 PowerShell 在該目錄執行：

```powershell
New-Item -ItemType Directory server
Set-Location server
java -version
java -jar ..\neoforge-21.1.251-installer.jar --installServer
```

確認為 Java 21，然後將包內 JAR 複製至 `server/mods`，不加入其他模組。先由使用者執行 `.\run.bat --nogui` 取得初始設定；若 EULA 尚未同意而停止，僅在自己同意 [Minecraft EULA](https://www.minecraft.net/eula) 後自行編修此 server 的 eula.txt。包未包含 eula=true，不沿用 T-007 的單一目錄授權。

停止 server 後，編修它生成的 `server.properties`：`level-name`、`server-ip=127.0.0.1`、`server-port`、`online-mode=true`、`max-players=2` 依 CASES.md；其餘先保持產生的值。使用新的世界名稱，勿匯入 OLD 世界。再於 `server` 執行 `.\run.bat --nogui`，完成啟動後 client 以 CASES 的 loopback 位址加入。保存／停服指令在 server console 輸入 `save-all flush`、`stop`。[官方 server 步驟](https://docs.neoforged.net/user/docs/server/)。

## 選用確認

JAR 可用 `Get-FileHash .\mods\simplerail-1.0.0.jar -Algorithm SHA256` 與 manifest 比對。這是包的識別方式，不是人工結案的證據要求。各 game directory 的 `logs/latest.log`、選用 debug.log／crash-reports，以及 client F2 圖片 `screenshots` 可協助回報問題。只需確認對應任務完成／通過或列出失敗項，不需上傳這些資料。正式軌道、GUI、列車、票證等皆未實作，此包只驗框架。
