#!/usr/bin/env bash
# Assert the version contract: pack/pack.toml version == PACK_VERSION in
# .env.example, and == the vX.Y.Z tag when HEAD carries one.
#
# Usage: scripts/version-check.sh
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$repo_root"

pack_version="$(sed -n 's/^version = "\(.*\)"$/\1/p' pack/pack.toml)"
env_version="$(sed -n 's/^PACK_VERSION=\(.*\)$/\1/p' .env.example)"
tag="$(git tag --points-at HEAD 2>/dev/null | grep -E '^v[0-9]' | head -n 1 || true)"

printf 'pack/pack.toml version: %s\n.env.example PACK_VERSION: %s\ntag on HEAD: %s\n' \
  "$pack_version" "$env_version" "${tag:-(none)}" >&2

[ -n "$pack_version" ] || { echo "FAIL: pack/pack.toml has no version" >&2; exit 1; }
if [ "$pack_version" != "$env_version" ]; then
  echo "FAIL: pack.toml version $pack_version != .env.example PACK_VERSION $env_version" >&2
  exit 1
fi
if [ -n "$tag" ] && [ "$tag" != "v$pack_version" ]; then
  echo "FAIL: tag $tag on HEAD != v$pack_version" >&2
  exit 1
fi
echo "VERSION OK: $pack_version" >&2
