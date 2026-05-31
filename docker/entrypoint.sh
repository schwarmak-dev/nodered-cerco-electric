#!/bin/bash
set -e

if [ "$(id -u)" = "0" ]; then
    echo "Fijando permisos de /data..."
    chown -R node-red:node-red /data 2>/dev/null || true
    exec su-exec node-red /entrypoint.sh "$@"
fi

FLOWS_DIR="/data/flows"
FLOWS_FILE="/data/flows.json"

if [ -d "$FLOWS_DIR" ]; then
  shopt -s nullglob
  FILES=("$FLOWS_DIR"/*.json)
  shopt -u nullglob

  if [ ${#FILES[@]} -gt 0 ]; then
    echo "Combinando ${#FILES[@]} archivos de flujo..."
    node -e "
      const fs = require('fs');
      const path = require('path');
      const dir = '$FLOWS_DIR';
      const files = fs.readdirSync(dir).filter(f => f.endsWith('.json'));
      const all = files.flatMap(f => JSON.parse(fs.readFileSync(path.join(dir, f), 'utf8')));
      fs.writeFileSync('$FLOWS_FILE', JSON.stringify(all, null, 2));
      console.log('✓ Flujos combinados en flows.json');
    "
  fi
fi

exec node-red --flowFile "$FLOWS_FILE" "$@"
