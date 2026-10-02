$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem
$root = (Resolve-Path '.').Path
$evidence = Join-Path $root 'docs/evidence/T-045'
$previous = Get-Content (Join-Path $root 'docs/evidence/T-044/audit.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$first = Get-Content (Join-Path $evidence 'build-01.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$build = Get-Content (Join-Path $evidence 'build-03.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$test = Get-Content (Join-Path $evidence 'test-scan.json') -Raw -Encoding UTF8 | ConvertFrom-Json

function Get-ZipEntryHashes([string]$path) {
    $archive = [IO.Compression.ZipFile]::OpenRead($path)
    $hashes = @{}
    try {
        foreach ($entry in $archive.Entries) {
            if ($entry.FullName.EndsWith('/')) { continue }
            $stream = $entry.Open()
            $sha = [Security.Cryptography.SHA256]::Create()
            try {
                $hashes[$entry.FullName] = [BitConverter]::ToString($sha.ComputeHash($stream)).Replace('-', '')
            } finally {
                $sha.Dispose()
                $stream.Dispose()
            }
        }
    } finally {
        $archive.Dispose()
    }
    return $hashes
}

$beforeJar = Join-Path $root 'docs/evidence/T-044/artifacts/simplerail-1.0.0.jar'
$afterJar = Join-Path $root 'docs/evidence/T-045/artifacts/simplerail-1.0.0.jar'
$before = Get-ZipEntryHashes $beforeJar
$after = Get-ZipEntryHashes $afterJar
$changedEntries = @((@($before.Keys) + @($after.Keys) | Sort-Object -Unique) | Where-Object {
    $before[$_] -ne $after[$_]
})
$newClassPrefix = 'com/ericchiu/simplerail/block/TrainDispenserScan'
$blockClass = 'com/ericchiu/simplerail/block/TrainDispenserBlock.class'
$blockSource = 'src/main/java/com/ericchiu/simplerail/block/TrainDispenserBlock.java'
$entitySource = 'src/main/java/com/ericchiu/simplerail/blockentity/TrainDispenserBlockEntity.java'
$scanSource = 'src/main/java/com/ericchiu/simplerail/block/TrainDispenserScan.java'
$jarHash = (Get-FileHash -LiteralPath $afterJar -Algorithm SHA256).Hash
$checks = [ordered]@{
    final_build_exit_zero = $build.exit_code -eq 0
    final_build_successful = (Get-Content (Join-Path $evidence 'build-03.log') -Raw) -match 'BUILD SUCCESSFUL'
    failed_first_compile_preserved = ($first.exit_code -eq 1) -and ($first.error_summary -match 'private access in Position')
    production_scan_test_pass = ($test.compile_exit_code -eq 0) -and ($test.test_exit_code -eq 0) -and
        ((Get-Content (Join-Path $evidence 'test-scan.log') -Raw) -match 'PASS checks=15; production scan only; MinecraftExecuted=false')
    prior_entity_unchanged = (Get-FileHash (Join-Path $root $entitySource) -Algorithm SHA256).Hash -eq $previous.added_files[1].sha256
    previous_block_changed = (Get-FileHash (Join-Path $root $blockSource) -Algorithm SHA256).Hash -ne $previous.added_files[0].sha256
    scan_source_exists = Test-Path -LiteralPath (Join-Path $root $scanSource)
    jar_delta_limited = ($changedEntries.Count -ge 4) -and
        @($changedEntries | Where-Object {
            $_ -ne $blockClass -and -not $_.StartsWith($newClassPrefix) -and
            -not $_.StartsWith('com/ericchiu/simplerail/block/TrainDispenserBlock$')
        }).Count -eq 0
    fixed_jar_matches_build = $jarHash -eq (Get-FileHash (Join-Path $root 'build/libs/simplerail-1.0.0.jar') -Algorithm SHA256).Hash
}
$failed = @($checks.Keys | Where-Object { -not $checks[$_] })
[ordered]@{
    command = 'powershell -NoProfile -ExecutionPolicy Bypass -File docs/evidence/T-045/audit.ps1'
    checks = $checks
    failed = $failed
    changed_jar_entries = $changedEntries
    sources = @(
        [ordered]@{ path = $blockSource; sha256 = (Get-FileHash (Join-Path $root $blockSource) -Algorithm SHA256).Hash },
        [ordered]@{ path = $scanSource; sha256 = (Get-FileHash (Join-Path $root $scanSource) -Algorithm SHA256).Hash },
        [ordered]@{ path = 'docs/evidence/T-045/tests/TrainDispenserScanTest.java'; sha256 = (Get-FileHash (Join-Path $evidence 'tests/TrainDispenserScanTest.java') -Algorithm SHA256).Hash }
    )
    previous_jar_sha256 = $previous.jar.sha256
    fixed_jar_sha256 = $jarHash
    result = if ($failed.Count -eq 0) { 'PASS' } else { 'FAIL' }
} | ConvertTo-Json -Depth 6 | Set-Content -Encoding UTF8 (Join-Path $evidence 'audit.json')
Write-Output "T045 audit checks=$($checks.Count) failed=$($failed.Count) delta=$($changedEntries.Count)"
if ($failed.Count -ne 0) { $failed; exit 1 }
