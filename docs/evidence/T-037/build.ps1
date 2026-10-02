param([int]$Attempt=1)
$ErrorActionPreference='Stop'
$e=Join-Path (Get-Location) 'docs/evidence/T-037'
$started=[DateTime]::UtcNow.ToString('o')
$ErrorActionPreference='Continue'
& .\gradlew.bat build t037Jar testT037 --offline --console=plain --no-configuration-cache -I docs/evidence/T-037/probe.init.gradle *> ($e+('/build-{0:d2}.log' -f $Attempt))
$code=$LASTEXITCODE
$ErrorActionPreference='Stop'
[ordered]@{command='.\gradlew.bat build t037Jar testT037 --offline --console=plain --no-configuration-cache -I docs/evidence/T-037/probe.init.gradle';cwd=(Get-Location).Path;startedUtc=$started;finishedUtc=[DateTime]::UtcNow.ToString('o');exitCode=$code;scope='NEW build + separate evidence-only fixture JAR + plain JVM NBT/time tests; no OLD build or Minecraft bootstrap/server/client/GameTest'}|ConvertTo-Json|Set-Content -Encoding UTF8 ($e+('/build-{0:d2}.json' -f $Attempt))
Get-Content ($e+('/build-{0:d2}.log' -f $Attempt)) -Tail 42
exit $code
