$ErrorActionPreference='Stop'
$root='D:\workspace\java\simple-rail-1.21.1'
Set-Location -LiteralPath $root
$ev=Join-Path $root 'docs/evidence/T-010'
$cp=Get-Content -Encoding UTF8 (Join-Path $ev 'compile-classpath.txt')
@($cp | ForEach-Object {[ordered]@{path=[string]$_;sha256=(Get-FileHash -LiteralPath $_ -Algorithm SHA256).Hash}}) | ConvertTo-Json -Depth 4 | Set-Content -Encoding UTF8 (Join-Path $ev 'classpath-manifest.json')
$base=Join-Path $root 'build/t010-probe/classes'
$classes=@()
foreach($f in Get-ChildItem -LiteralPath $base -Recurse -File -Filter '*.class'){
 $rel=$f.FullName.Substring($base.Length+1)
 $dest=Join-Path $ev ('compiled/'+$rel)
 New-Item -ItemType Directory -Force (Split-Path $dest)|Out-Null
 Copy-Item -LiteralPath $f.FullName -Destination $dest
 $bytes=[IO.File]::ReadAllBytes($f.FullName)
 $classes += [ordered]@{snapshot=('compiled/'+$rel);sha256=(Get-FileHash -LiteralPath $dest -Algorithm SHA256).Hash;majorVersion=([int]$bytes[6]*256+[int]$bytes[7]);bytes=$bytes.Length}
}
$classes | ConvertTo-Json -Depth 4 | Set-Content -Encoding UTF8 (Join-Path $ev 'compiled-classes.json')
$baseline=Get-Content -Encoding UTF8 'docs/evidence/T-009/product-source-check.json' | ConvertFrom-Json
$product=@($baseline | ForEach-Object {$h=(Get-FileHash -LiteralPath $_.path -Algorithm SHA256).Hash;[ordered]@{path=$_.path;expected=$_.expected;actual=$h;equal=($h -eq $_.expected)}})
foreach($p in $product){if(-not $p.equal){throw "Product changed: $($p.path)"}}
$product | ConvertTo-Json -Depth 4 | Set-Content -Encoding UTF8 (Join-Path $ev 'product-source-check.json')
$previous=Get-Content -Encoding UTF8 'docs/evidence/T-009/source-manifest.json'|ConvertFrom-Json
$source=Get-Content -Encoding UTF8 (Join-Path $ev 'source-manifest.json')|ConvertFrom-Json
$matched=0
foreach($s in $source){
 if($s.origin){
  $match=@($previous|Where-Object {$_.origin -eq $s.origin})
  if($match.Count -ne 1 -or $match[0].sha256 -ne $s.sha256){throw "OLD reference changed: $($s.origin)"}
  $matched++
 }
}
$head=& git rev-parse HEAD
$headExit=$LASTEXITCODE
$status=@(& git status --short)
$diff=@(& git diff HEAD --name-only -- src build.gradle settings.gradle gradle.properties gradle gradlew gradlew.bat)
$diffExit=$LASTEXITCODE
$version=& 'C:\Program Files\Eclipse Adoptium\jdk-21.0.12.101-hotspot\bin\javac.exe' -version
$versionExit=$LASTEXITCODE
[ordered]@{command='& ([scriptblock]::Create((Get-Content -Raw -Encoding UTF8 docs/evidence/T-010/save-verification.ps1)))';exitCode=0;utc=[DateTime]::UtcNow.ToString('o');newHead=$head;gitHeadExit=$headExit;newStatus=$status;oldHeadReference='6698b1c5f494095a15b055c10045293e91540012 (T-009 read-only Git verification; not rerun OLD build)';oldSourceFilesMatchingT009=$matched;productFilesUnchanged=$product.Count;productDiff=$diff;productDiffExit=$diffExit;compilerCommand='C:/Program Files/Eclipse Adoptium/jdk-21.0.12.101-hotspot/bin/javac.exe -version';compilerOutput=$version;compilerExit=$versionExit;compiledClasses=$classes.Count;probeSha256=(Get-FileHash -LiteralPath (Join-Path $ev 'probe/T010Probe.java') -Algorithm SHA256).Hash} | ConvertTo-Json -Depth 6 | Set-Content -Encoding UTF8 (Join-Path $ev 'verification.json')
"Saved $($classes.Count) classes; $matched OLD Java files and $($product.Count) product files unchanged."
