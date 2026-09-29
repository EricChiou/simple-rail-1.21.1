$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '../../..')).Path
Set-Location $root
$utf8 = [Text.UTF8Encoding]::new($false)
$taskPath = Join-Path $root 'TASK.md'
$taskText = [IO.File]::ReadAllText($taskPath)
$ids = @(5,6,7,8,9,10,11,12,13,14,15,16,17,18,89,90,91)
foreach ($id in $ids) {
    $name = 'T-{0:D3}' -f $id
    $pattern = '(?ms)^### ' + $name + ' .*?(?=^### |^## |\z)'
    $match = [regex]::Match($taskText, $pattern)
    if (!$match.Success) { throw "Missing task $name" }
    $section = $match.Value
    if ($id -in @(5,6,7)) {
        $section = $section.Replace('未取得獨立程式審查通過或使用者人工測試通過紀錄。', 'R-01 已完成基線程式／證據範圍審查（2026-09-28），不新增或改簽人工結果，詳 [獨立報告](docs/evidence/R-01/README.md)。')
    } else {
        $section = $section.Replace('R-01 程式審查待審', 'R-01 程式審查通過（2026-09-28，見 [獨立報告](docs/evidence/R-01/README.md)）')
        $section = $section.Replace('，程式審查待審', '，R-01 程式審查通過')
        $section = $section.Replace('R-01 待審，不簽已審正式交接', 'R-01 已審通過，固定包內待審文字保留為製作時快照')
        $section = $section.Replace('未啟動遊戲、R-01 待審', '未啟動遊戲、R-01 已審通過（固定包保留製作時快照）')
    }
    $taskText = $taskText.Substring(0, $match.Index) + $section + $taskText.Substring($match.Index + $match.Length)
}
[IO.File]::WriteAllText($taskPath, $taskText, $utf8)
$migrationPath = Join-Path $root 'MIGRATION.md'
$migration = [IO.File]::ReadAllText($migrationPath)
$migration = $migration.Replace('T-008–T-017、T-090／T-091 開發完成／待審', 'T-008–T-017、T-090／T-091 開發完成／R-01 程式審查通過')
$migration = $migration.Replace('三方分工與人工確認結案規則不變，本次依授權只執行 T-090／T-091。', '三方分工與人工確認結案規則不變，本次依授權只執行 R-01 獨立程式審查；結論與固定版本見 [審查報告](docs/evidence/R-01/README.md)。')
$migration = $migration.Replace('本輪只執行 T-090／T-091：以 T-017 正式空框架製作固定版 JAR、安裝／案例操作包，執行 NEW 離線 build 及 ZIP 靜態檢查；不修改模組程式碼、Gradle 或資源，不啟動 Minecraft／OLD build 或執行其他任務。', '本輪只執行 R-01：審查指定版 API 研究、T-017 正式空框架與 T-090／T-091 固定操作包，結論為程式審查通過。八組 API 探針及產品框架共 9 次 javac 重編成功，來源／JAR／ZIP 靜態核對通過；未重跑 Gradle build、未修改產品程式／Gradle／資源或啟動 Minecraft。')
$migration = $migration.Replace('T-090／T-091 本輪開發完成', 'T-090／T-091 已開發完成')
$migration = $migration.Replace('R-01 程式審查待審', 'R-01 程式審查通過')
$migration = $migration.Replace('R-01 待審', 'R-01 程式審查通過')
$migration = $migration.Replace('T-090／T-091 本輪另有實際開發交付，R-01 仍待審，不由人工確認推定程式審查通過', 'T-090／T-091 已有實際開發交付，R-01 本輪獨立審查通過，並非由人工確認推定')
$migration = $migration.Replace('本輪 T-090／T-091 固定包開發完成、R-01 程式審查通過', 'T-090／T-091 固定包開發完成；本輪 R-01 獨立程式審查通過，詳 [審查報告](docs/evidence/R-01/README.md)')
[IO.File]::WriteAllText($migrationPath, $migration, $utf8)
Write-Output 'Updated current task sections and migration status; historical evidence/packages unchanged.'
