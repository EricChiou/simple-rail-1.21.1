$ErrorActionPreference = 'Stop'
$taskEvidence = Join-Path (Get-Location) 'docs/evidence/T-026/fix-R2'
$started = [DateTime]::UtcNow.ToString('o')
$ErrorActionPreference = 'Continue'
& .\gradlew.bat build --offline --console=plain --no-configuration-cache *> (Join-Path $taskEvidence 'build-01.log')
$buildCode = $LASTEXITCODE
$ErrorActionPreference = 'Stop'
[ordered]@{command='.\gradlew.bat build --offline --console=plain --no-configuration-cache';cwd=(Get-Location).Path;startedUtc=$started;finishedUtc=[DateTime]::UtcNow.ToString('o');exitCode=$buildCode;scope='NEW only; no Minecraft, GameTest or OLD build'} | ConvertTo-Json | Set-Content -Encoding UTF8 (Join-Path $taskEvidence 'build-01.json')
Get-Content (Join-Path $taskEvidence 'build-01.log') -Tail 28
exit $buildCode
