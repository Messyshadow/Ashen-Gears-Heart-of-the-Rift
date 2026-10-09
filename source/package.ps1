param(
    [string]$Engine = 'E:\SourceCode\Games\engine\big_engine\godot\bin\godot.windows.editor.x86_64.console.exe',
    [string]$PublishRoot = 'E:\Godot\release',
    [switch]$SkipExport
)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$version = '0.4.0'
$folderName = '灰烬齿轮-裂界之心-' + $version
$stage = Join-Path $projectRoot ('build\package-' + $version)
New-Item -ItemType Directory -Path $stage -Force | Out-Null
if (-not $SkipExport) {
    $env:APPDATA = Join-Path $projectRoot '.godot-user-export'
    $env:TEMP = Join-Path $projectRoot 'build\export-temp'
    $env:TMP = $env:TEMP
    New-Item -ItemType Directory -Path $env:TEMP -Force | Out-Null
    & $Engine --headless --path $projectRoot --export-release 'Windows Ashen Gears' (Join-Path $projectRoot 'build\AshenGears.exe')
    if ($LASTEXITCODE -ne 0) { throw 'Godot export failed' }
    $env:APPDATA = Join-Path $projectRoot '.godot-user-exe04'
    $capture = (Join-Path $projectRoot 'qa\v04_screenshots').Replace('\','/')
    $acceptance = Start-Process -FilePath (Join-Path $projectRoot 'build\AshenGears.exe') -ArgumentList @('--resolution','1600x900','--','--qa',('"--capture-dir=' + $capture + '"')) -WindowStyle Hidden -PassThru -RedirectStandardOutput (Join-Path $projectRoot 'qa\exe_v04.log') -RedirectStandardError (Join-Path $projectRoot 'qa\exe_v04_error.log')
    $acceptance.WaitForExit()
    if ($acceptance.ExitCode -ne 0) { throw 'Exported EXE acceptance failed; see qa/exe_v04.log' }
}
$report = Get-Content -LiteralPath (Join-Path $projectRoot 'qa\runtime_tests.json') -Raw -Encoding utf8 | ConvertFrom-Json
if ($report.failures -ne 0) { throw 'Runtime acceptance checks did not pass' }
if ($report.version -ne $version) { throw 'Acceptance report version does not match release' }
if ((Get-FileHash -LiteralPath (Join-Path $projectRoot 'build\AshenGears.exe') -Algorithm SHA256).Hash.ToLower() -ne $report.executable_sha256) { throw 'EXE has not passed this acceptance run' }
if ((Get-FileHash -LiteralPath (Join-Path $projectRoot 'build\AshenGears.pck') -Algorithm SHA256).Hash.ToLower() -ne $report.pack_sha256) { throw 'PCK has changed since acceptance' }
foreach ($file in @('AshenGears.exe','AshenGears.pck')) {
    Copy-Item -LiteralPath (Join-Path $projectRoot ('build\' + $file)) -Destination $stage
}
Copy-Item -LiteralPath (Join-Path $projectRoot 'README.md') -Destination $stage
Copy-Item -LiteralPath (Join-Path $projectRoot 'licenses\Godot-LICENSE.txt'),(Join-Path $projectRoot 'licenses\Godot-COPYRIGHT.txt') -Destination $stage
Copy-Item -LiteralPath (Join-Path $projectRoot 'qa\runtime_tests.json') -Destination $stage
$images = Join-Path $stage 'qa\v04_screenshots'
New-Item -ItemType Directory -Path $images -Force | Out-Null
foreach ($name in @('05_gears.png','10_combat.png')) {
    Copy-Item -LiteralPath (Join-Path $projectRoot ('qa\v04_screenshots\' + $name)) -Destination $images
}
$records = @()
foreach ($file in (Get-ChildItem -LiteralPath $stage -File -Recurse | Where-Object Name -NotIn @('SHA256SUMS.txt','manifest.json'))) {
    $records += [ordered]@{ name=[System.IO.Path]::GetRelativePath($stage,$file.FullName).Replace('\','/'); bytes=$file.Length; sha256=(Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash.ToLower() }
}
$records | ForEach-Object { $_.sha256 + '  ' + $_.name } | Set-Content -LiteralPath (Join-Path $stage 'SHA256SUMS.txt') -Encoding utf8
[ordered]@{version=$version;date='2026-10-10';checks=$report.checks.Count;failures=$report.failures;files=$records;scope='18 authored rooms, three prototype characters, two boss encounters; see README for remaining design scope'} | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $stage 'manifest.json') -Encoding utf8
if ($PublishRoot) {
    $destination = Join-Path $PublishRoot $folderName
    if (Test-Path -LiteralPath $destination) { throw ('Release directory already exists: ' + $destination) }
    New-Item -ItemType Directory -Path $destination -Force | Out-Null
    Get-ChildItem -LiteralPath $stage | Copy-Item -Destination $destination -Recurse
    foreach ($record in $records) {
        if ((Get-FileHash -LiteralPath (Join-Path $destination $record.name) -Algorithm SHA256).Hash.ToLower() -ne $record.sha256) { throw 'Published file hash mismatch' }
    }
    $zipPath = Join-Path $PublishRoot ($folderName + '-Windows.zip')
    if (Test-Path -LiteralPath $zipPath) { throw ('Archive already exists: ' + $zipPath) }
    Compress-Archive -LiteralPath $destination -DestinationPath $zipPath -CompressionLevel Optimal
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $archive = [System.IO.Compression.ZipFile]::OpenRead($zipPath)
    try {
        foreach ($record in $records) {
            $entry = $archive.GetEntry($folderName + '/' + $record.name)
            if (-not $entry -or $entry.Length -ne $record.bytes) { throw 'Archive file missing or truncated' }
            $stream = $entry.Open()
            try {
                $algorithm = [System.Security.Cryptography.SHA256]::Create()
                try { $actual = [Convert]::ToHexString($algorithm.ComputeHash($stream)).ToLower() } finally { $algorithm.Dispose() }
            } finally { $stream.Dispose() }
            if ($actual -ne $record.sha256) { throw 'Archive file hash mismatch' }
        }
    } finally { $archive.Dispose() }
    Write-Output ('Published: ' + $destination)
    Write-Output ('Verified archive: ' + $zipPath)
}
