# T-043 診斷環境與共用操作

1. 準備 Minecraft 1.21.1＋NeoForge 21.1.251、Java 21 的獨立測試實例／世界。將 [診斷 JAR](mods/simplerail-1.0.0-T043-probe.jar) 複製至 `mods`；移除同 ID 的其他 Simple Rail JAR。dedicated server 與連線 client 均用同一份。可用 PowerShell `Get-FileHash mods/simplerail-1.0.0-T043-probe.jar -Algorithm SHA256` 核對 README 的 SHA-256。
2. 以有指令權限的玩家選一塊平坦區，例如基準座標 `(100,64,100)`。執行 `/setblock 100 64 100 simplerail:train_dispenser[facing=north]`，再於**正上方**執行 `/setblock 100 65 100 minecraft:chest`。上方箱子需維持單箱 27 格，不要與旁邊箱子合併；直接開這個原版箱子編輯樣板。診斷方塊本身沒有正式 T-044 GUI／專用 BE。
3. NORTH 範例：槽 `i` 的來源位置公式為 `(100.5+i,64,99.5)`；可沿 `(100..126,64,99)` 鋪東西向軌道，供觀察礦車。四朝向公式與案例見 CASES。不要把上方箱子的座標算成發射起點。
4. 在方塊南側 `(100,64,101)` 放紅石方塊作穩定供電；移除它會斷電。供電時於其他空側（例如 `(99,64,100)`）放置／移除普通方塊，產生不改供電的鄰居更新。每次是否真的觸發要以伺服端 `[T043] run=... START` 記錄判定；沒有 START 的操作不能當成重複觸發測例。
5. `/t043 scan 100 64 100` 可手動執行一次診斷掃描，適合測位置／車種／阻擋；它標記 `trigger=manual_command`，**不能**拿來證明紅石鄰居事件。每次 scan 記 `START`、各 `SLOT`、可能的 `SPAWN` 和 `END`；只有實際 `added=true` 才算診斷車加入世界。若前一輪車還在目標格，下一輪可能在該格 `BLOCKED`，請分開記錄「再次呼叫」與「再次成功生成」。
6. 若只需告知結論，回覆「T-120 通過」或案例 ID／失敗現象即可，無需附證。可選證據：單人世界的 `logs/latest.log` 或 dedicated server 的 `logs/latest.log` 中 `[T043]` 行、F2 截圖（`screenshots/`）、樣板槽位前後與生成車的位置／UUID。請不要將診斷爐車替身當成正式車頭。
