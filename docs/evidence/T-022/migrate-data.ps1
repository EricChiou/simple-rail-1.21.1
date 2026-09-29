$ErrorActionPreference = 'Stop'
$oldRoot = 'D:/workspace/java/simple-rail/src/main/resources'
$evidence = Join-Path (Get-Location) 'docs/evidence/T-022'
$manifest = Get-Content docs/evidence/T-009/source-manifest.json -Raw -Encoding utf8 | ConvertFrom-Json
$sourceRecords = @($manifest | Where-Object { $_.origin -like '*src\main\resources\data\*' })
if ($sourceRecords.Count -ne 29) { throw "Expected 29 original data records, got $($sourceRecords.Count)" }
$startedUtc = [DateTime]::UtcNow.ToString('o'); $mapping = @()
foreach ($record in $sourceRecords) {
    if ((Get-FileHash -LiteralPath $record.origin).Hash -ne $record.sha256) { throw "OLD source differs from T-009: $($record.origin)" }
    $oldPath = $record.origin.Substring($oldRoot.Length + 1).Replace('\','/')
    $targetPath = $oldPath.Replace('/recipes/', '/recipe/').Replace('/loot_tables/', '/loot_table/').Replace('/tags/blocks/', '/tags/block/').Replace('/tags/items/', '/tags/item/')
    $target = Join-Path 'src/main/resources' $targetPath
    if (Test-Path -LiteralPath $target) { throw "Refusing to overwrite existing data: $target" }
    New-Item -ItemType Directory -Force (Split-Path $target) | Out-Null
    $text = [IO.File]::ReadAllText($record.origin, [Text.Encoding]::UTF8)
    $change = 'Directory rename only; original bytes retained'
    if ($oldPath.Contains('/recipes/')) {
        $text = [regex]::Replace($text, '("result"\s*:\s*\{\s*)"item"', '$1"id"')
        $change = 'result.item -> result.id only; ingredients/pattern/count unchanged'
    } elseif ($oldPath.EndsWith('/loot_tables/blocks/locomotive_cart.json')) {
        $text = [regex]::Replace($text, '(?s),\s*"conditions"\s*:\s*\[\s*\{\s*"condition"\s*:\s*"minecraft:survives_explosion"\s*\}\s*\]', '')
        $change = 'Preserved entity type/blocks ID/pool/item; removed incompatible EXPLOSION_RADIUS condition; no entity attachment'
    }
    [IO.File]::WriteAllText($target, $text, [Text.UTF8Encoding]::new($false))
    $parts = $targetPath.Split('/')
    $logicalId = if ($targetPath.Contains('/tags/')) { $parts[1] + ':' + (($parts[4..($parts.Length-1)] -join '/') -replace '\.json$', '') } else { $parts[1] + ':' + (($parts[3..($parts.Length-1)] -join '/') -replace '\.json$', '') }
    $mapping += [ordered]@{oldPath = $oldPath; targetPath = $targetPath; logicalId = $logicalId; registry = if ($targetPath.Contains('/tags/')) {$parts[3]} else {$parts[2]}; oldSha256 = $record.sha256; targetSha256 = (Get-FileHash -LiteralPath $target).Hash; change = $change}
}
$mapping | ConvertTo-Json -Depth 5 | Set-Content -Encoding utf8 (Join-Path $evidence 'data-map.json')
[ordered]@{command = 'powershell -NoProfile -ExecutionPolicy Bypass -File docs/evidence/T-022/migrate-data.ps1'; startedUtc = $startedUtc; finishedUtc = [DateTime]::UtcNow.ToString('o'); migrated = $mapping.Count; sourceHashChecks = $sourceRecords.Count} | ConvertTo-Json | Set-Content -Encoding utf8 (Join-Path $evidence 'migration-command.json')
Write-Output ('Migrated {0} data files with original source hash checks' -f $mapping.Count)
