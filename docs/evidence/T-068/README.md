# T-068 y_cross_rail 左 Y 分岔

**開發完成；R-06 待審；T-069 人工驗收未執行。** `YCrossRail` 接替既有 ID 空方塊，保留 `powered`、`direction`、軌道 shape 與現有直行／轉彎材質變體；放置與鄰居更新在伺服器按實際紅石更新 `powered`。以獨立的左 Y 方向表決定出口，不從名稱猜轉向；4 來車×4 水平朝向×2 電源的 [32 組來源路徑](../T-066-070/ROUTES.md)逐一列出。來源是 OLD `YCrossRail.java:getDestDirection`，舊遊戲結果為「依原始碼推定／待確認」。其他不常用上下 `direction` 值只按 OLD fallback 走原來車方向，實際命令設定情境待確認。

NEW [最終 build log](../T-066-070/build-final.log)退出 0，Gradle test `NO-SOURCE`；[獨立來源路徑斷言](../T-066-070/results.txt)退出 0。T-110 包與 T-069 遊戲驗收仍待執行。
