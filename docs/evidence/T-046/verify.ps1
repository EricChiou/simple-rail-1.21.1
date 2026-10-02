$ErrorActionPreference = 'Continue'
$evidence = 'docs/evidence/T-046'
$jar = 'docs/evidence/T-045/artifacts/simplerail-1.0.0.jar'
$command = 'javap -classpath docs/evidence/T-045/artifacts/simplerail-1.0.0.jar -c -p com.ericchiu.simplerail.block.TrainDispenserBlock'
$started = (Get-Date).ToUniversalTime().ToString('o')
& javap -classpath $jar -c -p com.ericchiu.simplerail.block.TrainDispenserBlock *> (Join-Path $evidence 'bytecode.log')
$javapExit = $LASTEXITCODE
if ($javapExit -ne 0) { exit $javapExit }

$bytecode = Get-Content (Join-Path $evidence 'bytecode.log') -Raw -Encoding UTF8
$t045 = Get-Content 'docs/evidence/T-045/audit.json' -Raw -Encoding UTF8 | ConvertFrom-Json
$t120 = Get-Content 'docs/test-packages/T-043-v1/results.json' -Raw -Encoding UTF8 | ConvertFrom-Json
$sourceRoot = 'src/main/java/com/ericchiu/simplerail/block/'
$blockHash = (Get-FileHash ($sourceRoot + 'TrainDispenserBlock.java') -Algorithm SHA256).Hash
$scanHash = (Get-FileHash ($sourceRoot + 'TrainDispenserScan.java') -Algorithm SHA256).Hash
$jarHash = (Get-FileHash $jar -Algorithm SHA256).Hash
$checks = [ordered]@{
    same_fixed_jar = $jarHash -eq $t045.fixed_jar_sha256
    same_product_sources = ($blockHash -eq $t045.sources[0].sha256) -and ($scanHash -eq $t045.sources[1].sha256)
    four_item_identities = @('Items.CHEST_MINECART', 'Items.FURNACE_MINECART', 'Items.HOPPER_MINECART', 'Items.TNT_MINECART' | Where-Object { $bytecode.Contains($_) }).Count -eq 4
    no_string_classification = -not ($bytecode -match 'Item.toString|String.equals')
    no_sample_consumption = -not ($bytecode -match 'ItemStack.shrink|ItemStack.split|TrainDispenserBlockEntity.setItem|TrainDispenserBlockEntity.removeItem')
    immediate_powered_entry = ($bytecode -match 'ServerLevel.hasNeighborSignal') -and ($bytecode -match 'Method spawnTemplate:')
    no_vanilla_trigger_path = -not ($bytecode -match 'DispenserBlock.neighborChanged|DispenserBlock.dispenseFrom|scheduleTick')
    new_cart_without_template_components = $bytecode -match 'ItemStack.EMPTY'
    user_results_still_blank = ($t120.cases.Count -eq 8) -and (@($t120.cases | Where-Object { $null -ne $_.actual }).Count -eq 0)
}
$failed = @($checks.Keys | Where-Object { -not $checks[$_] })
[ordered]@{
    command = $command
    started_utc = $started
    finished_utc = (Get-Date).ToUniversalTime().ToString('o')
    javap_exit_code = $javapExit
    checks = $checks
    failed = $failed
    head = (git rev-parse HEAD).Trim()
    jar_sha256 = $jarHash
    product_changed_since_t045 = -not ($checks.same_fixed_jar -and $checks.same_product_sources)
    minecraft_executed = $false
    new_build_executed = $false
    result = if ($failed.Count -eq 0) { 'PASS' } else { 'FAIL' }
} | ConvertTo-Json -Depth 5 | Set-Content -Encoding UTF8 (Join-Path $evidence 'verify.json')
Write-Output "T046 static checks=$($checks.Count) failed=$($failed.Count)"
if ($failed.Count -ne 0) { $failed; exit 1 }
