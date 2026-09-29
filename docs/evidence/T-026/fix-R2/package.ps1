$ErrorActionPreference='Stop'
$taskEvidence=Join-Path (Get-Location) 'docs/evidence/T-026/fix-R2'
$bundle=Join-Path (Get-Location) 'docs/test-packages/T-026-R2-v1'
if(Test-Path -LiteralPath $bundle){throw 'Do not overwrite an existing frozen package'}
New-Item -ItemType Directory -Force $bundle,($bundle+'/mods'),($bundle+'/evidence')|Out-Null
$artifact=Get-Content -Raw -Encoding UTF8 (Join-Path $taskEvidence 'artifact.json')|ConvertFrom-Json
Copy-Item -LiteralPath $artifact.jar -Destination ($bundle+'/mods/simplerail-1.0.0.jar')
$cases=@(
    [ordered]@{id='R2-001';title='原反轉路線多次通過';expected='原有效供電坡底上坡不意外反轉';actual=$null},
    [ordered]@{id='R2-002';title='一般／動力／高速平軌進高速升坡';expected='三種接口皆可前進，包含高速接自身';actual=$null},
    [ordered]@{id='R2-003';title='高速平軌進一般／動力／高速升坡';expected='高速出格進坡不被坡頂支撐攔停或反向';actual=$null},
    [ordered]@{id='R2-004';title='連續高速升坡';expected='高一格下一升坡仍前進，坡頂不意外反向';actual=$null},
    [ordered]@{id='R2-005';title='四方向、設定邊界與正常制動回歸';expected='斜坡／畫面正常，平直最大值不被全域降速，正常回滾／未供電制動不被鎖方向';actual=$null},
    [ordered]@{id='R2-006';title='全原版對照';expected='記錄原版路線行為與是否同樣反轉，不推定高速修復效果';actual=$null},
    [ordered]@{id='R2-007';title='全平直接口對照';expected='無坡／彎道的各種軌道與高速接口不意外反轉；區分斜坡外問題';actual=$null}
)
$cases|ConvertTo-Json -Depth 5|Set-Content -Encoding UTF8 ($bundle+'/case-index.json')
[ordered]@{package='T-026-R2-v1';results=$cases;manualOverall=$null;confirmation='User text confirmation suffices; attachments optional';gameExecutedByAgent=$false}|ConvertTo-Json -Depth 6|Set-Content -Encoding UTF8 ($bundle+'/results.json')
[ordered]@{id='T-026-R2-v1';tasks=@('T-025 correction','T-026 partial retest');cases=@($cases|ForEach-Object {$_.id});head=$artifact.head;source='Uncommitted diff in evidence/source.diff and source-fingerprints.json';jar='mods/simplerail-1.0.0.jar';jarSha256=$artifact.sha256;minecraft='1.21.1';neoforge='21.1.251';mod='1.0.0';java='21';gradle='9.2.1';modDevGradle='2.0.147';parchment='2024.11.17';license='All Rights Reserved';migration=@('Section 3 shared rails/high_speed_rail','Section 6 stage 3');review=@('R-03 pending','R-F pending');manualHandoffReady=$false;reason='Independent code review pending; R2 user test not performed';priorUserResult='Slope subfeature confirmed; reversal still about 10%, including high-speed to itself; tested artifact not inferred';manualResult=$null;fullT094Completed=$false;gameStartedByAgent=$false;createdUtc=[DateTime]::UtcNow.ToString('o')}|ConvertTo-Json -Depth 5|Set-Content -Encoding UTF8 ($bundle+'/manifest.json')
@'
# T-026-R2-v1 局部修正與重測包

R2 只防護來源與數值模型可證的「高速跨進下一坡，未抬升就撞坡頂支撐」路徑；不是所有回報的根因證明。設定 0.4 的標準幾何沒有此碰撞，其他原因仍待確認。不宣稱已修復約 10% 的遊戲反轉。

使用者已確認斜坡子項通過；本包回歸結果仍空白，T-026 整項不通過、未結案。R-03／R-F 程式複查待完成，之後由使用者操作；不是完整 T-094，未啟動 Minecraft／GameTest 或 OLD build。

