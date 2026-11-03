#!/usr/bin/env bash
# L4 restore drill: take a backup now, restore the newest archive into a
# scratch directory, and check the world and admin files are inside it.
#
# Usage: scripts/restore-drill.sh   (the stack must be up; run scripts/smoke.sh first)
# Env:   COMPOSE_FILE / COMPOSE_PROJECT_NAME  as for scripts/smoke.sh
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$repo_root"
# shellcheck source=scripts/lib.sh
. "$repo_root/scripts/lib.sh"

service="backup"

log() { printf '%s\n' "$*" >&2; }
fail() { log "FAIL: $*"; exit 1; }

cid="$(docker compose ps -q "$service")"
[ -n "$cid" ] || fail "no container for service $service; is the stack up?"

log "== backup now (one-shot; the no-players pause is lifted for the drill)"
docker compose exec -T -e PAUSE_IF_NO_PLAYERS=false "$service" backup now >&2

log "== newest archive"
archive="$(docker compose exec -T "$service" sh -c 'ls -t /backups/*.tgz /backups/*.tar.gz 2>/dev/null | head -n 1' | tr -d '\r')"
[ -n "$archive" ] || fail "no archive found in /backups"
size="$(docker compose exec -T "$service" sh -c "wc -c < '$archive'" | tr -d ' \r')"
log "$archive ($size bytes)"

log "== restore into a scratch directory"
mkdir -p .build
restore_dir="$(mktemp -d .build/restore.XXXXXX)"
trap 'rm -rf "$restore_dir"' EXIT
docker compose --progress quiet run --rm --no-deps -T --entrypoint sh \
  --user "$(env_value UID):$(env_value GID)" \
  -v "$repo_root/$restore_dir:/restore" "$service" -c "tar xzf '$archive' -C /restore"
for f in world/level.dat whitelist.json ops.json; do
  [ -e "$restore_dir/$f" ] || fail "$f is missing from the restored archive"
done
log "restored $(find "$restore_dir" -type f | wc -l | tr -d ' ') files; world/level.dat, whitelist.json and ops.json present"
log "RESTORE OK"
