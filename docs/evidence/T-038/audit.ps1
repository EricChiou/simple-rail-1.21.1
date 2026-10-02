$ErrorActionPreference='Stop'
$root=(Get-Location).Path;$ev=Join-Path $root 'docs/evidence/T-038'
$checks=[Collections.Generic.List[object]]::new()
function Check($ok,$label){$checks.Add([ordered]@{name=$label;pass=[bool]$ok});if(!$ok){throw "Audit failed: $label"}}
function Sha($p){(Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash}
function ReadText($p){[IO.File]::ReadAllText($p,[Text.Encoding]::UTF8)}
function ZipMap($p){
 $map=@{};$z=[IO.Compression.ZipFile]::OpenRead($p)
 try{foreach($entry in $z.Entries){if($entry.FullName.EndsWith('/')){continue};Check (!$map.ContainsKey($entry.FullName)) ('Unique JAR entry '+$entry.FullName)
  $s=$entry.Open();$h=[Security.Cryptography.SHA256]::Create();try{$map[$entry.FullName]=([BitConverter]::ToString($h.ComputeHash($s))).Replace('-','')}finally{$s.Dispose();$h.Dispose()}
 }}finally{$z.Dispose()};return ,$map
}
function Tasks($p){$map=@{};foreach($m in [regex]::Matches((ReadText $p),'(?ms)^### (T-\d{3}) ([^\r\n]+)\r?\n(.*?)(?=^### T-\d{3} |^## |\z)')){
 $id=$m.Groups[1].Value;Check (!$map.ContainsKey($id)) ('Unique '+$id)
 $body=$m.Groups[3].Value;$depLine=[regex]::Match($body,'(?m)^- 前置任務：([^\r\n]*)').Groups[1].Value
 $map[$id]=[ordered]@{state=[regex]::Match($body,'(?m)^- 狀態：([^\r\n]*)').Groups[1].Value;deps=@([regex]::Matches($depLine,'T-\d{3}')|ForEach-Object{$_.Value})}
 };return ,$map}
try{
 Add-Type -AssemblyName System.IO.Compression.FileSystem
 $old=@{};foreach($f in (Get-Content (Join-Path $ev 'product-before.json') -Raw -Encoding UTF8|ConvertFrom-Json)){$old[$f.path.Replace('\','/')]=$f.sha256}
 $now=@{};foreach($f in (Get-Content (Join-Path $ev 'product-after.json') -Raw -Encoding UTF8|ConvertFrom-Json)){$now[$f.path.Replace('\','/')]=$f.sha256;Check ((Sha (Join-Path $root $f.path)) -eq $f.sha256) ('Source fixed '+$f.path)}
 $live=@(rg --files src gradle)+@('build.gradle','settings.gradle','gradle.properties','gradlew','gradlew.bat','.gitignore')
 Check (!(Compare-Object @($now.Keys|Sort-Object) @($live|ForEach-Object{$_.Replace('\','/')}|Sort-Object))) 'Live product file set equals after manifest'
 $changed=@($now.Keys|Where-Object{$old.ContainsKey($_) -and $old[$_] -ne $now[$_]})
 $added=@($now.Keys|Where-Object{!$old.ContainsKey($_)})
 $removed=@($old.Keys|Where-Object{!$now.ContainsKey($_)})
 $expectedChanged=@('src/main/java/com/ericchiu/simplerail/SimpleRail.java','src/main/java/com/ericchiu/simplerail/registry/ModBlocks.java')
 $expectedAdded=@('src/main/java/com/ericchiu/simplerail/block/TimerHoldingRail.java','src/main/java/com/ericchiu/simplerail/blockentity/HoldingTimer.java','src/main/java/com/ericchiu/simplerail/blockentity/HoldingTimerData.java','src/main/java/com/ericchiu/simplerail/blockentity/TimerHoldingRailBlockEntity.java','src/main/java/com/ericchiu/simplerail/registry/ModBlockEntities.java')
 Check (!(Compare-Object @($expectedChanged|Sort-Object) @($changed|Sort-Object))) 'Only two existing product Java changed'
 Check (!(Compare-Object @($expectedAdded|Sort-Object) @($added|Sort-Object))) 'Exactly five new product Java'
 Check ($removed.Count -eq 0) 'No product input removed'
 foreach($path in ($expectedChanged+$expectedAdded)){
  $copy=Join-Path $ev ('sources/'+$path)
  Check ((Sha $copy) -eq $now[$path]) ('Exact source copy '+$path)
 }
 $beforeIndex=Join-Path $ev 'index-before.diff';$afterIndex=Join-Path $ev 'index-after.diff'
 $cached=@(& git diff --cached --binary);Check ($LASTEXITCODE -eq 0) 'Read cached diff'
 [IO.File]::WriteAllText($afterIndex,($cached -join "`n"),[Text.UTF8Encoding]::new($false))
 Check ((Sha $beforeIndex) -eq (Sha $afterIndex)) 'Staged changes unchanged'
 $head=(& git rev-parse HEAD).Trim();Check ($head -eq (ReadText (Join-Path $ev 'head.txt')).Trim()) 'HEAD unchanged'
 $jar=Join-Path $ev 'artifacts/simplerail-1.0.0.jar';Check ((Sha $jar) -eq (Sha (Join-Path $root 'build/libs/simplerail-1.0.0.jar'))) 'Built JAR copied without change'
 $beforeJar=ZipMap (Join-Path $root 'docs/evidence/T-037/artifacts/simplerail-1.0.0.jar');$afterJar=ZipMap $jar
 $overrides=@('com/ericchiu/simplerail/SimpleRail.class','com/ericchiu/simplerail/registry/ModBlocks.class')
 foreach($name in $beforeJar.Keys){Check ($afterJar.ContainsKey($name)) ('JAR retains '+$name);if($name -notin $overrides){Check ($beforeJar[$name] -eq $afterJar[$name]) ('Other JAR entry unchanged '+$name)}}
 $newEntries=@($afterJar.Keys|Where-Object{!$beforeJar.ContainsKey($_)})
 foreach($name in $newEntries){Check ($name.StartsWith('com/ericchiu/simplerail/') -and $name.EndsWith('.class')) ('Only product class added '+$name)}
 foreach($name in @('block/TimerHoldingRail.class','blockentity/HoldingTimer.class','blockentity/HoldingTimerData.class','blockentity/HoldingTimerData$Snapshot.class','blockentity/TimerHoldingRailBlockEntity.class','registry/ModBlockEntities.class')){
  Check ($afterJar.ContainsKey('com/ericchiu/simplerail/'+$name)) ('Required class in JAR '+$name)
 }
 Check (!$afterJar.ContainsKey('evidence/t037/TimerProbe.class')) 'T-037 fixture excluded from production JAR'
 $blockstate=Get-Content 'src/main/resources/assets/simplerail/blockstates/timer_holding_rail.json' -Raw -Encoding UTF8|ConvertFrom-Json
 $variants=@($blockstate.variants.PSObject.Properties);Check ($variants.Count -eq 20) 'Existing 20 flat level/shape selectors'
 foreach($level in 0..9){foreach($shape in @('north_south','east_west')){
  $key="level=$level,shape=$shape";$candidate=$blockstate.variants.PSObject.Properties[$key]
  Check ($null -ne $candidate) ('Flat model selector '+$key)
  if($candidate){$model=$candidate.Value.model.Replace('simplerail:block/','src/main/resources/assets/simplerail/models/block/')+'.json';Check (Test-Path $model) ('Referenced model exists '+$model)}
 }}
 foreach($f in @('build-02.json','build-03.json')){$j=Get-Content (Join-Path $ev $f) -Raw -Encoding UTF8|ConvertFrom-Json;Check ($j.exitCode -eq 0) ('Successful build '+$f)}
 Check ((ReadText (Join-Path $ev 'build-03.log')).Contains('PASS production timer + real NEW NBT checks=1055; gameExecuted=false; oldBuildExecuted=false')) 'Real NEW NBT/plain JVM result'
 $hooks=Get-Content (Join-Path $ev 'hooks-04.json') -Raw -Encoding UTF8|ConvertFrom-Json
 Check ($hooks.compileExitCode -eq 0 -and $hooks.runExitCode -eq 0 -and $hooks.actualNewNbt -eq $false) 'Isolated hooks have clear boundaries'
 Check ((ReadText (Join-Path $ev 'hooks-test-04.log')).Contains('PASS actual rail/BE hooks checks=1526; matrix=9levels*6directions*2power; external doubles; no game runtime')) 'Actual product hook result'
 $tasks=Tasks (Join-Path $root 'TASK.md');$before=Tasks (Join-Path $ev 'before/TASK.md')
 Check ($tasks.Count -eq 126 -and $before.Count -eq 126) '126 task numbers retained'
 foreach($i in 1..126){$id='T-{0:D3}' -f $i;Check ($tasks.ContainsKey($id)) ('Task exists '+$id)
  Check (($tasks[$id].deps -join ',') -eq ($before[$id].deps -join ',')) ('Dependencies unchanged '+$id)
  if($id -ne 'T-038'){Check ($tasks[$id].state -eq $before[$id].state) ('Other task state unchanged '+$id)}
  foreach($dep in $tasks[$id].deps){Check ($tasks.ContainsKey($dep)) ('Dependency exists '+$dep)}
 }
 Check ($tasks['T-038'].state -eq '開發完成') 'T-038 development complete'
 Check ($tasks['T-039'].state -eq '待執行' -and $tasks['T-119'].state -eq '待執行') 'T-039 and T-119 pending'
 Check (@($tasks.Values|Where-Object{$_.state -like '開發完成*'}).Count -eq 25) '25 development complete'
 Check (@($tasks.Values|Where-Object{$_.state -eq '待執行'}).Count -eq 77) '77 pending'
 $colors=@{};function Visit($id){if($colors[$id] -eq 1){throw "Dependency cycle at $id"};if($colors[$id] -eq 2){return};$colors[$id]=1;foreach($dep in $tasks[$id].deps){Visit $dep};$colors[$id]=2}
 foreach($id in $tasks.Keys){Visit $id};Check ($colors.Count -eq 126) 'Dependency graph acyclic'
 $phases=[regex]::Matches((ReadText (Join-Path $root 'TASK.md')),'(?ms)^## 階段 ([0-8])：.*?(?=^## 階段 [0-8]：|\z)')
 $phaseCounts=@($phases|ForEach-Object{[regex]::Matches($_.Value,'(?m)^### T-\d{3} ').Count})
 Check (($phaseCounts -join ',') -eq '4,17,8,18,16,26,23,8,6') 'Nine phases and task counts'
 foreach($path in @('TASK.md','MIGRATION.md','REVIEW.md','docs/evidence/T-038/README.md','docs/evidence/T-038/DATA_AND_TIME.md')){
  $text=ReadText (Join-Path $root $path)
  Check (([regex]::Matches($text,'(?m)^```').Count%2) -eq 0) ('Balanced Markdown fences '+$path)
  Check (!$text.Contains([char]0xFFFD)) ('No replacement characters '+$path)
  foreach($link in [regex]::Matches($text,'\]\(([^)\r\n]+)\)')){
   $target=($link.Groups[1].Value.Trim('<','>') -split '#')[0]
   if(!$target -or $target -match '^(https?:|app:)'){continue}
   if($target -eq 'audit.json' -and $path -eq 'docs/evidence/T-038/README.md'){continue}
   Check (Test-Path -LiteralPath (Join-Path (Split-Path (Join-Path $root $path)) $target)) ('Local link '+$path+' -> '+$target)
  }
 }
 $out=[ordered]@{command='powershell -NoProfile -ExecutionPolicy Bypass -File docs/evidence/T-038/audit.ps1';exitCode=0;checkCount=$checks.Count;productFileCountBefore=$old.Count;productFileCountAfter=$now.Count;changedExisting=$changed;added=$added;removed=$removed;jarSha256=(Sha $jar);newJarEntries=$newEntries;phases=$phaseCounts;manualResults='none';independentReview='not performed';gameExecuted=$false;allPassed=$true;checks=$checks}
 $out|ConvertTo-Json -Depth 9|Set-Content (Join-Path $ev 'audit.json') -Encoding UTF8
 Write-Output ('PASS static checks='+$checks.Count+'; product changed='+$changed.Count+' added='+$added.Count+'; tasks=126; phases=9; dependencies=acyclic')
}catch{
 $attempt=1;do{$path=Join-Path $ev ('audit-failed-{0:D2}.json' -f $attempt);$attempt++}while(Test-Path $path)
 [ordered]@{exitCode=1;error=$_.Exception.Message;checks=$checks}|ConvertTo-Json -Depth 8|Set-Content $path -Encoding UTF8
 throw
}
