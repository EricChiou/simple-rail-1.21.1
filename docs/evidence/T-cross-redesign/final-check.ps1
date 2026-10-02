$ErrorActionPreference='Stop'
$root=(Resolve-Path (Join-Path $PSScriptRoot '../../..')).Path
Set-Location $root
$p='docs/test-packages/T-cross-v1'
$manifest=Get-Content -Raw -Encoding UTF8 "$p/manifest.json" | ConvertFrom-Json
$results=Get-Content -Raw -Encoding UTF8 "$p/results.json" | ConvertFrom-Json
if((Get-FileHash "$p/mods/simplerail-1.0.0.jar" -Algorithm SHA256).Hash -ne $manifest.jarSha256){throw 'JAR SHA mismatch'}
if($results.cases.Count -ne 83 -or @($results.cases | Where-Object {$null -ne $_.actual}).Count -ne 0){throw 'manual results invalid'}
$inputs=Get-Content -Raw -Encoding UTF8 "$p/source-inputs.json" | ConvertFrom-Json
foreach($row in $inputs){if((Get-FileHash -LiteralPath $row.path -Algorithm SHA256).Hash -ne $row.sha256){throw "stale input $($row.path)"}}
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip=[IO.Compression.ZipFile]::OpenRead((Resolve-Path 'docs/test-packages/T-cross-v1.zip'))
try {
    foreach($file in Get-ChildItem $p -Recurse -File){
        $relative=$file.FullName.Substring((Resolve-Path $p).Path.Length+1).Replace('\','/')
        $entry=$zip.GetEntry($relative)
        if($null -eq $entry){throw "ZIP missing $relative"}
        $stream=$entry.Open(); $sha=[Security.Cryptography.SHA256]::Create()
        try{$hash=([BitConverter]::ToString($sha.ComputeHash($stream))).Replace('-','')}finally{$stream.Dispose();$sha.Dispose()}
        if($hash -ne (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash){throw "ZIP stale $relative"}
    }
}finally{$zip.Dispose()}
$s=Get-Content -Raw -Encoding UTF8 TASK.md
$matches=[regex]::Matches($s,'(?ms)^### (T-\d{3}) [^\n]+\r?\n(.*?)(?=^### |^## |\z)')
$ids=@($matches | ForEach-Object {$_.Groups[1].Value})
if($ids.Count -ne 126 -or ($ids | Sort-Object -Unique).Count -ne 126){throw 'task IDs changed'}
$graph=@{}; foreach($m in $matches){$d=[regex]::Match($m.Groups[2].Value,'(?m)^- 前置任務：([^\r\n]+)'); $graph[$m.Groups[1].Value]=@([regex]::Matches($d.Value,'T-\d{3}') | ForEach-Object {$_.Value})}
$vis=@{}
function Visit([string]$id){if($vis[$id] -eq 1){throw "cycle $id"}; if($vis[$id] -eq 2){return}; $vis[$id]=1; foreach($dep in $graph[$id]){if(!$graph.ContainsKey($dep)){throw "missing $dep"}; Visit $dep}; $vis[$id]=2}
foreach($id in $ids){Visit $id}
if([regex]::Matches($s,'(?m)^## 階段 [0-8]：').Count -ne 9){throw 'phase count changed'}
Write-Output "PASS fixed JAR/ZIP contents, $($inputs.Count) source SHA values, 83 blank manual cases, 126 tasks/9 phases/acyclic dependencies"
