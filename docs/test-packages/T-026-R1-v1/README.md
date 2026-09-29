# T-026-R1-v1 高速斜坡局部回歸包

日期：2026-09-28。對應 T-025 修正／使用者 T-026、I-026-01／I-026-02；MIGRATION.md §3／§6 階段 3。**開發修正已建置；R-03／R-F 待審；人工未重測。** 本包供程式複查及後續人工使用，不簽 T-094 完成或 T-026 通過。

| 固定輸入 | 版本／位置 |
| --- | --- |
| Minecraft／NeoForge／mod | 1.21.1／21.1.251／simplerail 1.0.0 |
| Java／Gradle／映射／授權 | Temurin 21.0.12.1+1／Gradle 9.2.1／Parchment 2024.11.17／All Rights Reserved |
| HEAD | 8bd977dbb9f9000411ae5f4d10750228e5f33560，加 evidence/source.diff／source-fingerprints.json；沒有新 commit |
| JAR | mods/simplerail-1.0.0.jar |
| JAR SHA-256 | 8455CC5DE6FE2C7E5953E6A8F0D4A4E419A40489B954C8B0B1216304C5CEA599 |
| build／核對 | evidence/build-01.json／log：退出 0、test NO-SOURCE；靜態核對見 evidence/audit-results-02.json |

只改高速可成坡与補四升坡雙供電模型，兩種共用基底仍禁坡，其他軌道保持既定規格。原版 shape／供電／加速繼承不改，不加入強制反轉修補。全部 ID、速度鍵與範圍／D1–D8 不變。

I-026-01 實作完成待人工；I-026-02 在「由坡底上坡、供電、各速度都有可能反轉」已登錄，根因與本版是否改善未驗證。I-021-01 只補齊高速 24 個宣告组合，其他模型／狀態仍有缺口，不宣稱全部資源無錯誤。I-092-02 全設定觀測也未解除；本包無新設定同步、世界轉換或外部模組。

請依 INSTALL.md／CASES.md 在 NEW 世界操作，人工結果留空。使用者只需回覆案例或 T-026 的通過／失敗確認；附件、版本證明、逐值量測与 log 均非必要。若仍反轉，描述軌道種類、兩接口 Y、行進方向即可；不要求證據。本包不取代完整 T-026／T-094 的所有驗收要求。
