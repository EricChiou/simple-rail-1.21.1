$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem
$root='D:\workspace\java\simple-rail-1.21.1'
$evidence=Join-Path $root 'docs\evidence\T-008'
$archives=@(
 @{name='neoforge';path=(Join-Path $root 'build\moddev\artifacts\neoforge-21.1.251-sources.jar');patterns=@('net/neoforged/neoforge/registries/DeferredRegister.java','net/neoforged/neoforge/registries/DeferredHolder.java','net/neoforged/neoforge/registries/RegisterEvent.java','net/neoforged/neoforge/common/ModConfigSpec.java','net/neoforged/neoforge/internal/CommonModLoader.java','net/neoforged/neoforge/event/BuildCreativeModeTabContentsEvent.java','net/minecraft/world/item/CreativeModeTab.java','net/neoforged/neoforge/registries/GameData.java')},
 @{name='fml';path='C:\Users\Kinoko\.gradle\caches\modules-2\files-2.1\net.neoforged.fancymodloader\loader\4.0.44\49ddb1aae0afcc7dfbaa46f7e557c568fb88a084\loader-4.0.44-sources.jar';patterns=@('net/neoforged/fml/common/Mod.java','net/neoforged/fml/common/EventBusSubscriber.java','net/neoforged/fml/javafmlmod/FMLModContainer.java','net/neoforged/fml/javafmlmod/AutomaticEventSubscriber.java','net/neoforged/fml/ModContainer.java','net/neoforged/fml/config/ModConfig.java','net/neoforged/fml/config/ConfigTracker.java','net/neoforged/fml/event/config/ModConfigEvent.java','net/neoforged/fml/event/lifecycle/ParallelDispatchEvent.java')}
)
$records=@()
foreach($a in $archives){
 $zip=[IO.Compression.ZipFile]::OpenRead($a.path)
 try {
  foreach($name in $a.patterns){
   $entry=$zip.GetEntry($name)
   if(-not $entry){throw "Missing $name in $($a.path)"}
   $dest=Join-Path $evidence ('sources\'+$a.name+'\'+$name)
   New-Item -ItemType Directory -Force (Split-Path $dest) | Out-Null
   [IO.Compression.ZipFileExtensions]::ExtractToFile($entry,$dest,$true)
   $records += [ordered]@{archive=$a.path;archiveSha256=(Get-FileHash $a.path -Algorithm SHA256).Hash;entry=$name;snapshot=$dest.Substring($evidence.Length+1);sha256=(Get-FileHash $dest -Algorithm SHA256).Hash}
  }
 } finally {$zip.Dispose()}
}
$old='D:\workspace\java\simple-rail\src\main\java\ericchiu\simplerail'
foreach($name in 'SimpleRail.java','setup/Registration.java','registry/Blocks.java','registry/Items.java','registry/Entities.java','registry/TileEntities.java','config/CommonConfig.java','itemgroup/Rail.java','constants/I18n.java','block/TimerHoldingRail.java','tileentity/SignalTimerTileEntity.java'){
 $origin=Join-Path $old $name
 $dest=Join-Path $evidence ('sources\old\'+$name)
 New-Item -ItemType Directory -Force (Split-Path $dest) | Out-Null
 Copy-Item -LiteralPath $origin -Destination $dest
 $records += [ordered]@{origin=$origin;snapshot=$dest.Substring($evidence.Length+1);sha256=(Get-FileHash $dest -Algorithm SHA256).Hash}
}
$records | ConvertTo-Json -Depth 5 | Set-Content -Encoding UTF8 (Join-Path $evidence 'source-manifest.json')
"Extracted $($records.Count) source snapshots; no game execution."
