$ErrorActionPreference='Stop'
$root='D:\workspace\java\simple-rail-1.21.1'
Set-Location -LiteralPath $root
$ev=Join-Path $root 'docs/evidence/T-008'
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
 elseif($id -eq 'T-008'){if(-not $states[$id].StartsWith('開發完成')){throw 'T008 state'}}
 elseif($states[$id] -ne '待執行'){throw "Unexpected new state $id"}
}
$stageCounts=@([regex]::Matches($task,'(?ms)^## 階段 [0-8]：.*?(?=^## |\z)') | ForEach-Object {[regex]::Matches($_.Value,'(?m)^### T-\d{3} ').Count})
if(($stageCounts -join ',') -ne '4,17,8,18,16,26,23,8,6'){throw 'Stage counts'}
$files=@('MIGRATION.md','TASK.md','REVIEW.md','docs/evidence/T-008/README.md')
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
$sources=Get-Content -Encoding UTF8 (Join-Path $ev 'source-manifest.json') | ConvertFrom-Json
if($sources.Count -ne 28){throw 'Source count'}
foreach($s in $sources){if((Get-FileHash -LiteralPath (Join-Path $ev $s.snapshot) -Algorithm SHA256).Hash -ne $s.sha256){throw "Source hash $($s.snapshot)"}}
$cp=Get-Content -Encoding UTF8 (Join-Path $ev 'classpath-manifest.json') | ConvertFrom-Json
foreach($c in $cp){if((Get-FileHash -LiteralPath $c.path -Algorithm SHA256).Hash -ne $c.sha256){throw "Classpath hash $($c.path)"}}
$product=Get-Content -Encoding UTF8 (Join-Path $ev 'product-source-check.json') | ConvertFrom-Json
foreach($p in $product){if((Get-FileHash -LiteralPath $p.path -Algorithm SHA256).Hash -ne $p.expected){throw "Product changed $($p.path)"}}
$classes=Get-Content -Encoding UTF8 (Join-Path $ev 'compiled-classes.json') | ConvertFrom-Json
foreach($c in $classes){
 if((Get-FileHash -LiteralPath $c.path -Algorithm SHA256).Hash -ne $c.sha256){throw "Compiled class changed $($c.path)"}
 $copy=Join-Path $ev ('compiled/evidence/t008/'+[IO.Path]::GetFileName($c.path))
 if((Get-FileHash -LiteralPath $copy -Algorithm SHA256).Hash -ne $c.sha256){throw "Class copy hash $copy"}
}
$diff=@(& git diff HEAD --name-only -- src build.gradle settings.gradle gradle.properties gradle gradlew gradlew.bat)
$diffExit=$LASTEXITCODE
if($diffExit -ne 0 -or $diff.Count){throw 'Product git diff failed or nonempty'}
$result=[ordered]@{
 command="& ([scriptblock]::Create((Get-Content -Raw -Encoding UTF8 docs/evidence/T-008/check-evidence.ps1)))"
 checkedUtc=[DateTime]::UtcNow.ToString('o'); exitCode=0
 taskCount=$graph.Count; dependencyGraph='all references exist; acyclic'; stageCounts=$stageCounts
 states=[ordered]@{historicalComplete=6;userWaived=1;developmentComplete=1;pending=118}
 localLinksChecked=$linkCount; markdown='table column counts and fences pass'
 sourceSnapshotsVerified=$sources.Count; classpathFilesVerified=$cp.Count; compiledClassesVerified=$classes.Count
 productFilesUnchanged=$product.Count; productDiffExitCode=$diffExit; productDiff=$diff
 documentHashes=@($files | ForEach-Object {[ordered]@{path=$_;sha256=(Get-FileHash -LiteralPath $_ -Algorithm SHA256).Hash}})
 scope='Evidence/document self-check only; no independent review or game execution'
}
$result | ConvertTo-Json -Depth 6 | Set-Content -Encoding UTF8 (Join-Path $ev 'final-check.json')
$result | ConvertTo-Json -Depth 6
