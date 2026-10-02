# T-070 y_cross_right_rail 右 Y 分岔

**開發完成；R-06 待審；T-071 人工驗收未執行。** `YCrossRightRail` 接替既有 ID 空方塊，保留 `powered`、`direction`、shape 與現有右 Y 直行／轉彎材質變體。右 Y 通電分支按 OLD `YCrossRightRail.java:getDestDirection` 逐列編碼；[32 組來源路徑](../T-066-070/ROUTES.md)與左 Y 並列，不能由左 Y 鏡射推定。舊版結果仍為「依原始碼推定／待確認」。

NEW [最終 build log](../T-066-070/build-final.log)退出 0，Gradle test `NO-SOURCE`；[獨立來源路徑斷言](../T-066-070/results.txt)退出 0。T-111 包與 T-071 遊戲驗收仍待執行。
