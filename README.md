# MusicSeparator

Application Windows de bureau (C++20 / Qt 6 / CMake) qui sépare une musique en
pistes distinctes — **Vocals, Drums, Bass, Guitar, Piano, Other** — grâce à un
vrai réseau de neurones (HTDemucs / MDX-Net) exécuté par ONNX Runtime, avec
accélération GPU (DirectML / CUDA) et fallback CPU automatique.

Entrées : `.mp3`, `.wav`, `.mp4` (et autres conteneurs FFmpeg), ou un lien
YouTube. Sortie : mini table de mixage synchronisée + export WAV / MP3 / FLAC
dans un dossier `<Titre>_Stems`.

> ⚖️ YouTube : cette fonctionnalité ne doit servir qu'à traiter des contenus
> pour lesquels vous disposez des droits nécessaires. Aucun téléchargement
> illégal n'est encouragé.

---

## 1. Fonctionnalités

- Import par bouton ou **drag & drop** (fichiers) ; import par lien YouTube
  (titre + miniature + meilleure piste audio via `yt-dlp.exe`).
- Décodage universel par **FFmpeg** (tags, pochette, resampling 44,1 kHz stéréo).
- **Séparation neuronale réelle** (aucun filtre fréquentiel) :
  - **2 stems** : Vocals / Instrumental (modèle rapide `Kim_Vocal_2`, ou HTDemucs)
  - **4 stems** : Vocals / Drums / Bass / Other
  - **6 stems** : + Guitar / Piano (`htdemucs_6s`)
  - Qualité : Fast / Balanced / **Best Quality** (`htdemucs_ft` bag, meilleur SDR)
- Traitement par **chunks de 7,8 s avec overlap-add** (fenêtre triangulaire,
  normalisation par poids) → aucun artefact aux raccords, mémoire bornée,
  morceaux longs supportés.
- Interface 100 % non bloquante : l'inférence tourne dans un worker thread avec
  progression « Separating your track… », pourcentage, étape courante et **Cancel**.
- **Mixeur multipiste synchronisé échantillon-précise** : play/pause maître,
  seek par clic sur la waveform, Mute, Solo, volume par piste, bouton Export
  par piste.
- **Export All** : WAV (float32, qualité originale) / MP3 (320 kbps) / FLAC
  (lossless) dans `<Titre>_Stems/{vocals,drums,bass,guitar,piano,other}.ext`.
- GPU : détection automatique, indicateur dans l'en-tête
  (« GPU acceleration: Enabled (DirectML/CUDA) » ou « CPU processing »),
  réglage Auto/CPU/GPU, **jamais de crash** si CUDA/DirectML est absent.
- Gestion d'erreurs complète : format non supporté, fichier corrompu, erreur
  FFmpeg, modèle manquant, RAM/VRAM, CUDA, disque plein, URL YouTube invalide —
  toujours une boîte de dialogue compréhensible, l'application ne se ferme jamais.

## 2. Prérequis (machine de développement)

| Outil | Version | Rôle |
|---|---|---|
| Windows 10/11 x64 | — | plateforme cible |
| Visual Studio 2022 | ≥ 17.6 | compilateur MSVC, C++20 |
| CMake | ≥ 3.24 | génération de build |
| Git | — | clone + vcpkg |
| vcpkg | dernier | dépendances (Qt6, ONNX Runtime, FFmpeg) |

Aucun de ces outils n'est nécessaire sur la machine de l'utilisateur final :
tout est distribué avec `MusicSeparator.exe`.

## 3. Compilation

```powershell
# 1. vcpkg (une seule fois)
git clone https://github.com/microsoft/vcpkg C:\vcpkg
C:\vcpkg\bootstrap-vcpkg.bat

# 2. Cloner le projet
cd C:\dev
git clone <votre-dépôt> MusicSeparator
cd MusicSeparator

# 3. Configurer (vcpkg installe qtbase, qtmultimedia, onnxruntime[dml], ffmpeg —
#    première fois : 30-60 min, ensuite mis en cache)
cmake -B build -S . `
  -DCMAKE_TOOLCHAIN_FILE=C:\vcpkg\scripts\buildsystems\vcpkg.cmake `
  -DVCPKG_TARGET_TRIPLET=x64-windows `
  -DCMAKE_BUILD_TYPE=Release `
  -A x64

# 4. Compiler
cmake --build build --config Release -j

# 5. Télécharger les modèles IA + yt-dlp.exe
.\tools\download_models.ps1
```

Résultat : `build\Release\MusicSeparator.exe` avec à ses côtés, copiés
automatiquement : les DLL Qt/ONNX Runtime/FFmpeg/DirectML (vcpkg applocal +
windeployqt), le dossier `models/` et `yt-dlp.exe`.

