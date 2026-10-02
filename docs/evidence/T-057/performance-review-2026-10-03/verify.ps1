$ErrorActionPreference='Stop'
$root=(Get-Location).Path
$out=Join-Path $root 'docs/evidence/T-057/performance-review-2026-10-03'
$checks=[Collections.Generic.List[object]]::new()
function Check([string]$name,[bool]$pass,$detail=$null){$checks.Add([pscustomobject]@{name=$name;pass=$pass;detail=$detail})}
$inputs=Get-Content -Raw -Encoding UTF8 (Join-Path $out 'inputs.json') | ConvertFrom-Json
$changed=@($inputs | Where-Object {(Get-FileHash -LiteralPath (Join-Path $root $_.path)).Hash -ne $_.sha256})
Check 'product, historical evidence, JAR and API inputs unchanged' ($changed.Count -eq 0) $changed
$testInputs=Get-Content -Raw -Encoding UTF8 (Join-Path $out 'test-inputs.json') | ConvertFrom-Json
Check 'test inputs still match compiled sources' (@($testInputs | Where-Object {(Get-FileHash -LiteralPath $_.path).Hash -ne $_.sha256}).Count -eq 0)
$commands=Get-Content -Raw -Encoding UTF8 (Join-Path $out 'commands.json') | ConvertFrom-Json
Check 'compile plus six isolated JVM runs exit zero' ($commands.Count -eq 7 -and @($commands | Where-Object {$_.exitCode -ne 0}).Count -eq 0)
Check '41 original formation assertions' ((Get-Content -Raw (Join-Path $out 'formation-regression.log')) -match 'assertions=41 PASS')
Check '22 original R7 route assertions' ((Get-Content -Raw (Join-Path $out 'route-regression.log')) -match 'PASS: 22 assertions')
Check '1081 deterministic cost assertions' ((Get-Content -Raw (Join-Path $out 'deterministic.log')) -match 'PASS deterministic_checks=1081')
$timing=Import-Csv -Encoding UTF8 (Join-Path $out 'timing-summary.csv')
Check 'three forks times eight sizes preserved' ($timing.Count -eq 24 -and @($timing | Group-Object fork).Count -eq 3)
Check 'T057 Wrench unchanged since original delivery' ((Get-FileHash (Join-Path $root 'src/main/java/com/ericchiu/simplerail/item/Wrench.java')).Hash -eq '96767E7D4F0434AE8D537E4BE0D9AEF7464BF246921D8A50E0DC0E7467568389')
Add-Type -AssemblyName System.IO.Compression.FileSystem
$api=[IO.Compression.ZipFile]::OpenRead((Join-Path $root 'build/moddev/artifacts/neoforge-21.1.251-sources.jar'))
$apiHashes=@()
try{
 foreach($file in Get-ChildItem (Join-Path $out 'api') -File){
  $entry=@($api.Entries | Where-Object {$_.Name -eq $file.Name -and $_.FullName.StartsWith('net/minecraft/')})
  if($entry.Count -ne 1){throw ('Ambiguous API '+$file.Name)}
  $stream=$entry[0].Open();$sha=[Security.Cryptography.SHA256]::Create()
  try{$hash=[BitConverter]::ToString($sha.ComputeHash($stream)).Replace('-','')}finally{$stream.Dispose();$sha.Dispose()}
  Check ('fixed API entry '+$file.Name) ((Get-FileHash -LiteralPath $file.FullName).Hash -eq $hash)
  $apiHashes+=[pscustomobject]@{entry=$entry[0].FullName;sha256=$hash}
 }
}finally{$api.Dispose()}
$resultPath=Join-Path $out 'verification.json'
if(!(Test-Path $resultPath)){[IO.File]::WriteAllText($resultPath,'{}')}
$missing=@()
foreach($m in [regex]::Matches([IO.File]::ReadAllText((Join-Path $out 'README.md')),'\]\(([^)]+)\)')){
 $path=($m.Groups[1].Value -split '#')[0]
 if(!(Test-Path -LiteralPath (Join-Path $out $path))){$missing+=$path}
}
Check 'report local links resolve' ($missing.Count -eq 0) $missing
$result=[ordered]@{utc=[DateTime]::UtcNow.ToString('o');head=(& git rev-parse HEAD);gameExecuted=$false;productChanged=$false;inputCount=$inputs.Count;passed=@($checks | Where-Object {$_.pass}).Count;failed=@($checks | Where-Object {!$_.pass}).Count;apiEntries=$apiHashes;checks=$checks}
[IO.File]::WriteAllText($resultPath,($result | ConvertTo-Json -Depth 6),[Text.UTF8Encoding]::new($false))
Write-Output ('Verification: '+$result.passed+' passed, '+$result.failed+' failed; '+$inputs.Count+' inputs unchanged')
if($result.failed){$checks | Where-Object {!$_.pass} | ConvertTo-Json -Depth 5;exit 1}
