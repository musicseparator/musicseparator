$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath $PSScriptRoot
try {
    Start-Transcript -Path (Join-Path $PSScriptRoot 'compilation_ui.log') -Force | Out-Null
    $cache = Join-Path $PSScriptRoot 'build\CMakeCache.txt'
    if (!(Test-Path -LiteralPath $cache)) {
        throw 'Extrayez le ZIP dans votre dossier MusicSeparator existant, a cote de build, puis relancez.'
    }
    $content = Get-Content -LiteralPath $cache
    $line = $content | Where-Object { $_ -match '^CMAKE_COMMAND:INTERNAL=' } | Select-Object -First 1
    if ($line) { $cmake = $line.Substring($line.IndexOf('=') + 1) }
    else { $cmake = (Get-Command cmake -ErrorAction Stop).Source }
    if (!(Test-Path -LiteralPath $cmake)) { throw 'CMake introuvable. Utilisez votre terminal de compilation habituel.' }
    $running = Get-Process MusicSeparator -ErrorAction SilentlyContinue
    if ($running) { throw 'Fermez toutes les fenetres MusicSeparator (et le processus dans le Gestionnaire des taches), puis relancez APPLIQUER_UI.cmd. Aucun fichier executable ne sera remplace pendant son utilisation.' }
    $source = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'CMakeLists.txt') -Raw
    foreach ($required in @('src/ui/Theme.cpp', 'src/ui/StudioWindow.cpp', 'src/ui/AppearanceDialog.cpp', 'src/midi/MidiExportDialog.cpp')) {
        if (!$source.Contains($required)) { throw "Extraction incomplete : CMakeLists.txt ne contient pas $required. Extrayez TOUS les fichiers du nouveau ZIP avec remplacement." }
    }
    if (!(Select-String -LiteralPath (Join-Path $PSScriptRoot 'src/ui/Theme.cpp') -Pattern 'Sky Mint / Graphite' -Quiet)) {
        throw 'Les nouvelles sources Liquid Glass sont absentes. Extrayez le ZIP complet avec remplacement.'
    }
    Write-Host 'Configuration de Liquid Glass MIDI 2.1...'
    & $cmake -S $PSScriptRoot -B (Join-Path $PSScriptRoot 'build')
    if ($LASTEXITCODE -ne 0) { throw 'Configuration CMake echouee. Consultez compilation_ui.log.' }
    # ZIP timestamps can predate objects from a previous build. Recompile updated sources.
    Get-ChildItem (Join-Path $PSScriptRoot 'src'),(Join-Path $PSScriptRoot 'resources') -Recurse -File |
        ForEach-Object { $_.LastWriteTime = Get-Date }
    Write-Host 'Compilation de Liquid Glass MIDI 2.1...' 
    & $cmake --build build --config Release --target MusicSeparator --parallel 4
    if ($LASTEXITCODE -ne 0) { throw 'Compilation echouee. Fermez MusicSeparator si le fichier exe est verrouille.' }
    $multiConfig = $content | Where-Object { $_ -match '^CMAKE_CONFIGURATION_TYPES:[^=]+=.+' }
    if ($multiConfig) { $relativeExe = 'build\Release\MusicSeparator.exe' }
    else { $relativeExe = 'build\MusicSeparator.exe' }
    $exe = Join-Path $PSScriptRoot $relativeExe
    if (!(Test-Path -LiteralPath $exe)) { throw 'Executable compile introuvable. Consultez le journal.' }
    Write-Host 'Liquid Glass MIDI 2.1 compile. Appearance propose les 10 palettes.'
    Stop-Transcript | Out-Null
    Start-Process -FilePath $exe -WorkingDirectory (Split-Path $exe)
    exit 0
} catch {
    Write-Host $_.Exception.Message -ForegroundColor Red
    try { Stop-Transcript | Out-Null } catch {}
    exit 1
}
