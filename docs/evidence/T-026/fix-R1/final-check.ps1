$ErrorActionPreference='Stop'
$taskEvidence=Join-Path (Get-Location) 'docs/evidence/T-026/fix-R1'
function Read-Utf8([string]$path){[IO.File]::ReadAllText((Resolve-Path -LiteralPath $path),[Text.Encoding]::UTF8)}
function Normalize([string]$text){$text.Replace([string][char]13,'').Trim()}
$task=Read-Utf8 'TASK.md'
$before=Read-Utf8 (Join-Path $taskEvidence 'before/TASK.md')
$pattern='(?ms)^### (T-\d{3})[^\r\n]*\r?\n(.*?)(?=^### T-|^## |\z)'
$blocks=@([regex]::Matches($task,$pattern))
$oldBlocks=@([regex]::Matches($before,$pattern))
$ids=@($blocks|ForEach-Object {$_.Groups[1].Value})
$dependencies=@{};$missing=@();$statusCounts=@{};$otherChanged=@()
foreach($block in $blocks){
    $id=$block.Groups[1].Value;$body=$block.Groups[2].Value
    $dependencies[$id]=@([regex]::Matches([regex]::Match($body,'(?m)^- 前置任務[^\r\n]*').Value,'T-\d{3}')|ForEach-Object {$_.Value})
    foreach($dep in $dependencies[$id]){if($ids -notcontains $dep){$missing+=($id+' -> '+$dep)}}
    $status=[regex]::Match($body,'(?m)^- 狀態：([^\r\n]*)').Groups[1].Value
    if(-not $statusCounts.ContainsKey($status)){$statusCounts[$status]=0}
    $statusCounts[$status]++
    if($id -notin @('T-025','T-026')){
        $oldBody=($oldBlocks|Where-Object {$_.Groups[1].Value -eq $id}).Groups[2].Value
        if((Normalize $body) -ne (Normalize $oldBody)){$otherChanged+=$id}
    }
}
$resolved=[Collections.Generic.HashSet[string]]::new()
do{
    $advanced=$false
    foreach($id in $ids){
        if(-not $resolved.Contains($id) -and @($dependencies[$id]|Where-Object {-not $resolved.Contains($_)}).Count -eq 0){
            [void]$resolved.Add($id);$advanced=$true
        }
    }
}while($advanced)
$definitionPattern='(?m)^### T-\d{3}[^\r\n]*|^- 前置任務[^\r\n]*'
$oldDefinitions=@([regex]::Matches($before,$definitionPattern)|ForEach-Object {$_.Value})
$definitions=@([regex]::Matches($task,$definitionPattern)|ForEach-Object {$_.Value})
$coveragePattern='(?ms)^## [^\r\n]*覆蓋[^\r\n]*\r?\n.*?(?=^## |\z)'
$coverageNow=[regex]::Match($task,$coveragePattern).Value
$coverageBefore=[regex]::Match($before,$coveragePattern).Value
$coverageStable=([regex]::Matches($coverageNow,'T-\d{3}').Value -join ',') -eq ([regex]::Matches($coverageBefore,'T-\d{3}').Value -join ',')
$review=Read-Utf8 'REVIEW.md';$oldReview=Read-Utf8 (Join-Path $taskEvidence 'before/REVIEW.md')
$historyStable=(Normalize $oldReview.Substring($oldReview.IndexOf('## 8. '))) -eq (Normalize $review.Substring($review.IndexOf('## 8. '),$review.IndexOf('## 33. ')-$review.IndexOf('## 8. ')))
$migration=Read-Utf8 'MIGRATION.md';$oldMigration=Read-Utf8 (Join-Path $taskEvidence 'before/MIGRATION.md')
$requirementsStable=$true
foreach($section in @(4)){
    $sectionPattern='(?ms)^## '+$section+'[.] [^\r\n]*\r?\n.*?(?=^## |\z)'
    if((Normalize ([regex]::Match($migration,$sectionPattern).Value)) -ne (Normalize ([regex]::Match($oldMigration,$sectionPattern).Value))){$requirementsStable=$false}
}
$decisionsStable=$true
foreach($number in 1..8){
    $decisionPattern='(?m)^[|] D'+$number+' [|][^\r\n]*'
    $oldLine=[regex]::Match($oldMigration,$decisionPattern).Value
    $line=[regex]::Match($migration,$decisionPattern).Value
    if($number -eq 6){$oldLine=($oldLine -split '[|]')[2];$line=($line -split '[|]')[2]}
    if(-not $oldLine -or $line -ne $oldLine){$decisionsStable=$false}
}
$fingerprints=Get-Content (Join-Path $taskEvidence 'inputs-before.json') -Raw -Encoding UTF8|ConvertFrom-Json
$changedProduct=@($fingerprints|Where-Object {(Get-FileHash -LiteralPath $_.path).Hash -ne $_.sha256})
$stages=@([regex]::Matches($task,'(?m)^## 階段 ([0-8])[^\r\n]*'));$stageCounts=@()
for($i=0;$i -lt $stages.Count;$i++){
    $end=if($i+1 -lt $stages.Count){$stages[$i+1].Index}else{$task.Length}
    $stageCounts+=[regex]::Matches($task.Substring($stages[$i].Index,$end-$stages[$i].Index),'(?m)^### T-\d{3}').Count
}
$pending=0;$dev=0;$manualFailed=0;$blocked=0;$manualPassed=0
foreach($key in $statusCounts.Keys){
    if($key -eq '待執行'){$pending+=$statusCounts[$key]}
    if($key.StartsWith('開發完成')){$dev+=$statusCounts[$key]}
    if($key.StartsWith('人工測試不通過')){$manualFailed+=$statusCounts[$key]}
    if($key.StartsWith('人工測試通過')){$manualPassed+=$statusCounts[$key]}
    if($key.StartsWith('受阻')){$blocked+=$statusCounts[$key]}
}
$missingLinks=@();$markdownProblems=@()
foreach($path in @('TASK.md','MIGRATION.md','REVIEW.md','docs/evidence/T-026/fix-R1/README.md')){
    $content=Read-Utf8 $path;$full=(Resolve-Path -LiteralPath $path).Path
    foreach($match in [regex]::Matches($content,'\[[^\]]*\]\(([^)]+)\)')){
        $target=$match.Groups[1].Value
        if($target -match '^(https?://|#)' -or $target -match '[<>]'){continue}
        $resolvedPath=[IO.Path]::GetFullPath((Join-Path (Split-Path $full) ($target -split '#')[0]))
        if($resolvedPath -eq (Join-Path $taskEvidence 'final-check.json')){continue}
        if(-not (Test-Path -LiteralPath $resolvedPath)){$missingLinks+=($path+' -> '+$target)}
    }
    if([regex]::Matches($content,('(?m)^'+(([string][char]96)*3))).Count % 2 -ne 0){$markdownProblems+=($path+': unbalanced fences')}
    $columns=0
    foreach($row in ($content -split '\r?\n')){
        if($row -match '^[|]'){
            $newColumns=[regex]::Matches($row,'(?<!\\)[|]').Count
            if($columns -gt 0 -and $columns -ne $newColumns){$markdownProblems+=($path+': inconsistent table')}
            $columns=$newColumns
        }else{$columns=0}
    }
}
$ErrorActionPreference='Continue'
git diff --cached --binary *> (Join-Path $taskEvidence 'index-final.diff');$indexCode=$LASTEXITCODE
git -c core.safecrlf=false diff --check *> (Join-Path $taskEvidence 'diff-check-final.log');$diffCode=$LASTEXITCODE
$ErrorActionPreference='Stop'
function Index-Segments([string]$path){
    $text=Get-Content -LiteralPath $path -Raw;$map=@{}
    foreach($match in [regex]::Matches($text,'(?ms)^diff --git a/(.*?) b/[^\r\n]*\r?\n.*?(?=^diff --git |\z)')){$map[$match.Groups[1].Value]=$match.Value}
    $map
}
$indexBefore=Index-Segments (Join-Path $taskEvidence 'index-before.diff')
$indexAfter=Index-Segments (Join-Path $taskEvidence 'index-final.diff')
$indexDrift=@()
foreach($path in @(@($indexBefore.Keys)+@($indexAfter.Keys)|Select-Object -Unique)){if($indexBefore[$path] -ne $indexAfter[$path]){$indexDrift+=$path}}
$indexProductDrift=@($indexDrift|Where-Object {$_ -notin @('MIGRATION.md','TASK.md','REVIEW.md')})
$package=Get-Content (Join-Path $taskEvidence 'package.json') -Raw -Encoding UTF8|ConvertFrom-Json
$packageRoot=(Resolve-Path 'docs/test-packages/T-026-R1-v1').Path
$packageManifest=Get-Content (Join-Path $packageRoot 'manifest.json') -Raw -Encoding UTF8|ConvertFrom-Json
$cases=Get-Content (Join-Path $packageRoot 'case-index.json') -Raw -Encoding UTF8|ConvertFrom-Json
$manual=Get-Content (Join-Path $packageRoot 'results.json') -Raw -Encoding UTF8|ConvertFrom-Json
$artifact=Get-Content (Join-Path $taskEvidence 'artifact.json') -Raw -Encoding UTF8|ConvertFrom-Json
$audit=Get-Content (Join-Path $taskEvidence 'audit-results-02.json') -Raw -Encoding UTF8|ConvertFrom-Json
$currentFingerprints=Get-Content (Join-Path $taskEvidence 'source-fingerprints.json') -Raw -Encoding UTF8|ConvertFrom-Json
$postAuditDrift=@($currentFingerprints|Where-Object {(Get-FileHash $_.path).Hash -ne $_.sha256})
$t025=($blocks|Where-Object {$_.Groups[1].Value -eq 'T-025'}).Groups[2].Value
$t026=($blocks|Where-Object {$_.Groups[1].Value -eq 'T-026'}).Groups[2].Value
$approvedException=$migration.Contains('其他軌道維持原禁坡規格') -and $t025.Contains('僅高速 canMakeSlopes=true') -and $t026.Contains('高速例外可成坡') -and $review.Contains('兩基底禁坡')
$oldPackageInputs=Get-Content 'docs/evidence/T-092/packages.json' -Raw -Encoding UTF8|ConvertFrom-Json
$oldPackageChanges=@($oldPackageInputs|Where-Object {(Get-FileHash $_.zip).Hash -ne $_.zipSha256})
$checks=[ordered]@{
    fixed126Ids=($ids.Count -eq 126 -and @($ids|Select-Object -Unique).Count -eq 126 -and @(Compare-Object $ids @(1..126|ForEach-Object {'T-{0:D3}' -f $_})).Count -eq 0)
    titlesAndDependenciesStable=(@(Compare-Object $oldDefinitions $definitions).Count -eq 0)
    graphValid=($missing.Count -eq 0 -and $resolved.Count -eq 126)
    onlyT025T026TaskBodiesChanged=($otherChanged.Count -eq 0)
    coverageStable=$coverageStable
    stageCountsStable=($stages.Count -eq 9 -and ($stageCounts -join ',') -eq '4,17,8,18,16,26,23,8,6')
    countsReflectUserFailure=($pending -eq 97 -and $dev -eq 18 -and $manualFailed -eq 1 -and $manualPassed -eq 2 -and $blocked -eq 1)
    otherRequirementSection4Preserved=$requirementsStable
    d1ToD8Preserved=$decisionsStable
    reviewHistory8To32Preserved=$historyStable
    boundedProductChange=($changedProduct.Count -eq 2 -and @($changedProduct|Where-Object {-not $_.path.EndsWith('\block\HighSpeedRail.java') -and -not $_.path.EndsWith('\blockstates\high_speed_rail.json')}).Count -eq 0 -and $audit.failed -eq 0)
    stagedProductPreserved=($indexCode -eq 0 -and $indexProductDrift.Count -eq 0)
    linksValid=($missingLinks.Count -eq 0)
    markdownValid=($markdownProblems.Count -eq 0)
    diffCheck=($diffCode -eq 0)
    approvedHighSpeedOnlyException=$approvedException
    artifactFingerprintMatches=($postAuditDrift.Count -eq 0 -and (Get-FileHash $artifact.path).Hash -eq $artifact.sha256 -and (Get-FileHash 'build/libs/simplerail-1.0.0.jar').Hash -eq $artifact.sha256)
    packageFixedAndVerified=($package.exitCode -eq 0 -and $package.files -eq 18 -and $package.zipMismatches.Count -eq 0 -and (Get-FileHash $package.zip).Hash -eq $package.zipSha256 -and (Get-FileHash (Join-Path $packageRoot 'mods/simplerail-1.0.0.jar')).Hash -eq $artifact.sha256)
    sixBlankCaseGroups=($cases.Count -eq 6 -and $manual.Count -eq 6 -and @($cases|Where-Object {$null -ne $_.actualResult -or $null -ne $_.userConfirmation}).Count -eq 0 -and @($manual|Where-Object {$null -ne $_.result -or $null -ne $_.userConfirmation}).Count -eq 0)
    reviewAndFullT094StillPending=($packageManifest.manualHandoffReady -eq $false -and $packageManifest.fullT094Completed -eq $false)
    priorPackagesUnchanged=($oldPackageChanges.Count -eq 0)
}
$failed=@($checks.Keys|Where-Object {-not $checks[$_]})
[ordered]@{task='T-026';revision='fix-R1';utc=[DateTime]::UtcNow.ToString('o');scope='Developer document/dependency/scope/package check; no review approval or user game result';checks=$checks;failed=$failed;statusCounts=$statusCounts;stageCounts=$stageCounts;missingDependencies=$missing;otherChangedTasks=$otherChanged;changedExistingProductFiles=$changedProduct.path;observedIndexDrift=$indexDrift;stagedProductDrift=$indexProductDrift;missingLinks=$missingLinks;markdownProblems=$markdownProblems;artifactSha256=$artifact.sha256;packageSha256=$package.zipSha256;commands=@(@{command='git diff --cached --binary';exitCode=$indexCode},@{command='git -c core.safecrlf=false diff --check';exitCode=$diffCode})}|ConvertTo-Json -Depth 6|Set-Content -Encoding UTF8 (Join-Path $taskEvidence 'final-check.json')
Write-Output ('Report checks: '+$checks.Count+'; failures: '+$failed.Count)
if($failed.Count -gt 0){$failed|ForEach-Object {Write-Output $_};exit 1}
