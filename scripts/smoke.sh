#!/usr/bin/env bash
# L3 smoke test: check the mrpack for PACK_VERSION exists, start the stack,
# wait for the server to become healthy, then check the version and MOTD,
# that the mounted pack really is the version .env names, the current boot's
# log, the exact server-side mod set, the JVM, the security properties, the
# backup sidecar, the published port and RCON exposure.
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

[ -n "$(env_value RCON_PASSWORD)" ] || fail "RCON_PASSWORD is empty; set a real one in .env"

# The mod set and versions the test expects come from pack/ at the checked-out
# commit (check out the release tag you deploy); the release version comes
# from PACK_VERSION and is compared with the pack file itself further down.
env_v="$(env_value PACK_VERSION)"
[ -f "dist/cobblemon-$env_v.mrpack" ] \
  || fail "dist/cobblemon-$env_v.mrpack is missing; download it from the release or run scripts/pack-export.sh"
minecraft="$(sed -n 's/^minecraft = "\(.*\)"$/\1/p' pack/pack.toml)"
cobblemon_version="$(sed -n 's/^filename = "Cobblemon-fabric-\(.*\)+.*"$/\1/p' pack/mods/cobblemon.pw.toml)"
[ -n "$minecraft" ] && [ -n "$cobblemon_version" ] || fail "cannot read the Minecraft or Cobblemon version from pack/"
server_jars=""
for f in pack/mods/*.pw.toml; do
  if grep -Eq '^side = "(both|server)"$' "$f"; then
    server_jars="$server_jars$(sed -n 's/^filename = "\(.*\)"$/\1/p' "$f")
"
  fi
done

log "== docker compose up -d"
docker compose --progress quiet up -d

log "== waiting up to ${timeout}s for healthy"
wait_healthy "$service" "$timeout" || fail "server did not become healthy"

log "== status query"
status="$(docker compose exec -T "$service" mc-monitor status --host localhost --port 25565)"
log "$status"
printf '%s' "$status" | grep -Fc "version=$minecraft" >/dev/null || fail "status does not report version $minecraft"
printf '%s' "$status" | grep -Fc "Pack $env_v" >/dev/null || fail "MOTD does not announce Pack $env_v"
# The file name is only a claim; the version id inside the pack is the fact.
inside="$(docker compose exec -T "$service" sh -c "unzip -p /packs/cobblemon-$env_v.mrpack modrinth.index.json | jq -r .versionId" | tr -d '\r')"
[ "$inside" = "$env_v" ] || fail "dist/cobblemon-$env_v.mrpack carries version $inside inside, not $env_v"

# Only this boot's output: the container log since its last start. latest.log
# is not used because log4j rolls it over at midnight, which would hide the
# startup lines of a server that booted the day before.
log "== current boot log (container output since start)"
started="$(docker inspect -f '{{.State.StartedAt}}' "$(docker compose ps -q "$service")")"
bootlog="$(docker compose logs --no-color --since "$started" "$service")"
printf '%s' "$bootlog" | grep -c 'Done (' >/dev/null || fail "boot log has no 'Done (' line"
printf '%s' "$bootlog" | grep -Ec -- "- cobblemon ${cobblemon_version//./\\.}" >/dev/null \
  || fail "Fabric did not list cobblemon $cobblemon_version in its mod table"
log "Fabric loaded cobblemon $cobblemon_version"

log "== server-side mod set must be exactly the pack's server-side files"
mods="$(docker compose exec -T "$service" sh -c 'ls /data/mods' | tr -d '\r')"
log "$mods"
if ! diff <(printf '%s' "$server_jars" | sort) <(printf '%s\n' "$mods" | sort) >&2; then
  fail "/data/mods differs from the server-side set in pack/mods (see diff above)"
fi

log "== JVM, security properties, backup sidecar"
docker compose exec -T "$service" java -version 2>&1 | grep -c 'version "21\.' >/dev/null || fail "server JVM is not Java 21"
props="$(docker compose exec -T "$service" grep -Ec '^(online-mode|white-list|enforce-whitelist)=true$' /data/server.properties | tr -d '\r')"
[ "$props" = "3" ] || fail "online-mode, white-list and enforce-whitelist must all be true in server.properties (found $props)"
[ -n "$(docker compose ps -q --status running backup)" ] || fail "backup sidecar is not running"

log "== published port reachable from the host, RCON not published"
mapping="$(docker compose port "$service" 25565 | head -n 1)"
port="${mapping##*:}"
[ -n "$port" ] || fail "port 25565 is not published"
(exec 3<>"/dev/tcp/127.0.0.1/$port") 2>/dev/null || fail "nothing accepts connections on 127.0.0.1:$port"
log "tcp connect to 127.0.0.1:$port ok"
if [ -n "$(docker compose port "$service" 25575 2>/dev/null)" ]; then
  fail "RCON port 25575 is published on the host"
fi

log "SMOKE OK"
