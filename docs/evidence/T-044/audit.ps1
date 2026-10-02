$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem
$root = (Resolve-Path '.').Path
$evidence = Join-Path $root 'docs/evidence/T-044'
$baseline = Get-Content (Join-Path $root 'docs/evidence/T-040/fix-R1/product-inputs.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$build = Get-Content (Join-Path $evidence 'build.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$expectedChanged = @(
    'src/main/java/com/ericchiu/simplerail/registry/ModBlocks.java',
    'src/main/java/com/ericchiu/simplerail/registry/ModBlockEntities.java',
    'src/main/resources/assets/simplerail/blockstates/train_dispenser.json'
)
$newFiles = @(
    'src/main/java/com/ericchiu/simplerail/block/TrainDispenserBlock.java',
    'src/main/java/com/ericchiu/simplerail/blockentity/TrainDispenserBlockEntity.java'
)
$actualChanged = @($baseline | Where-Object {
    (Get-FileHash -LiteralPath (Join-Path $root $_.path) -Algorithm SHA256).Hash -ne $_.sha256
} | ForEach-Object { $_.path })
$jarPath = Join-Path $root 'build/libs/simplerail-1.0.0.jar'
$jarHash = (Get-FileHash -LiteralPath $jarPath -Algorithm SHA256).Hash
$states = Get-Content (Join-Path $root $expectedChanged[2]) -Raw -Encoding UTF8 | ConvertFrom-Json
$expectedKeys = @('north','south','east','west' | ForEach-Object {
    "facing=$_,triggered=false"
    "facing=$_,triggered=true"
})
$actualKeys = @($states.variants.PSObject.Properties.Name)
$archive = [IO.Compression.ZipFile]::OpenRead($jarPath)
try {
    $requiredEntries = @(
        'com/ericchiu/simplerail/block/TrainDispenserBlock.class',
        'com/ericchiu/simplerail/blockentity/TrainDispenserBlockEntity.class',
        'assets/simplerail/blockstates/train_dispenser.json'
    )
    $missingEntries = @($requiredEntries | Where-Object { $null -eq ($archive.GetEntry($_)) })
} finally {
    $archive.Dispose()
}
$checks = [ordered]@{
    build_exit_zero = $build.exit_code -eq 0
    build_successful = (Get-Content (Join-Path $evidence 'build.log') -Raw) -match 'BUILD SUCCESSFUL'
    prior_inputs_only_expected_changed = ($actualChanged.Count -eq 3) -and @($actualChanged | Where-Object { $_ -notin $expectedChanged }).Count -eq 0
    two_new_source_files = @($newFiles | Where-Object { -not (Test-Path -LiteralPath (Join-Path $root $_)) }).Count -eq 0
    eight_horizontal_state_variants = ($actualKeys.Count -eq 8) -and @($actualKeys | Where-Object { $_ -notin $expectedKeys }).Count -eq 0
    jar_entries = $missingEntries.Count -eq 0
    fixed_artifact_matches = (Get-FileHash (Join-Path $evidence 'artifacts/simplerail-1.0.0.jar') -Algorithm SHA256).Hash -eq $jarHash
}
$failed = @($checks.Keys | Where-Object { -not $checks[$_] })
[ordered]@{
    command = 'powershell -NoProfile -ExecutionPolicy Bypass -File docs/evidence/T-044/audit.ps1'
    checks = $checks
    failed = $failed
    changed_prior_files = $actualChanged
    added_files = @($newFiles | ForEach-Object {
        [ordered]@{ path = $_; sha256 = (Get-FileHash -LiteralPath (Join-Path $root $_) -Algorithm SHA256).Hash }
    })
    jar = [ordered]@{ path = 'build/libs/simplerail-1.0.0.jar'; sha256 = $jarHash }
    missing_jar_entries = $missingEntries
    result = if ($failed.Count -eq 0) { 'PASS' } else { 'FAIL' }
} | ConvertTo-Json -Depth 6 | Set-Content -Encoding UTF8 (Join-Path $evidence 'audit.json')
Write-Output "T044 audit checks=$($checks.Count) failed=$($failed.Count)"
if ($failed.Count -ne 0) { $failed; exit 1 }
