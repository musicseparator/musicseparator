$ErrorActionPreference = 'Stop'
$destination = Join-Path $PSScriptRoot 'models'
New-Item -ItemType Directory -Path $destination -Force | Out-Null
$model = Join-Path $destination 'ms_htdemucs_6s_verified.onnx'
$expectedHash = '7ce55792e2231c93fbf92de95f5fd5b3a5e6c89f7db690dfd693e8f1dce56869'
if (Test-Path -LiteralPath $model) {
    if ((Get-FileHash -LiteralPath $model -Algorithm SHA256).Hash -ieq $expectedHash) {
        Write-Host 'Modele voix/batterie/basse/guitare/piano deja installe.'
        return
    }
    throw 'Le modele ms_htdemucs_6s_verified.onnx est endommage ou a ete modifie. Renommez ce fichier puis relancez.'
}
# Reuse an existing verified download if possible; keep all existing models.
$candidates = @(
    (Join-Path $destination 'htdemucs_6s_fp16weights.onnx'),
    (Join-Path $PSScriptRoot 'build\Release\models\htdemucs_6s_fp16weights.onnx'),
    (Join-Path $PSScriptRoot 'build\models\htdemucs_6s_fp16weights.onnx')
)
foreach ($candidate in $candidates) {
    if ((Test-Path -LiteralPath $candidate) -and
        ((Get-FileHash -LiteralPath $candidate -Algorithm SHA256).Hash -ieq $expectedHash)) {
        Copy-Item -LiteralPath $candidate -Destination $model
        Write-Host 'Modele existant verifie et reutilise.'
        return
    }
}
$url = 'https://huggingface.co/StemSplitio/htdemucs-6s-onnx/resolve/main/htdemucs_6s_fp16weights.onnx?download=true'
$tempModel = Join-Path $destination ('model-' + [Guid]::NewGuid().ToString('N') + '.part')
try {
    Write-Host 'Telechargement du modele instruments (136 Mo environ). Connexion Internet requise.'
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri $url -OutFile $tempModel -UseBasicParsing
    if ((Get-FileHash -LiteralPath $tempModel -Algorithm SHA256).Hash -ine $expectedHash) {
        throw 'Le fichier telecharge ne correspond pas au modele attendu. Installation interrompue.'
    }
    Move-Item -LiteralPath $tempModel -Destination $model
    Write-Host 'Modele telecharge et empreinte SHA256 verifiee.'
} finally {
    if (Test-Path -LiteralPath $tempModel) { Remove-Item -LiteralPath $tempModel }
}
