# T-052-R2：一般礦車速度、不可乘坐與外觀重測包

> 後續使用者已[確認 T-052 人工驗收通過](../../evidence/T-052/fix-R2/USER_CONFIRMATION.md)。此包原始逐例結果保持空白；受測 JAR 指紋未由使用者提供，不能將本包 SHA 倒填為實際受測版。R-05／R-F 獨立程式審查仍待執行。

任務／案例：T-052，T052-R2-01～05 及 T052-FULL。**人工結果待使用者填寫；R-05／R-F 程式複查待執行。** Minecraft `1.21.1`、NeoForge `21.1.251`、mod `simplerail 1.0.0`、Java 21。來源 HEAD `11916b69c3549504928f7cfa6790d59a2717b4b6` 加未提交差異，R1／R2 源碼 SHA 見 [audit.json](../../evidence/T-052/fix-R2/audit.json)。

唯一安裝 JAR：[mods/simplerail-1.0.0.jar](mods/simplerail-1.0.0.jar)，SHA-256 `7FBBD041165C15EF21397FEE7648EECCE7BC4713F440D197951311A7E7CB64DA`。在 client 與 dedicated server 的 `mods` 目錄移除同 ID 的 R1／舊版／T-054 診斷 JAR，只保留此固定 JAR；兩端均使用相同檔案。建議先備份測試世界並以新世界重測速度；R1 既有 NEW 測試世界讀回可另行觀察，但不把舊 NBT 轉換列為需求。

[CASES.md](CASES.md) 提供每例步驟、預期與應回傳的實際現象；[results.json](results.json) 的 actual 全為 `null`。你確認 T-052 完成即可依既定規則結案，無須 log／截圖；若有失敗，請回報案例 ID 與現象，client／server `logs/latest.log`、影片或截圖可選附。T-052 原有的雙 client、命名、放置、碰撞、破壞／掉落、八方向、重連與材質條件仍由 T052-FULL 覆蓋，不以速度單項通過代替整項。

[R2 原因、父類變更與 NEW build／bytecode 證據](../../evidence/T-052/fix-R2/README.md)已保存。此包**尚未經遊戲驗證**；獨立 Review Agent 僅審程式與案例覆蓋，不替使用者試跑或簽署通過。
