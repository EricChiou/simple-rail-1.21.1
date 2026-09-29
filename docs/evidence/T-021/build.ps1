$ErrorActionPreference = 'Stop'
$evidence = Join-Path (Get-Location) 'docs/evidence/T-021'
$started = [DateTime]::UtcNow.ToString('o')
$ErrorActionPreference = 'Continue'
& .\gradlew.bat build --offline --console=plain --no-configuration-cache *> (Join-Path $evidence 'build-01.log')
$code = $LASTEXITCODE
$ErrorActionPreference = 'Stop'
[ordered]@{command='.\gradlew.bat build --offline --console=plain --no-configuration-cache'; cwd=(Get-Location).Path; startedUtc=$started; finishedUtc=[DateTime]::UtcNow.ToString('o'); exitCode=$code; logEncoding='UTF-16LE'; scope='NEW build only; no OLD build or Minecraft'} | ConvertTo-Json | Set-Content -Encoding utf8 (Join-Path $evidence 'build-01.json')
Get-Content (Join-Path $evidence 'build-01.log') -Tail 25
exit $code
