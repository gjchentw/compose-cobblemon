#!/usr/bin/env bash
# Shared helpers for scripts/. Source with:
#   # shellcheck source=scripts/lib.sh
#   . "$repo_root/scripts/lib.sh"

log() { printf '%s\n' "$*" >&2; }
fail() { log "FAIL: $*"; exit 1; }

# The only version the sources in git hold; a built pack carries the version
# of the commit it was built from (commit_version).
# shellcheck disable=SC2034  # used by the scripts that source this file
PLACEHOLDER_VERSION="0.0.0-dev"

# is_pack_version VERSION: true for a commit version, YYYY.MM.DD-<7 lowercase
# hex characters>, and for the placeholder (the whole string, not any one line
# of it).
is_pack_version() {
  local re='^[0-9]{4}\.(0[1-9]|1[0-2])\.(0[1-9]|[12][0-9]|3[01])-[0-9a-f]{7}$'
  [ "$1" = "$PLACEHOLDER_VERSION" ] || [[ "$1" =~ $re ]]
}

# commit_version [REV]: the pack version of a commit (default HEAD): its
# committer date in UTC and the first seven characters of its hash, for
# example 2026.11.17-dbb7da6. Use as `v="$(commit_version)"`, like pack_version.
commit_version() {
  local rev="${1:-HEAD}" line
  line="$(TZ=UTC0 git log -1 --format='%cd %H' --date=format-local:'%Y.%m.%d' "$rev" 2>/dev/null)" \
    || fail "cannot read commit $rev; run inside a git checkout"
  [ -n "$line" ] || fail "cannot read commit $rev; run inside a git checkout"
  printf '%s-%s\n' "${line%% *}" "$(printf '%s' "${line#* }" | cut -c1-7)"
}

# is_release_version VERSION: true for X.Y.Z and X.Y.Z-rc.N (the whole string,
# not any one line of it).
is_release_version() {
  local re='^[0-9]+\.[0-9]+\.[0-9]+(-rc\.[0-9]+)?$'
  [[ "$1" =~ $re ]]
}

# check_release_checkout VERSION
# For a release version in a git work tree, the checked-out commit must carry
# the tag vVERSION, so the compose files and pack/ on disk are the ones that
# release was built from. A tag this clone does not know (not fetched) only
# warns. The placeholder version and non-git directories are not checked.
check_release_checkout() {
  local version="$1"
  [ "$version" != "$PLACEHOLDER_VERSION" ] || return 0
  git rev-parse --is-inside-work-tree >/dev/null 2>&1 || return 0
  if ! git rev-parse -q --verify "refs/tags/v$version" >/dev/null; then
    log "WARNING: tag v$version is not known in this clone (git fetch --tags); cannot verify that the checkout matches the release"
    return 0
  fi
  if ! git tag --points-at HEAD | grep -Fxc "v$version" >/dev/null; then
    log "PACK_VERSION=$version but the checked-out commit is not tagged v$version; run: git fetch --tags && git checkout v$version"
    return 1
  fi
}

# pack_version: the version field of pack/pack.toml (the placeholder, by contract).
# Use as `v="$(pack_version)"`: the fail inside the substitution aborts the
# caller through the assignment's exit status under set -e.
pack_version() {
  local v
  v="$(sed -n 's/^version = "\(.*\)"$/\1/p' pack/pack.toml)"
  [ -n "$v" ] || fail "pack/pack.toml has no version field"
  printf '%s\n' "$v"
}

# env_value KEY
# Prints KEY from the environment, else from .env, else from .env.example.
# Not for UID or GID: bash's own read-only UID always wins; use id -u / id -g.
# The value is everything after the first '=', with one pair of surrounding
# quotes removed, which matches how docker compose reads .env files.
env_value() {
  local key="$1" file line
  if [ -n "${!key:-}" ]; then
    printf '%s\n' "${!key}"
    return 0
  fi
  for file in .env .env.example; do
    [ -f "$file" ] || continue
    line="$(grep -E "^${key}=" "$file" | tail -n 1 || true)"
    if [ -n "$line" ]; then
      line="${line#*=}"
      line="${line%\"}"
      line="${line#\"}"
      line="${line%\'}"
      line="${line#\'}"
      printf '%s\n' "$line"
      return 0
    fi
  done
  echo "missing $key in the environment, .env and .env.example" >&2
  return 1
}

# wait_healthy SERVICE TIMEOUT_SECONDS
# Polls the compose service's container health. Prints the elapsed time on
# success; on unhealthy or timeout prints the last log lines and returns 1.
# Docker keeps the previous "healthy" status across a stop/start until the
# next probe runs, so a probe newer than the ones seen on entry is required.
wait_healthy() {
  local service="$1" timeout="$2" cid health elapsed=0 probes0 probes
  cid="$(docker compose ps -q "$service")"
  if [ -z "$cid" ]; then
    echo "no container for service $service" >&2
    return 1
  fi
  probes0="$(docker inspect -f '{{range .State.Health.Log}}{{.Start}};{{end}}' "$cid")"
  while :; do
    health="$(docker inspect -f '{{.State.Health.Status}}' "$cid")"
    probes="$(docker inspect -f '{{range .State.Health.Log}}{{.Start}};{{end}}' "$cid")"
    case "$health" in
      healthy)
        if [ "$probes" != "$probes0" ]; then
          echo "healthy after ~${elapsed}s" >&2
          return 0
        fi
        ;;
      unhealthy)
        docker compose logs --no-color --tail 40 "$service" >&2
        echo "container is unhealthy" >&2
        return 1
        ;;
    esac
    if [ "$elapsed" -ge "$timeout" ]; then
      docker compose logs --no-color --tail 40 "$service" >&2
      echo "not healthy after ${timeout}s (last status: $health)" >&2
      return 1
    fi
    sleep 10
    elapsed=$((elapsed + 10))
  done
}