> Astuce Debug : remplacez `Release` par `Debug`. Pour forcer CUDA :
> ajoutez la feature `cuda` dans `vcpkg.json` (nécessite CUDA Toolkit +
> cuDNN installés sur la machine de build ; DirectML reste le défaut GPU).

## 4. Modèles (à télécharger une fois)

| Fichier (dans `models/`) | Stems | Taille | Qualité |
|---|---|---|---|
| `htdemucs_fp16weights.onnx` | 4 | 166 Mo | SDR vocals ~8,8 dB |
| `htdemucs.onnx` | 4 | 316 Mo | identique (poids fp32) |
| `htdemucs_6s_fp16weights.onnx` | 6 | 136 Mo | + guitar/piano |
| `htdemucs_6s.onnx` | 6 | 258 Mo | identique (poids fp32) |
| `htdemucs_ft_*_fp16weights.onnx` (×4) | 4 | 4 × 166 Mo | **SDR vocals ~9,19 dB** |
| `Kim_Vocal_2.onnx` | 2 | 67 Mo | vocals SOTA, rapide |

Sources : [StemSplitio](https://huggingface.co/StemSplitio) (exports ONNX
parité-vérifiés vs PyTorch, MIT) et `Eddycrack864/audio-separator-models`
(MIT). Détails et liens dans [models/README.md](models/README.md) et
[LICENSES.md](LICENSES.md).

Sélection automatique :

- **2 stems** : `Kim_Vocal_2` (Fast) sinon `htdemucs` ; instrumental = mix − vocals.
- **4 stems** : `htdemucs` (Fast/Balanced) ; `htdemucs_ft` bag (Best Quality,
  repli automatique sur `htdemucs` si le bag est absent).
- **6 stems** : `htdemucs_6s`.

## 5. Vérification de la qualité (développeurs)

Un script de référence numpy/ONNX est fourni :

```powershell
pip install numpy onnxruntime soundfile
python tools\ref_inference.py models\htdemucs_fp16weights.onnx test.wav ref_out --sources 4
```

Comparez `ref_out/*.wav` avec l'export de l'application sur le même morceau :
l'implémentation C++ (`src/separation/ChunkedInference.h`) reproduit
exactement l'algorithme (segment 343 980, overlap ¼, fenêtre triangulaire,
`weight = max(weight, 1e-8)`), la sortie doit être identique au bit près.

## 6. Distribution de l'utilisateur final

`MusicSeparator.exe` est **autonome** : Qt plugins, DLLs (Qt6, onnxruntime,
DirectML, FFmpeg), `models/` et `yt-dlp.exe` sont posés à côté de l'exe par le
build. Pour un installeur :

```powershell
# Optionnel : windeployqt est déjà exécuté en post-build.
# Installeur NSIS/WiX : inclure tout le contenu de build\Release.
```

Licences à respecter en distribution fermée : Qt 6 en LGPL (liaison dynamique,
fournir la mention de licence et la possibilité de relinker) ou licence
commerciale Qt ; modèles et Demucs en MIT ; FFmpeg LGPL (builds fournis avec
les bibliothèques dynamiques).

## 7. Démarrage rapide

1. Lancez `MusicSeparator.exe`.
2. Glissez un `.mp3` dans la fenêtre (ou Import Audio / lien YouTube).
3. Choisissez le nombre de stems (2 / 4 / 6) et la qualité, cliquez
   **Separate Tracks**.
4. Écoutez le mixeur, réglez Mute/Solo/volume, déplacez la tête de lecture.
5. **Export All** (WAV / MP3 / FLAC) → dossier `<Titre>_Stems`.

## 8. Structure du projet

```
MusicSeparator/
├── CMakeLists.txt            # build Release → MusicSeparator.exe
├── vcpkg.json                # dépendances (qtbase, qtmultimedia, onnxruntime[dml], ffmpeg)
├── src/
│   ├── main.cpp, MainWindow.*
│   ├── audio/                # décodage FFmpeg, buffer, waveform, moteur de lecture + mixer
│   ├── separation/           # ONNX Runtime, chunking overlap-add, worker QThread
│   ├── export/               # encodage WAV/MP3/FLAC + ExportWorker
│   ├── youtube/              # module YouTube isolé (yt-dlp.exe)
│   ├── settings/             # réglages persistants + boîte de dialogue
│   ├── ui/                   # widgets (drop zone, waveform, pistes, mixeur, overlay)
│   └── common/               # codes d'erreur + dialogues
├── models/                   # modèles .onnx (téléchargés, non versionnés)
├── tools/                    # download_models.ps1, ref_inference.py
└── resources/                # thème sombre QSS + icônes SVG
```
