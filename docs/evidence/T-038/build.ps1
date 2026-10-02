param([int]$Attempt=1)
$ErrorActionPreference='Stop'
$ev=Join-Path (Get-Location) 'docs/evidence/T-038'
$command='.\gradlew.bat build testT038 --offline --console=plain --no-configuration-cache -I docs/evidence/T-038/tests.init.gradle'
$started=[DateTime]::UtcNow.ToString('o')
$ErrorActionPreference='Continue'
& .\gradlew.bat build testT038 --offline --console=plain --no-configuration-cache -I docs/evidence/T-038/tests.init.gradle *> (Join-Path $ev ('build-{0:D2}.log' -f $Attempt))
$code=$LASTEXITCODE
$ErrorActionPreference='Stop'
[ordered]@{command=$command;startedUtc=$started;finishedUtc=[DateTime]::UtcNow.ToString('o');exitCode=$code;scope='NEW production build + plain JVM production timer/data tests; no Minecraft bootstrap/client/server/GameTest or OLD build'} | ConvertTo-Json | Set-Content (Join-Path $ev ('build-{0:D2}.json' -f $Attempt)) -Encoding UTF8
Get-Content (Join-Path $ev ('build-{0:D2}.log' -f $Attempt)) -Tail 34
exit $code
