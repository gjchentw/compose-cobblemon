#!/usr/bin/env bash
# L4 restore drill: take a backup now (or use a given archive), restore it
# into a scratch directory, and check the world and admin files are inside
# it and the files that carry the RCON password are not.
#
# Usage: scripts/restore-drill.sh [ARCHIVE]
#   ARCHIVE  path relative to backups/, e.g. keep/world-20261104-120000.tar.gz;
#            without it a new backup is taken and the archive it wrote is used
# Env:   COMPOSE_FILE / COMPOSE_PROJECT_NAME  as for scripts/smoke.sh
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$repo_root"
# shellcheck source=scripts/lib.sh
. "$repo_root/scripts/lib.sh"

service="backup"

cid="$(docker compose ps -q "$service")"
[ -n "$cid" ] || fail "no container for service $service; is the stack up?"

if [ -n "${1:-}" ]; then
  archive="/backups/$1"
  docker compose exec -T "$service" test -f "$archive" || fail "no such archive: backups/$1"
  log "== using archive $archive"
else
  log "== backup now (one-shot; the no-players pause is lifted for the drill)"
  docker compose exec -T "$service" touch /tmp/drill-marker
  docker compose exec -T -e PAUSE_IF_NO_PLAYERS=false "$service" backup now >&2

  log "== archive written by that backup"
  archive="$(docker compose exec -T "$service" sh -c \
    'find /backups -maxdepth 1 \( -name "*.tgz" -o -name "*.tar.gz" \) -newer /tmp/drill-marker | sort | tail -n 1' | tr -d '\r')"
  [ -n "$archive" ] || fail "backup now produced no new archive in /backups"
fi
size="$(docker compose exec -T "$service" sh -c "wc -c < '$archive'" | tr -d ' \r')"
log "$archive ($size bytes)"

log "== restore into a scratch directory"
mkdir -p .build
restore_dir="$(mktemp -d .build/restore.XXXXXX)"
trap 'rm -rf "$restore_dir"' EXIT
# The backup service already runs as the host user (user: in compose.yaml).
docker compose --progress quiet run --rm --no-deps -T --entrypoint sh \
  -v "$repo_root/$restore_dir:/restore" "$service" -c "tar xzf '$archive' -C /restore"
for f in world/level.dat whitelist.json ops.json; do
  [ -e "$restore_dir/$f" ] || fail "$f is missing from the restored archive"
done
for f in server.properties .rcon-cli.env .rcon-cli.yaml; do
  [ ! -e "$restore_dir/$f" ] || fail "$f (holds the RCON password) must not be in the archive; check EXCLUDES in compose.yaml"
done
log "restored $(find "$restore_dir" -type f | wc -l | tr -d ' ') files; world/level.dat, whitelist.json and ops.json present"
log "RESTORE OK"
