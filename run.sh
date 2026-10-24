#!/usr/bin/env bash
# Pilotage de la stack Docker tchatapi (dev). Même interface que odoo/run.sh et aiacms-classic/run.sh.
set -euo pipefail
ACTION="${1:-start}"; shift || true
cd "$(dirname "$0")"
case "${ACTION}" in
  start)   docker compose up -d --build; docker compose ps; docker compose logs --tail=30 chatapi_api ;;
  stop)    docker compose stop; docker compose ps ;;
  restart) docker compose down; docker compose up -d --build; docker compose ps ;;
  build)   docker compose build "$@" ;;
  logs)    docker compose logs -f --tail=100 "$@" ;;
  ps)      docker compose ps ;;
  shell)   docker compose exec chatapi_api bash ;;
  test)    # exécute le scénario d'exemple (/schemed_talk_examples) puis lit le détail (/schemed_talks_responses)
    B="http://localhost:${CHATAPI_WEB_PORT:-8090}"; T=$(mktemp)
    # /schemed_talk_examples renvoie {type, description, talkScheme:[...]} ; l'API attend le tableau talkScheme
    curl -sf "$B/schemed_talk_examples" | python3 -c "import json,sys; d=json.load(sys.stdin); json.dump(d['talkScheme'], open('$T','w')); print('scénario:', d['type'], '-', len(d['talkScheme']), 'étapes')"
    curl -sf -X POST -H "Content-Type: application/json" -d @"$T" "$B/schemed_talks" | head -c 800; echo; echo "--- responses:"
    curl -sf -X POST -H "Content-Type: application/json" -d @"$T" "$B/schemed_talks_responses" | head -c 800; echo; rm -f "$T" ;;
  deploy)  scripts/deploy-ovh.sh "$@" ;;
  clean)   docker compose down --remove-orphans; docker image prune -f; docker builder prune -f; docker system df ;;
  *) echo "Usage: $0 [start|stop|restart|build|logs|ps|shell|test|deploy|clean]"; exit 1 ;;
esac
