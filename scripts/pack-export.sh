#!/usr/bin/env bash
# Export the pack from pack/ to dist/cobblemon.mrpack, with its version file
# dist/cobblemon.env (PACK_VERSION=<version> and the display name the pack was
# built with, SERVER_NAME) next to it (L2).
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

# The display name and the public address come from config/public.env (or, for
# a one-off build, from the environment): see public_value in scripts/lib.sh.
name="$(public_value SERVER_NAME)"
host="$(public_value SERVER_PUBLIC_HOST)"
name="${name:-Cobblemon Server}"
# The name is written single-quoted into the version file, so Compose reads it
# literally; a single quote or a line break cannot be written that way.
case "$name" in
  *"'"* | *$'\n'* | *$'\r'*) fail "the display name (SERVER_NAME) must not contain a single quote or a line break: $name" ;;
esac
[ -n "$host" ] || fail "SERVER_PUBLIC_HOST is empty; set it in $PUBLIC_INFO_FILE (the template's placeholder is mc.example.com)"
# A published pack must never carry the placeholder host: players would get a
# dead pre-filled server entry. Enforced whenever PACK_REQUIRE_REAL_HOST is
# set, which scripts/pack-publish.sh does when it publishes.
if [ -n "${PACK_REQUIRE_REAL_HOST:-}" ]; then
  if [ "$host" = "mc.example.com" ]; then
    echo "SERVER_PUBLIC_HOST is still the placeholder; set it in $PUBLIC_INFO_FILE before publishing" >&2
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
# Compose interpolates all of compose.yaml before it runs the tools container,
# including the server's required PACK_VERSION. Supply the version being built
# (the environment wins over env files), so export also works in a checkout
# that has no dist/cobblemon.env yet.
export PACK_VERSION="$version"
# A caller's COMPOSE_ENV_FILES (the administrator's profile) may list
# dist/cobblemon.env before export has written it, and Compose refuses a listed
# file that is missing: keep only the files that exist.
if [ -n "${COMPOSE_ENV_FILES:-}" ]; then
  kept=""
  IFS=, read -r -a listed <<< "$COMPOSE_ENV_FILES"
  for f in "${listed[@]}"; do
    if [ -f "$f" ]; then kept="${kept:+$kept,}$f"; fi
  done
  if [ -n "$kept" ]; then export COMPOSE_ENV_FILES="$kept"; else unset COMPOSE_ENV_FILES; fi
fi

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
printf "PACK_VERSION=%s\nSERVER_NAME='%s'\n" "$version" "$name" > "$build_dir/cobblemon.env"
# Both files are moved into dist/ only after the export succeeded, so a failed
# export leaves the previous pair in dist/ as it was.
mv "$build_dir/cobblemon.mrpack" dist/cobblemon.mrpack
mv "$build_dir/cobblemon.env" dist/cobblemon.env
echo "exported dist/cobblemon.mrpack and dist/cobblemon.env, version $version, display name $name" >&2
