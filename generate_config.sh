#!/bin/bash -xv
# Usage: ./generate_config.sh <app> <env>
# Example: ./generate_config.sh chatapi dev

set -e

APP=$1
ENV=$2
DIR=$3

SHARED="Config.shared.${ENV}.toml"
SHARED_SECRETS="Secrets.shared.${ENV}.toml"
APP_CONF="$DIR/${APP}/Config.app.${ENV}.toml"
APP_CONF_SECRETS="$DIR/${APP}/Secrets.app.${ENV}.toml"
TARGET="$DIR/${APP}/Config.toml"

if [[ ! -f "$SHARED" ]]; then
  echo "Missing: $SHARED"
  exit 1
fi

if [[ ! -f "$APP_CONF" ]]; then
  echo "Missing: $APP_CONF"
  exit 2
fi

cat "$SHARED" "$APP_CONF" > "$TARGET"

if [[ -f "$SHARED_SECRETS" ]]; then
cat "$SHARED_SECRETS" >> "$TARGET"
fi

if [[ -f "$APP_CONF_SECRETS" ]]; then
cat "$APP_CONF_SECRETS" >> "$TARGET"
fi

echo "✅ Generated: $TARGET"