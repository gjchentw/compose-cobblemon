#!/usr/bin/env bash
# Publish the pack on main (L2). Rebuild the pack with the version of the
# committed dist/cobblemon.mrpack and compare the archive members byte for
# byte: equal members mean the pack did not change (a documentation-only
# commit, for example) and nothing is published. Otherwise build the pack with
# the version of the checked-out commit, inspect it, and commit
# dist/cobblemon.mrpack and dist/cobblemon.env, and nothing else, as
# github-actions[bot] with the message "pack <version> [skip ci]". Pushing the
# commit is left to the workflow.
#
# Usage: scripts/pack-publish.sh [--dry-run]
#   --dry-run  build, compare and report what would be committed; commit
#              nothing. Runs anywhere; CI runs it on every push.
#   Without --dry-run the script runs only in CI (CI=true) and refuses the
#   placeholder public address (PACK_REQUIRE_REAL_HOST).
# Either way dist/ is left holding the last pack it built.
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$repo_root"
# shellcheck source=scripts/lib.sh
. "$repo_root/scripts/lib.sh"

dry_run=""
case "${1:-}" in
  --dry-run) dry_run=1 ;;
  "") ;;
  *) fail "usage: scripts/pack-publish.sh [--dry-run]" ;;
esac
if [ -z "$dry_run" ]; then
  [ "${CI:-}" = "true" ] || fail "only CI publishes the pack; run scripts/pack-publish.sh --dry-run to see what it would do"
  export PACK_REQUIRE_REAL_HOST=1
fi

pack="dist/cobblemon.mrpack"
version_file="dist/cobblemon.env"

# compare A B: prints the archive members that differ (missing on one side or
# with other bytes) and returns 1 when there are any. Read in the tools image,
# so the host needs no Python.
compare() {
  docker compose --progress quiet --profile tools run --rm -T -w /work --entrypoint python3 \
    packwiz - "$1" "$2" <<'PY'
import sys
import zipfile

a, b = (zipfile.ZipFile(path) for path in sys.argv[1:3])
names_a = {i.filename for i in a.infolist() if not i.is_dir()}
names_b = {i.filename for i in b.infolist() if not i.is_dir()}
differ = sorted(n for n in names_a | names_b
                if n not in names_a or n not in names_b or a.read(n) != b.read(n))
print(", ".join(differ))
sys.exit(1 if differ else 0)
PY
}

if git cat-file -e "HEAD:$pack" 2>/dev/null && git cat-file -e "HEAD:$version_file" 2>/dev/null; then
  old_version="$(git show "HEAD:$version_file" | sed -n 's/^PACK_VERSION=//p')"
  is_pack_version "$old_version" \
    || fail "the committed $version_file does not name a pack version: ${old_version:-nothing}"
  mkdir -p .build
  committed="$(mktemp .build/committed.XXXXXX)"
  trap 'rm -f "$committed"' EXIT
  git show "HEAD:$pack" > "$committed"
  log "== rebuilding the committed pack $old_version from the checked-out sources"
  scripts/pack-export.sh "$old_version"
  if differ="$(compare "$committed" "$pack")"; then
    log "PUBLISH: unchanged; $pack stays at $old_version"
    exit 0
  fi
  log "== the pack differs from the committed $old_version in: $differ"
else
  log "== no pack is committed at HEAD"
fi

new_version="$(commit_version)"
log "== building pack $new_version"
scripts/pack-export.sh "$new_version"
scripts/pack-inspect.sh --expect "$new_version" >&2
if [ -n "$dry_run" ]; then
  log "PUBLISH (dry run): would commit pack $new_version ($pack and $version_file)"
  exit 0
fi
git add -- "$pack" "$version_file"
git -c user.name='github-actions[bot]' \
  -c user.email='41898282+github-actions[bot]@users.noreply.github.com' \
  commit -q -m "pack $new_version [skip ci]" -- "$pack" "$version_file"
log "PUBLISH: committed pack $new_version as $(git rev-parse --short HEAD); push it to main"
