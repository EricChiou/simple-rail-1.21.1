$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem
$root = (Resolve-Path '.').Path
$evidence = Join-Path $root 'docs/evidence/T-043'
$package = Join-Path $root 'docs/test-packages/T-043-v1'
$manifest = Get-Content (Join-Path $package 'manifest.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$results = Get-Content (Join-Path $package 'results.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$build = Get-Content (Join-Path $evidence 'build.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$previous = Get-Content (Join-Path $root 'docs/evidence/T-040/fix-R1/product-inputs.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$checks = [ordered]@{}
$checks.build_exit_zero = $build.exit_code -eq 0
$checks.test_model_pass = (Get-Content (Join-Path $evidence 'build.log') -Raw) -match 'PASS checks=18; model only; MinecraftExecuted=false'
$checks.jar_hash = (Get-FileHash (Join-Path $root $manifest.diagnostic_jar) -Algorithm SHA256).Hash -eq $manifest.diagnostic_jar_sha256
$checks.product_inputs_unchanged = @($previous | Where-Object {
    (Get-FileHash -LiteralPath (Join-Path $root $_.path) -Algorithm SHA256).Hash -ne $_.sha256
}).Count -eq 0
$checks.production_jar_unchanged = (Get-FileHash (Join-Path $root 'build/libs/simplerail-1.0.0.jar') -Algorithm SHA256).Hash -eq $manifest.base_product_jar_sha256
$checks.fixture_hashes = @($manifest.fixture_inputs | Where-Object {
    (Get-FileHash -LiteralPath (Join-Path $root $_.path) -Algorithm SHA256).Hash -ne $_.sha256
}).Count -eq 0
$checks.eight_empty_results = ($results.cases.Count -eq 8) -and (@($results.cases | Where-Object { $null -ne $_.actual -or $_.user_status -ne '待使用者' }).Count -eq 0)
$archive = [IO.Compression.ZipFile]::OpenRead((Join-Path $root $manifest.diagnostic_jar))
try {
    $requiredEntries = @(
        'com/ericchiu/simplerail/SimpleRail.class',
        'com/ericchiu/simplerail/registry/ModBlocks.class',
        'evidence/t043/DispenserProbe.class',
        'evidence/t043/DispenserSourceModel.class',
        'META-INF/neoforge.mods.toml'
    )
    $missingEntries = @($requiredEntries | Where-Object { $null -eq ($archive.GetEntry($_)) })
    $checks.jar_entries = ($missingEntries.Count -eq 0) -and ($null -eq ($archive.GetEntry('evidence/t043/DispenserSourceModelTest.class')))
} finally {
    $archive.Dispose()
}
$links = @()
foreach ($name in @('docs/evidence/T-043/README.md', 'docs/evidence/T-043/INVESTIGATION.md',
        'docs/test-packages/T-043-v1/README.md', 'docs/test-packages/T-043-v1/INSTALL.md',
        'docs/test-packages/T-043-v1/CASES.md')) {
    $path = Join-Path $root $name
    if (-not (Test-Path -LiteralPath $path)) { $links += $name; continue }
    $content = Get-Content $path -Raw -Encoding UTF8
    foreach ($match in [regex]::Matches($content, '\]\(([^)#]+)(?:#[^)]*)?\)')) {
        $target = $match.Groups[1].Value
        if ($target -match '^(https?:|mailto:)') { continue }
        if ($name -eq 'docs/evidence/T-043/README.md' -and $target -eq 'audit.json') { continue }
        if (-not (Test-Path -LiteralPath (Join-Path (Split-Path $path -Parent) $target))) {
            $links += "$name -> $target"
        }
    }
}
$checks.local_links = $links.Count -eq 0
$failed = @($checks.Keys | Where-Object { -not $checks[$_] })
[ordered]@{
    command = 'powershell -NoProfile -ExecutionPolicy Bypass -File docs/evidence/T-043/audit.ps1'
    checks = $checks
    failed = $failed
    missing_links = $links
    result = if ($failed.Count -eq 0) { 'PASS' } else { 'FAIL' }
} | ConvertTo-Json -Depth 6 | Set-Content -Encoding UTF8 (Join-Path $evidence 'audit.json')
Write-Output "T043 audit checks=$($checks.Count) failed=$($failed.Count)"
if ($failed.Count -ne 0) { $failed; exit 1 }
