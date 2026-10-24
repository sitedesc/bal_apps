#!/usr/bin/env bash
# Déploie tchatapi sur le serveur OVH it-doc ($OVH_SSH:$OVH_DIR) — cf. deploy/ovh/RUNBOOK.md.
# Synchronise le dépôt par rsync (l'origine GitHub sitedesc/bal_apps est privée et sans clé de
# déploiement sur le serveur), pousse .env et docker/chatapi/Config.toml, puis build + up.
set -euo pipefail
cd "$(dirname "$0")/.."; set -a; . ./.env; set +a
REMOTE="${OVH_SSH}"; DIR="${OVH_DIR}"
DC='docker compose -f docker-compose.yml -f docker-compose.prod.yml'
echo "== rsync -> $REMOTE:$DIR"
ssh "$REMOTE" "mkdir -p $DIR"
rsync -az --delete --exclude .git/ --exclude 'target/' --exclude .env --exclude 'docker/chatapi/Config.toml' --exclude 'apps/chatapi/srv_opportunity/responses/' ./ "$REMOTE:$DIR/"
grep -vE '^(OVH_|CHATAPI_(WEB|API)_PORT|OPENAPI_)' .env | ssh "$REMOTE" "cat > $DIR/.env && chmod 600 $DIR/.env"
scp -q docker/chatapi/Config.toml "$REMOTE:$DIR/docker/chatapi/Config.toml"; ssh "$REMOTE" "chmod 644 $DIR/docker/chatapi/Config.toml"
echo "== build + up sur le serveur (compilation Ballerina : plusieurs minutes)"
ssh "$REMOTE" "cd $DIR && $DC up -d --build --remove-orphans 2>&1 | tail -5 && $DC ps"
echo "OK — https://${CHATAPI_HOST}/"
