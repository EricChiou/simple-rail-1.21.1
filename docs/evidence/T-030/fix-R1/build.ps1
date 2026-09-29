param([int]$Attempt=1)
$ErrorActionPreference='Stop'
$e=Join-Path (Get-Location) 'docs/evidence/T-030/fix-R1'
$started=[DateTime]::UtcNow.ToString('o')
$ErrorActionPreference='Continue'
& .\gradlew.bat build --offline --console=plain --no-configuration-cache *> ($e+('/build-{0:d2}.log' -f $Attempt))
$code=$LASTEXITCODE
$ErrorActionPreference='Stop'
[ordered]@{command='.\gradlew.bat build --offline --console=plain --no-configuration-cache';cwd=(Get-Location).Path;startedUtc=$started;finishedUtc=[DateTime]::UtcNow.ToString('o');exitCode=$code;scope='NEW only; no OLD, Minecraft, GameTest or runData'}|ConvertTo-Json|Set-Content -Encoding UTF8 ($e+('/build-{0:d2}.json' -f $Attempt))
Get-Content ($e+('/build-{0:d2}.log' -f $Attempt)) -Tail 25
exit $code