固定版本：Minecraft 1.21.1、NeoForge 21.1.251、Java 21、Simple Rail 1.0.0、All Rights Reserved。HEAD 與 JAR SHA-256 見 manifest.json；未提交來源差異及指紋在 evidence。不要同時安裝兩份 Simple Rail。只使用 NEW 新世界，不匯入 OLD。

步驟見 INSTALL.md／CASES.md。只須文字確認結果，不要求逐例紀錄、log 或截圖。結果表是選用；開發／Review 不代填。人工失敗後依具體場景修正，程式複查後再重測受影響案例。
'@|Set-Content -Encoding UTF8 ($bundle+'/README.md')
$install=[IO.File]::ReadAllText((Resolve-Path 'docs/test-packages/T-026-R1-v1/INSTALL.md'),[Text.Encoding]::UTF8).Replace('T026-R1','T026-R2')
[IO.File]::WriteAllText(($bundle+'/INSTALL.md'),$install,[Text.UTF8Encoding]::new($false))
@'
# R2 局部重測案例

所有遊戲操作由使用者執行，R-03／R-F 先審程式與覆蓋。每組均於單人及 dedicated server 連線環境觀察；不由 Agent 啟動或填結果。I-026-01 已通過的歷史保留，但本 JAR 的回歸仍待確認。固定版本見 manifest.json。

共同：創造／可用指令的新世界，用一般原版礦車，先只放一車、避免其他實體推擠。供電的動力／高速軌維持 powered=true；一般軌無 powered 欄位。用 F3 查看實際 shape，勿把上坡無供電／低動能正常回滾當成異常。設定 0.4／0.8／2.0 是最大值參數，並非實測速度；停機後在真正執行逻輯的 client／server COMMON 設定再重啟。速度量測／容差仍待技術定義。

幾何東向例：z=100，前段 x=100–107 y=65，升坡 x=108 y=65（ascending_east），上段 x=109–116 y=66；升坡坡頂支撐在 x=109 y=65。三段都有正常支撐。需要供電的段可用下方紅石方塊。礦車從至少四格連續供電高速軌之前起步，前段一般軌測例可在坡前接短一般軌。先確認連線 shape 有效再啟動車，不以手推在坡腳近乎靜止的车驗高速慣性案例。西／北／南鏡像，坡型須相應改變。

| ID | 操作與場景 | 預期／判定 |
| --- | --- | --- |
| R2-001 | 原來仍反轉的 NEW 路線，其他條件不改，只換本 JAR；反覆從足夠長的前段啟動，至少 30 次作偶發問題篩查。若路線含其他實體，再補單車乾淨對照 | 有效供電上坡無意外反轉。只說測過的範圍；30 次不是約 10% 已消失的統計保證，任何再現均保留問題未結案 |
| R2-002 | 坡底前一格分別為一般、動力、高速，第一升坡均高速。預設 0.8 重複各 30 次；補四方向及 0.4／2.0 設定觀察。保持先前已實作高速坡型 | 三種來源接高速皆持續上坡；尤其高速接自身，不只動力軌接口。記實際反轉位置／設定即可，不要求證據 |
| R2-003 | 前段高速、升坡依序一般／動力／高速；同 Y 的平軌進第一坡，坡頂有完整支撐。0.8 各重複 30 次，補方向及設定邊界 | 不因支撐碰撞停住再倒退；有足夠進坡動量的一般坡能通過，正常低動能情況另列 |
| R2-004 | 接連兩格或更多高速升坡，後一格比前一格高一格，例如 x=108 y=65、x=109 y=66 都 ascending_east，上平段從 x=110 y=67；全供電，0.8／2.0 多次各 30 | 跨至下一升坡及坡頂不意外反轉，R2 找下一軌 Y 不錯位；下坡回程也無新增卡住 |
| R2-005 | 以四方向重跑已通過的斜坡、供電／未供電貼圖；測平直高速三設定、載人／空車及下坡。另做未供電制動、上坡近靜止且不足動量對照 | 已有斜坡／模型不退化；平直未被全域固定降速，實測最大值待原量測規格；原版制動與低動能回滾保留，不鎖方向。不推定其他特殊軌道已實作 |
| R2-006 | 把相同問題路線改為全原版一般／動力軌對照，單車與相同支撐／供電，至少 30 次 | 如仍反轉，回報對照差異，不能把所有問題歸於高速；對照成功也不是 R2 已通過 |
| R2-007 | 額外建完全平坦無彎道、長直線供電高速軌；中間分別放一般／動力／高速接口，三設定、多次各 30 | 若反轉，代表不只上坡支撐路徑，需另查；若未發生，只記此對照，不倒填原路線根因 |

