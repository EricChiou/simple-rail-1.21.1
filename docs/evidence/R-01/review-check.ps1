$ErrorActionPreference = 'Stop'
$OutputEncoding = [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()
$root = (Resolve-Path (Join-Path $PSScriptRoot '../../..')).Path
Set-Location $root
Add-Type -AssemblyName System.IO.Compression.FileSystem
$utf8 = [System.Text.UTF8Encoding]::new($false)
$checks = [System.Collections.Generic.List[object]]::new()
$hashCache = @{}
$archives = @{}
function FileHash([string]$path) {
    $full = [System.IO.Path]::GetFullPath($path)
    if (!$hashCache.ContainsKey($full)) { $hashCache[$full] = (Get-FileHash -LiteralPath $full -Algorithm SHA256).Hash }
    return $hashCache[$full]
}
function StreamHash($stream) {
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try { return [BitConverter]::ToString($sha.ComputeHash($stream)).Replace('-', '') }
    finally { $sha.Dispose(); $stream.Dispose() }
}
function Check([string]$name, [bool]$ok, $detail) {
    $checks.Add([pscustomobject][ordered]@{ name = $name; passed = $ok; detail = $detail })
}
try {
    foreach ($n in 8..16) {
        $task = 'T-{0:D3}' -f $n
        $dir = Join-Path $root "docs/evidence/$task"
        $count = 0
        $errors = @()
        foreach ($manifest in @('source-manifest.json','extra-source-manifest.json')) {
            $path = Join-Path $dir $manifest
            if (!(Test-Path -LiteralPath $path)) { continue }
            foreach ($row in (Get-Content -Raw -Encoding UTF8 $path | ConvertFrom-Json)) {
                $count++
                if ((FileHash (Join-Path $dir $row.snapshot)) -ne $row.sha256) { $errors += "snapshot: $($row.snapshot)" }
                if ($row.archive) {
                    if ((FileHash $row.archive) -ne $row.archiveSha256) { $errors += "archive: $($row.archive)" }
                    if (!$archives.ContainsKey($row.archive)) { $archives[$row.archive] = [IO.Compression.ZipFile]::OpenRead($row.archive) }
                    $entry = $archives[$row.archive].GetEntry($row.entry)
                    if (!$entry -or (StreamHash $entry.Open()) -ne $row.sha256) { $errors += "archive entry: $($row.entry)" }
                } elseif ($row.origin) {
                    if ((FileHash $row.origin) -ne $row.sha256) { $errors += "origin: $($row.origin)" }
                } else {
                    $errors += "No origin recorded: $($row.snapshot)"
                }
            }
        }
        Check "$task source snapshots and origins" ($errors.Count -eq 0) @{ count = $count; errors = $errors }
        if (Test-Path "$dir/classpath-manifest.json") {
            $rows = Get-Content -Raw -Encoding UTF8 "$dir/classpath-manifest.json" | ConvertFrom-Json
            $bad = @($rows | Where-Object { (FileHash $_.path) -ne $_.sha256 })
            Check "$task compile classpath" ($bad.Count -eq 0) @{ count = $rows.Count; mismatches = $bad }
        }
    }
    $inputs = Get-Content -Raw -Encoding UTF8 docs/evidence/T-090/source-fingerprints.json | ConvertFrom-Json
    $bad = @($inputs | Where-Object { (FileHash $_.path) -ne $_.sha256 })
    Check 'Current product inputs match T-090/T-091' ($bad.Count -eq 0) @{ count = $inputs.Count; mismatches = $bad }
    $baseline = Get-Content -Raw -Encoding UTF8 docs/evidence/T-005/artifact.json | ConvertFrom-Json
    Check 'T-005 historical JAR' ((FileHash $baseline.evidenceJar) -eq $baseline.sha256) $baseline.sha256
    foreach ($task in @('T-090','T-091')) {
        $dir = Join-Path $root "docs/test-packages/$task-v1"
        $manifest = Get-Content -Raw -Encoding UTF8 "$dir/manifest.json" | ConvertFrom-Json
        $files = Get-Content -Raw -Encoding UTF8 "$dir/files-manifest.json" | ConvertFrom-Json
        $zip = [IO.Compression.ZipFile]::OpenRead("$dir.zip")
        try {
            $errors = @()
            foreach ($row in $files) {
                if ((FileHash (Join-Path $dir $row.path)) -ne $row.sha256) { $errors += "file: $($row.path)" }
            }
            $disk = @(Get-ChildItem -LiteralPath $dir -Recurse -File)
            if ($disk.Count -ne $files.Count + 1) { $errors += 'Unmanifested disk files' }
            if ($zip.Entries.Count -ne $disk.Count) { $errors += 'ZIP count mismatch' }
            foreach ($file in $disk) {
                $relative = $file.FullName.Substring($dir.Length + 1).Replace('\','/')
                $entry = $zip.Entries | Where-Object { $_.FullName.Replace('\','/') -eq $relative }
                if (!$entry -or (StreamHash $entry.Open()) -ne (FileHash $file.FullName)) { $errors += "ZIP entry: $relative" }
            }
            Check "$task package integrity" ($errors.Count -eq 0) @{ files = $disk.Count; zipSha256 = (FileHash "$dir.zip"); errors = $errors }
            Check "$task JAR binding" ((FileHash (Join-Path $dir $manifest.jar.path)) -eq $manifest.jar.sha256 -and $manifest.jar.sha256 -eq (FileHash 'build/libs/simplerail-1.0.0.jar')) $manifest.jar
            $results = Get-Content -Raw -Encoding UTF8 "$dir/results.json" | ConvertFrom-Json
            $ids = @($results.cases | ForEach-Object caseId)
            $filled = @($results.cases | Where-Object { $null -ne $_.actualResult })
            Check "$task case/result boundary" ($ids.Count -eq 5 -and !(Compare-Object $manifest.cases $ids) -and $null -eq $results.userConfirmation -and $null -eq $results.actualVersion -and $filled.Count -eq 0) $ids
        } finally { $zip.Dispose() }
    }
    $jar = [IO.Compression.ZipFile]::OpenRead((Join-Path $root 'build/libs/simplerail-1.0.0.jar'))
    try {
        $classes = @($jar.Entries | Where-Object FullName -Like '*.class' | ForEach-Object FullName)
        Check 'Product JAR contains only the two entry classes' (($classes.Count -eq 2) -and ($classes -contains 'com/ericchiu/simplerail/SimpleRail.class') -and ($classes -contains 'com/ericchiu/simplerail/SimpleRailClient.class')) $classes
        $reader = [IO.StreamReader]::new($jar.GetEntry('META-INF/neoforge.mods.toml').Open())
        try { $metadata = $reader.ReadToEnd() } finally { $reader.Dispose() }
        [IO.File]::WriteAllText((Join-Path $PSScriptRoot 'jar-metadata.toml'), $metadata, $utf8)
        Check 'Product metadata' ($metadata.Contains('modId="simplerail"') -and $metadata.Contains('version="1.0.0"') -and $metadata.Contains('license="All Rights Reserved"') -and $metadata.Contains('versionRange="[21.1.251,)"') -and $metadata.Contains('versionRange="[1.21.1]"')) 'Exact build target and supported range remain distinct.'
    } finally { $jar.Dispose() }
} finally {
    foreach ($zip in $archives.Values) { $zip.Dispose() }
}
$result = [ordered]@{ dateUtc = [DateTime]::UtcNow.ToString('o'); head = (git rev-parse HEAD); checks = $checks; gameStarted = $false }
[IO.File]::WriteAllText((Join-Path $PSScriptRoot 'checks.json'), ($result | ConvertTo-Json -Depth 12), $utf8)
$checks | Select-Object name,passed | Format-Table -AutoSize
if (@($checks | Where-Object { !$_.passed }).Count) { exit 1 }
