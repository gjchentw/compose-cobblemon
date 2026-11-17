#!/usr/bin/env bash
# Assert the git side of the version contract: the sources hold only the
# placeholder version (a built pack carries the version of its commit), and a
# given pack version is well formed.
#
# Usage: scripts/version-check.sh [VERSION]
#   VERSION is YYYY.MM.DD-<7-character commit>, or the placeholder. When it is
#   given and well formed it is printed on stdout.
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$repo_root"
# shellcheck source=scripts/lib.sh
. "$repo_root/scripts/lib.sh"

pack_v="$(pack_version)"
env_v="$(sed -n 's/^PACK_VERSION=\(.*\)$/\1/p' .env.example)"
[ "$pack_v" = "$PLACEHOLDER_VERSION" ] \
  || fail "pack/pack.toml version is $pack_v; git must hold only $PLACEHOLDER_VERSION (export substitutes the commit's version)"
[ "$env_v" = "$PLACEHOLDER_VERSION" ] \
  || fail ".env.example PACK_VERSION is $env_v; git must hold only $PLACEHOLDER_VERSION"

if [ "$#" -gt 0 ]; then
  is_pack_version "$1" \
    || fail "version $1 is not YYYY.MM.DD-<7-character commit> or $PLACEHOLDER_VERSION"
  printf '%s\n' "$1"
  log "VERSION OK: $1 is a pack version; git holds only the placeholder $PLACEHOLDER_VERSION"
else
  log "VERSION OK: git holds only the placeholder $PLACEHOLDER_VERSION"
fi
