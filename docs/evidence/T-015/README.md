# T-015 軌道材質、車頭模型與渲染 API 查證

日期：2026-09-28。狀態：**開發交付完成；R-01 程式審查待審；人工遊戲未執行**。範圍只包含 OLD 原始碼／資源的靜態盤點、Minecraft 1.21.1＋NeoForge 21.1.251 指定版來源查證及獨立最小編譯。OLD 行為均為**依原始碼推定／待確認**；本輪不移植產品程式或資源，不啟動 Minecraft。

## 來源、版本及執行紀錄

- [21 個 Java 來源快照與 SHA-256](source-manifest.json)含指定版 16 個、OLD 5 個；[蒐集命令／版本雜湊](collection.json)。指定版來源由 `build/moddev/artifacts/neoforge-21.1.251-sources.jar` 擷取，與 1.21.1 官方 [模型與 `render_type` 說明](https://docs.neoforged.net/docs/1.21.1/resources/client/models/) 對照。後者說明 `minecraft:cutout` 與模型 JSON 的 `render_type` 用法；正式遊戲載入尚未驗證。
- [九軌與 PNG 靜態盤點](resources.json)由[唯讀檢查腳本](inspect-resources.ps1)取得：九個 OLD blockstate 引用 29 個方塊模型及 29 張實存方塊貼圖；每張都有完全透明像素，29 個模型皆未寫 `render_type`。這是路徑、雜湊與 PNG 像素檢查，**不是** NEW resource codec／模型烘焙通過；此腳本以來源文字擷取模型引用，不宣稱解析全部 blockstate 語法。
- [最小 Java 探針](probe/T015Probe.java)只用於[獨立 Gradle JavaCompile](probe.init.gradle)，命令：`.\gradlew.bat compileT015Probe --offline --console=plain --info --no-configuration-cache -I docs/evidence/T-015/probe.init.gradle`。[第一次紀錄](compile-01.json)退出 **1**，因沙箱內 `C:\.gradle\...zip.lck` 父目錄不能建立；[log](compile-01.log)保留。[獲允許的重試](compile-02.json)退出 **0**、`BUILD SUCCESSFUL`；[完整 log](compile-02.log)保留。Java 21.0.12.1、`--release 21 -Xlint:deprecation -Werror`，[編譯器](compiler.txt)、[classpath](compile-classpath.txt)、[三個 major 65 class](compiled-classes.json)及[範圍指紋](verification.json)均保存。探針不進入產品 sourceSet／JAR，未載入或執行。
- [任務、依賴、文件與雜湊自查](final-check.json)只屬開發 Agent 靜態自查，不是 R-01 獨立審查。12 個產品基線檔與 T-009 一致，產品 Java／Gradle／資源無差異。

## OLD 軌道 cutout 與 NEW 候選

`sources/old/setup/Render.java:14–24` 在 client setup 對下列九個方塊呼叫 `RenderTypeLookup.setRenderLayer(..., RenderType.cutout())`。指定版 `sources/target/net/minecraft/client/renderer/ItemBlockRenderTypes.java:455–483` 雖保有 `setRenderLayer`，但明標 deprecated，建議在方塊模型 JSON 設 `"render_type": "cutout"`；NeoForge 1.21.1 官方模型文件亦列 `minecraft:cutout`。T-021／T-050 應在每個被 blockstate 引用的模型加入對應 render type，而非只處理九個根 blockstate；屆時須按指定版資源格式、UV 與實際畫面核對。OLD 的 `textures/blocks` 路徑與 NEW atlas 遷移另由 T-009／T-021 處理，不能只加 `render_type` 就宣稱資源可載入。

| 既有方塊 ID（全部保留） | OLD blockstate 模型引用次數 | 唯一模型數 | NEW 候選 |
| --- | ---: | ---: | --- |
| `high_speed_rail` | 4 | 2 | 所引用模型 cutout |
| `holding_rail` | 4 | 2 | 同上 |
| `oneway_rail` | 16 | 4 | 同上 |
| `eject_rail` | 12 | 4 | 同上 |
| `destory_rail` | 6 | 2 | 同上，保留拼寫 |
| `timer_holding_rail` | 20 | 10 | 同上，含全部 0–9 級 |
| `cross_rail` | 1 | 1 | 同上 |
| `y_cross_rail` | 8 | 2 | 同上 |
| `y_cross_right_rail` | 8 | 2 | 同上 |

這 29 個模型的唯一集合及各自貼圖見 `resources.json`，不將 29 張貼圖誤作 29 個註冊方塊。每張 PNG 的透明像素數是靜態證據；哪些邊緣需 mipmap、cutout 或更特殊效果，仍待正式資源載入與使用者畫面驗收。

## 車頭模型、貼圖與 UV

OLD `sources/old/render/model/LocomotiveCartModel.java:20–58` 設 `texWidth=96`、`texHeight=64`，父零件 `cart` 錨點 `(0,5,0)`，下列六個子零件均在父零件原點、`addBox(..., 0.0F, true)` 表示舊鏡像選項。[原始 PNG 實檔盤點](resources.json)證明 `textures/entity/locomotive_cart.png` 是 **96×64、32-bit ARGB**，SHA-256 `F2B64C6502099024781691BFBE9A93693DCBABEB225B53DC0C07C545E070B1AF`；`sources/old/constants/Texture.java` 指向 `simplerail:textures/entity/locomotive_cart.png`。

| 零件 | OLD texOffs (u,v) | OLD 盒原點 (x,y,z) | 尺寸 (x,y,z) | NEW 模型定義候選 |
| --- | --- | --- | --- | --- |
| body | (0,0) | (-2,-14,-6) | (11,11,12) | `CubeListBuilder.texOffs(0,0).mirror().addBox(...)` |
| furnace | (47,0) | (-9,-15,-7) | (7,12,14) | `texOffs(47,0).mirror().addBox(...)` |
| chassis | (0,27) | (-10,-3,-8) | (20,2,16) | `texOffs(0,27).mirror().addBox(...)` |
| wheels | (0,46) | (-9,-1,-7) | (18,1,14) | `texOffs(0,46).mirror().addBox(...)` |
| bumper | (65,46) | (9,-4,-6) | (1,4,12) | `texOffs(65,46).mirror().addBox(...)` |
| smokestack | (73,27) | (4,-18,-2) | (4,4,4) | `texOffs(73,27).mirror().addBox(...)` |

指定版 `sources/target/net/minecraft/client/model/MinecartModel.java:17–63` 改用 `ModelPart`／`MeshDefinition`／`PartDefinition`／`CubeListBuilder`／`LayerDefinition`；`sources/target/net/minecraft/client/model/geom/builders/CubeListBuilder.java:20–105` 有 `texOffs`、`mirror`、`addBox`，探針以相同六個盒、`PartPose.offset(0,5,0)` 和 `LayerDefinition.create(mesh,96,64)` 編譯成功。這只確認**宣告尺寸、座標與候選 API**；鏡像展 UV 的視覺等價、各面像素對位、黑邊與模型遮擋仍待 T-050 實作及 T-052 使用者檢查，不以 Java 編譯推定畫面正確。

## 渲染入口、姿態及 client 範圍

| OLD 入口／行為 | 指定版依據與候選 | 後續責任／未驗證處 |
| --- | --- | --- |
| `sources/old/setup/Render.java:26–27` 呼叫 `RenderingRegistry.registerEntityRenderingHandler` | `sources/target/net/neoforged/neoforge/client/event/EntityRenderersEvent.java:62–100` 的 `RegisterLayerDefinitions#registerLayerDefinition`、`RegisterRenderers#registerEntityRenderer`，配 `ModelLayerLocation` 及 `EntityRendererProvider.Context#bakeLayer`；探針兩事件方法可編譯 | T-019／T-050 在 client-only mod bus 接上正式 `simplerail:locomotive_cart` EntityType；探針用 `MinecartFurnace` 佔型別，沒有註冊到模組 |
| `sources/old/render/LocomotiveCartRender.java:24–91` 自訂 `MinecartRenderer` 主要 render 流程及六盒車頭 | 指定版 `sources/target/net/minecraft/client/renderer/entity/MinecartRenderer.java:22–109` 提供軌道插值、坡度、受損搖晃、display block 及模型繪製的新版來源；`MinecartRenderer` 的 `model` 欄位為 final 並在建構時建立 vanilla `MinecartModel`。探針使用 `EntityRenderer`＋獨立模型，只證入口／繪製簽名 | T-050 必須決定如何完整保留軌道姿態、受損、名稱與 display block；不能把探針 renderer 當成正式等價實作，也不能 `super.render` 後再加自訂模型造成雙層車體 |
| OLD `getTextureLocation`／`MatrixStack`／`IRenderTypeBuffer`／`IVertexBuilder`／`Vector3f` | 探針以指定版 `ResourceLocation.fromNamespaceAndPath`、`PoseStack`、`MultiBufferSource`、`VertexConsumer`、`Axis`、`ModelPart#render` 用法編譯 | 正式透明、光照、overlay、陰影、名稱標籤與 client reload 效果未執行 |
| OLD `setRenderDirection` 讀 `FACING`，八向設定 Y 軸角；EAST／SOUTH 另反轉坡度 Z 角 | 指定版 `PoseStack#mulPose(Axis.YP/ZP.rotationDegrees(...))` 候選；T-014 提供 server 授權 FACING 同步值，renderer 只讀。OLD Y 角：E 180°、W 0°、N -90°、S 90°、NE -135°、NW -45°、SE 135°、SW 45° | T-050 逐向移植、保留坡度反轉與變向時序；T-052 由使用者在平軌、轉角及坡道逐一看外觀。探針只示意 yaw，不代表八向已可用 |
| OLD `SimpleRail#doClientStuff` 在 client setup 呼叫 `Render.setup` | 指定版事件來源註明僅 logical client／mod bus；NEW 現有 `src/main/java/com/ericchiu/simplerail/SimpleRailClient.java` 以 `@Mod(..., dist=Dist.CLIENT)` 隔離 client 類別 | T-050 將模型、事件 listener、renderer 均置 client 範圍；T-017／正式 dedicated server build 及使用者 server 啟動排除 client class 載入錯誤。探針不證明正式模組隔離 |

## 後續可操作的畫面驗收（尚未執行）

固定版本測試包須列案例 ID、commit、JAR SHA-256、Minecraft／NeoForge 版本、九軌與車頭放置方式、各場景預期及 client／server log／截圖取得方法，實際結果欄留白。T-052 使用者以 NEW 新世界及正式功能版本檢查：九種軌道在透明處可見下方地形、不出現實心黑底；對應供電／反向／0–9 級變體選正確貼圖；車頭六盒、96×64 UV、八方向在平軌與坡道顯示不錯位；受損、轉彎、重新加入及雙 client 所見一致。車頭／貼圖尚未移植，本輪**沒有可供此案例操作的候選 JAR**；T-021／T-050 開發與 R-05 程式審查後，才由使用者依交接包測試，不能代填結果。

## 完成條件與待查證

| T-015 完成條件 | 本輪證據 | 判定邊界 |
| --- | --- | --- |
| 九軌 cutout 與資源引用有指定版候選 | OLD 九軌設定、指定版 deprecated 註記與官方 1.21.1 模型文件、`resources.json` 的 9／29／29 對照 | **來源與設計完成**；尚未遷移 JSON／atlas 或載入遊戲 |
| OLD `ModelRenderer` 與渲染註冊入口有候選及編譯證據 | OLD 六盒／八向表、指定版來源、探針 layer／bake／register／render 編譯退出 0 | **最小編譯完成**；未編譯正式實體 renderer，未執行探針 |
| 貼圖尺寸與 UV 以來源核對 | OLD texWidth／texHeight、六個 texOffs／盒尺寸、PNG 實測 96×64 與雜湊 | **靜態規格完成**；視覺等價待使用者遊戲驗收 |

待查證：正式 renderer 如何保留完整礦車路徑插值與坡度、模型鏡像 UV 在 NEW 烘焙後的方向、client resource reload、九軌所有變體的 atlas 與透明畫面、多人重新追蹤時的方向呈現及 dedicated server 實際載入。這些只影響對應 T-021／T-050／T-052 等後續實作與驗收，不把 T-015 的編譯結果稱作遊戲通過。
