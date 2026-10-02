$ErrorActionPreference='Stop'
$root=(Get-Location).Path;$out=Join-Path $root 'docs/evidence/R-03'
$utf8=[Text.UTF8Encoding]::new($false)
Add-Type -AssemblyName System.IO.Compression.FileSystem
$checks=[Collections.Generic.List[object]]::new();$inputs=[Collections.Generic.List[object]]::new()
function Json([string]$path){Get-Content -Raw -Encoding UTF8 -LiteralPath $path|ConvertFrom-Json}
function Hash([string]$path){(Get-FileHash -LiteralPath $path).Hash}
function Input([string]$path){$inputs.Add([pscustomobject]@{path=$path;sha256=(Hash $path)})}
function Check([string]$name,[bool]$ok,$detail){$checks.Add([pscustomobject]@{name=$name;passed=$ok;detail=$detail})}
function EntryHash($entry){$stream=$entry.Open();$sha=[Security.Cryptography.SHA256]::Create();try{([BitConverter]::ToString($sha.ComputeHash($stream))).Replace('-','')}finally{$stream.Dispose();$sha.Dispose()}}
function EntryText($entry){$stream=[IO.StreamReader]::new($entry.Open());try{$stream.ReadToEnd()}finally{$stream.Dispose()}}
$taskPaths=@('T-025','T-026/fix-R1','T-026/fix-R2','T-027','T-029','T-031','T-033','T-035','T-030/fix-R1')
foreach($task in $taskPaths){
 $base='docs/evidence/'+$task
 $artifact=Json ($base+'/artifact.json')
 $jar=$base+'/artifacts/simplerail-1.0.0.jar'
 Check ($task+' archived JAR hash') ((Hash $jar) -eq $artifact.sha256) $artifact.sha256
 Input $jar
 $buildFile=if($task -eq 'T-030/fix-R1'){'build-02'}else{'build-01'}
 $build=Json ($base+'/'+$buildFile+'.json');$log=Get-Content -Raw ($base+'/'+$buildFile+'.log')
 Check ($task+' original NEW build successful, test NO-SOURCE') ($build.exitCode -eq 0 -and $log.Contains('BUILD SUCCESSFUL') -and $log.Contains('test NO-SOURCE')) $null
 foreach($file in Get-ChildItem -Recurse -File $base){
  if($file.Extension -in @('.java','.json','.md') -or $file.Name -match '^build-.*\.log$'){Input $file.FullName}
 }
}
$fingerprints=Json 'docs/evidence/T-030/fix-R1/source-fingerprints.json'
foreach($row in $fingerprints){Check ('current latest source '+$row.path) ((Hash $row.path) -eq $row.sha256) $null;Input $row.path}
foreach($task in @('T-027','T-029','T-031','T-033','T-035')){
 $base='docs/evidence/'+$task;$manifest=Json ($base+'/source-manifest.json')
 if($manifest -is [array]){
  foreach($row in $manifest){Check ($task+' source snapshot '+$row.path) ((Hash $row.path) -eq $row.sha256) $null}
  continue
 }
 Check ($task+' fixed source archive') ((Hash $manifest.archive) -eq $manifest.archiveSha256) $manifest.archive
 $zip=[IO.Compression.ZipFile]::OpenRead((Join-Path $root $manifest.archive))
 try{
  foreach($row in $manifest.target){
   $path=$base+'/sources/target/'+$row.path;$entry=$zip.GetEntry($row.path)
   Check ($task+' primary source '+$row.path) ((Hash $path) -eq $row.sha256 -and (EntryHash $entry) -eq $row.sha256) $null
  }
  foreach($row in $manifest.old){Check ($task+' OLD snapshot '+$row.path) ((Hash ($base+'/sources/old/'+$row.path)) -eq $row.sha256) $null}
 }finally{$zip.Dispose()}
}
$references=Json 'docs/evidence/T-025/source-references.json'
foreach($row in $references){
 Check ('T025 source '+$row.snapshot) ((Hash $row.snapshot) -eq $row.sha256) $null
 if($row.entry){$zip=[IO.Compression.ZipFile]::OpenRead($row.origin);try{Check ('T025 archive entry '+$row.entry) ((EntryHash $zip.GetEntry($row.entry)) -eq $row.sha256) $null}finally{$zip.Dispose()}}
}
$models=Json 'docs/evidence/T-026/fix-R1/model-sources.json'
foreach($row in $models){
 $zip=[IO.Compression.ZipFile]::OpenRead($row.archive)
 try{Check ('slope model primary source '+$row.entry) ((Hash $row.snapshot) -eq $row.sha256 -and (EntryHash $zip.GetEntry($row.entry)) -eq $row.sha256) $null}finally{$zip.Dispose()}
}
$jar=[IO.Compression.ZipFile]::OpenRead((Join-Path $root 'docs/evidence/T-030/fix-R1/artifacts/simplerail-1.0.0.jar'))
try{
 foreach($file in Get-ChildItem -Recurse -File src/main/resources){
  $relative=$file.FullName.Substring((Join-Path $root 'src/main/resources').Length+1).Replace('\','/')
  $entry=$jar.GetEntry($relative)
  Check ('current resource equals latest JAR '+$relative) ($null -ne $entry -and (EntryHash $entry) -eq (Hash $file.FullName)) $null
 }
 $metadata=EntryText $jar.GetEntry('META-INF/neoforge.mods.toml')
 Check 'common Mixin metadata registration' ($metadata.Contains('[[mixins]]') -and $metadata.Contains('config="simplerail.mixins.json"')) $null
 Check 'fixed D8 metadata' ($metadata.Contains('version="1.0.0"') -and $metadata.Contains('license="All Rights Reserved"')) $null
}finally{$jar.Dispose()}
$mixin=Json 'src/main/resources/simplerail.mixins.json'
Check 'one required common Java 21 Mixin only' ($mixin.required -and $mixin.compatibilityLevel -eq 'JAVA_21' -and $mixin.mixins.Count -eq 1 -and $mixin.mixins[0] -eq 'AbstractMinecartMixin' -and !$mixin.client -and !$mixin.server) $mixin
$domains=@{
 high_speed_rail=@{shape=@('north_south','east_west','ascending_east','ascending_west','ascending_north','ascending_south');powered=@('false','true');waterlogged=@('false','true')}
 holding_rail=@{shape=@('north_south','east_west','ascending_east','ascending_west','ascending_north','ascending_south');powered=@('false','true');waterlogged=@('false','true');direction=@('north','south','east','west','up','down')}
 oneway_rail=@{shape=@('north_south','east_west','ascending_east','ascending_west','ascending_north','ascending_south');powered=@('false','true');waterlogged=@('false','true');reverse=@('false','true');need_power=@('false','true');use_power=@('false','true')}
 eject_rail=@{shape=@('north_south','east_west','ascending_east','ascending_west','ascending_north','ascending_south');powered=@('false','true');waterlogged=@('false','true');reverse=@('false','true');need_power=@('false','true')}
 destory_rail=@{shape=@('north_south','east_west','ascending_east','ascending_west','ascending_north','ascending_south');powered=@('false','true');waterlogged=@('false','true');need_power=@('false','true')}
}
$coverage=@()
foreach($id in ($domains.Keys|Sort-Object)){
 $states=@(@{})
 foreach($key in ($domains[$id].Keys|Sort-Object)){
  $expanded=@();foreach($state in $states){foreach($value in $domains[$id][$key]){$next=$state.Clone();$next[$key]=$value;$expanded+=$next}};$states=$expanded
 }
 $variants=(Json ('src/main/resources/assets/simplerail/blockstates/'+$id+'.json')).variants.PSObject.Properties
 $missing=0;$overlap=0;$flatMissing=0
 foreach($state in $states){
  $matched=0
  foreach($variant in $variants){$fits=$true;foreach($clause in $variant.Name.Split(',')){$pair=$clause.Split('=');if($state[$pair[0]] -ne $pair[1]){$fits=$false;break}};if($fits){$matched++}}
  if($matched -eq 0){$missing++;if($state.shape -in @('north_south','east_west')){$flatMissing++}}
  if($matched -gt 1){$overlap++}
 }
 Check ($id+' natural-state model coverage') ($flatMissing -eq 0 -and $overlap -eq 0 -and ($id -ne 'high_speed_rail' -or $missing -eq 0)) @{total=$states.Count;missing=$missing;flatMissing=$flatMissing;overlap=$overlap}
 $coverage+=[pscustomobject]@{id=$id;total=$states.Count;missing=$missing;flatMissing=$flatMissing;overlap=$overlap;scope='source-domain enumeration, not game bake'}
}
foreach($file in Get-ChildItem src/main/resources/assets/simplerail/models/block/high_speed*raised*.json){
 $model=Json $file.FullName
 Check ('slope model cutout and original sprite '+$file.Name) ($model.render_type -eq 'minecraft:cutout' -and $model.parent -match '^minecraft:block/template_rail_raised_(ne|sw)$' -and $model.textures.rail -match '^simplerail:blocks/high_speed_(powered_)?rail$') $model
}
foreach($file in Get-ChildItem -Recurse -File src/main){Input $file.FullName}
foreach($path in @('docs/test-packages/T-026-R1-v1.zip','docs/test-packages/T-026-R2-v1.zip','docs/evidence/T-026/REPORT-003.md','docs/evidence/T-028/README.md','docs/evidence/T030-T036-user-confirmation/README.md','docs/evidence/T094-T099-user-handoff/README.md')){Input $path}
Check 'R2 existing local regression package hash' ((Hash 'docs/test-packages/T-026-R2-v1.zip') -eq '3C169310EA0E8374785583D84BD4E9A1A165CD7C59E5DCF89C3E393FE0A58A9B') $null
$report=[ordered]@{head=(& git rev-parse HEAD);utc=[DateTime]::UtcNow.ToString('o');passed=@($checks|Where-Object {$_.passed}).Count;failed=@($checks|Where-Object {!$_.passed}).Count;checks=$checks}
[IO.File]::WriteAllText((Join-Path $out 'checks.json'),($report|ConvertTo-Json -Depth 10),$utf8)
[IO.File]::WriteAllText((Join-Path $out 'state-coverage.json'),($coverage|ConvertTo-Json -Depth 5),$utf8)
[IO.File]::WriteAllText((Join-Path $out 'reviewed-inputs.json'),($inputs|Sort-Object path -Unique|ConvertTo-Json -Depth 5),$utf8)
Write-Output ('Static checks: '+$report.passed+' passed; '+$report.failed+' failed')
$checks|Where-Object {!$_.passed}|ConvertTo-Json -Depth 6
if($report.failed -gt 0){exit 1}
