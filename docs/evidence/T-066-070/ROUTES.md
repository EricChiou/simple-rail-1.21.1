# 三種路口路徑契約

來源為 OLD `CrossRail.java`、`YCrossRail.java`、`YCrossRightRail.java` 的 `onMinecartPass` 與兩份 `getDestDirection`，另見 [T-003 逐分支原始碼表](../T-003/route-reference.md)。OLD 未執行遊戲；全部舊結果皆為「依原始碼推定／待確認」。輸入指 `cart.getMotionDirection()`，不是玩家視角；E/W/N/S 分別是 +X/−X/−Z/+Z。若水平速度兩軸皆 0，來源不開始穿越。非水平方向在現有來源無正常路口路徑，NEW 明確略過，不猜測出口。

十字路口：E→東鄰格、W→西鄰格、N→北鄰格、S→南鄰格；無紅石選路。兩種 Y 路口如下。每格寫「斷電／通電」，出口位置是路口方塊 `pos.relative(出口方向)`；第一次回呼暫存 `max(abs(vx),abs(vz))`、出口格與旋轉並停車，第二次同 UUID 回呼移到出口、沿出口方向恢復該速度。

| 來車 | 方塊 `direction` | 左 Y 出口 | 右 Y 出口 |
| --- | --- | --- | --- |
| E | E | E／N | E／S |
| E | W | E／E | E／E |
| E | N | S／S | S／E |
| E | S | S／E | S／N |
| W | E | W／W | W／W |
| W | W | W／S | W／N |
| W | N | S／W | S／S |
| W | S | S／N | S／W |
| N | E | E／N | E／W |
| N | W | E／E | E／N |
| N | N | N／W | N／E |
| N | S | N／N | N／N |
| S | E | E／W | E／S |
| S | W | E／S | E／E |
| S | N | S／S | S／S |
| S | S | S／E | S／W |

`JunctionRoute` 直接編碼上述 16×2×2 分支；[獨立 Java 96 項斷言](results.txt)檢查十字及兩份 Y 表，`javac`／`java` 退出碼均 0。實際遊戲 `getMotionDirection`、軌道 shape 重算、過車 tick 時序、編組與材質仍待 T-067／T-069／T-071／T-074 使用者驗收。此矩陣不宣稱 1.21.1 遊戲行為已通過。

[資源鍵靜態檢查](resource-check.txt)退出 0：兩份 Y blockstate 各有 4 向×2 電源的 8 個既有變體，十字保留空鍵變體。首次檢查用 PowerShell `ConvertFrom-Json` 讀十字的空字串鍵時解析器報錯，退出 1；[原輸出](resource-check-01.txt)保留，修正為只對該鍵作文字檢查後通過。這不證明遊戲內材質顯示。

[固定 JAR 清單](jar-entries.txt)已核對三類路口、共用路徑、專用 BE 與三份 blockstate 都打包；JAR SHA-256 見 [T-123 manifest](../../test-packages/T-123-v1/manifest.json)。
