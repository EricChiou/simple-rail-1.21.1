# LC-R1 人工重測（未執行）

共同條件：新測試世界，非出生區塊，無 `/forceload add`、其他模組或其他車頭殘留票證。以 F3+G 核對區塊邊界。使用 NEW 的 config 預設 true。`/forceload query` 只反映原版集合，不能用其「空」判定 NeoForge 車頭票證不存在。

可重現的基本路線（有 OP 的使用者操作）：

1. `/tp @s 1024 68 1024`，建立支撐及持續供電水平直軌：`/fill 1024 63 1024 2047 63 1024 minecraft:redstone_block`，`/fill 1024 64 1024 2047 64 1024 minecraft:powered_rail[shape=east_west,powered=true]`。兩端加防墜設施；結尾前可安排停車區，或加長軌道。避免在已抵達終點後誤判為區塊停止。
2. `/give @s simplerail:locomotive_cart`，在起點以物品放置車頭。`/tag @e[type=simplerail:locomotive_cart,sort=nearest,limit=1] add LC_R1`；確認車頭已存在至少一個世界 tick。
3. `/data merge entity @e[type=simplerail:locomotive_cart,tag=LC_R1,limit=1] {Motion:[0.4d,0.0d,0.0d]}`，確認向 +X 行駛。不要只靠未供電的普通軌道測長程，正常阻力會讓車停止。
4. 玩家 `/tp @s 0 80 -1024`，其他玩家都離開鐵路的 view-distance／simulation-distance 範圍。由 dedicated server console 每隔約 10 秒執行 `execute in minecraft:overworld as @e[type=simplerail:locomotive_cart,tag=LC_R1] run data get entity @s Pos`，至少觀察 60 秒且跨越多個 16 格邊界；console 不加 `/`。不要傳送到車頭旁觀察，這會遮蔽問題。可先 `data get entity` 記 UUID 以區分多車。

| 案例 | 操作 | 預期（尚未實測） |
| --- | --- | --- |
| LC-R1-01 遠離玩家與跨區塊 | 依上方 4 步，新生成車頭離開所有玩家範圍，在持續供電的直路跑至少 60 秒；再以單頭＋至少 2 車編組重跑。 | 無玩家跟隨仍能跨越多個區塊，位置持續變化，不在 16 格邊界永久停止；編組未遺失、沒有新增車廂或異常斷連。 |
| LC-R1-02 同維度無玩家／全部離線 | 車頭行駛時，玩家全部到地獄（主世界無玩家）；再測全員離線但 dedicated server 持續運作至少 60 秒，使用 console 查位置。路線需足够長。 | 主世界無玩家超過 15 秒後仍更新，全部離線後仍行駛。只有世界仍在 tick 的 dedicated server 適用，不用關閉 client 的單人世界作此例。 |
| LC-R1-03 保存重啟 | 遠離鐵路正常 `/save-all flush`、`stop`；同包重啟 dedicated server，不登入到車頭附近，console 查同一 UUID 的位置並等待跨區塊。 | NEW 持久票證恢復，車頭不需玩家靠近即可繼續原有運動；UUID／編組保存，無異常錯誤。停服時間不會模擬行車。 |
| LC-R1-04 生成、停車與重新發車 | 在距出生點很遠的新測點放靜止車頭，等一個 tick 後全員離開；console 查車仍可存取，再用命令給水平 Motion、持續供電軌道使其行駛。另讀回一台舊 NEW 車头（先由玩家使其載入一次）。 | 即使尚未跨過第一個 chunk，初始票證也會建立；讀回已有實體同樣可啟動，不必重新製作車頭。已卸載且從未有票證的車不要求被全圖掃描找回。 |
| LC-R1-05 邊界、負座標、維度與多車 | 在 X/Z 的 15↔16、-1↔0、-16↔-17 區間鋪有供電軌道，雙向通行；兩車分開路線；主世界與地獄同 X/Z 各放車後離開。 | 中心計算不向零截斷；每車以自己的 UUID／所在世界申請票證，彼此不覆寫。沒有 client 申請、死鎖或重複註冊錯誤。 |
| LC-R1-06 設定關閉對照 | 在另一個乾淨測試世界／環境將歷史設定設 false 後啟動，同樣放車遠離玩家；再以 true 在乾淨世界重測。 | false 不新增車頭票證；true 在無玩家時仍行駛。不要用已有 true 票證的世界測 false 的卸載效果，原票證依 D3 不會被回收。關閉設定不是解除既有票證的命令。 |
| LC-R1-07 停車、移除及 D3 限制 | 已載入路線先停車、再移除車頭；正常保存重啟，觀察是否有錯誤。需要診斷時可在停服副本以 NBT 工具查看 `data/chunks.dat` 的 `ModForced`／`Controller=simplerail:locomotive`／UUID 集合；不要編輯原存檔。 | 移除／停車不新增釋放政策。既有中心票證可能繼續保留，不把它列為本次已修復的資源生命週期問題，也不假設全 5×5 為 ticking。實際集合／效能未測者標待確認，交 T-075／T-078 後續。 |
| LC-R1-08 世界切換／快速移除 | 單人世界 A 放車後正常退出，進入新世界 B 在同座標放另一車；另在生成車頭後立即移除。 | bootstrap 暫存不跨世界，已移除／未成功加入的實體不申請新票證；不出現 ConcurrentModification、載入死鎖、錯誤維度票證。 |

本包只重測此次缺少區塊載入接線的問題；不簽署 T-077／T-124 完整任務或政策疑點已通過。各實際結果待使用者確認；失敗時回報案例及停下的位置／時機即可，log 與截圖選用。
