param(
    [string]$Engine = 'E:\SourceCode\Games\engine\big_engine\godot\bin\godot.windows.editor.x86_64.console.exe',
    [string]$PublishRoot = 'E:\Godot\release',
    [switch]$SkipExport
)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$version = '0.1.0'
$folderName = '灰烬齿轮-裂界之心-' + $version
$stage = Join-Path $projectRoot 'build\package'
New-Item -ItemType Directory -Path $stage -Force | Out-Null
if (-not $SkipExport) {
    $env:APPDATA = Join-Path $projectRoot '.godot-user-export'
    $env:TEMP = Join-Path $projectRoot 'build\export-temp'
    $env:TMP = $env:TEMP
    New-Item -ItemType Directory -Path $env:TEMP -Force | Out-Null
    & $Engine --headless --path $projectRoot --export-release 'Windows Ashen Gears' (Join-Path $projectRoot 'build\AshenGears.exe')
    if ($LASTEXITCODE -ne 0) { throw 'Godot export failed' }
}
$report = Get-Content -LiteralPath (Join-Path $projectRoot 'qa\runtime_tests.json') -Raw -Encoding utf8 | ConvertFrom-Json
if ($report.failures -ne 0) { throw 'Runtime acceptance checks did not pass' }
foreach ($file in @('AshenGears.exe','AshenGears.pck')) {
    Copy-Item -LiteralPath (Join-Path $projectRoot ('build\' + $file)) -Destination $stage
}
Copy-Item -LiteralPath (Join-Path $projectRoot 'README.md') -Destination $stage
Copy-Item -LiteralPath (Join-Path $projectRoot 'licenses\Godot-LICENSE.txt'),(Join-Path $projectRoot 'licenses\Godot-COPYRIGHT.txt') -Destination $stage
Copy-Item -LiteralPath (Join-Path $projectRoot 'qa\runtime_tests.json') -Destination $stage
$records = @()
foreach ($file in (Get-ChildItem -LiteralPath $stage -File | Where-Object Name -NotIn @('SHA256SUMS.txt','manifest.json'))) {
    $records += [ordered]@{ name=$file.Name; bytes=$file.Length; sha256=(Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash.ToLower() }
}
$records | ForEach-Object { $_.sha256 + '  ' + $_.name } | Set-Content -LiteralPath (Join-Path $stage 'SHA256SUMS.txt') -Encoding utf8
[ordered]@{version=$version;date='2026-10-09';checks=$report.checks.Count;failures=$report.failures;files=$records;scope='12-room prologue prototype; see README for unimplemented design features'} | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $stage 'manifest.json') -Encoding utf8
if ($PublishRoot) {
    $destination = Join-Path $PublishRoot $folderName
    if (Test-Path -LiteralPath $destination) { throw ('Release directory already exists: ' + $destination) }
    New-Item -ItemType Directory -Path $destination -Force | Out-Null
    Get-ChildItem -LiteralPath $stage -File | Copy-Item -Destination $destination
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
