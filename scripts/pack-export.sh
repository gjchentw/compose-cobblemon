#!/usr/bin/env bash
# Export the pack from pack/ to dist/cobblemon-<version>.mrpack (L2).
# The committed pack/ is copied to a fresh build directory first, so what is
# generated at export time (the release version, servers.dat with the real
# server host) never touches the source of truth.
#
# Usage: scripts/pack-export.sh [X.Y.Z | X.Y.Z-rc.N]
#   Without a version the pack is built as the 0.0.0-dev placeholder. CI passes
#   the version of the release tag (see .github/workflows/ci.yml).
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$repo_root"
# shellcheck source=scripts/lib.sh
. "$repo_root/scripts/lib.sh"

name="$(env_value SERVER_NAME)"
host="$(env_value SERVER_PUBLIC_HOST)"
# A release must never carry the placeholder host: players would get a dead
# pre-filled server entry. Enforced on tag builds (GITHUB_REF_TYPE=tag) and
# whenever PACK_REQUIRE_REAL_HOST is set.
if [ "${GITHUB_REF_TYPE:-}" = "tag" ] || [ -n "${PACK_REQUIRE_REAL_HOST:-}" ]; then
  if [ "$host" = "mc.example.com" ] || [ -z "$host" ]; then
    echo "SERVER_PUBLIC_HOST is still the placeholder; set the SERVER_PUBLIC_HOST repository secret (CI) or .env before releasing" >&2
    exit 1
  fi
fi

version="${1:-$(pack_version)}"
if [ "$version" != "$PLACEHOLDER_VERSION" ] && ! is_release_version "$version"; then
  fail "version must be X.Y.Z or X.Y.Z-rc.N, got: $version"
fi

mkdir -p .build dist
# A fresh path on every run: Docker Desktop may serve stale contents for a
# path that was deleted and recreated while the daemon still has it cached.
build_dir="$(mktemp -d .build/pack.XXXXXX)"
trap 'rm -rf "$build_dir"' EXIT
cp -R pack/. "$build_dir/"
# The release version exists only in this build copy; pack/ keeps the placeholder.
sed -i.bak "s/^version = \".*\"$/version = \"$version\"/" "$build_dir/pack.toml" && rm -f "$build_dir/pack.toml.bak"

out="dist/cobblemon-$version.mrpack"
run() {
  docker compose --progress quiet --profile tools run --rm -T -w "/work/$build_dir" packwiz "$@"
}
docker compose --progress quiet --profile tools run --rm -T -w "/work/$build_dir" --entrypoint python3 \
  packwiz /work/scripts/make-servers-dat.py --name "$name" --host "$host" --out servers.dat
run refresh
run modrinth export -o "/work/$out"
echo "exported $out" >&2
