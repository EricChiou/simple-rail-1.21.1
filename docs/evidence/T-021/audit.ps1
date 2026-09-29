param([string]$Attempt = '01')
$ErrorActionPreference = 'Stop'
$evidence = Join-Path (Get-Location) 'docs/evidence/T-021'
$classes = Join-Path $evidence 'audit/classes'
New-Item -ItemType Directory -Force $classes | Out-Null
$gsonOriginal = 'C:\Users\Kinoko\.gradle\caches\modules-2\files-2.1\com.google.code.gson\gson\2.10.1\b3add478d4382b78ea20b1671390a858002feb6c\gson-2.10.1.jar'
$gson = Join-Path $evidence 'audit/gson-2.10.1.jar'
Copy-Item -LiteralPath $gsonOriginal -Destination $gson
$vanilla = 'C:\Users\Kinoko\.gradle\caches\neoformruntime\artifacts\minecraft_1.21.1_client.jar'
$records = [Collections.Generic.List[object]]::new()
function Record([string]$command, [scriptblock]$action, [string]$log) {
    $started = [DateTime]::UtcNow.ToString('o')
    $ErrorActionPreference = 'Continue'
    & $action *> (Join-Path $evidence $log)
    $code = $LASTEXITCODE
    $ErrorActionPreference = 'Stop'
    $records.Add([ordered]@{command=$command; cwd=(Get-Location).Path; startedUtc=$started; finishedUtc=[DateTime]::UtcNow.ToString('o'); exitCode=$code; log=$log; logEncoding='UTF-16LE'})
    $records | ConvertTo-Json -Depth 5 | Set-Content -Encoding utf8 (Join-Path $evidence ('audit-commands-' + $Attempt + '.json'))
    Get-Content (Join-Path $evidence $log)
    if ($code -ne 0) { exit $code }
}
[ordered]@{gson=$gson; gsonSha256=(Get-FileHash $gson).Hash; vanillaArchive=$vanilla; vanillaSha256=(Get-FileHash $vanilla).Hash; runtimeClasspath=@($classes,$gson); scope='Minecraft jar is ZipFile input only, not on runtime classpath'} | ConvertTo-Json -Depth 5 | Set-Content -Encoding utf8 (Join-Path $evidence 'audit-classpath.json')
Record 'javac --release 21 -proc:none -encoding UTF-8 -Xlint:all -Werror -cp docs/evidence/T-021/audit/gson-2.10.1.jar -d docs/evidence/T-021/audit/classes docs/evidence/T-021/audit/ResourceAudit.java' {
    javac --release 21 -proc:none -encoding UTF-8 -Xlint:all -Werror -cp $gson -d $classes docs/evidence/T-021/audit/ResourceAudit.java
} ('audit-compile-' + $Attempt + '.log')
Record 'java -Djava.awt.headless=true -cp <audit/classes;gson-2.10.1.jar> ResourceAudit D:/workspace/java/simple-rail/src/main/resources src/main/resources docs/evidence/T-021 <minecraft_1.21.1_client.jar as ZIP>' {
    java '-Djava.awt.headless=true' -cp ($classes + ';' + $gson) ResourceAudit D:/workspace/java/simple-rail/src/main/resources src/main/resources $evidence $vanilla
} ('audit-run-' + $Attempt + '.log')
