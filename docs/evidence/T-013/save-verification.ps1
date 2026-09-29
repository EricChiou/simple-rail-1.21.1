$ErrorActionPreference='Stop'
$root='D:\workspace\java\simple-rail-1.21.1'
Set-Location -LiteralPath $root
$ev=Join-Path $root 'docs/evidence/T-013'
$source=Get-Content -Raw -Encoding UTF8 (Join-Path $ev 'source-manifest.json') | ConvertFrom-Json
foreach($s in $source){
 $actual=(Get-FileHash -LiteralPath (Join-Path $ev $s.snapshot) -Algorithm SHA256).Hash
 if($actual -ne $s.sha256){throw "Source snapshot mismatch: $($s.snapshot)"}
 if($s.archive -and (Get-FileHash -LiteralPath $s.archive -Algorithm SHA256).Hash -ne $s.archiveSha256){throw "Archive mismatch: $($s.archive)"}
}
$oldPrevious=(Get-Content -Raw -Encoding UTF8 'docs/evidence/T-003/source-inventory.json' | ConvertFrom-Json).sourceFiles
$old=@($source|Where-Object {$_.origin})
foreach($s in $old){
 $rel=($s.origin -replace '^D:\\workspace\\java\\simple-rail\\','' -replace '\\','/'); $match=@($oldPrevious|Where-Object {$_.path -eq $rel})
 if($match.Count -ne 1 -or $match[0].sha256 -ne $s.sha256){throw "OLD source changed: $($s.origin)"}
}
$cp=@(Get-Content -Encoding UTF8 (Join-Path $ev 'compile-classpath.txt'))
$cpRecord=@($cp|ForEach-Object {[ordered]@{path=[string]$_;sha256=(Get-FileHash -LiteralPath $_ -Algorithm SHA256).Hash}})
$cpRecord|ConvertTo-Json -Depth 4|Set-Content -Encoding UTF8 (Join-Path $ev 'classpath-manifest.json')
$base=Join-Path $root 'build/t013-probe/classes'
$classes=@()
foreach($f in Get-ChildItem -LiteralPath $base -Recurse -File -Filter '*.class'){
 $rel=$f.FullName.Substring($base.Length+1);$dest=Join-Path $ev ('compiled/'+$rel)
 New-Item -ItemType Directory -Force (Split-Path $dest)|Out-Null
 Copy-Item -LiteralPath $f.FullName -Destination $dest
 $bytes=[IO.File]::ReadAllBytes($f.FullName)
 $classes += [ordered]@{snapshot=('compiled/'+$rel);sha256=(Get-FileHash -LiteralPath $dest -Algorithm SHA256).Hash;majorVersion=([int]$bytes[6]*256+[int]$bytes[7]);bytes=$bytes.Length}
}
if($classes.Count -ne 4 -or @($classes|Where-Object {$_.majorVersion -ne 65}).Count -ne 0){throw 'Compiled class count/version mismatch'}
$classes|ConvertTo-Json -Depth 4|Set-Content -Encoding UTF8 (Join-Path $ev 'compiled-classes.json')
$baseline=Get-Content -Raw -Encoding UTF8 'docs/evidence/T-009/product-source-check.json' | ConvertFrom-Json
$product=@($baseline|ForEach-Object {$h=(Get-FileHash -LiteralPath $_.path -Algorithm SHA256).Hash;[ordered]@{path=$_.path;expected=$_.expected;actual=$h;equal=($h -eq $_.expected)}})
foreach($p in $product){if(-not $p.equal){throw "Product changed: $($p.path)"}}
$product|ConvertTo-Json -Depth 4|Set-Content -Encoding UTF8 (Join-Path $ev 'product-source-check.json')
$head=& git rev-parse HEAD;$headExit=$LASTEXITCODE
$status=@(& git status --short)
$diff=@(& git diff HEAD --name-only -- src build.gradle settings.gradle gradle.properties gradle gradlew gradlew.bat);$diffExit=$LASTEXITCODE
if($diff.Count -ne 0){throw 'Product diff is not empty'}
$version=& 'C:\Program Files\Eclipse Adoptium\jdk-21.0.12.101-hotspot\bin\javac.exe' -version;$versionExit=$LASTEXITCODE
$attempts=@((Get-Content -Raw -Encoding UTF8 (Join-Path $ev 'compile-01.json')|ConvertFrom-Json);(Get-Content -Raw -Encoding UTF8 (Join-Path $ev 'compile-02.json')|ConvertFrom-Json))
if($attempts[0].exitCode -ne 1 -or $attempts[1].exitCode -ne 0){throw 'Compile outcomes differ from recorded attempts'}
[ordered]@{command='& ([scriptblock]::Create((Get-Content -Raw -Encoding UTF8 docs/evidence/T-013/save-verification.ps1)))';exitCode=0;utc=[DateTime]::UtcNow.ToString('o');newHead=$head;gitHeadExit=$headExit;newStatus=$status;oldHeadReference='6698b1c5f494095a15b055c10045293e91540012 (T-003 read-only reference; no OLD build)';oldSourceFilesMatchingT003=$old.Count;targetSourceFiles=($source.Count-$old.Count);targetArchiveSha256=$source[0].archiveSha256;productFilesUnchanged=$product.Count;productDiff=$diff;productDiffExit=$diffExit;compilerCommand='C:/Program Files/Eclipse Adoptium/jdk-21.0.12.101-hotspot/bin/javac.exe -version';compilerOutput=$version;compilerExit=$versionExit;compiledClasses=$classes.Count;probeSha256=(Get-FileHash -LiteralPath (Join-Path $ev 'probe/T013Probe.java') -Algorithm SHA256).Hash;compileAttempts=@($attempts|ForEach-Object {@{attempt=$_.log;exitCode=$_.exitCode}})}|ConvertTo-Json -Depth 6|Set-Content -Encoding UTF8 (Join-Path $ev 'verification.json')
"Saved $($classes.Count) classes; $($old.Count) OLD Java file and $($product.Count) product files unchanged."

