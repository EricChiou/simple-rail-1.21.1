. (Join-Path $PSScriptRoot 'final-prefix.ps1')
$oldBlocks = @([regex]::Matches($oldTask, '(?ms)^### (T-\d{3})[^\r\n]*\r?\n(.*?)(?=^### T-|^## |\z)'))
$otherChanged = @()
foreach($block in $taskBlocks) {
    $id=$block.Groups[1].Value
    if($id -eq 'T-025'){continue}
    $oldBody=($oldBlocks|Where-Object {$_.Groups[1].Value -eq $id}).Groups[2].Value
    if($block.Groups[2].Value.Trim() -ne $oldBody.Trim()){$otherChanged+=$id}
}
$audit=Read-Json (Join-Path $taskEvidence 'audit-results-01.json')
$build=Read-Json (Join-Path $taskEvidence 'build-01.json')
$artifact=Read-Json (Join-Path $taskEvidence 'artifact.json')
$sources=Read-Json (Join-Path $taskEvidence 'source-references.json')
$fingerprints=Read-Json (Join-Path $taskEvidence 'source-fingerprints.json')
$changedSources=@($sources|Where-Object {(Get-FileHash -LiteralPath $_.snapshot).Hash -ne $_.sha256})
$changedProduct=@($fingerprints|Where-Object {(Get-FileHash -LiteralPath $_.path).Hash -ne $_.sha256})
$oldMigration=Read-Utf8 (Join-Path $taskEvidence 'before/MIGRATION.md')
$migration=Read-Utf8 'MIGRATION.md'
$decisionsStable=$true
foreach($id in 1..8) {
    $pattern='(?m)^[|] D'+$id+' [|][^\r\n]*'
    $oldLine=[regex]::Match($oldMigration,$pattern).Value
    $newLine=[regex]::Match($migration,$pattern).Value
    if($id -eq 6) {
        $oldLine=($oldLine -split '[|]')[2].Trim()
        $newLine=($newLine -split '[|]')[2].Trim()
    }
    if(-not $oldLine -or $oldLine -ne $newLine){$decisionsStable=$false}
}
function Section([string]$text,[int]$section) {
    [regex]::Match($text, ('(?ms)^## '+$section+'[.] [^\r\n]*\r?\n.*?(?=^## |\z)')).Value.Trim()
}
$requirementsStable=(Section $oldMigration 3) -eq (Section $migration 3) -and (Section $oldMigration 4) -eq (Section $migration 4)
$reviewInputs=Read-Json 'docs/evidence/R-01/reviewed-inputs.json'
$changedPriorEvidence=@($reviewInputs|Where-Object {$_.path -match 'docs[\\/]evidence' -and (Get-FileHash -LiteralPath $_.path).Hash -ne $_.sha256})
$packages=Read-Json 'docs/evidence/T-092/packages.json'
$changedPackages=@($packages|Where-Object {(Get-FileHash -LiteralPath $_.zip).Hash -ne $_.zipSha256})
$pendingCount=0;$developerCount=0;$blockedCount=0
foreach($key in $statusCounts.Keys) {
    if($key -eq '待執行'){$pendingCount+=$statusCounts[$key]}
    if($key.StartsWith('開發完成')){$developerCount+=$statusCounts[$key]}
    if($key.StartsWith('受阻')){$blockedCount+=$statusCounts[$key]}
}
$t025=($taskBlocks|Where-Object {$_.Groups[1].Value -eq 'T-025'}).Groups[2].Value
$t092=($taskBlocks|Where-Object {$_.Groups[1].Value -eq 'T-092'}).Groups[2].Value
$t027=($taskBlocks|Where-Object {$_.Groups[1].Value -eq 'T-027'}).Groups[2].Value
$markdownProblems=@()
foreach($path in $documentPaths) {
    $content=Read-Utf8 $path
    $fencePattern='(?m)^'+(([string][char]96)*3)
    if([regex]::Matches($content,$fencePattern).Count % 2 -ne 0){$markdownProblems+=($path+': unbalanced code fences')}
    if($content.Contains([char]0xFFFD)){$markdownProblems+=($path+': replacement character')}
    $rows=@($content -split '\r?\n');$columns=0
    foreach($row in $rows) {
        if($row -match '^[|]') {
            $currentColumns=[regex]::Matches($row,'(?<!\\)[|]').Count
            if($columns -gt 0 -and $currentColumns -ne $columns){$markdownProblems+=($path+': inconsistent table column count: '+$row)}
            $columns=$currentColumns
        } else {$columns=0}
    }
}
$ErrorActionPreference='Continue'
git diff --cached --binary *> (Join-Path $taskEvidence 'index-final.diff');$indexCode=$LASTEXITCODE
git -c core.safecrlf=false diff --check *> (Join-Path $taskEvidence 'diff-check-final.log');$diffCode=$LASTEXITCODE
git status --short *> (Join-Path $taskEvidence 'git-status-final.txt');$statusCode=$LASTEXITCODE
git diff HEAD --binary *> (Join-Path $taskEvidence 'source.diff');$diffHeadCode=$LASTEXITCODE
$untracked=@(git ls-files --others --exclude-standard)
$untrackedCommands=@()
foreach($path in $untracked) {
    if($path -like 'src/*') {
        git diff --no-index --binary -- NUL $path *>> (Join-Path $taskEvidence 'source.diff')
        $untrackedCommands+=@{command=('git diff --no-index --binary -- NUL '+$path);exitCode=$LASTEXITCODE;meaning='1 means expected differences';log='source.diff'}
    }
}
$ErrorActionPreference='Stop'
$checks=[ordered]@{
    taskIds126Unique=($taskIds.Count -eq 126 -and @($taskIds|Select-Object -Unique).Count -eq 126 -and @(Compare-Object $taskIds $expectedIds).Count -eq 0)
    titlesAndDependenciesStable=$definitionStable
    allDependenciesExist=($missingDependencies.Count -eq 0)
    graphAcyclic=($unresolved.Count -eq 0 -and $resolved.Count -eq 126)
    nineStages=($stages.Count -eq 9)
    phaseCountsMatchOverview=(@($stageCounts|Where-Object {-not $_.matches}).Count -eq 0 -and (($stageCounts|ForEach-Object {$_.count}) -join ',') -eq '4,17,8,18,16,26,23,8,6')
    coverageUnchanged=$coverageStable
    onlyT025TaskBodyChanged=($otherChanged.Count -eq 0)
    t025DeveloperOnly=($t025.Contains('- 狀態：開發完成') -and $t025.Contains('R-03 程式審查待審') -and $t025.Contains('人工遊戲未執行'))
    progressCounts=($developerCount -eq 18 -and $pendingCount -eq 98 -and $blockedCount -eq 1)
    t092RemainsBlocked=($t092.Contains('- 狀態：受阻'))
    nextT027Pending=($t027.Contains('- 狀態：待執行') -and ($dependencies['T-027'] -join ',') -eq 'T-025,T-010,T-020')
    t002NoDescendants=(@($dependencies.Values|ForEach-Object {$_}|Where-Object {$_ -eq 'T-002'}).Count -eq 0)
    t003NoDescendants=(@($dependencies.Values|ForEach-Object {$_}|Where-Object {$_ -eq 'T-003'}).Count -eq 0)
    requirementSections3And4Unchanged=$requirementsStable
    d1ToD8DecisionTextStable=$decisionsStable
    reviewHistory8To30Unchanged=$reviewHistoryStable
    priorR01EvidenceUnchanged=($changedPriorEvidence.Count -eq 0)
    frozenT092T093ZipsUnchanged=($changedPackages.Count -eq 0)
    localLinksExist=($missingLinks.Count -eq 0)
    markdownFencesEncodingTables=($markdownProblems.Count -eq 0)
    actualNewBuild=($build.exitCode -eq 0)
    actualStaticChecks=($audit.checks -eq 40 -and $audit.failed -eq 0)
    frozenJarHash=((Get-FileHash -LiteralPath $artifact.path).Hash -eq $artifact.sha256 -and (Get-FileHash -LiteralPath 'build/libs/simplerail-1.0.0.jar').Hash -eq $artifact.sha256)
    sourceSnapshots13Unchanged=($sources.Count -eq 13 -and $changedSources.Count -eq 0)
    compiledProductFingerprintsUnchanged=($changedProduct.Count -eq 0)
    indexPreserved=($indexCode -eq 0 -and (Get-FileHash (Join-Path $taskEvidence 'index-final.diff')).Hash -eq (Get-FileHash (Join-Path $taskEvidence 'index-before.diff')).Hash)
    diffCheck=($diffCode -eq 0)
    gitStatusCaptured=($statusCode -eq 0)
    finalSourceDiffCaptured=($diffHeadCode -eq 0 -and @($untrackedCommands|Where-Object {$_.exitCode -ne 1}).Count -eq 0)
}
$failed=@($checks.Keys|Where-Object {-not $checks[$_]})
[ordered]@{
    task='T-025';utc=[DateTime]::UtcNow.ToString('o')
    scope='Developer document/dependency/scope self-check only; no review approval or game result'
    checks=$checks;checkCount=$checks.Count;failed=$failed
    statusCounts=$statusCounts;stages=$stageCounts
    missingDependencies=$missingDependencies;unresolved=$unresolved;otherChangedTasks=$otherChanged
    missingLinks=$missingLinks;markdownProblems=$markdownProblems
    artifactSha256=$artifact.sha256
    commands=@(
        @{command='git diff --cached --binary';exitCode=$indexCode;log='index-final.diff'},
        @{command='git -c core.safecrlf=false diff --check';exitCode=$diffCode;log='diff-check-final.log'},
        @{command='git status --short';exitCode=$statusCode;log='git-status-final.txt'},
        @{command='git diff HEAD --binary';exitCode=$diffHeadCode;log='source.diff'}
    )+$untrackedCommands
}|ConvertTo-Json -Depth 8|Set-Content -Encoding UTF8 (Join-Path $taskEvidence 'final-check.json')
Write-Output ('Document/scope checks: '+$checks.Count+'; failures: '+$failed.Count)
if($failed.Count -gt 0) {
    $failed|ForEach-Object {Write-Output $_}
    $markdownProblems|ForEach-Object {Write-Output $_}
    exit 1
}
