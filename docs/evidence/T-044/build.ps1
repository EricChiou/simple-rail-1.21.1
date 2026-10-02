$ErrorActionPreference = 'Stop'
$evidence = 'docs/evidence/T-044'
$command = '.\gradlew.bat build --offline --console=plain --no-configuration-cache'
$started = (Get-Date).ToUniversalTime().ToString('o')
& .\gradlew.bat build --offline --console=plain --no-configuration-cache *> (Join-Path $evidence 'build.log')
$exitCode = $LASTEXITCODE
[ordered]@{
    command = $command
    cwd = (Resolve-Path '.').Path
    started_utc = $started
    finished_utc = (Get-Date).ToUniversalTime().ToString('o')
    exit_code = $exitCode
    scope = 'NEW build only; no OLD build, Minecraft, or GameTest'
} | ConvertTo-Json | Set-Content -Encoding UTF8 (Join-Path $evidence 'build.json')
Get-Content (Join-Path $evidence 'build.log') -Tail 28
exit $exitCode
