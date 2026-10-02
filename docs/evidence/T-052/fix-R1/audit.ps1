$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..\..')).Path
$jar = Join-Path $root 'docs\test-packages\T-052-R1\mods\simplerail-1.0.0.jar'
$entityName = 'com.ericchiu.simplerail.entity.LocomotiveCartEntity'
$rendererName = 'com.ericchiu.simplerail.client.LocomotiveCartRenderer'
$entity = (javap -classpath $jar -c -p $entityName) -join "`n"
if ($LASTEXITCODE -ne 0) { throw 'javap entity failed' }
$renderer = (javap -classpath $jar -c -p $rendererName) -join "`n"
if ($LASTEXITCODE -ne 0) { throw 'javap renderer failed' }
$cap = [regex]::Match($entity, '(?s)public float getMaxCartSpeedOnRail\(\);.*?(?=\n  (?:public|protected|private)|\z)').Value
if ($cap -notmatch 'float 1\.2f') { throw 'Normal cart rail cap missing' }
if ($renderer -match 'renderSingleBlock|getDisplayBlockState|BlockRenderDispatcher') { throw 'Renderer still draws furnace display block' }
$drag = [regex]::Match($entity, '(?s)protected void applyNaturalSlowdown\(\);.*?(?=\n  (?:public|protected|private)|\z)').Value
if ($drag -notmatch 'double 0\.997d' -or $drag -notmatch 'double 0\.96d' -or
    $drag -notmatch 'MinecartFurnace.applyNaturalSlowdown') { throw 'Expected coast / fuel split missing' }
$old = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'docs\evidence\T-048-055\audit.json') | ConvertFrom-Json
$changed = @('src/main/java/com/ericchiu/simplerail/entity/LocomotiveCartEntity.java',
             'src/main/java/com/ericchiu/simplerail/client/LocomotiveCartRenderer.java')
$files = foreach ($relative in $changed) {
    [ordered]@{
        path = $relative
        beforeSha256 = ($old.source | Where-Object path -eq $relative).sha256
        afterSha256 = (Get-FileHash -LiteralPath (Join-Path $root $relative) -Algorithm SHA256).Hash
    }
}
$result = [ordered]@{
    command = 'powershell -NoProfile -ExecutionPolicy Bypass -File docs/evidence/T-052/fix-R1/audit.ps1'
    head = (git -C $root rev-parse HEAD).Trim()
    source = $files
    jar = [ordered]@{ path = 'docs/test-packages/T-052-R1/mods/simplerail-1.0.0.jar'; sha256 = (Get-FileHash $jar -Algorithm SHA256).Hash }
    bytecode = [ordered]@{
        railCap = '1.2f (ordinary cart extension default)'
        coastDrag = '0.997 occupied / 0.96 empty; parent fuel branch retained'
        rendererDisplayBlockCalls = 0
    }
    result = 'PASS'
}
$result | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $PSScriptRoot 'audit.json') -Encoding UTF8
Write-Output 'PASS: rail cap, coast/fuel split and renderer-only model verified in fixed JAR'
