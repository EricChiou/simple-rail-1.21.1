param([string]$Attempt='01')
$ErrorActionPreference='Continue'
$root='D:\workspace\java\simple-rail-1.21.1'
Set-Location $root
$start=[DateTime]::UtcNow.ToString('o')
$log="docs/evidence/T-011/compile-$Attempt.log"
& .\gradlew.bat compileT011Probe --offline --console=plain --info --no-configuration-cache -I docs/evidence/T-011/probe.init.gradle *> $log
$code=$LASTEXITCODE
[ordered]@{task='T-011';command='.\gradlew.bat compileT011Probe --offline --console=plain --info --no-configuration-cache -I docs/evidence/T-011/probe.init.gradle';cwd=$root;startedUtc=$start;endedUtc=[DateTime]::UtcNow.ToString('o');exitCode=$code;log=$log} | ConvertTo-Json | Set-Content -Encoding UTF8 "docs/evidence/T-011/compile-$Attempt.json"
Get-Content -Encoding Unicode $log -Tail 20
exit $code
