$ErrorActionPreference = 'Stop'
$root = (Get-Location).Path
$evidence = Join-Path $root 'docs/evidence/T-092'
New-Item -ItemType Directory -Force (Join-Path $evidence 'before'), (Join-Path $evidence 'sources'), 'docs/evidence/T-093' | Out-Null
foreach ($name in @('TASK.md','MIGRATION.md','REVIEW.md')) { Copy-Item -LiteralPath $name -Destination (Join-Path $evidence ('before/' + $name)) }
git diff --cached --binary *> (Join-Path $evidence 'index-before.diff')
if ($LASTEXITCODE -ne 0) { throw 'Index capture failed' }
git status --short *> (Join-Path $evidence 'git-status-before.txt')
$baseline = Get-Content docs/evidence/T-022/source-fingerprints.json -Raw -Encoding utf8 | ConvertFrom-Json
foreach ($entry in $baseline) { if ((Get-FileHash -LiteralPath $entry.path).Hash -ne $entry.sha256) { throw ('T-022 input changed: ' + $entry.path) } }
$artifact = Get-Content docs/evidence/T-022/artifact.json -Raw -Encoding utf8 | ConvertFrom-Json
if ((Get-FileHash 'build/libs/simplerail-1.0.0.jar').Hash -ne $artifact.jarSha256 -or (Get-FileHash 'docs/evidence/T-022/artifacts/simplerail-1.0.0.jar').Hash -ne $artifact.jarSha256) { throw 'Build evidence JAR mismatch' }
$productFiles = @('build.gradle','settings.gradle','gradle.properties','gradlew','gradlew.bat','.gitignore')
foreach ($dir in @('src/main','src/generated','gradle')) {
    if (Test-Path -LiteralPath $dir) { $productFiles += Get-ChildItem -LiteralPath $dir -Recurse -File | ForEach-Object { $_.FullName.Substring($root.Length+1).Replace('\','/') } }
}
@($productFiles | Sort-Object -Unique | ForEach-Object { [ordered]@{path=$_; sha256=(Get-FileHash -LiteralPath $_).Hash} }) | ConvertTo-Json -Depth 5 | Set-Content -Encoding utf8 (Join-Path $evidence 'source-fingerprints.json')
$ErrorActionPreference = 'Continue'
git -c core.safecrlf=false diff --binary --no-ext-diff HEAD -- src build.gradle settings.gradle gradle.properties gradle gradlew gradlew.bat *> (Join-Path $evidence 'source.diff')
$diffCode = $LASTEXITCODE
$newPaths = @(git ls-files --others --exclude-standard -- src build.gradle settings.gradle gradle.properties gradle gradlew gradlew.bat)
$newDiffCodes = @()
foreach ($path in $newPaths) {
    $delta = @(git -c core.safecrlf=false diff --binary --no-index -- NUL $path 2>&1); $code = $LASTEXITCODE
    $delta | Add-Content -Encoding Unicode (Join-Path $evidence 'source.diff')
    $newDiffCodes += [ordered]@{path=$path; exitCode=$code}
}
$ErrorActionPreference = 'Stop'
if ($diffCode -ne 0 -or @($newDiffCodes | Where-Object { $_.exitCode -ne 1 }).Count -gt 0) { throw 'Product diff capture failed' }
foreach ($name in @('build-01.json','build-01.log','artifact.json','jar-contents.txt','neoforge.mods.toml','audit-results.json','audit-classpath.json','audit-commands-01.json','java-version.log','javac-version.log','recipes.json','data-map.json','loot-responsibility.json')) {
    Copy-Item -LiteralPath ('docs/evidence/T-022/' + $name) -Destination (Join-Path $evidence $name)
}
Copy-Item docs/evidence/T-021/gradle-version.log (Join-Path $evidence 'gradle-version.log')
Copy-Item docs/evidence/T-020/config-contract.md (Join-Path $evidence 'config-contract-reference.md')
Copy-Item docs/evidence/T-020/simplerail-common.toml (Join-Path $evidence 'default-config-reference.toml')
Copy-Item docs/evidence/T-021/state-coverage.json (Join-Path $evidence 'state-coverage-reference.json')
Add-Type -AssemblyName System.IO.Compression.FileSystem
$sourceArchive = (Resolve-Path 'build/moddev/artifacts/neoforge-21.1.251-sources.jar').Path
$archive = [IO.Compression.ZipFile]::OpenRead($sourceArchive)
$sourceRecords = @()
try {
    foreach ($name in @('net/minecraft/server/commands/LootCommand.java','net/minecraft/server/commands/ExecuteCommand.java','net/minecraft/world/item/crafting/ShapedRecipePattern.java','net/minecraft/world/item/crafting/Ingredient.java')) {
        $entry = $archive.GetEntry($name); if ($null -eq $entry) { throw ('Missing command/pattern source: ' + $name) }
        $destination = Join-Path $evidence ('sources/' + [IO.Path]::GetFileName($name))
        [IO.Compression.ZipFileExtensions]::ExtractToFile($entry, $destination, $false)
        $sourceRecords += [ordered]@{archive=$sourceArchive; entry=$name; snapshot=('sources/' + [IO.Path]::GetFileName($name)); sha256=(Get-FileHash $destination).Hash}
    }
} finally { $archive.Dispose() }
[ordered]@{archiveSha256=(Get-FileHash $sourceArchive).Hash; sources=$sourceRecords; scope='Fixed 1.21.1/21.1.251 command syntax source only; no game execution'} | ConvertTo-Json -Depth 5 | Set-Content -Encoding utf8 (Join-Path $evidence 'command-sources.json')
[ordered]@{tasks=@('T-092','T-093'); capturedUtc=[DateTime]::UtcNow.ToString('o'); reusedBuild='T-022 build-01'; buildExitCode=0; newBuildExecuted=$false; jarSha256=$artifact.jarSha256; baselineInputsChecked=$baseline.Count; productInputs=$productFiles.Count; diffExitCode=$diffCode; untrackedDiffs=$newDiffCodes; gameStarted=$false; sourcesReadOnly=$true} | ConvertTo-Json -Depth 6 | Set-Content -Encoding utf8 (Join-Path $evidence 'preparation.json')
Write-Output 'Verified unchanged T-022 inputs/JAR; saved full HEAD + untracked product delta; reused actual build evidence'
