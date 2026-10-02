$ErrorActionPreference='Stop'
$root=(Get-Location).Path
$ev=Join-Path $root 'docs/evidence/T-037'
$pkg=Join-Path $root 'docs/test-packages/T-037-v1'
$checks=[Collections.Generic.List[object]]::new()
function Check($ok,$label) { $checks.Add([ordered]@{check=$label;passed=[bool]$ok}); if(!$ok){throw "Audit failed: $label"} }
function Sha($path) { (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash }
function ReadUtf8($path) { [IO.File]::ReadAllText($path,[Text.Encoding]::UTF8) }
function SaveJson($path,$data) { $data | ConvertTo-Json -Depth 9 | Set-Content -LiteralPath $path -Encoding UTF8 }
function ZipMap($path) {
 $zip=[IO.Compression.ZipFile]::OpenRead($path); $map=@{}
 try { foreach($entry in $zip.Entries) {
  if($entry.FullName.EndsWith('/')){continue}
  Check (!$map.ContainsKey($entry.FullName)) ('No duplicate entry: '+$entry.FullName)
  $stream=$entry.Open();$sha=[Security.Cryptography.SHA256]::Create()
  try {$map[$entry.FullName]=([BitConverter]::ToString($sha.ComputeHash($stream))).Replace('-','')}finally{$sha.Dispose();$stream.Dispose()}
 }}finally{$zip.Dispose()}; return ,$map
}
function Tasks($path) {
 $map=@{}
 foreach($match in [regex]::Matches((ReadUtf8 $path),'(?ms)^### (T-\d{3}) ([^\r\n]+)\r?\n(.*?)(?=^### T-\d{3} |^## |\z)')) {
  $id=$match.Groups[1].Value;$body=$match.Groups[3].Value
  Check (!$map.ContainsKey($id)) ('Unique task '+$id)
  $line=[regex]::Match($body,'(?m)^- 前置任務：([^\r\n]*)').Groups[1].Value
  $deps=@([regex]::Matches($line,'T-\d{3}') | ForEach-Object {$_.Value})
  $state=[regex]::Match($body,'(?m)^- 狀態：([^\r\n]*)').Groups[1].Value
  $map[$id]=[ordered]@{id=$id;title=$match.Groups[2].Value;deps=$deps;state=$state}
 }; return ,$map
}
try {
 Add-Type -AssemblyName System.IO.Compression.FileSystem
 $before=Get-Content (Join-Path $ev 'product-before.json') -Raw -Encoding UTF8 | ConvertFrom-Json
 foreach($file in $before){Check ((Sha (Join-Path $root $file.path)) -eq $file.sha256) ('Production unchanged: '+$file.path)}
 $now=@(& rg --files src gradle)+@('build.gradle','settings.gradle','gradle.properties','gradlew','gradlew.bat','.gitignore')
 Check (($now.Count -eq $before.Count) -and !(Compare-Object @($before.path|Sort-Object) @($now|Sort-Object))) 'Production file set unchanged'
 $cached=@(& git diff --cached --binary)
 Check ($LASTEXITCODE -eq 0) 'git diff --cached exit 0'
 [IO.File]::WriteAllText((Join-Path $ev 'index-after.diff'),($cached -join "`n"),[Text.UTF8Encoding]::new($false))
 Check ((Sha (Join-Path $ev 'index-before.diff')) -eq (Sha (Join-Path $ev 'index-after.diff'))) 'Index unchanged'
 & git status --short | Set-Content (Join-Path $ev 'status-after.txt') -Encoding UTF8
 Check ($LASTEXITCODE -eq 0) 'git status exit 0'
 $oldPaths=@{ 'TimerHoldingRailTileEntity.java'='tileentity/TimerHoldingRailTileEntity.java';'TimerHoldingRail.java'='block/TimerHoldingRail.java';'CommonConfig.java'='config/CommonConfig.java';'TileEntities.java'='registry/TileEntities.java' }
 foreach($name in $oldPaths.Keys){Check ((Sha (Join-Path $ev ('sources/old/'+$name))) -eq (Sha ('D:/workspace/java/simple-rail/src/main/java/ericchiu/simplerail/'+$oldPaths[$name]))) ('OLD source snapshot matches '+$name)}
 foreach($file in (Get-Content (Join-Path $ev 'input-fingerprints.json') -Raw -Encoding UTF8|ConvertFrom-Json)){Check ((Sha (Join-Path $root $file.path)) -eq $file.sha256) ('Input fingerprint '+$file.path)}
 $normal=ZipMap (Join-Path $ev 'artifacts/simplerail-1.0.0.jar')
 $probe=ZipMap (Join-Path $ev 'artifacts/simplerail-1.0.0-T037-probe.jar')
 $overrides=@('com/ericchiu/simplerail/SimpleRail.class','com/ericchiu/simplerail/registry/ModBlocks.class','META-INF/neoforge.mods.toml','META-INF/MANIFEST.MF')
 foreach($name in $normal.Keys){Check ($probe.ContainsKey($name)) ('Probe retains '+$name);if($name -notin $overrides){Check ($normal[$name] -eq $probe[$name]) ('Unchanged JAR entry '+$name)}}
 $added=@($probe.Keys | Where-Object {!$normal.ContainsKey($_)})
 foreach($name in $added){Check ($name.StartsWith('evidence/t037/') -and $name.EndsWith('.class')) ('Only fixture class added: '+$name)}
 Check (!$probe.ContainsKey('evidence/t037/TimerInvestigationTest.class')) 'Test main excluded from diagnostic JAR'
 Check ((Sha (Join-Path $ev 'artifacts/simplerail-1.0.0.jar')) -eq '3AB3E37EF4AA21342011332E9531088DB36D121A1F6C9C9823DD6B3259538594') 'Normal JAR still R-03 artifact'
 $jarZip=[IO.Compression.ZipFile]::OpenRead((Join-Path $ev 'artifacts/simplerail-1.0.0-T037-probe.jar'))
 try {$reader=[IO.StreamReader]::new($jarZip.GetEntry('META-INF/neoforge.mods.toml').Open());try{$metadata=$reader.ReadToEnd()}finally{$reader.Dispose()}}finally{$jarZip.Dispose()}
 foreach($value in @('displayName="Simple Rail [T037 diagnostic]"','modId="simplerail"','version="1.0.0"','All Rights Reserved','21.1.251','1.21.1')) {Check ($metadata.Contains($value)) ('Diagnostic metadata '+$value)}
 $manifest=Get-Content (Join-Path $pkg 'manifest.json') -Raw -Encoding UTF8|ConvertFrom-Json
 Check ((Sha (Join-Path $pkg $manifest.jar)) -eq $manifest.jarSha256) 'Package JAR hash'
 Check ($manifest.jarSha256 -eq 'AAF9977E094981A481305DCDCF6C60694931FFD3483A29C9A6A5B31BB10415C7') 'Fixed diagnostic JAR hash'
 $files=Get-Content (Join-Path $pkg 'files-manifest.json') -Raw -Encoding UTF8|ConvertFrom-Json
 foreach($file in $files){Check ((Sha (Join-Path $pkg $file.path)) -eq $file.sha256) ('Package file '+$file.path)}
 $zipMap=ZipMap ($pkg+'.zip')
 foreach($file in $files){Check ($zipMap[$file.path] -eq $file.sha256) ('ZIP file '+$file.path)}
 Check ($zipMap['files-manifest.json'] -eq (Sha (Join-Path $pkg 'files-manifest.json'))) 'ZIP manifest hash'
 Check ($zipMap.Count -eq ($files.Count+1)) 'ZIP exact entry set'
 $results=Get-Content (Join-Path $pkg 'results.json') -Raw -Encoding UTF8|ConvertFrom-Json
 Check ($null -eq $results.userConfirmation -and $null -eq $results.recordedDate) 'User confirmation empty'
 Check ($results.cases.Count -eq 13) '13 manual case variants'
 foreach($case in $results.cases){Check ($null -eq $case.actual -and $null -eq $case.result) ('Manual result empty '+$case.id);Check ((ReadUtf8 (Join-Path $pkg 'CASES.md')).Contains($case.id.Substring(0,7))) ('Case steps present '+$case.id)}
 $tasks=Tasks (Join-Path $root 'TASK.md');$oldTasks=Tasks (Join-Path $ev 'before/TASK.md')
 Check ($tasks.Count -eq 126 -and $oldTasks.Count -eq 126) '126 tasks retained'
 foreach($i in 1..126) {
  $id='T-{0:D3}' -f $i;Check ($tasks.ContainsKey($id)) ('Task exists '+$id)
  Check (($tasks[$id].deps -join ',') -eq ($oldTasks[$id].deps -join ',')) ('Dependencies unchanged '+$id)
  if($id -ne 'T-037'){Check ($tasks[$id].state -eq $oldTasks[$id].state) ('Task state unchanged '+$id)}
  foreach($dep in $tasks[$id].deps){Check ($tasks.ContainsKey($dep)) ('Dependency exists '+$id+' -> '+$dep)}
 }
 Check ($tasks['T-037'].state -eq '開發完成') 'T-037 development complete'
 Check ($tasks['T-119'].state -eq '待執行') 'T-119 still pending'
 $colors=@{}
 function Visit($id) {
  if($colors[$id] -eq 1){throw ('Dependency cycle at '+$id)}
  if($colors[$id] -eq 2){return};$colors[$id]=1
  foreach($dep in $tasks[$id].deps){Visit $dep};$colors[$id]=2
 }
 foreach($id in $tasks.Keys){Visit $id};Check ($colors.Count -eq 126) 'Dependency graph acyclic'
 $phaseParts=[regex]::Matches((ReadUtf8 (Join-Path $root 'TASK.md')),'(?ms)^## 階段 ([0-8])：.*?(?=^## 階段 [0-8]：|\z)')
 Check ($phaseParts.Count -eq 9) 'Nine phases'
 $phaseCounts=@($phaseParts|ForEach-Object{[regex]::Matches($_.Value,'(?m)^### T-\d{3} ').Count})
 Check (($phaseCounts -join ',') -eq '4,17,8,18,16,26,23,8,6') 'Phase counts unchanged'
 $states=@($tasks.Values|Group-Object state|ForEach-Object{[ordered]@{state=$_.Name;count=$_.Count}})
 Check (@($tasks.Values|Where-Object{$_.state -like '開發完成*'}).Count -eq 24) '24 development complete'
 Check (@($tasks.Values|Where-Object{$_.state -eq '待執行'}).Count -eq 78) '78 pending'
 $docPaths=@('TASK.md','MIGRATION.md','REVIEW.md','docs/evidence/T-037/README.md','docs/evidence/T-037/INVESTIGATION.md','docs/test-packages/T-037-v1/README.md','docs/test-packages/T-037-v1/INSTALL.md','docs/test-packages/T-037-v1/CASES.md')
 foreach($path in $docPaths){
  $text=ReadUtf8 (Join-Path $root $path)
  Check (([regex]::Matches($text,'(?m)^```').Count%2) -eq 0) ('Balanced code fences '+$path)
  Check (!$text.Contains([char]0xFFFD)) ('No replacement characters '+$path)
  foreach($link in [regex]::Matches($text,'\]\(([^)\r\n]+)\)')) {
   $target=$link.Groups[1].Value.Trim('<','>');if($target -match '^(https?:|#|app:)'){continue}
   $target=($target -split '#')[0];if(!$target){continue}
   $dest=Join-Path (Split-Path (Join-Path $root $path)) $target
   if($target -eq 'audit.json' -and $path -eq 'docs/evidence/T-037/README.md'){continue}
   Check (Test-Path -LiteralPath $dest) ('Local link '+$path+' -> '+$target)
  }
 }
 $build=Get-Content (Join-Path $ev 'build-03.json') -Raw -Encoding UTF8|ConvertFrom-Json
 Check ($build.exitCode -eq 0) 'Final build exit 0'
 Check ((ReadUtf8 (Join-Path $ev 'build-03.log')).Contains('PASS checks=1049; actualNewNbt=true; oldRuntimeExecuted=false; minecraftBootstrap=false; gameExecuted=false')) 'Actual non-game test summary'
 SaveJson (Join-Path $ev 'audit.json') ([ordered]@{command='powershell -NoProfile -ExecutionPolicy Bypass -File docs/evidence/T-037/audit.ps1';exitCode=0;checks=$checks.Count;allPassed=$true;productionFileCount=$before.Count;addedJarEntries=$added;phaseCounts=$phaseCounts;states=$states;manualResults='empty';independentReview='not performed';gameExecuted=$false;details=$checks})
 Write-Output ('PASS static checks='+$checks.Count+'; production files unchanged='+$before.Count+'; tasks=126; graph=acyclic; phases=9; manual=empty')
} catch {
 $attempt=1;do {$failure=Join-Path $ev ('audit-failed-{0:D2}.json' -f $attempt);$attempt++}while(Test-Path -LiteralPath $failure)
 SaveJson $failure ([ordered]@{exitCode=1;error=$_.Exception.Message;checks=$checks})
 throw
}
