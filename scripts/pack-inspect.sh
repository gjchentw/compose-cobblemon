#!/usr/bin/env bash
# Assert an exported mrpack matches the expected pack contents (L2).
# Runs scripts/pack-inspect.py inside the tools image; the host needs only Docker.
# Usage: scripts/pack-inspect.sh [--expect VERSION] [FILE]
#   FILE defaults to dist/cobblemon.mrpack, a path relative to the repository.
#   The tools container sees dist/; a file elsewhere is copied into a fresh
#   directory under .build/ that only this run mounts. The pack's version must
#   have the pack version format; with --expect it must also equal VERSION.
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$repo_root"

# shellcheck source=scripts/lib.sh
. "$repo_root/scripts/lib.sh"

expect=()
if [ "${1:-}" = "--expect" ]; then
  [ -n "${2:-}" ] || fail "--expect needs a version"
  is_pack_version "$2" || fail "--expect $2 is not YYYY.MM.DD-<7-character commit> or $PLACEHOLDER_VERSION"
  expect=(--expect "$2")
  shift 2
fi
file="${1:-dist/cobblemon.mrpack}"
[ -f "$file" ] || fail "missing $file; run scripts/pack-export.sh first"
# The same source export uses: the environment, then config/public.env.
name="$(public_value SERVER_NAME)"
host="$(public_value SERVER_PUBLIC_HOST)"
name="${name:-Cobblemon Server}"

# The file is copied rather than its directory mounted: that directory could be
# the repository root, which would show the container .env.
extra=()
if [ "$(cd "$(dirname "$file")" && pwd -P)" = "$(pwd -P)/dist" ]; then
  in_container="/work/dist/$(basename "$file")"
else
  mkdir -p .build
  copy_dir="$(mktemp -d .build/inspect.XXXXXX)"
  trap 'rm -rf "$copy_dir"' EXIT
  cp "$file" "$copy_dir/"
  extra=(-v "$(cd "$copy_dir" && pwd -P):/inspect:ro")
  in_container="/inspect/$(basename "$file")"
fi

docker compose --progress quiet --profile tools run --rm -T ${extra[@]+"${extra[@]}"} -w /work --entrypoint python3 \
  packwiz scripts/pack-inspect.py "$in_container" ${expect[@]+"${expect[@]}"} --name "$name" --host "$host" --pack /work/pack
