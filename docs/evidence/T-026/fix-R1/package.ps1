$ErrorActionPreference='Stop'
$taskEvidence=Join-Path (Get-Location) 'docs/evidence/T-026/fix-R1'
$packageRoot=Join-Path (Get-Location) 'docs/test-packages/T-026-R1-v1'
$zipPath=Join-Path (Get-Location) 'docs/test-packages/T-026-R1-v1.zip'
if(Test-Path -LiteralPath $zipPath){throw 'Frozen package exists; create a new revision instead.'}
New-Item -ItemType Directory -Force -Path (Join-Path $packageRoot 'mods'),(Join-Path $packageRoot 'evidence')|Out-Null
$artifact=Get-Content (Join-Path $taskEvidence 'artifact.json') -Raw -Encoding UTF8|ConvertFrom-Json
Copy-Item -LiteralPath $artifact.path -Destination (Join-Path $packageRoot 'mods/simplerail-1.0.0.jar')
$names=@('artifact.json','build-01.json','build-01.log','source.diff','source-fingerprints.json','audit-results-01.json','audit-results-02.json','audit-commands.json','state-coverage.json','model-sources.json')
foreach($name in $names){Copy-Item -LiteralPath (Join-Path $taskEvidence $name) -Destination (Join-Path $packageRoot ('evidence/'+$name))}
$cases=1..6|ForEach-Object {[ordered]@{id=('R1-{0:D3}' -f $_);task='T-026';issue=if($_ -le 2){'I-026-01'}else{'I-026-02'};steps='CASES.md';environments=@('SP','DS');actualResult=$null;userConfirmation=$null}}
$cases|ConvertTo-Json -Depth 5|Set-Content -Encoding UTF8 (Join-Path $packageRoot 'case-index.json')
$cases|ForEach-Object {[ordered]@{caseId=$_.id;result=$null;userConfirmation=$null;optionalNotes=$null}}|ConvertTo-Json|Set-Content -Encoding UTF8 (Join-Path $packageRoot 'results.json')
[ordered]@{
    id='T-026-R1-v1';dateUtc=[DateTime]::UtcNow.ToString('o');tasks=@('T-025 correction','T-026 partial retest');cases=@($cases.id)
    migration=@('Section 3 shared base/high_speed_rail','Section 6 stage 3');review=@('R-03 pending','R-F pending')
    head=$artifact.head;jar='mods/simplerail-1.0.0.jar';jarSha256=$artifact.sha256
    minecraft=$artifact.minecraft;neoforge=$artifact.neoforge;mod=$artifact.mod;java=$artifact.java;gradle=$artifact.gradle;license=$artifact.license;parchment=$artifact.parchment
    scope='User-approved high-speed-only slope exception and targeted reversal diagnostic/retest; not full T-094'
    manualHandoffReady=$false;reason='Code review pending; no user retest result';manualResult=$null;gameStartedByAgent=$false;fullT094Completed=$false
}|ConvertTo-Json -Depth 6|Set-Content -Encoding UTF8 (Join-Path $packageRoot 'manifest.json')
Get-ChildItem -LiteralPath $packageRoot -Recurse -File|Where-Object {$_.Name -ne 'files-manifest.json'}|ForEach-Object {@{path=$_.FullName.Substring($packageRoot.Length+1).Replace('\','/');sha256=(Get-FileHash $_.FullName).Hash}}|ConvertTo-Json|Set-Content -Encoding UTF8 (Join-Path $packageRoot 'files-manifest.json')
Add-Type -AssemblyName System.IO.Compression.FileSystem
Add-Type -AssemblyName System.IO.Compression
$stream=[IO.File]::Open($zipPath,[IO.FileMode]::CreateNew)
$created=[IO.Compression.ZipArchive]::new($stream,[IO.Compression.ZipArchiveMode]::Create,$false)
try{
    foreach($file in Get-ChildItem $packageRoot -Recurse -File){
        $portableName=$file.FullName.Substring($packageRoot.Length+1).Replace('\','/')
        [IO.Compression.ZipFileExtensions]::CreateEntryFromFile($created,$file.FullName,$portableName,[IO.Compression.CompressionLevel]::Optimal)|Out-Null
    }
}finally{$created.Dispose();$stream.Dispose()}
$zip=[IO.Compression.ZipFile]::OpenRead($zipPath)
function Entry-Hash($entry){$stream=$entry.Open();$hash=[Security.Cryptography.SHA256]::Create();try{[BitConverter]::ToString($hash.ComputeHash($stream)).Replace('-','')}finally{$stream.Dispose();$hash.Dispose()}}
$mismatches=@()
try{
    foreach($file in Get-ChildItem $packageRoot -Recurse -File){
        $entryName=$file.FullName.Substring($packageRoot.Length+1).Replace('\','/')
        $entry=$zip.GetEntry($entryName)
        if($null -eq $entry -or (Entry-Hash $entry) -ne (Get-FileHash $file.FullName).Hash){$mismatches+=$entryName}
    }
    $entryCount=$zip.Entries.Count
}finally{$zip.Dispose()}
[ordered]@{id='T-026-R1-v1';command='powershell -NoProfile -ExecutionPolicy Bypass -File docs/evidence/T-026/fix-R1/package.ps1';zip=$zipPath;zipSha256=(Get-FileHash $zipPath).Hash;jarSha256=$artifact.sha256;files=$entryCount;caseGroups=$cases.Count;exitCode=if($mismatches.Count -eq 0){0}else{1};zipMismatches=$mismatches;scope='Offline packaging and ZIP byte verification only; no game or full T-094 execution'}|ConvertTo-Json -Depth 5|Set-Content -Encoding UTF8 (Join-Path $taskEvidence 'package.json')
Write-Output ('Package files: '+$entryCount+'; case groups: '+$cases.Count+'; byte mismatches: '+$mismatches.Count)
if($mismatches.Count -gt 0){exit 1}
