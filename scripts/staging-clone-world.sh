#!/usr/bin/env bash
# Copy the production world and admin files into the staging data directory,
# for testing an upgrade against real data (docs/upgrade.md).
#
# Production is paused for the copy with save-off / save-all flush / save-on
# over RCON when it is running; when it is stopped the files are copied as is.
# The staging stack must be stopped. The existing staging world is replaced.
#
# Usage: scripts/staging-clone-world.sh [--production DIR]
#   --production DIR  the production checkout, when this script runs from
#                     another one: a git worktree of a branch under acceptance
#                     (docs/upgrade.md). Default: this checkout.
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$repo_root"
# shellcheck source=scripts/lib.sh
. "$repo_root/scripts/lib.sh"

prod_dir="$repo_root"
case "${1:-}" in
  --production)
    [ -n "${2:-}" ] || fail "--production needs the production checkout's directory"
    prod_dir="$(cd "$2" 2>/dev/null && pwd)" || fail "--production $2: no such directory"
    ;;
  "") ;;
  *) fail "usage: scripts/staging-clone-world.sh [--production DIR]" ;;
esac
[ -f "$prod_dir/compose.yaml" ] || fail "$prod_dir has no compose.yaml; --production must name the production checkout"

# Production's own compose file, project directory and environment files:
# relative env-file paths resolve from the working directory, which is not
# production's when this runs from a worktree.
prod_env_files=""
for f in "$prod_dir/.env" "$prod_dir/dist/cobblemon.env"; do
  if [ -f "$f" ]; then prod_env_files="${prod_env_files:+$prod_env_files,}$f"; fi
done
prod_compose() {
  COMPOSE_FILE="$prod_dir/compose.yaml" COMPOSE_ENV_FILES="$prod_env_files" \
    docker compose --project-directory "$prod_dir" "$@"
}

staging_files="compose.yaml:compose.staging.yaml"
if [ -n "$(COMPOSE_FILE="$staging_files" docker compose ps -q --status running minecraft 2>/dev/null)" ]; then
  fail "the staging server is running; stop it first: COMPOSE_FILE=$staging_files docker compose down"
fi
[ -e "$prod_dir/data/world/level.dat" ] || fail "$prod_dir/data/world/level.dat not found; is there a production world yet?"
log "== production checkout: $prod_dir"

prod_running=""
if [ -n "$(prod_compose ps -q --status running minecraft 2>/dev/null)" ]; then
  prod_running=1
fi
rcon() { prod_compose exec -T minecraft rcon-cli "$@" >/dev/null; }

mkdir -p staging/data
if [ -e staging/data/world ]; then
  log "replacing existing staging world: $(du -sh staging/data/world | cut -f1) in staging/data/world"
fi

if [ -n "$prod_running" ]; then
  log "== pausing production saves (save-off, save-all flush)"
  # The trap is installed before save-off so that any failure or Ctrl-C after
  # this point still turns autosave back on.
  trap 'if rcon save-on; then log "== production saves resumed"; else log "WARNING: save-on failed; in $prod_dir run: docker compose exec minecraft rcon-cli save-on"; fi' EXIT
  rcon save-off
  rcon save-all flush
fi

log "== copying world, config and admin files into staging/data"
# The copy runs in the backup service's container as the host user (user: in compose.yaml),
# the same ids the server chowns /data to, so ownership stays consistent on Linux hosts.
# Written out instead of prod_compose so the single-quoted script below is
# recognised as running in the container.
COMPOSE_FILE="$prod_dir/compose.yaml" COMPOSE_ENV_FILES="$prod_env_files" \
  docker compose --project-directory "$prod_dir" --progress quiet run --rm --no-deps -T --entrypoint sh \
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
