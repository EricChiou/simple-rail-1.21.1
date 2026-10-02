$ErrorActionPreference = 'Stop'
$evidence = Join-Path (Get-Location) 'docs/evidence/T-043'
$started = [DateTime]::UtcNow.ToString('o')
$ErrorActionPreference = 'Continue'
& .\gradlew.bat build t043Jar testT043 --offline --console=plain --no-configuration-cache -I docs/evidence/T-043/probe.init.gradle *> (Join-Path $evidence 'build.log')
$exitCode = $LASTEXITCODE
$ErrorActionPreference = 'Stop'
[ordered]@{
    command = '.\gradlew.bat build t043Jar testT043 --offline --console=plain --no-configuration-cache -I docs/evidence/T-043/probe.init.gradle'
    cwd = (Get-Location).Path
    started_utc = $started
    finished_utc = [DateTime]::UtcNow.ToString('o')
    exit_code = $exitCode
    scope = 'NEW build + evidence-only diagnostic jar + plain JVM model test; no OLD build, Minecraft client/server/GameTest'
} | ConvertTo-Json | Set-Content -Encoding UTF8 (Join-Path $evidence 'build.json')
exit $exitCode
