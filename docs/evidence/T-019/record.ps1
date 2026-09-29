$ErrorActionPreference = 'Stop'
$taskEvidence = Join-Path (Get-Location) 'docs/evidence/T-019'
$records = [System.Collections.Generic.List[object]]::new()
function Record-Command([string]$label, [scriptblock]$action, [string]$outputFile, [int[]]$allowedExitCodes = @(0)) {
    $started = [DateTime]::UtcNow.ToString('o')
    $ErrorActionPreference = 'Continue'
    & $action *> (Join-Path $taskEvidence $outputFile)
    $code = $LASTEXITCODE
    $ErrorActionPreference = 'Stop'
    $records.Add([ordered]@{ command = $label; exitCode = $code; startedUtc = $started; finishedUtc = [DateTime]::UtcNow.ToString('o'); log = $outputFile; logEncoding = 'UTF-16LE' })
    if ($allowedExitCodes -notcontains $code) { throw "Unexpected exit code $code for $label" }
}
Record-Command 'java -version' { java -version } 'java-version.log'
Record-Command 'javac -version' { javac -version } 'javac-version.log'
Record-Command 'javap -classpath build/libs/simplerail-1.0.0.jar -p -c -s com.ericchiu.simplerail.SimpleRail com.ericchiu.simplerail.registry.ModBlocks com.ericchiu.simplerail.registry.ModItems com.ericchiu.simplerail.registry.ModCreativeTabs' {
    javap -classpath build/libs/simplerail-1.0.0.jar -p -c -s com.ericchiu.simplerail.SimpleRail com.ericchiu.simplerail.registry.ModBlocks com.ericchiu.simplerail.registry.ModItems com.ericchiu.simplerail.registry.ModCreativeTabs
} 'registry-bytecode.txt'
Record-Command 'git diff -- src/main/java/com/ericchiu/simplerail/SimpleRail.java' { git diff -- src/main/java/com/ericchiu/simplerail/SimpleRail.java } 'source.diff'
foreach ($file in @('ModBlocks.java','ModItems.java','ModCreativeTabs.java')) {
    $newPath = 'src/main/java/com/ericchiu/simplerail/registry/' + $file
    Record-Command ("git diff --no-index -- NUL $newPath") { git diff --no-index -- NUL $newPath } ($file + '.diff') @(1)
    Get-Content (Join-Path $taskEvidence ($file + '.diff')) | Add-Content -Encoding Unicode (Join-Path $taskEvidence 'source.diff')
}
Record-Command 'git diff --cached --binary' { git diff --cached --binary } 'preexisting-index.diff'
$records | ConvertTo-Json -Depth 6 | Set-Content -Encoding utf8 (Join-Path $taskEvidence 'commands.json')
Write-Output ("Recorded {0} commands; no product classes were executed." -f $records.Count)
