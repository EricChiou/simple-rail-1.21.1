# OLD 路口方向分支參考

所有結果為 **依原始碼推定／待確認**，未執行 OLD 或 NEW 路口測試。來源：J/block/YCrossRail.java 與 YCrossRightRail.java 的 getDestDirection（114–232行），HEAD 同 README。此處「來車方向」是 getMotionDirection 的回傳值，不是玩家站在哪一側；E=東/+X，W=西/−X，N=北/−Z，S=南/+Z。

每一表列含斷電／供電兩子案例：左Y 32組、右Y 32組。T-069／T-071 另各以單車／編組及兩種執行環境展開；確認入口方向API語意後才能把本分支表當NEW案例預期。非水平／靜止、動態切電另列邊界，不補造方向。

| 來車方向 | 方塊 direction | 左Y 斷電 | 左Y 供電 | 右Y 斷電 | 右Y 供電 |
| --- | --- | --- | --- | --- | --- |
| E | E | E | N | E | S |
| E | W | E | E | E | E |
| E | N | S | S | S | E |
| E | S | S | E | S | N |
| W | E | W | W | W | W |
| W | W | W | S | W | N |
| W | N | S | W | S | S |
| W | S | S | N | S | W |
| N | E | E | N | E | W |
| N | W | E | E | E | N |
| N | N | N | W | N | E |
| N | S | N | N | N | N |
| S | E | E | W | E | S |
| S | W | E | S | E | E |
| S | N | S | S | S | S |
| S | S | S | E | S | W |

十字軌來源 CrossRail.java:34–88：非零水平運動時記下來車方向與速度 max(abs(vx),abs(vz))，目的格為同方向相鄰格；下一次回呼同UUID才按暫存移動。適用 E/W/N/S，原碼沒有紅石分支；測例仍覆蓋電源不改方向、零速與兩車交錯。破壞有清理，不代表世界卸載也有清理。

