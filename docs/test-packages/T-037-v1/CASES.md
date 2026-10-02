# T-119 案例、事先預期及結果空白規則

全部實際結果目前為空，見 results.json。每項案例的來源為開發證據 INVESTIGATION.md；OLD 都是「依原始碼推定／待確認」，不用 OLD JAR 或重建。此包使用合成 UUID，沒有實際礦車等待／放行；不替代 T-040／T-083。正式約 3 秒誤差 M-01 仍待技術定義。

## 共用場景

SP 為單人、DS 為 dedicated server＋client。建立新超平坦創造世界，允許指令／OP。用指令到遠離出生點的空區域並放置支撐，聊天輸入：

```text
/tp @s 10000 66 10000
/setblock 10000 63 10000 minecraft:stone
/setblock 10000 64 10000 simplerail:timer_holding_rail
/t037 status 10000 64 10000
```

在此 chunk 不放礦車、車頭、紅石、其他方塊實體或 /forceload，不改 D3。在需要卸載前先確認沒有其他玩家留在附近。保持視距 4、模擬距離 4（SP 取設定允許的最低值也可）；離開 2048 格後以實際 CHUNK_UNLOAD 判定，不以看不見區塊判定。等到真正卸載再返回；若無事件，記條件未成立並檢查玩家／出生／票證，不記未重現。指令座標皆為主世界同一塊軌道。

## T119-01-SP／DS：首次未使用的計時資料

1. 放置後不輸入 start，status 應為 remaining_ms=0。
2. SP 儲存退出再進入；DS console `save-all flush`、`stop`，等程序結束再開服並重新連線。
3. 返回測試座標，status 應仍 idle（0），沒有讀 UUID 例外；觀察 LOAD 的 idle 與 FIRST_TICK。

預期依據 I-037-01／NEW guard，非 OLD 已修復。保存資料可以沒有 cart_uuid／remaining_ms。實際結果待使用者；若軌道消失或進世界失敗，記診斷包失敗。

## T119-02-SP／DS：缺鍵、錯型與越界

各次先 `/t037 start 10000 64 10000 60 true`，再執行表內一條命令，status 應回 0、沒有例外。分別正常存讀，重載仍 idle。不要在這些案例使用 arm（/data 會呼叫序列化）。

| 子例 | 指令（聊天） | 事先預期 |
| --- | --- | --- |
| A 空資料 | `/data modify block 10000 64 10000 t037_data set value {}` | LOAD idle |
| B 缺 UUID | `/data remove block 10000 64 10000 t037_data.cart_uuid` | invalid_keys_or_types，安全 idle |
| C 缺剩餘時間 | `/data remove block 10000 64 10000 t037_data.remaining_ms` | invalid_keys_or_types，安全 idle |
| D UUID 錯型 | `/data modify block 10000 64 10000 t037_data.cart_uuid set value "bad"` | 安全 idle |
| E 時間錯型 | `/data modify block 10000 64 10000 t037_data.remaining_ms set value "3000"` | 安全 idle |
| F 時間負值 | `/data modify block 10000 64 10000 t037_data.remaining_ms set value -1L` | invalid_range，安全 idle |
| G 超過允許最大值 | `/data modify block 10000 64 10000 t037_data.remaining_ms set value 2147483647001L` | invalid_range，安全 idle |

這是在 NEW probe 自身資料上做故障注入，不是 OLD NBT 轉換／世界相容驗收。UUID 長度錯誤與 int/long 型別差別另有 JVM 測試，遊戲內如需追加可回報具體值。

## T119-03-DS：setter 未標髒的控制比較

1. `/t037 clear 10000 64 10000 false`，console `save-all flush`，status 確認 0 且 chunkUnsaved=false。若一直 true，排除世界活動／其他玩家，記条件未成立，不推定保存失敗。
2. `/t037 start 10000 64 10000 60 false`，立即 status。控制前提仍為 chunkUnsaved=false；START 有新 UUID／時間，setter 故意未標髒。
3. 在未有其他區塊修改時 `save-all flush`，觀察是否略過此 chunk 的 CHUNK_DATA_SAVE；正常 stop／重開後回到該位置。
4. 若整段直到停服都無其他標髒且讀回舊 idle，符合 I-037-02 的保存風險假說；若外界已標髒／產生新版 snapshot，即記有干擾，不能稱舊版無 bug 或此風險未重現。
5. 對照：`/t037 start 10000 64 10000 60 true`，status 應 true，立刻 console `save-all flush`；應有帶正剩餘值的 CHUNK_DATA_SAVE。接著正常停服、等至少 10 秒再開服；LOAD 讀回末次保存剩餘值，首 tick 後恢復遞減。

