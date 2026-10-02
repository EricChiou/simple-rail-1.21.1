# T-054-v1：T-121 編組載入時序診斷包

> 後續使用者已[確認 T-121 人工驗證完成](../../evidence/T-121/USER_CONFIRMATION.md)，但未回報有無異常或逐例分類；本包原始結果表保持空白。R-05 程式審查仍待執行。

**診斷用途；T-121 人工結果待使用者填寫。** 此包只提供測試入口，並非正式發行 JAR。任務／案例：T-054 → T-121／T121-01～08。Minecraft `1.21.1`、NeoForge `21.1.251`、mod `simplerail 1.0.0`、Java 21；來源 HEAD `11916b69c3549504928f7cfa6790d59a2717b4b6` **加未提交產品差異與 fixture**，不可只由 commit 重建，逐檔 SHA 見 [audit.json](../../evidence/T-048-055/audit.json)。

唯一安裝 JAR：[mods/simplerail-1.0.0-T054-probe.jar](mods/simplerail-1.0.0-T054-probe.jar)，SHA-256 `D48B2F529207B77B35E5FC02DAA2F0D4726313EB842E3A706167C0975E3C4477`。同目錄**不要**再放正式 `simplerail-1.0.0.jar`；兩者 mod ID 相同。正式對照 JAR 見 [T-048～T-053 開發證據](../../evidence/T-048-055/README.md)，SHA-256 `63A31C515F0E4682AD16B78731ACF9653421723BA0254A487BC4063FF04D2766`。診斷 command 僅此包存在，正式產品尚未有連結 UI；T-057／T-059 後續處理。

操作：用新世界與此 JAR 啟動 Minecraft client 或 dedicated server，啟用 cheats／OP（指令 permission 2）。在軌道上放 `simplerail:locomotive_cart` 和原版礦車；用 `/t054 link <head> <cart>` 連結已載入的實體，例如 `/t054 link @e[type=simplerail:locomotive_cart,sort=nearest,limit=1] @e[type=minecraft:minecart,sort=nearest,limit=1]`。用 `/t054 inspect @e[type=simplerail:locomotive_cart,sort=nearest,limit=1]` 查清單；請站在目標維度。指令的回覆與 server `logs/latest.log` 帶 `[T054]` 記錄 head UUID、車廂次序、載入與 owner。必要時用 `/forceload add <x> <z>` 保持車頭區塊載入，之後用 `/forceload remove <x> <z>` 清理本測試建立的強制載入；只操作您的測試世界。

[CASES.md](CASES.md) 有逐例步驟／預期／須回報欄位；[results.json](results.json) 保持 actual `null`。使用者可直接文字確認 T-121 完成，無須提供 log／截圖；若要定位失敗，請回傳受影響案例 ID、實際現象、client／server `logs/latest.log` 中 `[T054]` 附近的行，截圖或世界副本均可選附。遊戲結果只有使用者回報才記錄，開發 build、純 JVM 測試及此空白表均不是遊戲驗收。

診斷包的 build 指令、失敗與成功退出碼見 [T-054 證據](../../evidence/T-054/README.md)。R-05 獨立程式審查待執行；未因包製作而推定通過。
