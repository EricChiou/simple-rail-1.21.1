# T-092 固定版本審查草稿與受阻紀錄

2026-09-28。**T-092 受阻：操作／案例草稿已製作，未達可交接 T-023 包的完成條件；R-02 待審，人工未執行。** 前置 T-020／T-021／T-022 開發成果已齊。原完整驗收與 D1–D8 保留，不修改正式依賴、不實作 state 或其他功能。

[T-092-v1-draft ZIP](../../test-packages/T-092-v1-draft.zip)／[草稿入口](../../test-packages/T-092-v1-draft/README.md)共 31 檔、156 案例，完整展開 SP／DS 的 13 物品、11 方塊、25 設定、兩語系與 reload／metadata。JAR 放 reference/，**僅固定現況供審查，不供使用者安裝驗 T-023**。case-index／CASES／TABLES 有前置、具體步驟、事前預期與來源及 log／截圖方法，所有 actualResult=null；使用者確認即可人工結案，附件選用。

| 阻礙 | 具體缺項／受影響案例 | 解除方式（本輪不執行） |
| --- | --- | --- |
| I-021-01 | 10 個骨架缺 selector property，9 種候選域缺模型；C-002 全矩陣、C-004 方塊變體／無錯誤載入受阻 | 依 D6 定義 StateDefinition／正式預設／受控狀態設置與模型承接，再出新 JAR 與新版包；不擅删 slope／up/down |
| I-092-02 | C-003 有效 COMMON 快照／即時 reload／两端權威沒有可操作的觀測介面，消費者未實作；看檔案不能證明 publication | 定義只讀觀測或由後續功能消費者案例驗證有效值；不以 `/reload` 成功或設定檔写回取代 |

保留整份步驟不等於已解受阻或完成開發交接。R-02 可審草稿覆蓋與已存在程式／資源，不能簽本 JAR 可通過 T-023。只有 state／模型及有效值承接後的新包才可交操作；具體任務承接／前置調整仍待審閱，不新增或重排 T 編號。

## 實際版本、命令與证據

使用 T-022 已成功 build 的相同 JAR，SHA-256 `3D4BFC8926509DCE28C6DE11E8198D3639EB288E1EB29FAD89D3AEC9C1C6BBD3`；本輪核對全部 T-022 來源指紋與 live／保存 JAR 一致，**沒有新 build 或遊戲啟動**。HEAD `8bd977dbb9f9000411ae5f4d10750228e5f33560` 加既有 staged／未提交產品差異，未 commit／stage／reset。固定 MC 1.21.1、NeoForge 21.1.251、mod 1.0.0、Java 21、Gradle 9.2.1、ModDevGradle 2.0.147、All Rights Reserved。

- 準備：`powershell -NoProfile -ExecutionPolicy Bypass -File docs/evidence/T-092/prepare.ps1`，退出 0；[輸入核對](preparation.json)、[完整 HEAD＋untracked 產品差異](source.diff)、[所有來源指紋](source-fingerprints.json)、[原 index](index-before.diff)。
- 封裝：`powershell -NoProfile -ExecutionPolicy Bypass -File docs/evidence/T-092/package.ps1`。首次退出 1：工具的表格正規式失去跳脫，未產包；[原稿](package-attempt-01.ps1.txt)、[命令](package-command-01.json)／[log](package-01.log)保存。第二次退出 1：工具未顯式載入 Compression assembly，[命令](package-command-02.json)／[log](package-02.log)、[失敗未封裝草稿](attempt-02-package/README.md)保存。只修工具的 regex／assembly 與 README 分行，第三次退出 0：[命令](package-command-03.json)／[log](package-03.log)／[兩包 metadata](packages.json)。未修改產品以讓封裝成功。
- 靜態驗證與文件核對：`powershell -NoProfile -ExecutionPolicy Bypass -File docs/evidence/T-092/final-check.ps1`，[腳本](final-check.ps1)、[結果](final-check.json)、[最終命令](final-check-command-02.json)／[log](final-check-02.log)。逐 ZIP entry／JAR／空白結果／案例覆蓋及任務編號／依賴／原 index／產品未變均檢查；不是 R-02 或 runtime 通過。首次工具因 JSON 不接受 int-key 字典而在輸出報告時退出 1，[原稿](final-check-attempt-01.ps1.txt)、[命令](final-check-command-01.json)／[log](final-check-01.log)保存；改用 stage/count 列表，只修證據工具、不修改包或產品。

[build-01.json](build-01.json)／[原 log](build-01.log)為 **T-022 歷史 build** 退出 0、test NO-SOURCE。393 資料／159 設定／2519 資源檢查都是既有非遊戲結果，包內保留來源，不重跑或推定本包已測。指令語法從指定 1.21.1／21.1.251 source archive 唯讀取出：[manifest](command-sources.json)／[來源](sources/ExecuteCommand.java)；只讀 LootCommand／ExecuteCommand／Ingredient／ShapedRecipePattern，未執行指令或 codec。

安裝流程於 2026-09-28 查閱 [官方 client](https://docs.neoforged.net/user/docs/client/)及 [server](https://docs.neoforged.net/user/docs/server/) 文件，未下载／執行 installer。包不含 EULA 同意、世界或人工結果。T-093 可獨立製作；其人工 T-024 仍等 T-023，T-025 原前置不受草稿阻礙，本輪未執行它或其他任務。
