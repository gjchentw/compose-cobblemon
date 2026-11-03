#!/usr/bin/env bash
# Export the pack from pack/ to dist/cobblemon-<version>.mrpack (L2).
# The committed pack/ is copied to a fresh build directory first, so files
# generated at export time (servers.dat with the real server host) never
# touch the source of truth.
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
    echo "SERVER_PUBLIC_HOST is still the placeholder; set the repository variable (CI) or .env before releasing" >&2
    exit 1
  fi
fi

version="$(sed -n 's/^version = "\(.*\)"$/\1/p' pack/pack.toml)"
if [ -z "$version" ]; then
  echo "pack/pack.toml has no version field" >&2
  exit 1
fi

mkdir -p .build dist
# A fresh path on every run: Docker Desktop may serve stale contents for a
# path that was deleted and recreated while the daemon still has it cached.
build_dir="$(mktemp -d .build/pack.XXXXXX)"
trap 'rm -rf "$build_dir"' EXIT
cp -R pack/. "$build_dir/"

out="dist/cobblemon-$version.mrpack"
run() {
  docker compose --progress quiet --profile tools run --rm -T -w "/work/$build_dir" packwiz "$@"
}
docker compose --progress quiet --profile tools run --rm -T -w "/work/$build_dir" --entrypoint python3 \
  packwiz /work/scripts/make-servers-dat.py --name "$name" --host "$host" --out servers.dat
run refresh
run modrinth export -o "/work/$out"
echo "exported $out" >&2
