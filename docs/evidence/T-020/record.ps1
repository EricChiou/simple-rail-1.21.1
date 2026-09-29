$ErrorActionPreference = 'Stop'
$taskEvidence = Join-Path (Get-Location) 'docs/evidence/T-020'
$records = [Collections.Generic.List[object]]::new()
function Record-Command([string]$label, [scriptblock]$action, [string]$log, [int[]]$allowedCodes = @(0)) {
    $started = [DateTime]::UtcNow.ToString('o')
    $ErrorActionPreference = 'Continue'
    & $action *> (Join-Path $taskEvidence $log)
    $code = $LASTEXITCODE
    $ErrorActionPreference = 'Stop'
    $records.Add([ordered]@{command=$label; startedUtc=$started; finishedUtc=[DateTime]::UtcNow.ToString('o'); exitCode=$code; log=$log; logEncoding='UTF-16LE'})
    if ($allowedCodes -notcontains $code) { throw "Unexpected exit code $code for $label" }
}
Record-Command 'java --version' { java --version } 'java-version.log'
Record-Command 'javac -version' { javac -version } 'javac-version.log'
Record-Command '.\gradlew.bat --version --offline --console=plain' { .\gradlew.bat --version --offline --console=plain } 'gradle-version.log'
Record-Command 'javap -classpath build/libs/simplerail-1.0.0.jar -p -c com.ericchiu.simplerail.SimpleRail com.ericchiu.simplerail.config.CommonConfig com.ericchiu.simplerail.config.CommonConfig$Snapshot' {
    javap -classpath build/libs/simplerail-1.0.0.jar -p -c com.ericchiu.simplerail.SimpleRail com.ericchiu.simplerail.config.CommonConfig 'com.ericchiu.simplerail.config.CommonConfig$Snapshot'
} 'config-bytecode.txt'
$mainPath = 'src/main/java/com/ericchiu/simplerail/SimpleRail.java'
$main = [IO.File]::ReadAllText((Resolve-Path $mainPath), [Text.Encoding]::UTF8)
$baseline = [regex]::Replace($main, '(?m)^import com\.ericchiu\.simplerail\.config\.CommonConfig;\r?\n', '')
$baseline = [regex]::Replace($baseline, '(?m)^import net\.neoforged\.fml\.ModContainer;\r?\n', '')
$baseline = $baseline.Replace('SimpleRail(IEventBus modEventBus, ModContainer modContainer)', 'SimpleRail(IEventBus modEventBus)')
$baseline = [regex]::Replace($baseline, '(?m)^        CommonConfig\.register\(modEventBus, modContainer\);\r?\n', '')
$beforePath = Join-Path $taskEvidence 'SimpleRail-before.java.txt'
[IO.File]::WriteAllText($beforePath, $baseline, [Text.UTF8Encoding]::new($false))
$previousFingerprints = Get-Content docs/evidence/T-019/source-fingerprints.json -Raw -Encoding utf8 | ConvertFrom-Json
$expectedMain = @($previousFingerprints | Where-Object { $_.path.EndsWith('\SimpleRail.java') })[0]
if ((Get-FileHash -LiteralPath $beforePath).Hash -ne $expectedMain.sha256) { throw 'Reconstructed T-019 entry does not match saved baseline fingerprint' }
Copy-Item -LiteralPath $mainPath -Destination (Join-Path $taskEvidence 'SimpleRail.java.txt')
Copy-Item -LiteralPath src/main/java/com/ericchiu/simplerail/config/CommonConfig.java -Destination (Join-Path $taskEvidence 'CommonConfig.java.txt')
Record-Command 'git diff --no-index -- docs/evidence/T-020/SimpleRail-before.java.txt src/main/java/com/ericchiu/simplerail/SimpleRail.java' {
    git -c core.safecrlf=false diff --no-index -- $beforePath $mainPath
} 'source.diff' @(1)
Record-Command 'git diff --no-index -- NUL src/main/java/com/ericchiu/simplerail/config/CommonConfig.java' {
    git -c core.safecrlf=false diff --no-index -- NUL src/main/java/com/ericchiu/simplerail/config/CommonConfig.java
} 'CommonConfig.diff' @(1)
Get-Content (Join-Path $taskEvidence 'CommonConfig.diff') | Add-Content -Encoding Unicode (Join-Path $taskEvidence 'source.diff')
$records | ConvertTo-Json -Depth 5 | Set-Content -Encoding utf8 (Join-Path $taskEvidence 'commands.json')
$paths = @('build.gradle','settings.gradle','gradle.properties','gradle/wrapper/gradle-wrapper.properties') + @(Get-ChildItem src/main -Recurse -File | ForEach-Object { $_.FullName })
@($paths | ForEach-Object { $fingerprint = Get-FileHash -Algorithm SHA256 -LiteralPath $_; [ordered]@{path=$fingerprint.Path; sha256=$fingerprint.Hash} }) | ConvertTo-Json -Depth 5 | Set-Content -Encoding utf8 (Join-Path $taskEvidence 'source-fingerprints.json')
$sourceReferences = @('docs/evidence/T-008/sources/neoforge/net/neoforged/neoforge/common/ModConfigSpec.java','docs/evidence/T-008/sources/fml/net/neoforged/fml/ModContainer.java','docs/evidence/T-008/sources/fml/net/neoforged/fml/config/ModConfig.java','docs/evidence/T-008/sources/fml/net/neoforged/fml/event/config/ModConfigEvent.java','docs/evidence/T-020/sources/IConfigSpec.java','docs/evidence/T-020/sources/LoadedConfig.java','docs/evidence/T-020/sources/OldCommonConfig.java.txt','docs/evidence/T-020/sources/OldConstants.java.txt')
@($sourceReferences | ForEach-Object { [ordered]@{path=$_; sha256=(Get-FileHash -LiteralPath $_).Hash} }) | ConvertTo-Json -Depth 5 | Set-Content -Encoding utf8 (Join-Path $taskEvidence 'source-references.json')
Write-Output 'Recorded versions, bytecode, exact T-019 baseline/source diff and fingerprints.'
