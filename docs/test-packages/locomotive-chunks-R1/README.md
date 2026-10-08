# 車頭持續載入區塊 R1（待使用者重測）

固定版本：Minecraft 1.21.1、NeoForge 21.1.251、Java 21、Simple Rail 1.0.0。JAR 為 `mods/simplerail-1.0.0.jar`；commit／SHA-256 見 [manifest.json](manifest.json)，未提交產品差異見 `product.diff`，來源指紋見 `source-inputs.json`。本包保留目前 T 型路口 R1 與先前功能，新增車頭持續更新票證；R-06／R-F 獨立程式審查待辦。

由使用者將本包 JAR 放入獨立測試環境 client／dedicated server 的 `mods/`，移除測試環境內另一份 Simple Rail JAR，再自行啟動。不要匯入 OLD 世界。關服／重啟都只操作測試環境。本包不代表 T-075／T-113／T-124 全部調查或完整驗收已完成。

設定 `config/simplerail-common.toml` 的 `cart.locomotive.disableLoadingChunk = true` 才是啟用（沿用歷史反直覺名稱；TOML 可能顯示群組＋`disableLoadingChunk`）。新生成、NEW 存檔讀回與跨區塊會申請中心區塊的 ticking 票證；停車、移除車頭、設定關閉不釋放既有票證，維持 D3。現有 NEW 世界中已卸載、且從未取得票證的車頭需先靠近使其載入一次；修正不會掃描所有區域檔尋找舊實體。

請依 [CASES.md](CASES.md) 操作。優先驗證 LC-R1-01、02、03。需使用持續供電軌道；區塊載入不會替車頭新增動力。單人暫停選單、關閉遊戲或停止 dedicated server 時不會繼續運算；要測所有玩家離線後持續行駛，使用仍在運作的 dedicated server。

只需回報案例 ID 與「通過」或異常現象，即可記錄人工結果。log（兩端 `logs/latest.log`）、F2 截圖（client `screenshots/`）、座標與 UUID 可選附，不作結案必備。所有 `results.json` 結果初始空白，開發 Agent 不代填。開發證據見 [README](../../evidence/locomotive-chunks-R1/README.md)。
