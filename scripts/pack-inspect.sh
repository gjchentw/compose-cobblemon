#!/usr/bin/env bash
# Assert an exported mrpack matches the expected pack contents (L2).
# Runs scripts/pack-inspect.py inside the tools image; the host needs only Docker.
# Usage: scripts/pack-inspect.sh [file.mrpack]   (default: dist/cobblemon-<version>.mrpack)
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$repo_root"

# shellcheck source=scripts/lib.sh
. "$repo_root/scripts/lib.sh"

version="$(pack_version)"
file="${1:-dist/cobblemon-$version.mrpack}"
[ -f "$file" ] || fail "missing $file; run scripts/pack-export.sh first"
name="$(env_value SERVER_NAME)"
host="$(env_value SERVER_PUBLIC_HOST)"

docker compose --progress quiet --profile tools run --rm -T -w /work --entrypoint python3 \
  packwiz scripts/pack-inspect.py "$file" "$version" --name "$name" --host "$host" --pack /work/pack
