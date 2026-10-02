$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..\..')).Path
$jar = Join-Path $root 'docs\test-packages\T-052-R2\mods\simplerail-1.0.0.jar'
$class = (javap -classpath $jar -p com.ericchiu.simplerail.entity.LocomotiveCartEntity) -join "`n"
if ($LASTEXITCODE -ne 0) { throw 'javap class failed' }
$code = (javap -classpath $jar -c -p com.ericchiu.simplerail.entity.LocomotiveCartEntity) -join "`n"
if ($LASTEXITCODE -ne 0) { throw 'javap code failed' }
$renderer = (javap -classpath $jar -c -p com.ericchiu.simplerail.client.LocomotiveCartRenderer) -join "`n"
if ($LASTEXITCODE -ne 0) { throw 'javap renderer failed' }
if ($class -notmatch 'LocomotiveCartEntity extends net\.minecraft\.world\.entity\.vehicle\.Minecart\s*\{') { throw 'Not a normal Minecart subclass' }
foreach ($method in @('getMaxSpeed\(', 'getMaxCartSpeedOnRail\(', 'applyNaturalSlowdown\(', 'moveAlongTrack\(', 'moveMinecartOnRail\(', 'getMinecartType\(')) {
    if ($class -match $method) { throw "Custom movement/type override remains: $method" }
}
$interact = [regex]::Match($code, '(?s)public net\.minecraft\.world\.InteractionResult interact\(.*?\);.*?(?=\n  (?:public|protected|private)|\z)').Value
if ($interact -notmatch 'InteractionResult\.PASS' -or $interact -match 'Minecart\.interact|startRiding') { throw 'Interaction may ride' }
$passenger = [regex]::Match($code, '(?s)protected boolean canAddPassenger\(.*?\);.*?(?=\n  (?:public|protected|private)|\z)').Value
if ($passenger -notmatch 'iconst_0\s+1: ireturn') { throw 'Passenger guard missing' }
if ($renderer -match 'renderSingleBlock|getDisplayBlockState|BlockRenderDispatcher') { throw 'Furnace display rendering returned' }
if ($class -notmatch 'getDropItem\(' -or $class -notmatch 'getPickResult\(' -or $class -notmatch 'trainIds\(') { throw 'Custom ID or train method missing' }
$prev = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'docs\evidence\T-052\fix-R1\audit.json') | ConvertFrom-Json
$source = 'src/main/java/com/ericchiu/simplerail/entity/LocomotiveCartEntity.java'
$result = [ordered]@{
    command = 'powershell -NoProfile -ExecutionPolicy Bypass -File docs/evidence/T-052/fix-R2/audit.ps1'
    head = (git -C $root rev-parse HEAD).Trim()
    source = [ordered]@{ path = $source; r1Sha256 = ($prev.source | Where-Object path -eq $source).afterSha256; r2Sha256 = (Get-FileHash (Join-Path $root $source) -Algorithm SHA256).Hash }
    jar = [ordered]@{ path = 'docs/test-packages/T-052-R2/mods/simplerail-1.0.0.jar'; sha256 = (Get-FileHash $jar -Algorithm SHA256).Hash }
    bytecode = [ordered]@{ parent = 'Minecart'; ownMovementOrSpeedOverrides = 0; interaction = 'PASS'; canAddPassenger = 'false'; rendererDisplayBlockCalls = 0; customDropPickAndTrain = $true }
    result = 'PASS'
}
$result | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $PSScriptRoot 'audit.json') -Encoding UTF8
Write-Output 'PASS: ordinary Minecart parent/movement, no riding, custom ID/train retained'
