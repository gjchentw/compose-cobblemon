#!/usr/bin/env bash
# Export the pack from pack/ to dist/cobblemon.mrpack, with its version file
# dist/cobblemon.env (only PACK_VERSION=<version>) next to it (L2).
# The committed pack/ is copied to a fresh build directory first, so what is
# generated at export time (the version, servers.dat with the real server
# host) never touches the source of truth.
#
# Usage: scripts/pack-export.sh [YYYY.MM.DD-<commit> | 0.0.0-dev]
#   Without a version the pack is built with the version of the checked-out
#   commit (commit_version in scripts/lib.sh).
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

if [ "$#" -ge 1 ] && [ -z "$1" ]; then
  fail "empty version argument; pass YYYY.MM.DD-<commit> or omit it for the checked-out commit's version"
fi
if [ "$#" -ge 1 ]; then
  version="$1"
else
  version="$(commit_version)"
fi
is_pack_version "$version" \
  || fail "version must be YYYY.MM.DD-<7-character commit> or $PLACEHOLDER_VERSION, got: $version"

mkdir -p .build dist
# A fresh path on every run: Docker Desktop may serve stale contents for a
# path that was deleted and recreated while the daemon still has it cached.
build_dir="$(mktemp -d .build/pack.XXXXXX)"
trap 'rm -rf "$build_dir"' EXIT
mkdir "$build_dir/pack"
cp -R pack/. "$build_dir/pack/"
# The version exists only in this build copy; pack/ keeps the placeholder.
sed -i.bak "s/^version = \".*\"$/version = \"$version\"/" "$build_dir/pack/pack.toml"
rm -f "$build_dir/pack/pack.toml.bak"
grep -q "^version = \"$version\"$" "$build_dir/pack/pack.toml" \
  || fail "could not set version $version in the build copy of pack.toml"

run() {
  docker compose --progress quiet --profile tools run --rm -T -w "/work/$build_dir/pack" packwiz "$@"
}
# The pre-filled entry carries the version, so players can compare it with the
# version in the server's MOTD (public-server-info).
docker compose --progress quiet --profile tools run --rm -T -w "/work/$build_dir/pack" --entrypoint python3 \
  packwiz /work/scripts/make-servers-dat.py --name "$name ($version)" --host "$host" --out servers.dat
run refresh
run modrinth export -o "/work/$build_dir/cobblemon.mrpack"
printf 'PACK_VERSION=%s\n' "$version" > "$build_dir/cobblemon.env"
# Both files are moved into dist/ only after the export succeeded, so a failed
# export leaves the previous pair in dist/ as it was.
mv "$build_dir/cobblemon.mrpack" dist/cobblemon.mrpack
mv "$build_dir/cobblemon.env" dist/cobblemon.env
echo "exported dist/cobblemon.mrpack and dist/cobblemon.env, version $version" >&2
