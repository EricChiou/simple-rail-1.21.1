$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '../../..')).Path
Set-Location $root
$package = Join-Path $root 'docs/test-packages/locomotive-chunks-R1'
New-Item -ItemType Directory -Force (Join-Path $package 'mods') | Out-Null
Copy-Item -LiteralPath 'build/libs/simplerail-1.0.0.jar' -Destination (Join-Path $package 'mods/simplerail-1.0.0.jar')
$hash = (Get-FileHash -Algorithm SHA256 (Join-Path $package 'mods/simplerail-1.0.0.jar')).Hash
$head = (git rev-parse HEAD).Trim()
$inputs = @(Get-ChildItem src -Recurse -File | Where-Object { $_.FullName -notmatch '\\.cache\\' })
$inputs += @(Get-Item build.gradle,settings.gradle,gradle.properties,gradlew,gradlew.bat)
$inputs += @(Get-ChildItem gradle -Recurse -File)
$rows = @($inputs | Sort-Object FullName | ForEach-Object {
    [ordered]@{ path=$_.FullName.Substring($root.Length+1).Replace('\','/'); sha256=(Get-FileHash -Algorithm SHA256 -LiteralPath $_.FullName).Hash }
})
$rows | ConvertTo-Json -Depth 5 | Set-Content -Encoding UTF8 (Join-Path $package 'source-inputs.json')
$ErrorActionPreference = 'Continue' # Git's CRLF warnings are stderr, not a failed diff.
$diff = @(git diff --no-ext-diff --binary HEAD -- src build.gradle settings.gradle gradle.properties 2> (Join-Path $PSScriptRoot 'diff-warnings.log'))
if ($LASTEXITCODE -ne 0) { throw 'git diff failed' }
foreach($file in @(git ls-files --others --exclude-standard -- src)) {
    $diff += @(git diff --no-ext-diff --binary --no-index -- NUL $file 2>> (Join-Path $PSScriptRoot 'diff-warnings.log'))
    if ($LASTEXITCODE -gt 1) { throw "git no-index diff failed: $file" }
}
$ErrorActionPreference = 'Stop'
$diff | Set-Content -Encoding UTF8 (Join-Path $package 'product.diff')
$cases = @(1..8 | ForEach-Object { 'LC-R1-{0:00}' -f $_ })
[ordered]@{
    package='locomotive-chunks-R1'; jarSha256=$hash; execution='user only'
    cases=@($cases | ForEach-Object { [ordered]@{ id=$_; actual=$null; status='pending user' } })
} | ConvertTo-Json -Depth 6 | Set-Content -Encoding UTF8 (Join-Path $package 'results.json')
[ordered]@{
    head=$head; workingTree='uncommitted source changes; product.diff includes all differences from HEAD, including earlier tasks'
    minecraft='1.21.1'; neoforge='21.1.251'; java=21; mod='1.0.0'
    tasks=@('T-076'); manualTasks=@('T-077','T-124'); scope='user-reported missing locomotive chunk loading; partial regression package, not full task acceptance'
    jar='mods/simplerail-1.0.0.jar'; jarSha256=$hash
    buildCommand='GRADLE_USER_HOME=C:\Users\Kinoko\.gradle; gradlew.bat --offline build'
    buildExitCode=0; gradleTest='NO-SOURCE'; eventAssertions=1125; tests='actual loader with isolated API doubles; no Minecraft'
    sourceFiles=$rows.Count; pendingManualCases=$cases.Count
    independentReview='R-06 pending'; gameTests='not executed by Agent'
} | ConvertTo-Json -Depth 5 | Set-Content -Encoding UTF8 (Join-Path $package 'manifest.json')
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
$zipPath=Join-Path $root 'docs/test-packages/locomotive-chunks-R1.zip'
if(Test-Path -LiteralPath $zipPath) { Remove-Item -LiteralPath $zipPath }
$archive=[IO.Compression.ZipFile]::Open($zipPath, [IO.Compression.ZipArchiveMode]::Create)
try {
    foreach($file in Get-ChildItem -LiteralPath $package -Recurse -File) {
        $entry=$file.FullName.Substring($package.Length+1).Replace('\','/')
        [IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive,$file.FullName,$entry,[IO.Compression.CompressionLevel]::Optimal) | Out-Null
    }
} finally { $archive.Dispose() }
Write-Output "JAR SHA256=$hash; source inputs=$($rows.Count); empty manual cases=$($cases.Count)"


