#!/usr/bin/env bash
# Assert the version contract: pack/pack.toml version == PACK_VERSION in
# .env.example, and == the vX.Y.Z tag when HEAD carries one.
#
# Usage: scripts/version-check.sh
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$repo_root"
# shellcheck source=scripts/lib.sh
. "$repo_root/scripts/lib.sh"

version="$(pack_version)"
env_version="$(sed -n 's/^PACK_VERSION=\(.*\)$/\1/p' .env.example)"
tags="$(git tag --points-at HEAD 2>/dev/null | grep -E '^v[0-9]' || true)"

printf 'pack/pack.toml version: %s\n.env.example PACK_VERSION: %s\nv* tags on HEAD: %s\n' \
  "$version" "$env_version" "$(printf '%s' "$tags" | tr '\n' ' ')" >&2

[ "$version" = "$env_version" ] \
  || fail "pack.toml version $version != .env.example PACK_VERSION $env_version"
# In a tag-triggered CI run the tag that fired the workflow is the one that matters.
if [ "${GITHUB_REF_TYPE:-}" = "tag" ] && [ "${GITHUB_REF_NAME:-}" != "v$version" ]; then
  fail "workflow tag ${GITHUB_REF_NAME:-} != v$version"
fi
# Every v* tag on HEAD must agree; a second, different tag on a released commit is an error.
for tag in $tags; do
  [ "$tag" = "v$version" ] || fail "tag $tag on HEAD != v$version"
done
log "VERSION OK: $version"
