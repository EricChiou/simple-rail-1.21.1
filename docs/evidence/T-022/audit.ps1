$ErrorActionPreference = 'Stop'
$evidence = Join-Path (Get-Location) 'docs/evidence/T-022'
$classes = Join-Path $evidence 'audit/classes'
New-Item -ItemType Directory -Force $classes | Out-Null
$gson = Join-Path $evidence 'audit/gson-2.10.1.jar'
$vanilla = 'C:\Users\Kinoko\.gradle\caches\neoformruntime\artifacts\minecraft_1.21.1_client.jar'
$records = [Collections.Generic.List[object]]::new()
function Record([string]$command, [scriptblock]$action, [string]$log) {
    $started = [DateTime]::UtcNow.ToString('o'); $ErrorActionPreference = 'Continue'
    & $action *> (Join-Path $evidence $log); $code = $LASTEXITCODE; $ErrorActionPreference = 'Stop'
    $records.Add([ordered]@{command=$command; cwd=(Get-Location).Path; startedUtc=$started; finishedUtc=[DateTime]::UtcNow.ToString('o'); exitCode=$code; log=$log; logEncoding='UTF-16LE'})
    $records | ConvertTo-Json -Depth 5 | Set-Content -Encoding utf8 (Join-Path $evidence 'audit-commands-01.json')
    Get-Content (Join-Path $evidence $log)
    if ($code -ne 0) { exit $code }
}
[ordered]@{gson=$gson; gsonSha256=(Get-FileHash $gson).Hash; vanillaArchive=$vanilla; vanillaSha256=(Get-FileHash $vanilla).Hash; runtimeClasspath=@($classes,$gson); scope='Minecraft jar is ZipFile input only, not runtime classpath'} | ConvertTo-Json -Depth 5 | Set-Content -Encoding utf8 (Join-Path $evidence 'audit-classpath.json')
Record 'javac --release 21 -proc:none -encoding UTF-8 -Xlint:all -Werror -cp <local gson> -d <audit/classes> docs/evidence/T-022/audit/DataAudit.java' {
    javac --release 21 -proc:none -encoding UTF-8 -Xlint:all -Werror -cp $gson -d $classes docs/evidence/T-022/audit/DataAudit.java
} 'audit-compile-01.log'
Record 'java -cp <audit/classes;local gson> DataAudit D:/workspace/java/simple-rail/src/main/resources src/main/resources docs/evidence/T-022 <minecraft_1.21.1_client.jar as ZIP>' {
    java -cp ($classes + ';' + $gson) DataAudit D:/workspace/java/simple-rail/src/main/resources src/main/resources $evidence $vanilla
} 'audit-run-01.log'
