param([string]$Attempt='01')
$ErrorActionPreference='Continue'
$root='D:\workspace\java\simple-rail-1.21.1'
Set-Location $root
$start=[DateTime]::UtcNow.ToString('o')
$log="docs/evidence/T-013/compile-$Attempt.log"
& .\gradlew.bat compileT013Probe --offline --console=plain --info --no-configuration-cache -I docs/evidence/T-013/probe.init.gradle *> $log
$code=$LASTEXITCODE
[ordered]@{task='T-013';command='.\gradlew.bat compileT013Probe --offline --console=plain --info --no-configuration-cache -I docs/evidence/T-013/probe.init.gradle';cwd=$root;startedUtc=$start;endedUtc=[DateTime]::UtcNow.ToString('o');exitCode=$code;log=$log} | ConvertTo-Json | Set-Content -Encoding UTF8 "docs/evidence/T-013/compile-$Attempt.json"
Get-Content -Encoding Unicode $log -Tail 28
exit $code
