#!/usr/bin/env bash
# Assert an exported mrpack matches the expected pack contents (L2).
# Runs scripts/pack-inspect.py inside the tools image; the host needs only Docker.
# Usage: scripts/pack-inspect.sh [dist/cobblemon-<version>.mrpack]
#   The expected version is taken from the file name (the name is part of the
#   version contract). Default: the placeholder build, dist/cobblemon-0.0.0-dev.mrpack.
#   The path must be inside the repository (it is read in the tools container).
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$repo_root"

# shellcheck source=scripts/lib.sh
. "$repo_root/scripts/lib.sh"

file="${1:-dist/cobblemon-$(pack_version).mrpack}"
[ -f "$file" ] || fail "missing $file; run scripts/pack-export.sh first"
version="$(basename "$file")"
case "$version" in
  cobblemon-*.mrpack) version="${version#cobblemon-}"; version="${version%.mrpack}" ;;
  *) fail "file name must be cobblemon-<version>.mrpack: $file" ;;
esac
name="$(env_value SERVER_NAME)"
host="$(env_value SERVER_PUBLIC_HOST)"

docker compose --progress quiet --profile tools run --rm -T -w /work --entrypoint python3 \
  packwiz scripts/pack-inspect.py "$file" "$version" --name "$name" --host "$host" --pack /work/pack
