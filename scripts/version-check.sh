#!/usr/bin/env bash
# Assert the git side of the version contract: git holds only the placeholder
# version (the release version lives in the tag), and a release tag is well formed.
#
# Usage: scripts/version-check.sh [vX.Y.Z | vX.Y.Z-rc.N]
#   Without an argument the tag is taken from GITHUB_REF_NAME when the workflow
#   runs for a tag. When a tag is known, its version (without the "v") is
#   printed on stdout for the caller to pass to scripts/pack-export.sh.
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$repo_root"
# shellcheck source=scripts/lib.sh
. "$repo_root/scripts/lib.sh"

pack_v="$(pack_version)"
env_v="$(sed -n 's/^PACK_VERSION=\(.*\)$/\1/p' .env.example)"
[ "$pack_v" = "$PLACEHOLDER_VERSION" ] \
  || fail "pack/pack.toml version is $pack_v; git must hold only $PLACEHOLDER_VERSION (the tag carries the release version)"
[ "$env_v" = "$PLACEHOLDER_VERSION" ] \
  || fail ".env.example PACK_VERSION is $env_v; git must hold only $PLACEHOLDER_VERSION"

tag="${1:-}"
if [ -z "$tag" ] && [ "${GITHUB_REF_TYPE:-}" = "tag" ]; then
  tag="${GITHUB_REF_NAME:-}"
fi
if [ -n "$tag" ]; then
  version="${tag#v}"
  if [ "$version" = "$tag" ] || ! is_release_version "$version"; then
    fail "tag $tag is not vX.Y.Z or vX.Y.Z-rc.N"
  fi
  printf '%s\n' "$version"
  log "VERSION OK: tag $tag builds pack $version"
else
  log "VERSION OK: git holds only the placeholder $PLACEHOLDER_VERSION"
fi
