$ErrorActionPreference = 'Stop'
$evidence = Join-Path (Get-Location) 'docs/evidence/T-022'
$records = [Collections.Generic.List[object]]::new()
function Record([string]$command, [scriptblock]$action, [string]$log, [int[]]$allowed = @(0)) {
    $started = [DateTime]::UtcNow.ToString('o'); $ErrorActionPreference = 'Continue'
    & $action *> (Join-Path $evidence $log); $code = $LASTEXITCODE; $ErrorActionPreference = 'Stop'
    $records.Add([ordered]@{command=$command; startedUtc=$started; finishedUtc=[DateTime]::UtcNow.ToString('o'); exitCode=$code; log=$log; logEncoding='UTF-16LE'})
    $records | ConvertTo-Json -Depth 5 | Set-Content -Encoding utf8 (Join-Path $evidence 'commands.json')
    if ($allowed -notcontains $code) { throw "Unexpected exit $code for $command" }
}
Record 'java --version' { java --version } 'java-version.log'
Record 'javac -version' { javac -version } 'javac-version.log'
Record 'javap -classpath build/classes/java/main -p -s -c com.ericchiu.simplerail.registry.ModTags' {
    javap -classpath build/classes/java/main -p -s -c com.ericchiu.simplerail.registry.ModTags
} 'tags-bytecode.txt'
Record 'git diff -- src/main/java src/main/resources/data' { git diff -- src/main/java src/main/resources/data } 'source.diff'
$newPaths = @('src/main/java/com/ericchiu/simplerail/registry/ModTags.java') + @(rg --files src/main/resources/data)
foreach ($path in $newPaths) {
    $ErrorActionPreference = 'Continue'; $delta = @(git -c core.safecrlf=false diff --no-index -- NUL $path 2>&1); $code = $LASTEXITCODE; $ErrorActionPreference = 'Stop'
    if ($code -ne 1) { throw "Unexpected no-index exit: $path" }
    $delta | Add-Content -Encoding Unicode (Join-Path $evidence 'source.diff')
    $records.Add([ordered]@{command=('git -c core.safecrlf=false diff --no-index -- NUL ' + $path); exitCode=$code; log='source.diff'; logEncoding='UTF-16LE'})
}
$records | ConvertTo-Json -Depth 5 | Set-Content -Encoding utf8 (Join-Path $evidence 'commands.json')
$paths = @('build.gradle','settings.gradle','gradle.properties','gradle/wrapper/gradle-wrapper.properties') + @(rg --files src/main)
@($paths | ForEach-Object { [ordered]@{path=(Resolve-Path -LiteralPath $_).Path; sha256=(Get-FileHash -LiteralPath $_).Hash} }) | ConvertTo-Json -Depth 5 | Set-Content -Encoding utf8 (Join-Path $evidence 'source-fingerprints.json')
Copy-Item -LiteralPath 'build/libs/simplerail-1.0.0.jar' -Destination (Join-Path $evidence 'artifacts/simplerail-1.0.0.jar')
$head = git rev-parse HEAD
[ordered]@{task='T-022'; head=$head; jar='build/libs/simplerail-1.0.0.jar'; jarSha256=(Get-FileHash 'build/libs/simplerail-1.0.0.jar').Hash; scope='T-022 plus previously staged product changes; no commit, no Minecraft'; staticChecks=393; references=85; integrationLimitation='I-021-01 remains; not a T-092 ready game package'} | ConvertTo-Json | Set-Content -Encoding utf8 (Join-Path $evidence 'artifact.json')
Write-Output 'Saved JAR, versions, new product source delta, typed tag bytecode and full input fingerprints'
