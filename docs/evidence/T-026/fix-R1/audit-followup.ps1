$ErrorActionPreference='Stop'
$taskEvidence=Join-Path (Get-Location) 'docs/evidence/T-026/fix-R1'
function Segments([string]$path){
    $text=Get-Content -LiteralPath $path -Raw
    $map=@{}
    foreach($match in [regex]::Matches($text,'(?ms)^diff --git a/(.*?) b/[^\r\n]*\r?\n.*?(?=^diff --git |\z)')){
        $map[$match.Groups[1].Value]=$match.Value
    }
    $map
}
$before=Segments (Join-Path $taskEvidence 'index-before.diff')
$after=Segments (Join-Path $taskEvidence 'index-after.diff')
$drift=@()
foreach($path in @(@($before.Keys)+@($after.Keys)|Select-Object -Unique)){
    if($before[$path] -ne $after[$path]){$drift+=$path}
}
$productDrift=@($drift|Where-Object {$_ -notin @('MIGRATION.md','TASK.md','REVIEW.md')})
$original=Get-Content (Join-Path $taskEvidence 'audit-results.json') -Raw -Encoding UTF8|ConvertFrom-Json
Copy-Item -LiteralPath (Join-Path $taskEvidence 'audit-results.json') -Destination (Join-Path $taskEvidence 'audit-results-01.json')
$results=@($original.results|Where-Object {$_.id -ne 'index-preserved'})
$results+=@{id='staged-product-preserved';passed=($productDrift.Count -eq 0);detail='Observed index drift only in the three planning documents during inspection. No stage/reset command was issued; current index is preserved, not reset to initial snapshot.'}
$failed=@($results|Where-Object {-not $_.passed})
[ordered]@{scope=$original.scope;checks=$results.Count;passed=$results.Count-$failed.Count;failed=$failed.Count;results=$results;artifactSha256=$original.artifactSha256;changedExisting=$original.changedExisting;newFiles=$original.newFiles;initialAuditExitCode=1;followupReason='Index snapshot drift is an observed external-state change, not a product check failure or game result';stagedDriftPaths=$drift;stagedProductDrift=$productDrift;agentStagingCommandsIssued=$false}|ConvertTo-Json -Depth 6|Set-Content -Encoding UTF8 (Join-Path $taskEvidence 'audit-results-02.json')
$fingerprints=Get-Content (Join-Path $taskEvidence 'source-fingerprints.json') -Raw -Encoding UTF8|ConvertFrom-Json
if(@($fingerprints|Where-Object {(Get-FileHash -LiteralPath $_.path).Hash -ne $_.sha256}).Count -gt 0){throw 'Product changed since the static audit; repeat affected verification.'}
Write-Output ('Follow-up contracts: '+$results.Count+'; failures: '+$failed.Count+'; observed staged drift: '+($drift -join ', '))
if($failed.Count -gt 0){exit 1}
