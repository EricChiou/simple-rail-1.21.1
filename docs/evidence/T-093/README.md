# T-093 配方、掉落與 tag 固定版本操作包

2026-09-28。**開發完成；R-02 程式審查待審；T-024 人工未執行／尚未交接。** 包製作可不等待前次人工結果，T-024 的正式前置 T-023 仍需使用者確認；I-021-01 尚未解除，不宣稱現在能完整驗收。

[T-093-v1 ZIP](../../test-packages/T-093-v1.zip)／[包入口](../../test-packages/T-093-v1/README.md)共 31 檔、226 個 SP／DS 案例：13 配方各原網格／平移／鏡射、2 配方損傷鎬材料、11 方塊的鎬／手／loot mine／真爆炸邊界、四組 tag 全成員與原版保留／負例、reload 前後重核及額外車頭表載入／責任。未知的車頭 Java destroy 仍留 T-048／T-052／T-062，不把表載入當無雙重掉落通過。

交付 JAR／固定版本、HEAD＋完整 staged／untracked 差異、来源指紋、build 命令／退出碼／log、非遊戲檢查、安裝步骤、具體場景／case IDs／事前預期／來源、log／截圖取得方法與空白 results.json。case-index 每例 actualResult=null，人工確認即可結案，不需附件。符合本項**包製作**完成條件，不等於人工／程式審查／功能交付完成。

共用 [T-092 封裝命令與失敗／成功紀錄](../T-092/README.md)、[packages.json](packages.json)、[最終靜態核對](../T-092/final-check.json)；本輪沒有新 build，直接使用已核對輸入未變的 T-022 build（退出 0、test NO-SOURCE）。JAR SHA-256 `3D4BFC8926509DCE28C6DE11E8198D3639EB288E1EB29FAD89D3AEC9C1C6BBD3`，MC 1.21.1／NeoForge 21.1.251／mod 1.0.0／All Rights Reserved；未啟動 Minecraft 或 OLD build，未修改模組 Java／Gradle／資源、stage／commit／reset。

R-02 只審差異、掉落責任及案例覆蓋，不代跑遊戲或填結果。現在先提供包作審查；R-02 與 T-023 齊後再交使用者執行 T-024。失敗時開發修正→程式複查→使用者重測；新產物另出版本，不覆寫 v1。T-018／T-089 舊確認及 R-01 不延伸到本包。
