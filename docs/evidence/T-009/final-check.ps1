$ErrorActionPreference='Stop'
$root='D:\workspace\java\simple-rail-1.21.1'
Set-Location -LiteralPath $root
$ev=Join-Path $root 'docs/evidence/T-009'
$task=[IO.File]::ReadAllText((Join-Path $root 'TASK.md'))
$matches=[regex]::Matches($task,'(?ms)^### (T-\d{3}) [^\r\n]+\r?\n(.*?)(?=^### |^## |\z)')
$graph=@{}
$states=@{}
foreach($m in $matches){
 $id=$m.Groups[1].Value
 if($graph.ContainsKey($id)){throw "Duplicate $id"}
 $body=$m.Groups[2].Value
 $dep=[regex]::Match($body,'(?m)^- 前置任務：([^\r\n]+)').Groups[1].Value
 $graph[$id]=@([regex]::Matches($dep,'T-\d{3}') | ForEach-Object {$_.Value})
 $states[$id]=[regex]::Match($body,'(?m)^- 狀態：([^\r\n]+)').Groups[1].Value
 if(-not $states[$id]){throw "Missing state $id"}
}
if($graph.Count -ne 126){throw "Task count $($graph.Count)"}
foreach($n in 1..126){if(-not $graph.ContainsKey(('T-{0:000}' -f $n))){throw "Missing task $n"}}
$color=@{}
function Visit([string]$id){
 if($color[$id] -eq 1){throw "Dependency cycle $id"}
 if($color[$id] -eq 2){return}
 $color[$id]=1
 foreach($d in $graph[$id]){if(-not $graph.ContainsKey($d)){throw "Missing dependency $d"};Visit $d}
 $color[$id]=2
}
foreach($id in $graph.Keys){Visit $id}
$expectedDone=@('T-001','T-003','T-004','T-005','T-006','T-007')
foreach($id in $states.Keys){
 if($expectedDone -contains $id){if(-not $states[$id].StartsWith('已完成')){throw "Historical status changed $id"}}
 elseif($id -eq 'T-002'){if($states[$id] -ne '使用者決定免執行'){throw 'Waiver changed'}}
 elseif($id -in @('T-008','T-009')){if(-not $states[$id].StartsWith('開發完成')){throw 'T008 state'}}
 elseif($states[$id] -ne '待執行'){throw "Unexpected new state $id"}
}
$stageCounts=@([regex]::Matches($task,'(?ms)^## 階段 [0-8]：.*?(?=^## |\z)') | ForEach-Object {[regex]::Matches($_.Value,'(?m)^### T-\d{3} ').Count})
if(($stageCounts -join ',') -ne '4,17,8,18,16,26,23,8,6'){throw 'Stage counts'}
$files=@('MIGRATION.md','TASK.md','REVIEW.md','docs/evidence/T-009/README.md','docs/evidence/T-009/recipes.md')
$linkCount=0
foreach($rel in $files){
 $path=Join-Path $root $rel
 $text=[IO.File]::ReadAllText($path)
 foreach($r in [regex]::Matches($text,'T-\d{3}')){if(-not $graph.ContainsKey($r.Value)){throw "Bad reference $rel $($r.Value)"}}
 $fenced=$false
 $columns=0
 foreach($line in ($text -split '\r?\n')){
  if($line -match '^```'){$fenced=-not $fenced;continue}
  if($fenced){continue}
  if($line -match '^\|'){
   $c=[regex]::Matches($line,'(?<!\\)\|').Count
   if($columns -and $columns -ne $c){throw "Table column mismatch in $rel : $line"}
   $columns=$c
  }else{$columns=0}
 }
 if($fenced){throw "Unclosed fence $rel"}
 foreach($link in [regex]::Matches($text,'\[[^\]]*\]\(([^)]+)\)')){
  $target=$link.Groups[1].Value
  if($target -match '^(https?://|#)'){continue}
  $target=($target -split '#')[0]
  if(-not (Test-Path -LiteralPath (Join-Path (Split-Path $path) $target))){throw "Missing link $rel -> $target"}
  $linkCount++
 }
}
$sources=@(Get-Content -Encoding UTF8 (Join-Path $ev 'source-manifest.json') | ConvertFrom-Json)
$extra=Get-Content -Encoding UTF8 (Join-Path $ev 'extra-source-manifest.json') | ConvertFrom-Json
# Flatten ConvertFrom-Json arrays explicitly for Windows PowerShell.
$sources=Get-Content -Encoding UTF8 (Join-Path $ev 'source-manifest.json') | ConvertFrom-Json
$sources=@($sources)+@($extra)
if($sources.Count -ne 241){throw 'Source count'}
foreach($s in $sources){if((Get-FileHash -LiteralPath (Join-Path $ev $s.snapshot) -Algorithm SHA256).Hash -ne $s.sha256){throw "Source hash $($s.snapshot)"}}
$product=Get-Content -Encoding UTF8 (Join-Path $ev 'product-source-check.json') | ConvertFrom-Json
foreach($p in $product){if((Get-FileHash -LiteralPath $p.path -Algorithm SHA256).Hash -ne $p.expected){throw "Product changed $($p.path)"}}
$audit=Get-Content -Encoding UTF8 (Join-Path $ev 'static-audit.json') | ConvertFrom-Json
if($audit.exitCode -ne 0 -or $audit.failures.Count){throw 'Audit failed'}
$commands=Get-Content -Encoding UTF8 (Join-Path $ev 'audit-commands-2.json') | ConvertFrom-Json
if($commands.Count -ne 3 -or @($commands | Where-Object {$_.exitCode -ne 0}).Count){throw 'Command record failed'}
$diff=@(& git diff HEAD --name-only -- src build.gradle settings.gradle gradle.properties gradle gradlew gradlew.bat)
$diffExit=$LASTEXITCODE
if($diffExit -ne 0 -or $diff.Count){throw 'Product diff nonempty'}
$ErrorActionPreference='Continue'
& git diff --check 2>&1 | Out-File -Encoding utf8 (Join-Path $ev 'git-diff-check.log')
$checkExit=$LASTEXITCODE
$ErrorActionPreference='Stop'
if($checkExit -ne 0){throw 'Whitespace check'}
$indexTask=(& git show :TASK.md) -join "`n"
foreach($m in [regex]::Matches($indexTask,'(?ms)^### (T-\d{3}) [^\r\n]+\r?\n(.*?)(?=^### |^## |\z)')){
 $dep=[regex]::Match($m.Groups[2].Value,'(?m)^- 前置任務：([^\r\n]+)').Groups[1].Value
 $before=@([regex]::Matches($dep,'T-\d{3}')|ForEach-Object {$_.Value})
 if(($before -join ',') -ne ($graph[$m.Groups[1].Value] -join ',')){throw "Dependency changed $($m.Groups[1].Value)"}
}
$result=[ordered]@{
 command='& ([scriptblock]::Create((Get-Content -Raw -Encoding UTF8 docs/evidence/T-009/final-check.ps1)))'
 utc=[DateTime]::UtcNow.ToString('o');exitCode=0
 taskCount=$graph.Count;dependencyGraph='valid references, acyclic, unchanged from index';stageCounts=$stageCounts
 states=[ordered]@{historicalComplete=6;userWaived=1;developmentComplete=2;pending=117}
 localLinksChecked=$linkCount;markdown='table columns/fences valid';sourceSnapshotsVerified=$sources.Count
 productFilesUnchanged=$product.Count;productDiffExit=$diffExit;gitDiffCheckExit=$checkExit
 audit=[ordered]@{compileExit=$commands[1].exitCode;runExit=$commands[2].exitCode;jsonParsed=$audit.jsonParsed;directReferences=$audit.referencesChecked}
 documentHashes=@($files | ForEach-Object {[ordered]@{path=$_;sha256=(Get-FileHash -LiteralPath $_ -Algorithm SHA256).Hash}})
 scope='Document/evidence self-check only; no independent review, Minecraft load or game tests'
}
$result | ConvertTo-Json -Depth 6 | Set-Content -Encoding UTF8 (Join-Path $ev 'final-check.json')
$result | ConvertTo-Json -Depth 6
