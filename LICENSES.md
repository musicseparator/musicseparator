# Licences des composants

## Modèles de séparation (dossier `models/`)

| Composant | Licence | Auteur | Note |
|---|---|---|---|
| HTDemucs (htdemucs / htdemucs_ft / htdemucs_6s) | MIT | Meta (facebookresearch/demucs) | Poids + code |
| Exports ONNX (`StemSplitio/*`) | MIT | StemSplit / demucs-onnx | Parité vérifiée vs PyTorch |
| MDX-Net `Kim_Vocal_2.onnx` | MIT | Kuielab & W. Choi (MDX-Net) / UVR | modèle vocal 2 stems |

Ces modèles sont librement redistribuables ; veuillez citer les auteurs
originaux (Demucs, MDX-Net, Ultimate Vocal Remover) en cas d'usage académique.

## Bibliothèques

| Bibliothèque | Licence | Utilisation |
|---|---|---|
| Qt 6 (Widgets, Multimedia, Network, Concurrent) | LGPL-3.0 (ou licence commerciale Qt) | UI, audio output, réseau — liaison **dynamique** |
| ONNX Runtime | MIT | moteur d'inférence (DLL `onnxruntime.dll`) |
| Microsoft.AI.DirectML | MIT | exécution GPU DX12 (DLL `DirectML.dll`) |
| FFmpeg | LGPL-2.1+ (build partagé avec libmp3lame) | décodage + encodage audio |
| yt-dlp | Unlicense / Public Domain | import YouTube (binaire autonome) |

## Obligations en distribution

- **Qt LGPL** : distribuer la licence, et permettre à l'utilisateur de relier
  son propre Qt (liaison dynamique : suffisant ici). Pour une distribution
  fermée sans ces obligations, acquérir une licence commerciale Qt.
- **FFmpeg LGPL** : utiliser exclusivement des builds en bibliothèques
  dynamiques (par défaut dans ce projet) et fournir la licence.
- Conserver les fichiers de licence et d'attribution dans l'installeur.

Ce projet (code source C++, hors dépendances) est distribué sous licence MIT.
