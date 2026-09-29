$ErrorActionPreference = 'Stop'
$taskEvidence = Join-Path (Get-Location) 'docs/evidence/T-019'
$started = [DateTime]::UtcNow.ToString('o')
$ErrorActionPreference = 'Continue'
& .\gradlew.bat build --offline --console=plain --no-configuration-cache *> (Join-Path $taskEvidence 'build-01.log')
$buildExit = $LASTEXITCODE
$ErrorActionPreference = 'Stop'
[ordered]@{
    command = '.\gradlew.bat build --offline --console=plain --no-configuration-cache'
    cwd = (Get-Location).Path
    startedUtc = $started
    finishedUtc = [DateTime]::UtcNow.ToString('o')
    exitCode = $buildExit
    logEncoding = 'UTF-16LE'
    scope = 'NEW build only; no OLD build or Minecraft runtime'
} | ConvertTo-Json | Set-Content -Encoding utf8 (Join-Path $taskEvidence 'build-01.json')
Get-Content (Join-Path $taskEvidence 'build-01.log') -Tail 35
exit $buildExit
