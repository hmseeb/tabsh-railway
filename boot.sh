#!/bin/bash
# Root only long enough to hand the volume to `node`, then both processes run
# as `node`. If either exits the container exits, so Railway restarts it.
set -euo pipefail
: "${TABSH_PASSWORD:?TABSH_PASSWORD must be set}"
rm -rf /data/lost+found
mkdir -p "$HOME"
[ "$(stat -c %U "$HOME")" = node ] || chown -R node:node "$HOME"
TABSH_PASSWORD_HASH=$(caddy hash-password --plaintext "$TABSH_PASSWORD")
export TABSH_PASSWORD_HASH
unset TABSH_PASSWORD
cd "$HOME"
# tabsh would otherwise take Railway's PORT, and it logs its token: keep that out of deploy logs.
exec setpriv --reuid=node --regid=node --init-groups bash -c '
  /usr/local/bin/agents.sh
  { tabsh 7681 2>&1 | grep --line-buffered -v "#token="; } &
  caddy run --config /etc/caddy/Caddyfile --adapter caddyfile &
  wait -n; exit 1'
