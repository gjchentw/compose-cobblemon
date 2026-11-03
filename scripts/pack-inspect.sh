#!/usr/bin/env bash
# Assert an exported mrpack matches the expected pack contents (L2).
# Runs scripts/pack-inspect.py inside the tools image; the host needs only Docker.
# Usage: scripts/pack-inspect.sh [file.mrpack]   (default: dist/cobblemon-<version>.mrpack)
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$repo_root"

version="$(sed -n 's/^version = "\(.*\)"$/\1/p' pack/pack.toml)"
file="${1:-dist/cobblemon-$version.mrpack}"
if [ ! -f "$file" ]; then
  echo "missing $file; run scripts/pack-export.sh first" >&2
  exit 1
fi

docker compose --progress quiet --profile tools run --rm -T -w /work --entrypoint python3 \
  packwiz scripts/pack-inspect.py "$file" "$version"
