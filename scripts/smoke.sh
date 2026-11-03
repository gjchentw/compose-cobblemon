#!/usr/bin/env bash
# L3 smoke test: start the stack, wait for the server to become healthy,
# then check version, log evidence, server-side mod set and RCON exposure.
#
# Usage: scripts/smoke.sh
# Env:   SMOKE_TIMEOUT  seconds to wait for healthy (default 600)
#        COMPOSE_FILE / COMPOSE_PROJECT_NAME  honoured by docker compose, so the
#        same script serves staging (see compose.staging.yaml).
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$repo_root"
# shellcheck source=scripts/lib.sh
. "$repo_root/scripts/lib.sh"

timeout="${SMOKE_TIMEOUT:-600}"
service="cobblemon"
# Files that must never be installed server-side (client-only mods, by filename token).
client_only="sodium immediatelyfast entityculling modmenu placeholder-api emi xaerominimap xaeroworldmap mousetweaks"

log() { printf '%s\n' "$*" >&2; }
fail() { log "FAIL: $*"; exit 1; }

if [ "$(env_value RCON_PASSWORD)" = "replace-with-a-long-random-password" ]; then
  fail "RCON_PASSWORD is still the placeholder from .env.example; set a real one in .env"
fi

log "== docker compose up -d"
docker compose --progress quiet up -d

log "== waiting up to ${timeout}s for healthy"
wait_healthy "$service" "$timeout" || fail "server did not become healthy"

log "== status query"
status="$(docker compose exec -T "$service" mc-monitor status --host localhost --port 25565)"
log "$status"
printf '%s' "$status" | grep -q 'version=1\.21\.1' || fail "status does not report version 1.21.1"

log "== log evidence"
logs="$(docker compose logs --no-color "$service")"
printf '%s' "$logs" | grep -q 'Done (' || fail "log has no 'Done (' line"
printf '%s' "$logs" | grep -qi 'cobblemon' || fail "log never mentions cobblemon"

log "== server-side mod set"
mods="$(docker compose exec -T "$service" sh -c 'ls /data/mods')"
log "$mods"
for token in $client_only; do
  if printf '%s' "$mods" | grep -qi "$token"; then
    fail "client-only mod installed on the server: $token"
  fi
done
printf '%s' "$mods" | grep -qi 'cobblemon' || fail "cobblemon jar missing from /data/mods"

log "== RCON must not be published"
if [ -n "$(docker compose port "$service" 25575 2>/dev/null)" ]; then
  fail "RCON port 25575 is published on the host"
fi

log "SMOKE OK"
