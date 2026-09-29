$ErrorActionPreference = 'Stop'
$evidence = Join-Path (Get-Location) 'docs/evidence/T-021'
$records = [Collections.Generic.List[object]]::new()
function Record([string]$command, [scriptblock]$action, [string]$log, [int[]]$allowed = @(0)) {
    $started = [DateTime]::UtcNow.ToString('o')
    $ErrorActionPreference = 'Continue'
    & $action *> (Join-Path $evidence $log)
    $code = $LASTEXITCODE
    $ErrorActionPreference = 'Stop'
    $records.Add([ordered]@{command=$command; startedUtc=$started; finishedUtc=[DateTime]::UtcNow.ToString('o'); exitCode=$code; log=$log; logEncoding='UTF-16LE'})
    if ($allowed -notcontains $code) { throw "Unexpected exit $code for $command" }
}
Record 'java --version' { java --version } 'java-version.log'
Record 'javac -version' { javac -version } 'javac-version.log'
Record '.\gradlew.bat --version --offline --console=plain' { .\gradlew.bat --version --offline --console=plain } 'gradle-version.log'
Record 'git -c core.safecrlf=false diff -- src/main/resources src/main/templates' { git -c core.safecrlf=false diff -- src/main/resources src/main/templates } 'resource-text.diff'
$newTextPaths = @(rg --files src/main/resources | Where-Object { ($_ -like '*.json' -or $_ -like '*.mcmeta') -and $_ -ne 'src/main/resources\assets\simplerail\lang\en_us.json' })
foreach ($path in $newTextPaths) {
    $ErrorActionPreference = 'Continue'
    $patch = @(git -c core.safecrlf=false diff --no-index -- NUL $path 2>&1)
    $code = $LASTEXITCODE
    $ErrorActionPreference = 'Stop'
    if ($code -ne 1) { throw ('Unexpected no-index exit for ' + $path) }
    $patch | Add-Content -Encoding Unicode (Join-Path $evidence 'resource-text.diff')
    $records.Add([ordered]@{command=('git -c core.safecrlf=false diff --no-index -- NUL ' + $path); exitCode=$code; log='resource-text.diff'; logEncoding='UTF-16LE'})
}
$records | ConvertTo-Json -Depth 5 | Set-Content -Encoding utf8 (Join-Path $evidence 'commands.json')
$paths = @('build.gradle','settings.gradle','gradle.properties','gradle/wrapper/gradle-wrapper.properties') + @(rg --files src/main)
@($paths | ForEach-Object { $file = Get-FileHash -LiteralPath $_ -Algorithm SHA256; [ordered]@{path=$file.Path; sha256=$file.Hash} }) | ConvertTo-Json -Depth 5 | Set-Content -Encoding utf8 (Join-Path $evidence 'source-fingerprints.json')
$sourceReferences = @('docs/evidence/T-009/sources/target/net/neoforged/neoforge/resource/ResourcePackLoader.java','docs/evidence/T-009/sources/target/net/minecraft/client/renderer/texture/atlas/SpriteSourceList.java','docs/evidence/T-009/sources/target/net/neoforged/neoforge/client/textures/NamespacedDirectoryLister.java','docs/evidence/T-009/sources/target/net/minecraft/client/resources/model/BlockStateModelLoader.java','docs/evidence/T-015/sources/target/net/minecraft/client/renderer/ItemBlockRenderTypes.java','docs/evidence/T-010/state-domains.json','docs/evidence/T-009/source-manifest.json','docs/evidence/T-009/resource-map.json','docs/evidence/T-015/resources.json')
@($sourceReferences | ForEach-Object { [ordered]@{path=$_; sha256=(Get-FileHash -LiteralPath $_).Hash} }) | ConvertTo-Json -Depth 5 | Set-Content -Encoding utf8 (Join-Path $evidence 'source-references.json')
Write-Output 'Recorded versions, text-resource diff, full input fingerprints and fixed source references.'
