#!/usr/bin/env bash
# L3 smoke test: start the stack, wait for the server to become healthy,
# then check the version, the current boot's log, the server-side mod set
# and RCON exposure.
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


rcon_password="$(env_value RCON_PASSWORD)"
if [ -z "$rcon_password" ] || [ "$rcon_password" = "replace-with-a-long-random-password" ]; then
  fail "RCON_PASSWORD is empty or still the placeholder; set a real one in .env"
fi

# The pinned Cobblemon version and the client-only jar list come from pack/,
# the source of truth, so this test cannot drift from the pack.
cobblemon_version="$(sed -n 's/^filename = "Cobblemon-fabric-\(.*\)+.*"$/\1/p' pack/mods/cobblemon.pw.toml)"
[ -n "$cobblemon_version" ] || fail "cannot read the Cobblemon version from pack/mods/cobblemon.pw.toml"
client_only=""
for f in pack/mods/*.pw.toml; do
  if grep -q '^side = "client"$' "$f"; then
    client_only="$client_only $(sed -n 's/^filename = "\(.*\)"$/\1/p' "$f")"
  fi
done

log "== docker compose up -d"
docker compose --progress quiet up -d

log "== waiting up to ${timeout}s for healthy"
wait_healthy "$service" "$timeout" || fail "server did not become healthy"

log "== status query"
status="$(docker compose exec -T "$service" mc-monitor status --host localhost --port 25565)"
log "$status"
printf '%s' "$status" | grep -c 'version=1\.21\.1' >/dev/null || fail "status does not report version 1.21.1"

# The game writes one log per boot, so latest.log is bounded and cannot be
# confused with earlier boots of the same container.
log "== current boot log (/data/logs/latest.log)"
bootlog="$(docker compose exec -T "$service" cat /data/logs/latest.log)"
printf '%s' "$bootlog" | grep -c 'Done (' >/dev/null || fail "boot log has no 'Done (' line"
printf '%s' "$bootlog" | grep -Ec -- "- cobblemon ${cobblemon_version//./\\.}" >/dev/null \
  || fail "Fabric did not list cobblemon $cobblemon_version in its mod table"
log "Fabric loaded cobblemon $cobblemon_version"

log "== server-side mod set"
mods="$(docker compose exec -T "$service" sh -c 'ls /data/mods')"
log "$mods"
for jar in $client_only; do
  if printf '%s\n' "$mods" | grep -Fxc "$jar" >/dev/null; then
    fail "client-only mod installed on the server: $jar"
  fi
done
printf '%s\n' "$mods" | grep -Fxc "Cobblemon-fabric-${cobblemon_version}+1.21.1.jar" >/dev/null \
  || fail "Cobblemon-fabric-${cobblemon_version}+1.21.1.jar missing from /data/mods"

log "== RCON must not be published"
if [ -n "$(docker compose port "$service" 25575 2>/dev/null)" ]; then
  fail "RCON port 25575 is published on the host"
fi

log "SMOKE OK"
