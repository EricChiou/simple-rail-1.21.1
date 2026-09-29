$ErrorActionPreference='Stop'
$ev=Join-Path $PWD 'docs/evidence/T-009'
$jdk='C:\Program Files\Eclipse Adoptium\jdk-21.0.12.101-hotspot\bin'
$gson='C:\Users\Kinoko\.gradle\caches\modules-2\files-2.1\com.google.code.gson\gson\2.10.1\b3add478d4382b78ea20b1671390a858002feb6c\gson-2.10.1.jar'
$vanilla='C:\Users\Kinoko\.gradle\caches\neoformruntime\artifacts\minecraft_1.21.1_client.jar'
$out=Join-Path $ev 'audit/classes'
New-Item -ItemType Directory -Force $out | Out-Null
$results=@()
$attempt=1
while(Test-Path -LiteralPath (Join-Path $ev ("audit-commands-$attempt.json"))){$attempt++}
foreach($run in @(
 @{exe=(Join-Path $jdk 'javac.exe');args=@('-version');log='javac-version'},
 @{exe=(Join-Path $jdk 'javac.exe');args=@('--release','21','-encoding','UTF-8','-Xlint:all','-Werror','-cp',$gson,'-d',$out,(Join-Path $ev 'audit/ResourceAudit.java'));log='compile'},
 @{exe=(Join-Path $jdk 'java.exe');args=@('-cp',($out+';'+$gson),'ResourceAudit',$ev,$vanilla);log='audit'}
)){
 $started=[DateTime]::UtcNow.ToString('o')
 $logName=$run.log+"-$attempt.log"
 $ErrorActionPreference='Continue'
 & $run.exe @($run.args) > (Join-Path $ev $logName) 2>&1
 $code=$LASTEXITCODE
 $ErrorActionPreference='Stop'
 $results += [ordered]@{executable=$run.exe;arguments=$run.args;startedUtc=$started;endedUtc=[DateTime]::UtcNow.ToString('o');exitCode=$code;log=$logName}
 $results | ConvertTo-Json -Depth 6 | Set-Content -Encoding UTF8 (Join-Path $ev ("audit-commands-$attempt.json"))
 if($code -ne 0){Get-Content (Join-Path $ev $logName);exit $code}
}
[ordered]@{gson=$gson;gsonSha256=(Get-FileHash -LiteralPath $gson -Algorithm SHA256).Hash;sourceSha256=(Get-FileHash (Join-Path $ev 'audit/ResourceAudit.java') -Algorithm SHA256).Hash;classSha256=(Get-FileHash (Join-Path $out 'ResourceAudit.class') -Algorithm SHA256).Hash;runtimeClasspath=@($out,$gson);minecraftRuntimeLoaded=$false} | ConvertTo-Json -Depth 4 | Set-Content -Encoding UTF8 (Join-Path $ev 'audit-toolchain.json')
Get-Content -Encoding UTF8 (Join-Path $ev 'static-audit.json') | Select-Object -Last 20
