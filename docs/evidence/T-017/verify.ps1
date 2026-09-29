$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem

$source = Get-Content 'src/main/java/com/ericchiu/simplerail/SimpleRail.java' -Raw -Encoding utf8
$client = Get-Content 'src/main/java/com/ericchiu/simplerail/SimpleRailClient.java' -Raw -Encoding utf8
$resources = Get-Content 'src/main/resources/assets/simplerail/lang/en_us.json' -Raw -Encoding utf8
$allSource = Get-ChildItem 'src/main/java' -Recurse -Filter '*.java' | ForEach-Object { Get-Content $_.FullName -Raw -Encoding utf8 }
$allResources = Get-ChildItem 'src/main/resources' -Recurse -File | ForEach-Object { Get-Content $_.FullName -Raw -Encoding utf8 }
$jar = Get-ChildItem 'build/libs' -Filter '*.jar' | Select-Object -First 1
if (-not $jar) { throw 'No built JAR was found.' }

$zip = [System.IO.Compression.ZipFile]::OpenRead($jar.FullName)
try {
    $entries = @($zip.Entries | ForEach-Object { $_.FullName })
    $metadataEntry = $zip.GetEntry('META-INF/neoforge.mods.toml')
    if (-not $metadataEntry) { throw 'JAR metadata is missing.' }
    $reader = [System.IO.StreamReader]::new($metadataEntry.Open())
    try { $metadata = $reader.ReadToEnd() } finally { $reader.Dispose() }
} finally { $zip.Dispose() }

$checks = [ordered]@{
    commonEntryKeepsModId = $source -match '@Mod\(SimpleRail\.MODID\)' -and $source -match 'MODID\s*=\s*"simplerail"'
    commonEntryUsesModEventBus = $source -match 'SimpleRail\(IEventBus modEventBus\)'
    commonHasNoDirectClientReference = $source -notmatch 'net\.minecraft\.client|net\.neoforged\.neoforge\.client|SimpleRailClient'
    clientEntryRestrictedToPhysicalClient = $client -match '@Mod\(value\s*=\s*SimpleRail\.MODID,\s*dist\s*=\s*Dist\.CLIENT\)'
    exampleRegistrationAndConfigRemoved = ($allSource -join "`n") -notmatch 'example_block|example_item|example_tab|registerConfig|ConfigurationScreen|InterModComms|IMC'
    exampleTranslationsRemoved = ($allResources -join "`n") -notmatch 'example_block|example_item|example_tab|simplerail\.configuration'
    languageJsonParses = $null -ne ($resources | ConvertFrom-Json)
    configClassAbsentFromJar = $entries -notcontains 'com/ericchiu/simplerail/Config.class'
    commonAndClientClassesInJar = ($entries -contains 'com/ericchiu/simplerail/SimpleRail.class') -and ($entries -contains 'com/ericchiu/simplerail/SimpleRailClient.class')
    metadataKeepsD8 = $metadata -match 'modId="simplerail"' -and $metadata -match 'version="1\.0\.0"' -and $metadata -match 'license="All Rights Reserved"' -and $metadata -match 'versionRange="\[21\.1\.251,\)"' -and $metadata -match 'versionRange="\[1\.21\.1\]"'
}

$result = [ordered]@{
    task = 'T-017'
    timestampUtc = (Get-Date).ToUniversalTime().ToString('o')
    head = (git rev-parse HEAD).Trim()
    jar = $jar.Name
    jarSha256 = (Get-FileHash -Algorithm SHA256 $jar.FullName).Hash
    checks = $checks
    allPassed = -not ($checks.Values -contains $false)
}
$result | ConvertTo-Json -Depth 5 | Set-Content -Encoding utf8 'docs/evidence/T-017/checks.json'
$result | ConvertTo-Json -Depth 5
if (-not $result.allPassed) { exit 1 }
