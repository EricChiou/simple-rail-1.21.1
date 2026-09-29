$ErrorActionPreference='Stop'
$e=Join-Path (Get-Location) 'docs/evidence/T-035'
$root=$e+'/isolated-tests'
$jdk='C:/Program Files/Eclipse Adoptium/jdk-21.0.12.101-hotspot/bin'
New-Item -ItemType Directory -Force ($root+'/classes')|Out-Null
$doubles=@(Get-ChildItem ($root+'/stubs') -Recurse -Filter '*.java'|ForEach-Object {$_.FullName})
$files=$doubles+@((Join-Path (Get-Location) 'src/main/java/com/ericchiu/simplerail/item/Wrench.java'),($e+'/WrenchHooksTest.java'))
$start=[DateTime]::UtcNow.ToString('o')
& ($jdk+'/javac.exe') --release 21 -encoding UTF-8 -Xlint:unchecked -Werror -d ($root+'/classes') $files *> ($e+'/hooks-compile-01.log');$compileCode=$LASTEXITCODE
& ($jdk+'/java.exe') -cp ($root+'/classes') com.ericchiu.simplerail.item.WrenchHooksTest *> ($e+'/hooks-test-01.log');$runCode=$LASTEXITCODE
[ordered]@{command='powershell -NoProfile -ExecutionPolicy Bypass -File docs/evidence/T-035/hooks-test.ps1';compileCommand='Temurin 21 javac --release 21 -encoding UTF-8 -Xlint:unchecked -Werror -d isolated-tests/classes [explicit doubles + actual Wrench.java + WrenchHooksTest.java]';testDoubleCount=$doubles.Count;compileExitCode=$compileCode;runCommand='Temurin 21 java -cp isolated-tests/classes com.ericchiu.simplerail.item.WrenchHooksTest';runExitCode=$runCode;startedUtc=$start;finishedUtc=[DateTime]::UtcNow.ToString('o');scope='Real hook source against isolated doubles; no real Minecraft classes or ConfigSpec lifecycle';gameExecuted=$false}|ConvertTo-Json|Set-Content -Encoding UTF8 ($e+'/hooks-test.json')
Get-Content ($e+'/hooks-compile-01.log');Get-Content ($e+'/hooks-test-01.log')
if($compileCode -ne 0 -or $runCode -ne 0){exit 1}
