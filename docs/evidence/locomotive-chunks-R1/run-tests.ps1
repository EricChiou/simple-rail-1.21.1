$ErrorActionPreference='Stop'
$root=(Resolve-Path (Join-Path $PSScriptRoot '../../..')).Path
Set-Location $root
$classes=Join-Path $PSScriptRoot 'test/classes'
New-Item -ItemType Directory -Force $classes | Out-Null
$sources=@((Get-ChildItem (Join-Path $PSScriptRoot 'test/stubs') -Recurse -Filter *.java).FullName)
$sources+=Join-Path $PSScriptRoot 'test/LocomotiveChunkLoaderTest.java'
$sources+=Join-Path $root 'src/main/java/com/ericchiu/simplerail/entity/LocomotiveChunkLoader.java'
& "$env:JAVA_HOME/bin/javac.exe" -d $classes @sources *> (Join-Path $PSScriptRoot 'test-compile-02.log')
$c=$LASTEXITCODE
"exit_code=$c" | Set-Content (Join-Path $PSScriptRoot 'test-compile-02-exit.txt')
if($c -ne 0){throw "javac exit $c"}
& "$env:JAVA_HOME/bin/java.exe" -cp $classes com.ericchiu.simplerail.entity.LocomotiveChunkLoaderTest *> (Join-Path $PSScriptRoot 'test-02.log')
$c=$LASTEXITCODE
"exit_code=$c" | Set-Content (Join-Path $PSScriptRoot 'test-02-exit.txt')
Get-Content -Encoding UTF8 (Join-Path $PSScriptRoot 'test-02.log')
exit $c
