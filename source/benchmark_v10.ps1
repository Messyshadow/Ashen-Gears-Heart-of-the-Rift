param([string]$Engine='E:\SourceCode\Games\engine\big_engine\godot\bin\godot.windows.editor.x86_64.console.exe')
$ErrorActionPreference='Stop'
$projectRoot=Split-Path -Parent $PSScriptRoot
foreach ($profile in @('high','medium','low')) {
    $env:APPDATA=Join-Path $projectRoot ('.godot-user-bench-v10-' + $profile)
    $output=Join-Path $projectRoot ('build\benchmark-v10-' + $profile + '.log')
    $errors=Join-Path $projectRoot ('build\benchmark-v10-' + $profile + '-error.log')
    $report=Join-Path $projectRoot ('qa\performance_v10_' + $profile + '.json')
    $started=[DateTime]::UtcNow
    $process=Start-Process -FilePath $Engine -ArgumentList @('--path',('"'+$projectRoot+'"'),'--script','res://scripts/benchmark.gd','--',('--profile='+$profile),('--report=res://qa/performance_v10_'+$profile+'.json')) -WindowStyle Hidden -PassThru -RedirectStandardOutput $output -RedirectStandardError $errors
    $process.WaitForExit()
    if ($process.ExitCode -ne 0 -or (Get-Item -LiteralPath $errors).Length -ne 0) {throw ('Benchmark failed: '+$profile)}
    if ((Get-Item -LiteralPath $report).LastWriteTimeUtc -lt $started) {throw 'Benchmark did not produce a fresh report'}
    $data=Get-Content -LiteralPath $report -Raw | ConvertFrom-Json
    if ($data.version -ne '1.0.0' -or $data.records.Count -ne 14) {throw 'Benchmark scope mismatch'}
    Write-Output ('Measured '+$profile+' on '+$data.gpu+' with 14 rooms')
}
