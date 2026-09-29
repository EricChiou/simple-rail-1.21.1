$ErrorActionPreference='Stop'
$e=Join-Path (Get-Location) 'docs/evidence/T-031'
$started=[DateTime]::UtcNow.ToString('o')
$ErrorActionPreference='Continue'
& .\gradlew.bat build --offline --console=plain --no-configuration-cache *> ($e+'/build-01.log')
$code=$LASTEXITCODE
$ErrorActionPreference='Stop'
[ordered]@{command='.\gradlew.bat build --offline --console=plain --no-configuration-cache';cwd=(Get-Location).Path;startedUtc=$started;finishedUtc=[DateTime]::UtcNow.ToString('o');exitCode=$code;scope='NEW only; no OLD, Minecraft, GameTest or runData'}|ConvertTo-Json|Set-Content -Encoding UTF8 ($e+'/build-01.json')
Get-Content ($e+'/build-01.log') -Tail 22
exit $code

