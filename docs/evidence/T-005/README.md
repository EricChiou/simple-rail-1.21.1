# T-005 NEW 既有框架建置基線

日期：2026-09-26（Asia/Taipei）。NEW：`D:/workspace/java/simple-rail-1.21.1`，HEAD `8bd977dbb9f9000411ae5f4d10750228e5f33560`。開始時MIGRATION.md、TASK.md、REVIEW.md為已暫存新增，docs/未追蹤；未重設、提交或變更暫存區。

**結論：NEW 既有框架 build 成功，T-005 完成。** 不代表已移植Simple Rail功能、查證全部1.21.1 API、啟動遊戲或完成T-006/T-007/T-089。OLD build由使用者先前驗證，本次流程不重跑，亦未補下載Java 8/Gradle 6.8.1。

## 實際命令與結果

命令均在NEW執行：`.\gradlew.bat build --console=plain --info`。PowerShell包裝僅保存輸出/時間/退出碼，完整腳本見 [commands.json](commands.json)。

| 嘗試 | 執行環境 | 退出碼 | 實際結果與證據 |
| --- | --- | --- | --- |
| 01 | 沙箱內 | 1 | Wrapper無法建立C:\.gradle下的distribution鎖檔父目錄；未到專案編譯。[完整log](build-attempt-01.log)、[時間/結果](build-attempt-01.json) |
| 02 | 經允許沙箱外重跑相同Gradle命令 | 0 | BUILD SUCCESSFUL in 2m 39s，5 actionable tasks: 5 executed。[完整log](build-attempt-02.log)、[時間/結果](build-attempt-02.json) |

嘗試02記錄UTC 14:39:23.1388693–14:42:03.2238399（台北22:39:23–22:42:03）。沙箱外使用C:/Users/Kinoko/.gradle；未修改JAVA_HOME、Gradle設定或專案程式以修復沙箱。嘗試01的失敗保留，不改寫為第一次即成功。log由PowerShell Tee-Object保存（UTF-16），包含完整Gradle stdout/stderr及PowerShell對原生stderr的包裝。

## 宣告與實際解析核對

| 項目 | 實際證據 | 判定 |
| --- | --- | --- |
| Java | build log JVM metadata: Temurin21.0.12.1+1-LTS；compileJava使用C:/Program Files/Eclipse Adoptium/jdk-21.0.12.101-hotspot | 使用Java21 toolchain；偵測到Java25僅為Gradle候選探測，未用它編譯本模組 |
| Gradle | daemon命令與wrapper distribution路徑均為9.2.1 | 與NEW宣告吻合 |
| ModDevGradle | Resolved plugin net.neoforged.moddev version2.0.147 | 實際解析成功 |
| Foojay resolver | Resolved plugin org.gradle.toolchains.foojay-resolver-convention version1.0.0 | 實際解析成功 |
| Minecraft／NeoForge | 下載1.21.1 version JSON/client/server artifacts；NeoForm參數net.neoforged:neoforge:21.1.251:userdev | 指定目標artifacts處理完成，非遊戲啟動證據 |
| Parchment | parchment-1.21.1/2024.11.17 ZIP被解析，作為--parchment-data傳入transformSources | 指定mappings已供本次build使用 |
| 額外建置工具 | neoform-runtime2.0.31等見實際log與[artifact解析清冊](resolved-artifact-manifest.properties) | 保存實際解析結果，不把工具相依當作外部模組整合 |
| 編譯與測試 | compileJava重新編譯；compileTestJava、processTestResources、test均NO-SOURCE | 編譯已執行；沒有Java測試案例可跑，不能記「功能測試通過」 |

此build只驗證目前範例程式使用到的接線可編譯，不完成T-008–T-016 API研究或執行語意驗證。

## 產物識別與內容

- 原產物：`build/libs/simplerail-1.0.0.jar`。
- 保存的同份基線：[simplerail-1.0.0.jar](simplerail-1.0.0.jar)，10,033 bytes。
- SHA-256：`D6BB8A92830EDDE583838496D471E9F201BE0D16694D0B487D06D46D21D9FE94`。
- [artifact.json](artifact.json)記大小、雜湊及class major65；[JAR完整entry清單](jar-entries.txt)含Config、SimpleRail、SimpleRailClient等既有框架類別，沒有已移植的11方塊/13物品程式。
- [JAR內metadata原文](neoforge.mods.toml.txt)：modId=simplerail、version=1.0.0、displayName=Simple Rail、license=All Rights Reserved、loader=javafml/[1,)、Minecraft=[1.21.1]、NeoForge=[21.1.251,)。
- 建置使用的NeoForge固定21.1.251；metadata的範圍宣告不代表已驗證其他NeoForge版本。
- 這是**範例框架基線JAR，不是發行候選或完成遷移的JAR**。

## 限制、警告與變更範圍

Gradle回報用了deprecated features、未來Gradle10不相容；本次既定9.2.1 build仍成功，不為此擅改D8/Gradle版本。完整警告保留在log，未額外重跑build或擴大環境修復。

未執行client、dedicated server、GameTestServer、data generation、OLD Wrapper、OLD build或發布。build自然寫入build/、.gradle與使用者Gradle快取；沒有修改Java、Gradle宣告或src資源。12個NEW來源/設定檔指紋見[source-manifest.json](source-manifest.json)，本輪結束再比對，另以git diff HEAD核對追蹤來源無變動。

## 完成條件判定

| 條件 | 本次證據 |
| --- | --- |
| NEW build退出碼0 | 嘗試02 JSON与完整log；嘗試01限制另存 |
| 目標Java/Gradle/NeoForge/ModDevGradle/Parchment實際解析可辨識 | 上表、build INFO輸出及artifact清冊 |
| JAR及metadata可識別，基線不變 | artifact.json、保留JAR、metadata原文與SHA-256 |
| 未把框架當遷移完成 | NO-SOURCE／未遊戲測試／未API研究均明列 |
| 修改與失敗可追溯 | commands.json、兩次完整log、Git起始紀錄与來源指紋；未改專案設定 |

據此T-005可標 **已完成（NEW既有框架建置基線）**。後續就緒的啟動／API任務仍須各自授權與證據，本輪不提前執行。

