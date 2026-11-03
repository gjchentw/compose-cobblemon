#!/usr/bin/env bash
# Copy the production world and admin files into the staging data directory,
# for testing an upgrade against real data (docs/upgrade.md).
#
# Production is paused for the copy with save-off / save-all flush / save-on
# over RCON when it is running; when it is stopped the files are copied as is.
# The staging stack must be stopped. The existing staging world is replaced.
#
# Usage: scripts/staging-clone-world.sh
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$repo_root"
# shellcheck source=scripts/lib.sh
. "$repo_root/scripts/lib.sh"

log() { printf '%s\n' "$*" >&2; }
fail() { log "FAIL: $*"; exit 1; }

staging_files="compose.yaml:compose.staging.yaml"
if [ -n "$(COMPOSE_FILE="$staging_files" docker compose ps -q --status running cobblemon 2>/dev/null)" ]; then
  fail "the staging server is running; stop it first: COMPOSE_FILE=$staging_files docker compose down"
fi
[ -e data/world/level.dat ] || fail "data/world/level.dat not found; is there a production world yet?"

prod_running=""
if [ -n "$(COMPOSE_FILE=compose.yaml docker compose ps -q --status running cobblemon 2>/dev/null)" ]; then
  prod_running=1
fi
rcon() { COMPOSE_FILE=compose.yaml docker compose exec -T cobblemon rcon-cli "$@" >/dev/null; }

mkdir -p staging/data
if [ -e staging/data/world ]; then
  log "replacing existing staging world: $(du -sh staging/data/world | cut -f1) in staging/data/world"
fi

if [ -n "$prod_running" ]; then
  log "== pausing production saves (save-off, save-all flush)"
  # The trap is installed before save-off so that any failure or Ctrl-C after
  # this point still turns autosave back on.
  trap 'if rcon save-on; then log "== production saves resumed"; else log "WARNING: save-on failed; run: docker compose exec cobblemon rcon-cli save-on"; fi' EXIT
  rcon save-off
  rcon save-all flush
fi

log "== copying world, config and admin files into staging/data"
# Run the copy in a container as root so file ownership is preserved on Linux hosts.
COMPOSE_FILE=compose.yaml docker compose --progress quiet run --rm --no-deps -T --entrypoint sh \
  -v "$repo_root/staging/data:/staging" backup -c '
    set -e
    rm -rf /staging/world
    cp -a /data/world /staging/
    [ -d /data/config ] && { rm -rf /staging/config; cp -a /data/config /staging/; }
    for f in whitelist.json ops.json banned-players.json banned-ips.json usercache.json; do
      [ -e "/data/$f" ] && cp -a "/data/$f" /staging/
    done
    echo "copied $(find /staging -type f | wc -l) files"
  ' >&2

[ -e staging/data/world/level.dat ] || fail "staging/data/world/level.dat missing after the copy"
log "CLONE OK: staging/data now holds a copy of the production world"
