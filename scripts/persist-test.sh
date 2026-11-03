#!/usr/bin/env bash
# L4 persistence test: the world survives an orderly stop and restart.
#
# Sets a gamerule through RCON (it is stored in the world's level.dat), stops
# the stack with `docker compose stop` (SIGTERM, which the image turns into an
# RCON "stop" within stop_grace_period), starts it again, waits for healthy,
# and checks that the gamerule, the world directory and the admin files
# survived. The container must exit with code 0 and the log lines written
# during the stop must show the full orderly shutdown sequence, so a SIGKILL
# (signal override or grace period too short) fails the test.
#
# Usage: scripts/persist-test.sh   (the stack must be healthy; run scripts/smoke.sh first)
# Env:   SMOKE_TIMEOUT  seconds to wait for healthy after the restart (default 600)
#        COMPOSE_FILE / COMPOSE_PROJECT_NAME  as for scripts/smoke.sh
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$repo_root"
# shellcheck source=scripts/lib.sh
. "$repo_root/scripts/lib.sh"

timeout="${SMOKE_TIMEOUT:-600}"
service="cobblemon"
grace=120   # must match stop_grace_period in compose.yaml

log() { printf '%s\n' "$*" >&2; }
fail() { log "FAIL: $*"; exit 1; }
rcon() { docker compose exec -T "$service" rcon-cli "$@"; }

cid="$(docker compose ps -q "$service")"
if [ -z "$cid" ] || [ "$(docker inspect -f '{{.State.Health.Status}}' "$cid")" != "healthy" ]; then
  fail "service $service is not healthy; run scripts/smoke.sh first"
fi

log "== marker: gamerule keepInventory true, then save-all flush"
rcon gamerule keepInventory true >/dev/null
rcon save-all flush >/dev/null
before="$(docker compose logs --no-color "$service" | wc -l | tr -d ' ')"

log "== docker compose stop (grace period ${grace}s)"
start="$(date +%s)"
docker compose --progress quiet stop
elapsed=$(( $(date +%s) - start ))
log "stopped in ${elapsed}s"
if [ "$elapsed" -ge "$grace" ]; then
  fail "stop took ${elapsed}s, at or above the ${grace}s grace period: the server was probably killed"
fi

log "== orderly-stop evidence"
exit_code="$(docker inspect -f '{{.State.ExitCode}}' "$cid")"
[ "$exit_code" = "0" ] || fail "container exit code is $exit_code, not 0 (137 means SIGKILL)"
during="$(docker compose logs --no-color "$service" | tail -n +"$((before + 1))")"
for evidence in 'gracefully stopping server' 'Stopping server' 'Saving worlds' 'All dimensions are saved' 'mc-server-runner.*Done'; do
  printf '%s' "$during" | grep -Ec "$evidence" >/dev/null || fail "no '$evidence' line in the log during the stop"
done

log "== docker compose up -d"
docker compose --progress quiet up -d
wait_healthy "$service" "$timeout" || fail "server did not become healthy after the restart"

log "== state after the restart"
value="$(rcon gamerule keepInventory)"
log "$value"
printf '%s' "$value" | grep -c 'true' >/dev/null || fail "gamerule keepInventory did not survive the restart"
rcon gamerule keepInventory false >/dev/null
docker compose exec -T "$service" sh -c 'test -e /data/world/level.dat && test -e /data/whitelist.json && test -e /data/ops.json' \
  || fail "world/level.dat, whitelist.json or ops.json missing after the restart"

log "PERSIST OK"