log 可在本機觀察，不要求回傳。這一例限定 DS，因 SP 沒有 save-all 命令。缺標記不保證每次丟資料；OLD 方向 setBlock 可能遮蔽風險，不能用本候選替 OLD 實測。

## T119-04-SP／DS：秒數上限

分別執行 `/t037 arithmetic 2147483`、`/t037 arithmetic 2147484`、`/t037 arithmetic 2147483647`。預期 legacy_int_ms 依序為 2147483000、-2147483296、-1000；candidate_long_ms 為 2147483000、2147484000、2147483647000。

再 `/t037 start 10000 64 10000 2147483647 true`，status 應為接近但不大於 2147483647000 的正 long；立即正常存讀，仍為正值並可持續遞減，不能瞬間到期。最後 `/t037 clear 10000 64 10000 true`。零秒另用 start ... 0 true，應 idle。這只查界限／接線，不等待最大值自然到期；0–9 等級讀正式設定仍留 T-038／040。

## T119-05-SP／DS：計時途中保存與重複讀回

1. `/t037 start 10000 64 10000 60 true`，保持世界活動約 10 秒；status 应接近 50000，依實際經過時間下降。
2. DS 在 console `save-all flush` 後繼續等約 5 秒，status 應繼續下降、沒有因保存重設成 60000。SP 以正常退出觸發保存，不使用 DS 指令。
3. 正常停服／退出，等至少 10 秒再開啟；比較最後保存的正 remaining_ms 與 LOAD／FIRST_TICK 的 stored_remaining_ms。應讀回相同保存預算，離線不額外扣掉 10 秒；開始 tick 後才繼續遞減。
4. 在尚未到期前再正常存讀一次，應從各自末次 snapshot 恢復，不重置總長、不累加離線期間。到期後保持 0。

需分清「最後保存值」與先前 status 值的活動間隔；status 不凍結計時。fixture 只量測實際時間，遊戲卡頓／暫停選單並非真正區塊卸載，不拿它替代下一例。正式放行誤差未在本例判定。

## T119-06-SP／DS：真卸載及約 3 秒讀回

1. `/t037 arm unload 10000 64 10000 3000`，立即 `/tp @s 12048 66 10000`，不要再請求遠方區塊。
2. 觀察真正 CHUNK_UNLOAD；預期順序為 CHUNK_UNLOAD → ARM_FIRED trigger=unload → SERIALIZE／CHUNK_DATA_SAVE → BE_UNLOADED。沒有事件則條件未成立。此 arm 在事件中直接把當前 chunk 標髒，避免請求 chunk／新增票證。
3. 在已卸載後等至少 10 秒，再 `/tp @s 10000 66 10000`。
4. 預期 LOAD 正值接近 3000、FIRST_TICK 保有讀回預算；自 FIRST_TICK 至 EXPIRED 約 3 秒，卸載的 10 秒沒有被扣除。保存與首 tick 的預算應與實際序列化值一致；事件至序列化可能已經過少量時間，不要求精確寫成 3000。

若卸載排程太慢，arm 仍在真正事件才設 3000，不能拿起初 60 秒倒數推定卸載發生。這是受控邊界注入，並未證明正式礦車自然剩 3 秒時的策略可靠。約 3 秒遊戲容許誤差與 tick 延遲量測 M-01 仍待技術定義；本例先確認來源順序與預算不扣離線時間，不能簽正式 T-040／083 通過。

## T119-07-SP／DS：關服／退出後約 3 秒讀回

1. `/t037 arm save 10000 64 10000 3000` 後立即正常關閉：SP 儲存並退出，DS console `stop`。此時不要 `/data`、save-all 或其他序列化操作。
2. 確認 ARM_FIRED trigger=save 屬於正常退出／停服保存；若自動保存或其他序列化提前消耗 arm，記此輪條件未成立並重新安排，不偽稱停服邊界重現。
3. 程序／世界真正停止後等至少 10 秒，再開服／進入世界。
4. 預期 LOAD／FIRST_TICK 與末次序列化的剩餘值一致且接近 3000；FIRST_TICK 到 EXPIRED 約 3 秒，離線不扣時。先前 SERIALIZE 不等於落盤成功，必須正常讀回觀察。

這個「剩餘約 3 秒時關服」候選測例與上一個真卸載測例分開。正式遊戲誤差仍待技術定義，礦車放行未實作。T-119 的使用者結果可確認／否定診斷假說，不能當作 T-040 的正式停車驗收。

## 回報與判定

只須確認「T-119 完成／通過」或列失敗現象。若有無法建立的場景，可指出案例與原因，保留待確認；不得填「未重現」取代未測。results.json 中 actual、userConfirmation 均留空等待使用者；任何 log／截圖／碼表數值皆選用。不要求重測 T-023–036 或其他已結案任務。
