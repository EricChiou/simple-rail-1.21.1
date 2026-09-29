$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem
Add-Type -AssemblyName System.IO.Compression
$root = (Get-Location).Path
$evidence = Join-Path $root 'docs/evidence/T-092'
$head = (git rev-parse HEAD).Trim()
$artifact = Get-Content docs/evidence/T-022/artifact.json -Raw -Encoding utf8 | ConvertFrom-Json
$build = Get-Content docs/evidence/T-022/build-01.json -Raw -Encoding utf8 | ConvertFrom-Json
$fingerprints = Get-Content (Join-Path $evidence 'source-fingerprints.json') -Raw -Encoding utf8 | ConvertFrom-Json
foreach ($entry in $fingerprints) { if ((Get-FileHash -LiteralPath $entry.path).Hash -ne $entry.sha256) { throw 'Product changed since preparation' } }
$jarPath = (Resolve-Path 'docs/evidence/T-022/artifacts/simplerail-1.0.0.jar').Path
if ($build.exitCode -ne 0 -or (Get-FileHash $jarPath).Hash -ne $artifact.jarSha256) { throw 'Build/JAR evidence mismatch' }
$recipes = Get-Content docs/evidence/T-022/recipes.json -Raw -Encoding utf8 | ConvertFrom-Json
$ids = @($recipes | ForEach-Object { $_.id })
$blocks = @($ids | Where-Object { $_ -notin @('simplerail:wrench','simplerail:locomotive_cart') })
$rails = @($blocks | Where-Object { $_ -notin @('simplerail:train_dispenser','simplerail:signal_timer') })
$machines = @('simplerail:train_dispenser','simplerail:signal_timer')
$langs = @{}
foreach ($lang in @('en_us','zh_tw')) { $langs[$lang] = Get-Content ('src/main/resources/assets/simplerail/lang/' + $lang + '.json') -Raw -Encoding utf8 | ConvertFrom-Json }
$configText = [IO.File]::ReadAllText((Resolve-Path docs/evidence/T-020/config-contract.md), [Text.Encoding]::UTF8)
$configRows = @([regex]::Matches($configText, '(?m)^[|] `((?:cart|rail)[.][^`]+)` [|] ([^|]+) [|] ([^|]+) [|]') | ForEach-Object { [ordered]@{key=$_.Groups[1].Value; default=$_.Groups[2].Value.Trim(); domain=$_.Groups[3].Value.Trim()} })
if ($configRows.Count -ne 25 -or $ids.Count -ne 13 -or $blocks.Count -ne 11) { throw 'Inventory/config counts differ' }
function Crop-Pattern($pattern) {
    $rows = @($pattern | ForEach-Object { [string]$_ })
    $first = 0; $last = $rows.Count - 1
    while ($rows[$first].Trim().Length -eq 0) { $first++ }
    while ($rows[$last].Trim().Length -eq 0) { $last-- }
    $left = 3; $right = -1
    foreach ($row in $rows[$first..$last]) { for ($i=0; $i -lt $row.Length; $i++) { if ($row[$i] -ne ' ') { $left=[Math]::Min($left,$i); $right=[Math]::Max($right,$i) } } }
    return @($rows[$first..$last] | ForEach-Object { $_.Substring($left, $right-$left+1) })
}
$recipeCatalog = @($recipes | ForEach-Object { [ordered]@{id=$_.id; pattern=$_.pattern; croppedPattern=@(Crop-Pattern $_.pattern); ingredients=$_.ingredients; result=$_.result; expectedSource='OLD resource + fixed ShapedRecipePattern/Ingredient source; not game tested'} })
$versions = [ordered]@{minecraft='1.21.1'; neoForge='21.1.251'; mod='1.0.0'; modId='simplerail'; license='All Rights Reserved'; javaMajor=21; buildJava='Temurin 21.0.12.1+1'; gradle='9.2.1'; modDevGradle='2.0.147'; parchmentMinecraft='1.21.1'; parchmentMappings='2024.11.17'}
$outputs = @()
foreach ($spec in @(
    @{task='T-092'; manual='T-023'; package='T-092-v1-draft'; draft=$true; base=@('C-001','C-002','C-003','C-004'); guide='docs/evidence/T-092/CASE_GUIDE.md'},
    @{task='T-093'; manual='T-024'; package='T-093-v1'; draft=$false; base=@('C-005','C-006'); guide='docs/evidence/T-093/CASE_GUIDE.md'}
)) {
    $packageRoot = Join-Path $root ('docs/test-packages/' + $spec.package)
    $zipPath = $packageRoot + '.zip'
    if (Test-Path -LiteralPath $packageRoot) { throw ('Frozen package already exists: ' + $packageRoot) }
    $jarRelative = if ($spec.draft) { 'reference/simplerail-1.0.0.jar' } else { 'mods/simplerail-1.0.0.jar' }
    New-Item -ItemType Directory -Force (Join-Path $packageRoot (Split-Path $jarRelative)), (Join-Path $packageRoot 'evidence') | Out-Null
    Copy-Item -LiteralPath $jarPath -Destination (Join-Path $packageRoot $jarRelative)
    Copy-Item docs/evidence/T-092/INSTALL.md (Join-Path $packageRoot 'INSTALL.md')
    Copy-Item -LiteralPath $spec.guide -Destination (Join-Path $packageRoot 'CASES.md')
    foreach ($name in @('source.diff','source-fingerprints.json','build-01.json','build-01.log','artifact.json','jar-contents.txt','neoforge.mods.toml','audit-results.json','audit-classpath.json','audit-commands-01.json','java-version.log','javac-version.log','gradle-version.log','data-map.json','loot-responsibility.json')) { Copy-Item -LiteralPath (Join-Path $evidence $name) -Destination (Join-Path $packageRoot ('evidence/' + $name)) }
    Copy-Item docs/evidence/T-022/audit-run-01.log (Join-Path $packageRoot 'evidence/audit-run-01.log')
    Copy-Item docs/evidence/T-020/test-results.json (Join-Path $packageRoot 'evidence/config-static-tests-reference.json')
    Copy-Item docs/evidence/T-021/audit-results.json (Join-Path $packageRoot 'evidence/resource-static-audit-reference.json')
    Copy-Item docs/evidence/T-092/state-coverage-reference.json (Join-Path $packageRoot 'evidence/state-coverage-reference.json')
    Copy-Item docs/evidence/T-092/default-config-reference.toml (Join-Path $packageRoot 'default-config-reference.toml')
    Copy-Item docs/evidence/T-010/state-domains.json (Join-Path $packageRoot 'STATE-DOMAINS.json')
    $recipeCatalog | ConvertTo-Json -Depth 8 | Set-Content -Encoding utf8 (Join-Path $packageRoot 'RECIPE-CATALOG.json')
    $cases = [Collections.Generic.List[object]]::new()
    function Case([string]$id,[string]$base,[string]$env,[string]$subject,[string[]]$steps,[string[]]$expected,[string[]]$issues=@()) {
        $cases.Add([ordered]@{caseId=$id; sourceCase=$base; environment=$env; subject=$subject; prerequisites=@('R-02 審查指定包通過','新建 NEW 世界，不匯入 OLD') + $(if ($spec.draft) {'新版包解除 I-021-01／I-092-02；此草稿不安裝'} else {'T-023 使用者驗收通過（T-024 的正式前置）'}); steps=$steps; expected=$expected; expectedSource='MIGRATION §3/§4.1/§4.4/§6 階段2；T-004；T-019/T-020/T-021/T-022 + fixed command sources；OLD 依原始碼推定／待確認'; localIssues=$issues; status='未執行'; actualResult=$null; optionalEvidence='client/server logs/latest.log、F2 screenshots、實際現象；人工確認即可結案'; guide='CASES.md'})
    }
    foreach ($env in @('SP','DS')) {
        if ($spec.draft) {
            foreach ($id in $ids) { Case ("T023-C001-$env-" + $id.Split(':')[1]) 'C-001' $env $id @("/give @s $id 1",'F3+H 比 ID；創造分頁核對該項及順序／圖示') @('取得同 ID 物品，分頁無範例或額外 reverse 物品','完整分頁僅 13 項，圖示 high_speed_rail') }
            foreach ($id in $blocks) { Case ("T023-C002-$env-" + $id.Split(':')[1]) 'C-002' $env $id @('依承接方案单獨放置；F3 讀預設','依 STATE-DOMAINS.json 全鍵值／selector 做受控設置、讀回與外觀核對；設置／保持方式尚待承接定義') @('正式 default／值域與已定契約相符，不漏 slope／up/down','無未知 property 或缺模型變體') @('I-021-01','正式預設與受控狀態觀測方法待承接定義') }
            foreach ($config in $configRows) { Case ("T023-C003-$env-" + $config.key) 'C-003' $env $config.key @('新目錄生成 COMMON 檔，讀該鍵預設','停止後改合法兩端；新啟動與運行中改檔分開','用待定只讀觀測方式確認有效 snapshot／reload；DS 與 client 異值比較 server 權威') @('預設 ' + $config.default, '域 ' + $config.domain, 'runtime 有效值符合當次快照；檔案存在不等於生效') @('I-092-02') }
            foreach ($lang in @('en_us','zh_tw')) {
                foreach ($id in $ids) {
                    $key = if ($blocks -contains $id) { 'block.simplerail.' + $id.Split(':')[1] } else { 'item.simplerail.' + $id.Split(':')[1] }
                    Case ("T023-C004-$env-$lang-" + $id.Split(':')[1]) 'C-004' $env $id @("切語系 $lang，讀物品／方塊名稱",'單放適用方塊，依完整模型矩陣看透明／變體，F3+T 後再讀') @('名稱 ' + $langs[$lang].$key,'有效圖示／引用，無 missing texture/model／未知 property；entity renderer 不在本項') $(if ($blocks -contains $id) { @('I-021-01') } else { @() })
                }
                Case "T023-C004-$env-$lang-tab" 'C-004' $env 'simplerail:tab' @("切語系 $lang，查看分頁") @('名稱 Simple Rail，圖示 high_speed_rail，13 項順序見 TABLES')
            }
            Case "T023-C004-$env-reload" 'C-004' $env 'pack／metadata／logo' @('Mods 頁核版號／logo／授權','F3+T 與 /reload 分開，看各端 log') @('D8 版本／原 logo 正確','無本模組 atlas／resource／data／JSON／registry 錯誤') @('I-021-01')
        } else {
            foreach ($recipe in $recipeCatalog) {
                foreach ($mode in @('original','offset','mirror')) { Case ("T024-C005-$env-" + $recipe.id.Split(':')[1] + '-' + $mode) 'C-005' $env $recipe.id @("按 RECIPE-CATALOG 與 TABLES 以 $mode 網格放材料，每格 1 件",'生存取一次結果，不 Shift-click；檢查輸入扣除') @('result ' + $recipe.result.id + ' x' + $recipe.result.count,'所有非空格消耗 1 原材料，無額外產出／工具退還') }
            }
            foreach ($id in @('wrench','destory_rail')) { Case "T024-C005-$env-$id-damaged-tool" 'C-005' $env "simplerail:$id" @('生存使用 iron_pickaxe 採石至有損傷','用該鎬按原配方取一次結果') @('仍可合成原 ID／產量且消耗鎬；一般 ingredient.item 只比物品種類') }
            foreach ($id in $blocks) {
                foreach ($mode in @('iron_pickaxe','hand','loot-mine','explosion')) {
                    $steps = if ($mode -eq 'loot-mine') { @("/setblock 0 65 0 $id",'/loot spawn ~ ~1 ~ mine 0 65 0 minecraft:iron_pickaxe','計數唯一對照掉落，不再挖同一目標混計') } elseif ($mode -eq 'explosion') { @('單獨場景放目標／TNT；先清掉落，doTileDrops=true','引爆；若目標未破壞則另场景重做，不算 loot 判定') } else { @("單放 $id，生存 doTileDrops=true", "用 $mode 完整破壞，前後計數") }
                    $expected = if ($mode -eq 'explosion') { @("目標真的破壞後，同 ID $id 可 0 或 1 件，不要求固定機率",'無其他 ID／超過单件／loot context 錯誤') } else { @("同 ID $id 恰 1 件，不因 destory recipe count 改掉落量", $(if ($mode -eq 'loot-mine') {'指令產掉落、目標仍在'} else {'正常破壞、無重複掉落'})) }
                    Case ("T024-C006-$env-" + $id.Split(':')[1] + '-' + $mode) 'C-006' $env $id $steps $expected
                }
            }
            foreach ($tag in @('simplerail:rails','simplerail:machines','minecraft:rails')) {
                $members = if ($tag -eq 'simplerail:machines') { $machines } elseif ($tag -eq 'minecraft:rails') { $rails + @('minecraft:rail','minecraft:powered_rail','minecraft:detector_rail','minecraft:activator_rail') } else { $rails }
                foreach ($id in $members) {
                    $steps = @("/setblock 0 65 0 $id", "/execute if block 0 65 0 #$tag run say MATCH")
                    if ($tag -eq 'simplerail:rails') { $steps += '/execute unless block 0 65 0 #simplerail:machines run say NOT_MACHINE' }
                    if ($tag -eq 'simplerail:machines') { $steps += '/execute unless block 0 65 0 #simplerail:rails run say NOT_RAIL' }
                    Case ("T024-TAG-$env-" + $tag.Replace(':','-') + '-' + $id.Replace(':','-')) 'C-006' $env $tag $steps @('正向 MATCH；適用反向不誤列','minecraft:rails 保留 4 vanilla + 9 自訂，replace=false')
                }
            }
            foreach ($id in @('simplerail:wrench','minecraft:stick')) {
                $condition = if ($id -eq 'simplerail:wrench') {'if'} else {'unless'}
                Case ("T024-TAG-$env-wrench-" + $id.Replace(':','-')) 'C-006' $env 'simplerail:wrench/item' @("/give @s $id 1，將它放主手", "/execute $condition items entity @s weapon.mainhand #simplerail:wrench run say EXPECTED") @('wrench 屬於 item tag，stick 不屬於；不建立 wrench block')
            }
            Case "T024-RELOAD-$env" 'C-005/C-006' $env '資料 reload' @('/reload；確認成功並看 server log','重做該環境原網格13配方、11 loot-mine及所有 tag 成員案例') @('前後內容／產量／成員不變','無本模組 recipe/tag/loot/registry/context 或 JSON 錯誤')
            Case "T024-EXTRA-LOOT-$env" 'C-006' $env 'simplerail:blocks/locomotive_cart' @('/reload，觀察 loader/context log','審責任表，不對不存在車頭方塊執行 mine，不將任意 loot 命令冒充實體 destroy') @('表 ID 保留，entity context 無舊 explosion condition 警告','車頭 Java destroy／無雙重掉落仍由 T-048/T-052/T-062 與對應包驗收')
        }
    }
    $cases | ConvertTo-Json -Depth 8 | Set-Content -Encoding utf8 (Join-Path $packageRoot 'case-index.json')
    $table = [Collections.Generic.List[string]]::new()
    $table.Add('# 固定名冊、資料與配置參考'); $table.Add(''); $table.Add('原資料／候選域參考，不是 runtime dump。所有 case-index 案例在 SP／DS 各做；人工確認即可結案，附件選用。'); $table.Add('')
    $table.Add('## 13 物品與 11 方塊'); $table.Add(''); $table.Add('| ID | 方塊 | en_us | zh_tw |'); $table.Add('| --- | --- | --- | --- |')
    foreach ($id in $ids) {
        $key = if ($blocks -contains $id) {'block.simplerail.' + $id.Split(':')[1]} else {'item.simplerail.' + $id.Split(':')[1]}
        $table.Add('| ' + $id + ' | ' + $(if ($blocks -contains $id) {'是'} else {'否'}) + ' | ' + $langs.en_us.$key + ' | ' + $langs.zh_tw.$key + ' |')
    }
    $table.Add(''); $table.Add('分頁順序：high_speed_rail、holding_rail、oneway_rail、eject_rail、destory_rail、timer_holding_rail、cross_rail、y_cross_rail、y_cross_right_rail、train_dispenser、signal_timer、wrench、locomotive_cart；分頁 simplerail:tab，兩語系名 Simple Rail。'); $table.Add('')
    $table.Add('## 13 配方'); $table.Add(''); $table.Add('工作台每格放 1 原材料；·＝空格。原 3×3 與裁空邊網格均保留在 RECIPE-CATALOG.json；offset／mirror 依裁邊網格操作。'); $table.Add('')
    foreach ($recipe in $recipeCatalog) {
        $table.Add('### ' + $recipe.id); $table.Add(''); $table.Add('```text'); foreach ($row in $recipe.pattern) { $table.Add(([string]$row).Replace(' ','·')) }; $table.Add('```'); $table.Add('')
        $binding = @($recipe.ingredients.PSObject.Properties | ForEach-Object { $_.Name + '=' + $_.Value.item }) -join '；'
        $table.Add($binding + '；結果 ' + $recipe.result.id + ' × ' + $recipe.result.count + '。'); $table.Add('')
    }
    $table.Add('## 25 設定（有效值觀測受 I-092-02 限制）'); $table.Add(''); $table.Add('| key | default | domain |'); $table.Add('| --- | --- | --- |')
    foreach ($config in $configRows) { $table.Add('| ' + $config.key + ' | ' + $config.default + ' | ' + $config.domain + ' |') }
    $table.Add(''); $table.Add('level 組內「同上」是 0..2147483647 int 秒；disableLoadingChunk 的 true＝啟用不改，D3 保持 true。檔案參考不是 FML 已生成實測。'); $table.Add('')
    $table.Add('## State、loot 與 tag'); $table.Add(''); $table.Add('STATE-DOMAINS.json＝T-010 完整候選域，evidence/state-coverage-reference.json＝T-021 未覆蓋變體。正式 StateDefinition／defaults 未齊，不能稱全狀態可選。11 block 表同名掉落 1；額外 entity loot 不附掛。rails 9／machines 2／wrench 1，minecraft:rails 加 9 自訂但保留 4 vanilla。');
    $table | Set-Content -Encoding utf8 (Join-Path $packageRoot 'TABLES.md')
    $readme = @(('# ' + $spec.package), '', $(if ($spec.draft) {'**受阻審查草稿，不安裝／不交使用者驗 T-023。** reference JAR 僅固定現況，I-021-01 與 I-092-02 未解除，需新版包。'} else {'**開發包已製作；R-02 待審，T-024 仍等待 T-023。現在不開始人工測試。** 此包不是人工通過或功能交付完成。'}), '', '只由使用者操作 Minecraft，全部 actualResult=null。INSTALL.md、CASES.md、TABLES.md、case-index.json 為完整操作／索引；results.json 選用，確認任務完成即可結案、不要求附件。', '', ('固定 JAR SHA-256：`' + $artifact.jarSha256 + '`；來源 HEAD `'+$head+'` 加 staged／未提交差異，evidence/source.diff 包含 HEAD 差異與全部 untracked 產品檔，未虛構新 commit。'), '', '使用 T-022 真實 build 退出 0（本輪不重跑）；test NO-SOURCE。393 資料／159 設定／2519 資源檢查是既有非遊戲證據，不能簽本包 runtime 或 R-02。', '', '失敗後：開發修正→Review 只審程式→使用者重測；新 JAR 產新版包，不覆寫本包。車頭實體／BE／GUI／計時／區塊票證等功能未完成，不以現況取代 D1–D8。')
    $readme | Set-Content -Encoding utf8 (Join-Path $packageRoot 'README.md')
    $manifest = [ordered]@{packageId=$spec.package; createdUtc=[DateTime]::UtcNow.ToString('o'); developerTask=$spec.task; manualTask=$spec.manual; developerStatus=$(if ($spec.draft) {'受阻；固定審查草稿'} else {'開發完成'}); manualHandoffReady=$false; prerequisites=$(if ($spec.draft) {@('I-021-01','I-092-02','R-02','新版可操作包')} else {@('R-02 指定版程式審查通過','T-023 使用者確認通過')}); cases=@($cases | ForEach-Object {$_.caseId}); sourceCases=$spec.base; review=@{id='R-02'; status='待審'; conclusion=$null; gameTestAuthority='使用者'}; migration=@('§3 註冊/物品/設定/配方與資料/渲染','§4.1','§4.4','D1–D8','§6 階段2'); head=$head; cleanCommit=$false; productDiff='evidence/source.diff'; sourceFingerprints='evidence/source-fingerprints.json'; jar=@{path=$jarRelative; sha256=$artifact.jarSha256; role=$(if ($spec.draft) {'review reference only; not T-023 playable package'} else {'fixed T-024 test artifact; handoff gated'})}; versions=$versions; build=@{originTask='T-022'; command=$build.command; startedUtc=$build.startedUtc; exitCode=$build.exitCode; log='evidence/build-01.log'; newBuildExecuted=$false; test='NO-SOURCE'; gameStarted=$false}; install='INSTALL.md'; scenarios='CASES.md'; index='case-index.json'; optionalEvidence='client/server logs/latest.log、F2 screenshots、選用 results.json'; requiredUserReply='只需任務 ID 與完成／通過或失敗確認；附件與逐例資料選用'; actualResult=$null; issues=$(if ($spec.draft) {@('I-021-01','I-092-02')} else {@('T-023 尚未通過；I-021-01 未解','R-02 待審')})}
    $manifest | ConvertTo-Json -Depth 9 | Set-Content -Encoding utf8 (Join-Path $packageRoot 'manifest.json')
    [ordered]@{packageId=$spec.package; userConfirmation=$null; actualVersion=$null; cases=@($cases | ForEach-Object {@{caseId=$_.caseId; status='未填（未執行）'; actualResult=$null}}); note='選用；使用者整項確認即可人工結案，Agent 不代填'} | ConvertTo-Json -Depth 6 | Set-Content -Encoding utf8 (Join-Path $packageRoot 'results.json')
    $files = @(Get-ChildItem -LiteralPath $packageRoot -Recurse -File | Sort-Object FullName | ForEach-Object { [ordered]@{path=$_.FullName.Substring($packageRoot.Length+1).Replace('\','/'); sha256=(Get-FileHash -LiteralPath $_.FullName).Hash} })
    $files | ConvertTo-Json -Depth 4 | Set-Content -Encoding utf8 (Join-Path $packageRoot 'files-manifest.json')
    $zip = [IO.Compression.ZipFile]::Open($zipPath,[IO.Compression.ZipArchiveMode]::Create)
    try {
        foreach ($file in Get-ChildItem -LiteralPath $packageRoot -Recurse -File) {
            $entry = $zip.CreateEntry($file.FullName.Substring($packageRoot.Length+1).Replace('\','/'),[IO.Compression.CompressionLevel]::Optimal)
            $input = [IO.File]::OpenRead($file.FullName); $output = $entry.Open()
            try {$input.CopyTo($output)} finally {$input.Dispose();$output.Dispose()}
        }
    } finally {$zip.Dispose()}
    $outputs += [ordered]@{task=$spec.task; package=$spec.package; zip=('docs/test-packages/' + $spec.package + '.zip'); zipSha256=(Get-FileHash $zipPath).Hash; jarSha256=$artifact.jarSha256; cases=$cases.Count; files=$files.Count+1; developerStatus=$manifest.developerStatus; manualHandoffReady=$false; gameStarted=$false}
}
$outputs | ConvertTo-Json -Depth 6 | Set-Content -Encoding utf8 (Join-Path $evidence 'packages.json')
Copy-Item (Join-Path $evidence 'packages.json') docs/evidence/T-093/packages.json
foreach ($entry in $fingerprints) { if ((Get-FileHash -LiteralPath $entry.path).Hash -ne $entry.sha256) { throw 'Product changed during packaging' } }
$outputs | ConvertTo-Json -Depth 4
