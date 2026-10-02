$ErrorActionPreference = 'Continue'
$evidence = 'docs/evidence/T-045'
$command = '.\gradlew.bat build --offline --console=plain --no-configuration-cache'
$started = (Get-Date).ToUniversalTime().ToString('o')
& .\gradlew.bat build --offline --console=plain --no-configuration-cache *> (Join-Path $evidence 'build-03.log')
$exitCode = $LASTEXITCODE
[ordered]@{
    command = $command
    cwd = (Resolve-Path '.').Path
    started_utc = $started
    finished_utc = (Get-Date).ToUniversalTime().ToString('o')
    exit_code = $exitCode
    scope = 'NEW build only; no OLD build, Minecraft, or GameTest'
} | ConvertTo-Json | Set-Content -Encoding UTF8 (Join-Path $evidence 'build-03.json')
Get-Content (Join-Path $evidence 'build-03.log') -Tail 30
exit $exitCode
