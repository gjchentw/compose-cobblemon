#!/usr/bin/env bash
# Export the pack from pack/ to dist/cobblemon-<version>.mrpack (L2).
# The committed pack/ is copied to a fresh build directory first, so files
# generated at export time never touch the source of truth.
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$repo_root"

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
run refresh
run modrinth export -o "/work/$out"
echo "exported $out" >&2
