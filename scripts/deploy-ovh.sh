#!/usr/bin/env bash
# Déploie tchatapi sur le serveur OVH it-doc ($OVH_SSH:$OVH_DIR) — modèle aiacms/odoo : /srv/bal_apps est un
# clone de git@github.com:sitedesc/bal_apps.git (clé de déploiement du serveur, lecture seule), mis à jour
# par `git pull --ff-only`, sans sudo. Cf. deploy/ovh/RUNBOOK.md.
#   scripts/deploy-ovh.sh            # push main, git pull + build + up sur le serveur
#   scripts/deploy-ovh.sh --secrets  # idem + pousse .env et docker/chatapi/Config.toml (première fois, ou changement)
set -euo pipefail
cd "$(dirname "$0")/.."; set -a; . ./.env; set +a
REMOTE="${OVH_SSH}"; DIR="${OVH_DIR}"
DC='docker compose -f docker-compose.yml -f docker-compose.prod.yml'

[ -z "$(git status --porcelain --untracked-files=no)" ] || { echo "Modifications non commitées : commiter d'abord (le serveur déploie origin/main)."; git status --short --untracked-files=no; exit 1; }
echo "== git push origin main"; git push -q origin main
if [ "${1:-}" = "--secrets" ]; then
  echo "== secrets -> serveur"
  grep -vE '^(OVH_|CHATAPI_(WEB|API)_PORT|OPENAPI_)' .env | ssh "$REMOTE" "cat > $DIR/.env && chmod 600 $DIR/.env"
  scp -q docker/chatapi/Config.toml "$REMOTE:$DIR/docker/chatapi/Config.toml"; ssh "$REMOTE" "chmod 644 $DIR/docker/chatapi/Config.toml"
fi
echo "== git pull + build + up sur $REMOTE:$DIR (compilation Ballerina : plusieurs minutes)"
ssh "$REMOTE" "cd $DIR && git pull --ff-only origin main && test -f .env && test -f docker/chatapi/Config.toml || { echo 'ERREUR : .env ou docker/chatapi/Config.toml absent (relancer avec --secrets)'; exit 1; }
  $DC up -d --build --remove-orphans 2>&1 | tail -4 && $DC ps"
echo "OK — https://${CHATAPI_HOST}/"
