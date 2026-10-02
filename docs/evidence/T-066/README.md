# T-066 cross_rail 十字路口

**開發完成；R-06 待審；T-067 人工驗收未執行。** `CrossRail` 接替原 ID 的空方塊，沿用共用 `BaseRail` 速度上限與禁坡。伺服器第一次過車記 `max(abs(vx),abs(vz))`、同方向鄰格與旋轉，停在路口；第二次同 UUID 過車才移至該格並恢復方向速度。輸入 E/W/N/S 的出口見[完整路徑契約](../T-066-070/ROUTES.md)；只以來源推定 OLD，未測 OLD 遊戲。暫存隔離／保存由 T-072／T-073 處理。

NEW [最終 build log](../T-066-070/build-final.log)退出 0，Gradle test `NO-SOURCE`；另有[96 項來源路徑斷言](../T-066-070/results.txt)退出 0。T-109 固定版本人工包尚未製作；本輪未啟動 Minecraft。
