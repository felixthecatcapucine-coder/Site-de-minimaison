#!/bin/bash
# Recompile le site web de Mini Maisons et prépare le paquet pour Vercel
# (version Mac et Linux de preparer_vercel.ps1) :
#   vercel/site/                                 le site prêt à mettre en ligne
#   vercel/pour-github/MiniMaisons-vercel.zip    le même site, en un seul fichier
#     (à envoyer sur GitHub avec ouvrir-zip.js et vercel.json, qui sont à côté :
#      Vercel décompresse le zip lui-même)
#
# Utilisation (depuis le dossier du projet) :
#   bash vercel/preparer_vercel.sh
#   (ajoute --sans-compiler pour réutiliser le dernier build/web)

set -euo pipefail
projet="$(cd "$(dirname "$0")/.." && pwd)"
dossier="$projet/vercel"
site="$dossier/site"
zip="$dossier/pour-github/MiniMaisons-vercel.zip"

cd "$projet"
if ! command -v flutter > /dev/null; then
  export PATH="$HOME/development/flutter/bin:$PATH"
fi
if [ "${1:-}" != "--sans-compiler" ]; then
  # Le site est servi à la racine de l'adresse Vercel.
  flutter build web --release --base-href /
fi

# Le site compilé, plus les réglages Vercel et le mode d'emploi.
rm -rf "$site"
cp -R build/web "$site"
cp "$dossier/vercel.json" "$dossier/LISEZ-MOI-VERCEL.txt" "$site/"
# Fichier interne de Flutter, inutile en ligne.
rm -f "$site/.last_build_id"
# Les .gitignore de flutter_scene disent d'ignorer ses shaders : sur GitHub
# (ou avec l'outil Vercel), la 3D ne marcherait plus. Ils ne servent à rien en ligne.
find "$site" -name .gitignore -delete
find "$site" -name .DS_Store -delete

# Le zip contient le site à sa racine (index.html tout en haut).
rm -f "$zip"
(cd "$site" && zip -q -r -X "$zip" .)
echo "Paquet Vercel prêt : $zip ($(du -h "$zip" | cut -f1))"