「30 次」為交付的建議篩查操作，無需提交逐次紀錄或附件；使用者對受影響案例確認即可記人工結果。失敗可回覆案例／哪個接口／是否平坦及當時有無載人，log／截圖選用。需要時 latest.log 位於 client/server 各自 logs；F2 截圖在 client screenshots，F3 可看目標 state；不要求提供檔案。結果不由開發或 Review 推定。

本包只覆盖本次反轉與回歸；速度完整量測、全部基底／實體破壞等 T-026 要求仍由 T-094 全量包承接，不取消任務或驗收。
'@|Set-Content -Encoding UTF8 ($bundle+'/CASES.md')
foreach($file in @('source.diff','source-fingerprints.json','artifact.json','primary-sources.json','numeric-test.json','numeric-test-01.log','AscentBoundaryTest.java','audit-results-02.json','build-01.json','build-01.log')){Copy-Item -LiteralPath (Join-Path $taskEvidence $file) -Destination ($bundle+'/evidence/'+$file)}
$files=@(Get-ChildItem $bundle -Recurse -File|ForEach-Object {[ordered]@{path=$_.FullName.Substring($bundle.Length+1).Replace('\','/');sha256=(Get-FileHash -LiteralPath $_.FullName).Hash}})
$files|ConvertTo-Json -Depth 4|Set-Content -Encoding UTF8 ($bundle+'/files-manifest.json')
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
$zipPath=$bundle+'.zip'
if(Test-Path -LiteralPath $zipPath){throw 'Do not overwrite a frozen ZIP'}
$archive=[IO.Compression.ZipFile]::Open($zipPath,[IO.Compression.ZipArchiveMode]::Create)
foreach($file in Get-ChildItem $bundle -Recurse -File){$relative=$file.FullName.Substring($bundle.Length+1).Replace('\','/');[IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive,$file.FullName,$relative)|Out-Null}
$archive.Dispose()
$archive=[IO.Compression.ZipFile]::OpenRead($zipPath)
$mismatches=@()
foreach($file in Get-ChildItem $bundle -Recurse -File){
    $relative=$file.FullName.Substring($bundle.Length+1).Replace('\','/');$entry=$archive.GetEntry($relative)
    if(-not $entry){$mismatches+=$relative;continue}
    $stream=$entry.Open();$sha=[Security.Cryptography.SHA256]::Create();$hash=[BitConverter]::ToString($sha.ComputeHash($stream)).Replace('-','');$stream.Dispose();$sha.Dispose()
    if($hash -ne (Get-FileHash -LiteralPath $file.FullName).Hash){$mismatches+=$relative}
}
$count=$archive.Entries.Count;$archive.Dispose()
[ordered]@{command='powershell -NoProfile -ExecutionPolicy Bypass -File docs/evidence/T-026/fix-R2/package.ps1';package=$zipPath;sha256=(Get-FileHash -LiteralPath $zipPath).Hash;files=$count;cases=$cases.Count;mismatches=$mismatches;review='pending';manualResults='null';fullT094Completed=$false;gameExecuted=$false}|ConvertTo-Json -Depth 5|Set-Content -Encoding UTF8 (Join-Path $taskEvidence 'package.json')
Write-Output ('Files='+$count+'; cases='+$cases.Count+'; mismatches='+$mismatches.Count)
if($mismatches.Count){exit 1}
