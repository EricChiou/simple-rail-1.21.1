# T-037-v1：T-119 計時保存診斷包

2026-09-30。開發調查包已建置，**R-04 程式審查待審；T-119 人工未執行**。這份 JAR 只供獨立 NEW 診斷世界使用，以指令控制合成 UUID／計時資料；沒有正式礦車停車／放行功能，不代表 T-038 或 D5 遊戲驗收完成。不要將本包與一般 Simple Rail JAR 同時安裝，也不要拿診斷世界當後续發行世界。

| 固定項目 | 值 |
| --- | --- |
| 任務／案例／審查 | T-037 → T-119；T119-01–07（部分分 SP／DS）；R-04 待審 |
| 需求 | MIGRATION §4.2、§4.3(4)、D5／D6、§6 階段 4；T-004 C-014–016、C-036 計時子集 |
| Minecraft／NeoForge／Simple Rail | 1.21.1／21.1.251／1.0.0，All Rights Reserved |
| 工具 | Java 21；本次 Temurin 21.0.12.1+1，Gradle 9.2.1，ModDevGradle 2.0.147，Parchment 1.21.1／2024.11.17 |
| NEW HEAD | 11916b69c3549504928f7cfa6790d59a2717b4b6，加 evidence 內未提交 fixture；不是正式產品新 commit |
| JAR | mods/simplerail-1.0.0-T037-probe.jar |
| SHA-256 | AAF9977E094981A481305DCDCF6C60694931FFD3483A29C9A6A5B31BB10415C7 |

先依 [INSTALL.md](INSTALL.md) 準備，再按 [CASES.md](CASES.md) 操作。命令與事先預期、已知缺口已列明；Agent 沒有啟動本包。正式交接仍需相關 R-04 程式審查；使用者結果不從編譯成功推定。

[manifest.json](manifest.json) 綁定版本／來源，[evidence](evidence/) 保存 build／非遊戲測試 log、完整 fixture／測試／init script、產品指紋及 overlay diff。NEW build 退出 0，Gradle test NO-SOURCE；另跑 testT037 的 1,049 項 plain JVM 判定通過，使用真實 NEW NBT，沒有遊戲 bootstrap。

[results.json](results.json) 的實際結果留空。操作完成後只需回覆「T-119 完成／通過」或失敗項與現象，不要求提交 log、截圖、版本或逐例證據。這些資料可選擇提供協助定位。約 3 秒的正式遊戲誤差仍待 T-040 技術定義，本包不替正式計時驗收簽署通過。
