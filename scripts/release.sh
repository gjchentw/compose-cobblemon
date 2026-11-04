#!/usr/bin/env bash
# Cut a release: set the pack version everywhere the contract names it,
# export and inspect the pack, record the release, commit and tag.
# Nothing is pushed; the last line prints the push command.
#
# Usage: scripts/release.sh X.Y.Z[-rc.N] [--dry-run]
#   --dry-run  print every step without changing anything
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$repo_root"
# shellcheck source=scripts/lib.sh
. "$repo_root/scripts/lib.sh"

version="${1:-}"
dry_run=""
[ "${2:-}" = "--dry-run" ] && dry_run=1

step() {
  log "== $*"
  if [ -z "$dry_run" ]; then
    "$@"
  fi
}

if ! printf '%s' "$version" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+(-rc\.[0-9]+)?$'; then
  fail "usage: scripts/release.sh X.Y.Z[-rc.N] [--dry-run]"
fi
if [ -n "$(git status --porcelain)" ]; then
  fail "working tree is not clean; commit or stash first"
fi
if git rev-parse -q --verify "refs/tags/v$version" >/dev/null; then
  fail "tag v$version already exists"
fi

# release metadata for docs/releases.md
minecraft="$(sed -n 's/^minecraft = "\(.*\)"$/\1/p' pack/pack.toml)"
fabric="$(sed -n 's/^fabric = "\(.*\)"$/\1/p' pack/pack.toml)"
cobblemon="$(sed -n 's/^filename = "Cobblemon-fabric-\(.*\)+.*"$/\1/p' pack/mods/cobblemon.pw.toml)"
image="$(sed -n 's/^ *image: docker.io\/itzg\/minecraft-server:\([^@]*\)@.*$/\1/p' compose.yaml)"
row="| $(date -u +%Y-%m-%d) | $version | $minecraft | $fabric | $cobblemon | $image | |"

set_versions() {
  sed -i.bak "s/^version = \".*\"$/version = \"$version\"/" pack/pack.toml && rm -f pack/pack.toml.bak
  sed -i.bak "s/^PACK_VERSION=.*$/PACK_VERSION=$version/" .env.example && rm -f .env.example.bak
}
refresh_pack() {
  docker compose --progress quiet --profile tools run --rm -T packwiz refresh >/dev/null
}
record_release() {
  printf '%s\n' "$row" >> docs/releases.md
}
commit_and_tag() {
  git add pack/pack.toml pack/index.toml .env.example docs/releases.md
  git commit -q -m "Release $version"
  git tag -a "v$version" -m "Release $version"
}

log "release $version: minecraft $minecraft, fabric $fabric, cobblemon $cobblemon, image $image"
step set_versions
step refresh_pack
step scripts/pack-export.sh
step scripts/pack-inspect.sh
step record_release
step scripts/version-check.sh
step commit_and_tag
log "RELEASE ${dry_run:+DRY RUN }OK: v$version"
log "next: git push origin \"\$(git branch --show-current)\" v$version"
