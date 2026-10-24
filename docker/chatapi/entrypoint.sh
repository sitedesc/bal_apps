#!/bin/sh
# Adapte le bloc `servers` du contrat OpenAPI servi par /openapi_dev (celui que charge Swagger UI)
# à l'URL publique de l'instance, puis lance le service.
set -e
f=schemed_talk_service_openapi_dev.yaml
sed -i -e "s#default: http://www.sitems.org#default: ${OPENAPI_SERVER}#" -e "s#default: \"16387\"#default: \"${OPENAPI_PORT}\"#" "$f"
[ -f Config.toml ] || { echo "Config.toml manquant (monter docker/chatapi/Config.toml)"; exit 1; }
exec java $JAVA_OPTS -jar srv_opportunity.jar "$@"
