# 車頭區塊載入 R2：新 D3 驗收包

Minecraft 1.21.1、NeoForge 21.1.251、Java 21、Simple Rail 1.0.0。固定 JAR 位於 `mods/simplerail-1.0.0.jar`；[manifest](manifest.json) 記 commit／SHA-256，`source-inputs.json` 記全部產品來源指紋，`product.diff` 包含先前尚未提交差異。R-06／R-F 尚未獨立審查，人工結果全部未填。

**首次從 R1 升級，會清除 `simplerail:locomotive` 的歷史票證。請先正常關服並備份 NEW 測試世界，再由使用者替換兩端 mods 中唯一的 Simple Rail JAR。既有整列要靠近載入一次重新登錄；之後啟用中正常重啟可從新索引恢復。** 不刪除車輛，不清原版／其他 controller 票證，不匯入 OLD 1.16.5 世界。

載入規則：整列實際位置及移動目標的 3×3 聯集，先加新需求再回收舊需求；停車保留，永久刪車釋放。歷史設定 `cart.locomotive.disableLoadingChunk=true` 是啟用。關閉設定在下一個 server tick 回收票證並清索引；重新開啟只自動處理已載入車頭。未知車廂會暫停整列、保留速度和 UUID，log 提示載入缺車位置或明確解除連結。

只在仍運作的 dedicated server 測所有玩家離線。關服或單人暫停不會運算，區塊載入也不會替車頭新增動力。測例見 [CASES.md](CASES.md)，結果欄在 [results.json](results.json) 留白。

票證的選用觀察方法：正常 `save-all flush` 後關閉測試服，使用 NBT 檢視工具讀**備份副本**的主世界 `data/simplerail_locomotive_chunks.dat`（外層 `data` → `Owners` → 該車頭 `Owner`／`Chunks`）與 `data/chunks.dat`（`data.ModForced` → `Controller=simplerail:locomotive` → `ModForced`／`TickingEntities`）。地獄在 `DIM-1/data/`。比較同 owner 集合，不能把所有列車共用 chunk 當同一票證，亦不能以 `/forceload query` 的空集合判定 NeoForge 票證不存在。

使用者只需回報案例／任務 ID 與通過或異常。兩端 `logs/latest.log`、client 的 F2 `screenshots/`、UUID、NBT 副本與計數均可選附；不要求證據才能結案。[開發契約與限制](../../evidence/locomotive-chunks-R2/README.md)列出保存失配的保守暫停／手動恢復方式。
