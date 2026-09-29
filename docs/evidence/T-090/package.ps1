$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem
$projectRoot = (Get-Location).Path
$evidenceRoot = Join-Path $projectRoot 'docs/evidence/T-090'
$jarPath = Join-Path $projectRoot 'build/libs/simplerail-1.0.0.jar'
$jarHash = (Get-FileHash -LiteralPath $jarPath -Algorithm SHA256).Hash
$head = (git rev-parse HEAD).Trim()
$commands = Get-Content (Join-Path $evidenceRoot 'commands.json') -Raw -Encoding utf8 | ConvertFrom-Json
if ($commands.buildExitCode -ne 0 -or $commands.javaExitCode -ne 0 -or $commands.javacExitCode -ne 0 -or $commands.gradleVersionExitCode -ne 0) {
    throw 'Build or tool version command did not succeed.'
}

$productFiles = @('build.gradle', 'gradle.properties', 'settings.gradle', 'gradlew', 'gradlew.bat')
foreach ($dir in @('src/main', 'src/generated', 'gradle')) {
    if (Test-Path $dir) {
        $productFiles += Get-ChildItem -LiteralPath $dir -Recurse -File | ForEach-Object {
            $_.FullName.Substring($projectRoot.Length + 1).Replace('\', '/')
        }
    }
}
$fingerprints = @($productFiles | Sort-Object -Unique | ForEach-Object {
    [ordered]@{path=$_; sha256=(Get-FileHash -LiteralPath $_ -Algorithm SHA256).Hash}
})
$fingerprints | ConvertTo-Json -Depth 5 | Set-Content -Encoding utf8 (Join-Path $evidenceRoot 'source-fingerprints.json')
git -c core.safecrlf=false diff --no-ext-diff HEAD -- src build.gradle gradle.properties settings.gradle gradle gradlew gradlew.bat |
    Set-Content -Encoding utf8 (Join-Path $evidenceRoot 'source.diff')
if ($LASTEXITCODE -ne 0) { throw 'Product diff failed.' }
jar tf $jarPath | Set-Content -Encoding utf8 (Join-Path $evidenceRoot 'jar-contents.txt')
if ($LASTEXITCODE -ne 0) { throw 'JAR listing failed.' }
$jarZip = [IO.Compression.ZipFile]::OpenRead($jarPath)
try {
    $jarEntries = @($jarZip.Entries | ForEach-Object {$_.FullName})
    $reader = [IO.StreamReader]::new($jarZip.GetEntry('META-INF/neoforge.mods.toml').Open())
    try {$metadata = $reader.ReadToEnd()} finally {$reader.Dispose()}
} finally {$jarZip.Dispose()}
if ($jarEntries -contains 'com/ericchiu/simplerail/Config.class') {throw 'Template Config class remains.'}
if (@($jarEntries | Where-Object {$_ -match '\.class$'}).Count -ne 2) {throw 'Unexpected framework classes.'}
if ($metadata -notmatch 'modId="simplerail"' -or $metadata -notmatch 'version="1\.0\.0"' -or
    $metadata -notmatch 'license="All Rights Reserved"' -or $metadata -notmatch 'versionRange="\[21\.1\.251,\)"' -or
    $metadata -notmatch 'versionRange="\[1\.21\.1\]"') {throw 'D8 metadata differs.'}
$metadata | Set-Content -Encoding utf8 (Join-Path $evidenceRoot 'neoforge.mods.toml')

$outputs = @()
foreach ($spec in @(
    @{task='T-090'; target='T-089'; prefix='T089'; baseCases=@('C-040'); clauses=@('§3 入口與網路','§6 階段 1'); reviewChecks=@('C-09')},
    @{task='T-091'; target='T-018'; prefix='T018'; baseCases=@('C-039','C-040'); clauses=@('§3 入口與生命週期','§6 階段 1'); reviewChecks=@('C-01','C-09')}
)) {
    $packageId = $spec.task + '-v1'
    $packageRoot = Join-Path $projectRoot ('docs/test-packages/' + $packageId)
    $zipPath = $packageRoot + '.zip'
    if ((Test-Path (Join-Path $packageRoot 'manifest.json')) -or (Test-Path $zipPath)) {
        throw ('Package already frozen; use a new package version: ' + $packageId)
    }
    New-Item -ItemType Directory -Path (Join-Path $packageRoot 'mods'),(Join-Path $packageRoot 'evidence') | Out-Null
    Copy-Item -LiteralPath $jarPath -Destination (Join-Path $packageRoot 'mods/simplerail-1.0.0.jar')
    Copy-Item -LiteralPath (Join-Path $evidenceRoot 'INSTALL.md') -Destination (Join-Path $packageRoot 'INSTALL.md')
    foreach ($name in @('source.diff','source-fingerprints.json','jar-contents.txt','neoforge.mods.toml','commands.json','build-01.log','java-version.log','javac-version.log','gradle-version.log')) {
        Copy-Item -LiteralPath (Join-Path $evidenceRoot $name) -Destination (Join-Path $packageRoot ('evidence/' + $name))
    }
    $caseIds = @(1..5 | ForEach-Object {'{0}-{1:D2}' -f $spec.prefix,$_})
    $manifest = [ordered]@{
        packageId=$packageId
        createdUtc=(Get-Date).ToUniversalTime().ToString('o')
        developerTasks=@($spec.task)
        manualTask=$spec.target
        cases=$caseIds
        sourceCases=$spec.baseCases
        migration=$spec.clauses
        review=@{id='R-01'; checks=$spec.reviewChecks; status='待審'; conclusion=$null}
        head=$head
        cleanCommit=$false
        productDiff='evidence/source.diff'
        sourceFingerprints='evidence/source-fingerprints.json'
        jar=@{path='mods/simplerail-1.0.0.jar'; sha256=$jarHash}
        versions=@{minecraft='1.21.1'; neoForge='21.1.251'; mod='1.0.0'; modId='simplerail'; license='All Rights Reserved'; javaMajor=21; buildJava='Temurin 21.0.12.1+1'; gradle='9.2.1'; modDevGradle='2.0.147'; parchmentMinecraft='1.21.1'; parchmentMappings='2024.11.17'}
        build=@{command=$commands.buildCommand; exitCode=$commands.buildExitCode; log='evidence/build-01.log'; test='NO-SOURCE'; gameStarted=$false}
        install='INSTALL.md'
        scenarios='CASES.md'
        optionalObservations='各 game directory 的 logs/latest.log、選用 debug.log／crash-reports；client F2 圖片在 screenshots。'
        requiredUserReply='任務完成／通過或失敗確認即可；附件與版本證明均選用。既有結案不要求重測。'
        historicalManualConfirmation=@{task=$spec.target; status='人工通過並已結案'; quote='我已驗證完 T-089、T-018，皆正確執行。'; artifactBinding=$null; note='先前整項回報不綁定本次包，不代填本包逐例結果。'}
        untested='本包未啟動 Minecraft；逐例結果空白；不代表正式功能或候選發行驗收。'
    }
    $manifest | ConvertTo-Json -Depth 8 | Set-Content -Encoding utf8 (Join-Path $packageRoot 'manifest.json')
    $results = [ordered]@{packageId=$packageId; userConfirmation=$null; actualVersion=$null; cases=@($caseIds | ForEach-Object {@{caseId=$_; actualResult=$null; status='未填（本包未測）'}}); note='選用回報模板；只需使用者確認任務完成，不要求逐例或附件。'}
    $results | ConvertTo-Json -Depth 6 | Set-Content -Encoding utf8 (Join-Path $packageRoot 'results.json')
    $files = @(Get-ChildItem -LiteralPath $packageRoot -Recurse -File | Sort-Object FullName | ForEach-Object {
        @{path=$_.FullName.Substring($packageRoot.Length+1).Replace('\','/'); sha256=(Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash}
    })
    $files | ConvertTo-Json -Depth 5 | Set-Content -Encoding utf8 (Join-Path $packageRoot 'files-manifest.json')
    foreach ($file in $files) {
        if ((Get-FileHash -LiteralPath (Join-Path $packageRoot $file.path) -Algorithm SHA256).Hash -ne $file.sha256) {throw 'Package file fingerprint mismatch.'}
    }
    if ((Get-FileHash -LiteralPath (Join-Path $packageRoot $manifest.jar.path) -Algorithm SHA256).Hash -ne $jarHash) {throw 'Copied JAR mismatch.'}
    $caseText = Get-Content (Join-Path $packageRoot 'CASES.md') -Raw -Encoding utf8
    foreach ($id in $caseIds) {if (-not $caseText.Contains($id)) {throw ('Missing case: '+$id)}}
    if (@($results.cases | Where-Object {$null -ne $_.actualResult}).Count -ne 0) {throw 'Actual result was prefilled.'}
    # Create portable ZIP entries explicitly; .NET Framework on Windows may use backslashes.
    $zipBuild = [IO.Compression.ZipFile]::Open($zipPath,[IO.Compression.ZipArchiveMode]::Create)
    try {
        foreach ($sourceFile in Get-ChildItem -LiteralPath $packageRoot -Recurse -File) {
            $relative = $sourceFile.FullName.Substring($packageRoot.Length+1).Replace('\','/')
            $entry = $zipBuild.CreateEntry($relative,[IO.Compression.CompressionLevel]::Optimal)
            $inputStream = [IO.File]::OpenRead($sourceFile.FullName)
            $outputStream = $entry.Open()
            try {$inputStream.CopyTo($outputStream)} finally {$inputStream.Dispose();$outputStream.Dispose()}
        }
    } finally {$zipBuild.Dispose()}
    $zip = [IO.Compression.ZipFile]::OpenRead($zipPath)
    try {
        if ($zip.Entries.Count -ne $files.Count+1) {throw 'ZIP entry count mismatch.'}
        foreach ($file in $files) {
            $entry = $zip.GetEntry($file.path)
            if (-not $entry) {throw ('ZIP missing '+$file.path)}
            $stream = $entry.Open()
            $hasher = [Security.Cryptography.SHA256]::Create()
            try {$hash=[BitConverter]::ToString($hasher.ComputeHash($stream)).Replace('-','')} finally {$stream.Dispose();$hasher.Dispose()}
            if ($hash -ne $file.sha256) {throw ('ZIP content mismatch '+$file.path)}
        }
    } finally {$zip.Dispose()}
    $outputs += [ordered]@{task=$spec.task; packageId=$packageId; path=$packageRoot; zip=$zipPath; zipSha256=(Get-FileHash -LiteralPath $zipPath -Algorithm SHA256).Hash; jarSha256=$jarHash; files=$files.Count+1; cases=$caseIds.Count; staticChecks='通過'; review='待審'; gameStarted=$false}
}
# Check that packaging did not mutate any product inputs.
foreach ($file in $fingerprints) {
    if ((Get-FileHash -LiteralPath $file.path -Algorithm SHA256).Hash -ne $file.sha256) {throw ('Product input changed: '+$file.path)}
}
$outputs | ConvertTo-Json -Depth 5 | Set-Content -Encoding utf8 (Join-Path $evidenceRoot 'packages.json')
Copy-Item -LiteralPath (Join-Path $evidenceRoot 'packages.json') -Destination 'docs/evidence/T-091/packages.json'
$outputs | ConvertTo-Json -Depth 5
