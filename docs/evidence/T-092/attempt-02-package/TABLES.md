# 固定名冊、資料與配置參考

原資料／候選域參考，不是 runtime dump。所有 case-index 案例在 SP／DS 各做；人工確認即可結案，附件選用。

## 13 物品與 11 方塊

| ID | 方塊 | en_us | zh_tw |
| --- | --- | --- | --- |
| simplerail:cross_rail | 是 | Cross Rail | 交叉鐵軌 |
| simplerail:destory_rail | 是 | Destory Rail | 銷毀鐵軌 |
| simplerail:eject_rail | 是 | Eject Rail | 彈出鐵軌 |
| simplerail:high_speed_rail | 是 | High Speed Rail | 高速鐵軌 |
| simplerail:holding_rail | 是 | Holding Rail | 鎖定鐵軌 |
| simplerail:locomotive_cart | 否 | Locomotive | 火車頭 |
| simplerail:oneway_rail | 是 | Oneway Rail | 單向鐵軌 |
| simplerail:signal_timer | 是 | Signal Timer | 信號計時器 |
| simplerail:timer_holding_rail | 是 | Timer Rail | 定時鐵軌 |
| simplerail:train_dispenser | 是 | Train Dispenser | 火車放置器 |
| simplerail:wrench | 否 | Wrench | 板手 |
| simplerail:y_cross_rail | 是 | Y-Cross Rail(left) | Y型交叉鐵軌(左) |
| simplerail:y_cross_right_rail | 是 | Y-Cross Rail(right) | Y型交叉鐵軌(右) |

分頁順序：high_speed_rail、holding_rail、oneway_rail、eject_rail、destory_rail、timer_holding_rail、cross_rail、y_cross_rail、y_cross_right_rail、train_dispenser、signal_timer、wrench、locomotive_cart；分頁 simplerail:tab，兩語系名 Simple Rail。

## 13 配方

工作台每格放 1 原材料；·＝空格。原 3×3 與裁空邊網格均保留在 RECIPE-CATALOG.json；offset／mirror 依裁邊網格操作。

### simplerail:cross_rail

```text
·I·
·R·
···
```

I=minecraft:iron_ingot；R=minecraft:rail；結果 simplerail:cross_rail × 1。

### simplerail:destory_rail

```text
·P·
·I·
···
```

P=minecraft:iron_pickaxe；I=minecraft:powered_rail；結果 simplerail:destory_rail × 3。

### simplerail:eject_rail

```text
R··
·I·
···
```

I=minecraft:powered_rail；R=minecraft:redstone；結果 simplerail:eject_rail × 1。

### simplerail:high_speed_rail

```text
·I·
·R·
···
```

I=minecraft:powered_rail；R=minecraft:redstone；結果 simplerail:high_speed_rail × 1。

### simplerail:holding_rail

```text
·R·
·I·
···
```

R=minecraft:redstone；I=minecraft:powered_rail；結果 simplerail:holding_rail × 1。

### simplerail:locomotive_cart

```text
·G·
·C·
···
```

G=minecraft:gold_ingot；C=minecraft:minecart；結果 simplerail:locomotive_cart × 1。

### simplerail:oneway_rail

```text
···
RI·
···
```

R=minecraft:redstone；I=minecraft:powered_rail；結果 simplerail:oneway_rail × 1。

### simplerail:signal_timer

```text
·R·
·I·
···
```

R=minecraft:repeater；I=minecraft:iron_block；結果 simplerail:signal_timer × 1。

### simplerail:timer_holding_rail

```text
·R·
·I·
·R·
```

R=minecraft:redstone；I=minecraft:powered_rail；結果 simplerail:timer_holding_rail × 1。

### simplerail:train_dispenser

```text
·C·
·D·
···
```

C=minecraft:minecart；D=minecraft:dispenser；結果 simplerail:train_dispenser × 1。

### simplerail:wrench

```text
·G·
·I·
···
```

G=minecraft:gold_nugget；I=minecraft:iron_pickaxe；結果 simplerail:wrench × 1。

### simplerail:y_cross_rail

```text
·I·
·R·
·S·
```

I=minecraft:iron_nugget；R=minecraft:rail；S=minecraft:redstone；結果 simplerail:y_cross_rail × 1。

### simplerail:y_cross_right_rail

```text
·S·
·R·
·I·
```

I=minecraft:iron_nugget；R=minecraft:rail；S=minecraft:redstone；結果 simplerail:y_cross_right_rail × 1。

## 25 設定（有效值觀測受 I-092-02 限制）

| key | default | domain |
| --- | --- | --- |
| cart.locomotive.disableLoadingChunk | true | boolean；**true＝啟用**，沿用舊碼語意，D3 基線保持啟用 |
| rail.high_speed_rail.maxSpeed | 0.8 | double，0.4–2.0（含端點）；是 rail speed 上限設定，非實測速度 |
| rail.oneway_rail.needPower | true | boolean |
| rail.oneway_rail.usePowerChangeDirection | false | boolean；不從名字推定會自動切 reverse |
| rail.eject_rail.transportDistance | 3 | int，1–100（含端點） |
| rail.eject_rail.needPower | true | boolean |
| rail.destory_rail.needPower | false | boolean |
| rail.timer_holding_rail.lv1 | 5 | int，0–2147483647 秒，實際時間 |
| rail.timer_holding_rail.lv2 | 10 | 同上 |
| rail.timer_holding_rail.lv3 | 15 | 同上 |
| rail.timer_holding_rail.lv4 | 20 | 同上 |
| rail.timer_holding_rail.lv5 | 25 | 同上 |
| rail.timer_holding_rail.lv6 | 30 | 同上 |
| rail.timer_holding_rail.lv7 | 40 | 同上 |
| rail.timer_holding_rail.lv8 | 50 | 同上 |
| rail.timer_holding_rail.lv9 | 60 | 同上 |
| rail.signal_timer_block.lv1 | 5 | int，0–2147483647 秒，後續訊號排程換算用 |
| rail.signal_timer_block.lv2 | 10 | 同上 |
| rail.signal_timer_block.lv3 | 15 | 同上 |
| rail.signal_timer_block.lv4 | 20 | 同上 |
| rail.signal_timer_block.lv5 | 25 | 同上 |
| rail.signal_timer_block.lv6 | 30 | 同上 |
| rail.signal_timer_block.lv7 | 40 | 同上 |
| rail.signal_timer_block.lv8 | 50 | 同上 |
| rail.signal_timer_block.lv9 | 60 | 同上 |

level 組內「同上」是 0..2147483647 int 秒；disableLoadingChunk 的 true＝啟用不改，D3 保持 true。檔案參考不是 FML 已生成實測。

## State、loot 與 tag

STATE-DOMAINS.json＝T-010 完整候選域，evidence/state-coverage-reference.json＝T-021 未覆蓋變體。正式 StateDefinition／defaults 未齊，不能稱全狀態可選。11 block 表同名掉落 1；額外 entity loot 不附掛。rails 9／machines 2／wrench 1，minecraft:rails 加 9 自訂但保留 4 vanilla。
