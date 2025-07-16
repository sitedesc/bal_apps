#!/bin/bash
set -e

ORG="cosmobilis"
LOCAL_REPO="$HOME/.ballerina/repositories/local"

modules_dir="./modules"
repo_dir=`pwd`
VERSION="0.1.0"  # adapte ou récupère dynamiquement si besoin

echo "Début publication locale des modules modifiés..."

for mod_path in "$modules_dir"/*; do
  if [ -d "$mod_path" ]; then
    mod_name=$(basename "$mod_path")
    pushd modules/schemed_content_connector
    VERSION=`bal run ./main.bal -- $repo_dir/$mod_path/Ballerina.toml $.package.version`
    popd
    echo "==> Module : $mod_name"

    # Trouver le .bala local installé s'il existe
    bala_path="$LOCAL_REPO/$ORG/$mod_name/$VERSION/${mod_name}.bala"
    if [ -f "$bala_path" ]; then
      # Date du .bala local
      bala_mtime=$(stat -c %Y "$bala_path")
    else
      bala_mtime=0
    fi

    # Trouver la date la plus récente des fichiers sources dans le module
    src_mtime=$(find "$mod_path" -type f -name '*.bal' -printf '%T@\n' | sort -nr | head -1)
    src_mtime=${src_mtime%.*}  # convertir en int

    if [ "$src_mtime" -gt "$bala_mtime" ]; then
      echo "  Sources modifiées plus récentes que la dernière publication locale."
      cd "$mod_path"
      echo "  Packaging..."
      bal pack
      echo "  Pushing to local repo..."
      bal push --repository local
      cd - >/dev/null
    else
      echo "  Pas de modification depuis la dernière publication locale."
    fi
  fi
done

echo "Publication locale terminée."
