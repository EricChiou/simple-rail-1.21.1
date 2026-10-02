# T-122-v1：client／server 權責最小重現包

此包由開發 Agent 為 T-063 製作，**沒有人工測試結果**。任務 T-122，案例 T122-01～07；R-05 程式審查待審。Minecraft 1.21.1、NeoForge 21.1.251、Java 21、Simple Rail 1.0.0。來源 commit `11916b69c3549504928f7cfa6790d59a2717b4b6` 加本工作樹未提交產品差異，不能單靠 commit 重建；[manifest](manifest.json) 記本輪關聯檔案指紋，[完整輸入指紋](source-inputs.json)列出 192 個來源／資源／建置設定檔。[JAR](mods/simplerail-1.0.0.jar) SHA-256 `8FE277F07B81B737189F8D12524745B7CA90962107F9F9E635884797F9EDE581`。

使用獨立測試世界及 dedicated server，兩個 client 均安裝**相同** JAR 與版本；`mods` 內只放一份 Simple Rail。以 `Get-FileHash -Algorithm SHA256 mods/simplerail-1.0.0.jar` 核對。玩家須有操作／查詢指令權限。依 [案例](CASES.md) 逐一操作；本包沒有測試專用 command 或新增產品功能。server 的 `/data get entity`／`/data get block` 可作權威狀態參考，兩 client 同時記可見結果。伺服器與 client log 均在各自實例的 `logs/latest.log`；F2 截圖在 `screenshots/`。若想定位失敗，回傳案例 ID、實際現象及相關 log／截圖；依既定人工規則，**使用者直接確認通過亦可結案，log／截圖不是前置要求**。

[results.json](results.json) 的實際欄位保持 `null`，只由使用者回報填寫。此包的 NEW build／來源結論在 [T-063 調查](../../evidence/T-063/README.md)；沒有啟動 Minecraft。三種路口與票證尚在後續階段，不能以本輪結果代表 T-084 全功能多人回歸。T-064 已修一個來源可確認的初始朝向缺口，其餘疑點按 T-122 的使用者觀察決定。
