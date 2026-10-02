$ErrorActionPreference='Stop'
$root=(Get-Location).Path;$ev=Join-Path $root 'docs/evidence/T-039'
$checks=[Collections.Generic.List[object]]::new()
function Check($ok,$label){$checks.Add([ordered]@{name=$label;pass=[bool]$ok});if(!$ok){throw "Audit failed: $label"}}
function Sha($p){(Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash}
function ReadText($p){[IO.File]::ReadAllText($p,[Text.Encoding]::UTF8)}
function Tasks($p){$map=@{};foreach($m in [regex]::Matches((ReadText $p),'(?ms)^### (T-\d{3}) ([^\r\n]+)\r?\n(.*?)(?=^### T-\d{3} |^## |\z)')){
 $id=$m.Groups[1].Value;Check (!$map.ContainsKey($id)) ('Unique task '+$id)
 $body=$m.Groups[3].Value;$line=[regex]::Match($body,'(?m)^- 前置任務：([^\r\n]*)').Groups[1].Value
 $map[$id]=[ordered]@{state=[regex]::Match($body,'(?m)^- 狀態：([^\r\n]*)').Groups[1].Value;deps=@([regex]::Matches($line,'T-\d{3}')|ForEach-Object{$_.Value})}
 };return ,$map}
try{
 $base=Get-Content (Join-Path $ev 'product-before.json') -Raw -Encoding UTF8|ConvertFrom-Json
 $prior=Get-Content 'docs/evidence/T-038/product-after.json' -Raw -Encoding UTF8|ConvertFrom-Json
 Check ($base.Count -eq 181 -and $prior.Count -eq 181) '181 fixed product/toolchain inputs'
 $lookup=@{};foreach($f in $prior){$lookup[$f.path.Replace('\','/')]=$f.sha256}
 foreach($f in $base){$name=$f.path.Replace('\','/');Check ($lookup[$name] -eq $f.sha256) ('T-038 fingerprint retained '+$name);Check ((Sha (Join-Path $root $f.path)) -eq $f.sha256) ('Current product unchanged '+$name)}
 $live=@(rg --files src gradle)+@('build.gradle','settings.gradle','gradle.properties','gradlew','gradlew.bat','.gitignore')
 Check (!(Compare-Object @($lookup.Keys|Sort-Object) @($live|ForEach-Object{$_.Replace('\','/')}|Sort-Object))) 'Product file set unchanged'
 $cached=@(& git diff --cached --binary);Check ($LASTEXITCODE -eq 0) 'Read cached diff'
 $afterIndex=Join-Path $ev 'index-after.diff';[IO.File]::WriteAllText($afterIndex,($cached -join "`n"),[Text.UTF8Encoding]::new($false))
 Check ((Sha (Join-Path $ev 'index-before.diff')) -eq (Sha $afterIndex)) 'Git index unchanged'
 Check ((& git rev-parse HEAD).Trim() -eq (ReadText (Join-Path $ev 'head.txt')).Trim()) 'HEAD unchanged'
 $jar=Join-Path $root 'build/libs/simplerail-1.0.0.jar';$priorJar='docs/evidence/T-038/artifacts/simplerail-1.0.0.jar'
 Check ((Sha $jar) -eq 'EABD253F9EA50B58B62A5311D2B7289F22AA1DEECADF9059FFF76A736DEAE21B') 'Fixed T-038 JAR retained'
 Check ((Sha $jar) -eq (Sha $priorJar)) 'Built and preserved JAR equal'
 $oldJar=Get-Content (Join-Path $ev 'jar-before.json') -Raw -Encoding UTF8|ConvertFrom-Json
 Check ((Sha $jar) -eq $oldJar.sha256) 'T-039 JAR unchanged'
 foreach($name in @('T-038-build-03.log','T-038-build-03.json','T-038-hooks-test-04.log','T-038-hooks-04.json')){
  $original=$name.Replace('T-038-','');$original=if($name -like '*build*'){'docs/evidence/T-038/'+$original}else{'docs/evidence/T-038/'+$original}
  Check ((Sha (Join-Path $ev ('reused/'+$name))) -eq (Sha $original)) ('Copied old command/evidence exactly '+$name)
 }
 $build=Get-Content (Join-Path $ev 'reused/T-038-build-03.json') -Raw -Encoding UTF8|ConvertFrom-Json
 $hook=Get-Content (Join-Path $ev 'reused/T-038-hooks-04.json') -Raw -Encoding UTF8|ConvertFrom-Json
 Check ($build.exitCode -eq 0 -and (ReadText (Join-Path $ev 'reused/T-038-build-03.log')).Contains('PASS production timer + real NEW NBT checks=1055')) 'Earlier NEW build/real NBT pass'
 Check ($hook.compileExitCode -eq 0 -and $hook.runExitCode -eq 0 -and (ReadText (Join-Path $ev 'reused/T-038-hooks-test-04.log')).Contains('hooks checks=1526')) 'Earlier isolated hook pass'
 $data=ReadText 'src/main/java/com/ericchiu/simplerail/blockentity/HoldingTimerData.java'
 $timer=ReadText 'src/main/java/com/ericchiu/simplerail/blockentity/HoldingTimer.java'
 $be=ReadText 'src/main/java/com/ericchiu/simplerail/blockentity/TimerHoldingRailBlockEntity.java'
 $registry=ReadText 'src/main/java/com/ericchiu/simplerail/registry/ModBlockEntities.java'
 Check ($data.Contains('data.hasUUID("cart_uuid")') -and $data.Contains('data.contains("remaining_ms", Tag.TAG_LONG)') -and $data.Contains('new Snapshot(null, 0)')) '01 guard path remains'
 Check ($be.Contains('setChanged();') -and $be.Contains('level.blockEntityChanged(pos);') -and $registry.Contains('chunk.setUnsaved(true);')) '02 dirty paths remain'
 Check ($timer.Contains('Math.multiplyExact((long) seconds, 1000L)') -and $data.Contains('HoldingTimer.MAX_MILLIS')) '03 long upper bound remains'
 Check ($be.Contains('HoldingTimerData.encode(timer.cartUuid(), timer.remainingMillis())') -and $be.Contains('timer.restore(data.cart(), data.remainingMillis())')) '04 serialization/readback paths remain'
 Check ($registry.Contains('onChunkUnload(ChunkEvent.Unload event)') -and $registry.Contains('timer.pauseForUnload()') -and !$registry.Contains('onChunkUnloaded()')) '05 event-before-save path remains'
 foreach($text in @($data,$timer,$be,$registry)){Check (!$text.Contains('"save_time"') -and !$text.Contains('"go_time"')) 'No OLD timestamp conversion key in executable code'}
 $confirmation=ReadText (Join-Path $ev 'USER_CONFIRMATION.md')
 Check ($confirmation.Contains('我已驗證T-119 計時保存／讀回且已完成T-100') -and $confirmation.Contains('不是 Agent 已建置')) 'User wording and T-100 evidence limit retained'
 $tasks=Tasks (Join-Path $root 'TASK.md');$before=Tasks (Join-Path $ev 'before/TASK.md')
 Check ($tasks.Count -eq 126 -and $before.Count -eq 126) '126 task numbers retained'
 foreach($i in 1..126){$id='T-{0:D3}' -f $i;Check ($tasks.ContainsKey($id)) ('Task exists '+$id)
  Check (($tasks[$id].deps -join ',') -eq ($before[$id].deps -join ',')) ('Dependencies unchanged '+$id)
  if($id -notin @('T-039','T-119','T-100')){Check ($tasks[$id].state -eq $before[$id].state) ('Other task state unchanged '+$id)}
  foreach($dep in $tasks[$id].deps){Check ($tasks.ContainsKey($dep)) ('Dependency exists '+$id+' -> '+$dep)}
 }
 Check ($tasks['T-039'].state.StartsWith('開發完成')) 'T-039 development complete'
 Check ($tasks['T-119'].state.StartsWith('人工驗證完成')) 'T-119 user verified'
 Check ($tasks['T-100'].state.StartsWith('已結案（使用者確認完成')) 'T-100 user closed'
 Check ($tasks['T-040'].state -eq '待執行' -and $tasks['T-083'].state -eq '待執行') 'Formal game tests pending'
 Check (@($tasks.Values|Where-Object{$_.state -like '開發完成*'}).Count -eq 26) '26 development complete'
 Check (@($tasks.Values|Where-Object{$_.state -eq '待執行'}).Count -eq 74) '74 pending'
 $colors=@{};function Visit($id){if($colors[$id] -eq 1){throw "Dependency cycle $id"};if($colors[$id] -eq 2){return};$colors[$id]=1;foreach($dep in $tasks[$id].deps){Visit $dep};$colors[$id]=2}
 foreach($id in $tasks.Keys){Visit $id};Check ($colors.Count -eq 126) 'Dependency graph acyclic'
 $phases=[regex]::Matches((ReadText (Join-Path $root 'TASK.md')),'(?ms)^## 階段 ([0-8])：.*?(?=^## 階段 [0-8]：|\z)')
 $phaseCounts=@($phases|ForEach-Object{[regex]::Matches($_.Value,'(?m)^### T-\d{3} ').Count})
 Check (($phaseCounts -join ',') -eq '4,17,8,18,16,26,23,8,6') 'Nine phases and unchanged counts'
 $docs=@('MIGRATION.md','TASK.md','REVIEW.md','docs/evidence/T-039/README.md','docs/evidence/T-039/DECISIONS.md','docs/evidence/T-039/USER_CONFIRMATION.md')
 foreach($doc in $docs){$text=ReadText (Join-Path $root $doc)
  Check (([regex]::Matches($text,'(?m)^```').Count%2) -eq 0) ('Balanced code fences '+$doc)
  Check (!$text.Contains([char]0xFFFD)) ('No replacement chars '+$doc)
  foreach($link in [regex]::Matches($text,'\]\(([^)\r\n]+)\)')){
   $target=($link.Groups[1].Value.Trim('<','>') -split '#')[0]
   if(!$target -or $target -match '^(https?:|app:)'){continue}
   if($target -eq 'audit.json' -and $doc -like '*/T-039/DECISIONS.md'){continue}
   if($target -eq 'audit.json' -and $doc -like '*/T-039/README.md'){continue}
   Check (Test-Path -LiteralPath (Join-Path (Split-Path (Join-Path $root $doc)) $target)) ('Local link '+$doc+' -> '+$target)
  }
 }
 $result=[ordered]@{command='powershell -NoProfile -ExecutionPolicy Bypass -File docs/evidence/T-039/audit.ps1';exitCode=0;checkCount=$checks.Count;productFiles=$base.Count;productChanged=$false;buildRerun=$false;jarSha256=(Sha $jar);priorBuildExit=$build.exitCode;priorHookCompileExit=$hook.compileExitCode;priorHookRunExit=$hook.runExitCode;oldBuildExecuted=$false;gameExecuted=$false;review='R-04 pending';manualResultSource='user wording only';phaseCounts=$phaseCounts;allPassed=$true;checks=$checks}
 $result|ConvertTo-Json -Depth 9|Set-Content (Join-Path $ev 'audit.json') -Encoding UTF8
 Write-Output ('PASS T-039 static checks='+$checks.Count+'; product=unchanged; Jar='+$result.jarSha256+'; tasks=126; graph=acyclic')
}catch{
 $attempt=1;do{$path=Join-Path $ev ('audit-failed-{0:D2}.json' -f $attempt);$attempt++}while(Test-Path $path)
 [ordered]@{exitCode=1;error=$_.Exception.Message;checks=$checks}|ConvertTo-Json -Depth 9|Set-Content $path -Encoding UTF8
 throw
}
