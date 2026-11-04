#!/usr/bin/env bash
# Write .env for a CI job from .env.example: the runner's uid/gid, a random
# RCON password, and any overrides given as KEY=VALUE arguments.
#
# Usage: scripts/ci-env.sh [KEY=VALUE ...]
#   scripts/ci-env.sh MEMORY=4G PAUSE_IF_NO_PLAYERS=false
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$repo_root"
# shellcheck source=scripts/lib.sh
. "$repo_root/scripts/lib.sh"

# Never clobber a real .env: GitHub Actions always sets CI=true.
if [ -z "${CI:-}" ] && [ -e .env ]; then
  fail "refusing to overwrite an existing .env outside CI"
fi

cp .env.example .env
set_var() {
  grep -q "^$1=" .env || fail "unknown .env key: $1"
  case "$2" in
    *[!A-Za-z0-9._:/-]*) fail "value for $1 contains characters outside [A-Za-z0-9._:/-]" ;;
  esac
  sed -i.bak "s|^$1=.*|$1=$2|" .env && rm -f .env.bak
}
set_var UID "$(id -u)"
set_var GID "$(id -g)"
set_var RCON_PASSWORD "$(openssl rand -hex 24)"
for kv in "$@"; do
  set_var "${kv%%=*}" "${kv#*=}"
done
grep -E '^(UID|GID|MEMORY|PAUSE_IF_NO_PLAYERS)=' .env >&2
