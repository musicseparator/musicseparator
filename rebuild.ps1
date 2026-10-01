$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath $PSScriptRoot
$log = Join-Path $PSScriptRoot 'compilation_fix.log'
try {
    Start-Transcript -Path $log -Force | Out-Null
    $cache = Join-Path $PSScriptRoot 'build\CMakeCache.txt'
    if (!(Test-Path -LiteralPath $cache)) {
        throw 'build\CMakeCache.txt absent. Extrayez le ZIP dans le dossier du projet existant, au meme niveau que src, build et CMakeLists.txt.'
    }
    $line = Get-Content -LiteralPath $cache | Where-Object { $_ -match '^CMAKE_COMMAND:INTERNAL=' } | Select-Object -First 1
    if ($line) { $cmake = $line.Substring($line.IndexOf('=') + 1) }
    else { $cmake = (Get-Command cmake -ErrorAction Stop).Source }
    if (!(Test-Path -LiteralPath $cmake)) { throw 'CMake introuvable. Relancez depuis votre terminal de compilation habituel.' }
    & (Join-Path $PSScriptRoot 'install_instrument_model.ps1')
    Write-Host 'Compilation du correctif et des tests...'
    & $cmake --build build --config Release --target MusicSeparator MixerDeviceTests SeparationMathTests --parallel 4
    if ($LASTEXITCODE -ne 0) { throw 'La compilation a echoue. Aucun ancien executable ne sera lance.' }
    $exe = @('build\Release\MusicSeparator.exe', 'build\MusicSeparator.exe') | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
    if (!$exe) { throw 'Executable compile introuvable.' }
    $exe = (Resolve-Path -LiteralPath $exe).Path
    $test = Join-Path (Split-Path $exe) 'MixerDeviceTests.exe'
    if (!(Test-Path -LiteralPath $test)) { throw 'Executable de tests introuvable.' }
    & $test
    if ($LASTEXITCODE -ne 0) { throw 'Les tests audio ont echoue.' }
    $mathTest = Join-Path (Split-Path $exe) 'SeparationMathTests.exe'
    if (!(Test-Path -LiteralPath $mathTest)) { throw 'Tests de separation introuvables.' }
    & $mathTest
    if ($LASTEXITCODE -ne 0) { throw 'Les tests de separation ont echoue.' }
    $modelOutput = Join-Path (Split-Path $exe) 'models'
    New-Item -ItemType Directory -Path $modelOutput -Force | Out-Null
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'models\ms_htdemucs_6s_verified.onnx') -Destination $modelOutput -Force
    Write-Host 'Compilation et tests termines. Lancement de la version corrigee.' 
    Stop-Transcript | Out-Null
    Start-Process -FilePath $exe -WorkingDirectory (Split-Path $exe)
    exit 0
} catch {
    Write-Host $_.Exception.Message -ForegroundColor Red
    try { Stop-Transcript | Out-Null } catch {}
    exit 1
}
