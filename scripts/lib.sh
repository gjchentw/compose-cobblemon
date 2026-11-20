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

# The environment files Compose reads, as the administrator's shell has them:
# COMPOSE_ENV_FILES=.env,dist/cobblemon.env (dist/cobblemon.env holds only
# PACK_VERSION; the later file wins). When the caller has not set it, use the
# same list, keeping only the files that exist: Compose refuses a listed file
# that is missing, and dist/cobblemon.env does not exist before the first
# export or publish. Relative paths resolve from the working directory, the
# repository root for every script.
if [ -z "${COMPOSE_ENV_FILES:-}" ]; then
  _env_files=""
  for _f in .env dist/cobblemon.env; do
    if [ -f "$_f" ]; then _env_files="${_env_files:+$_env_files,}$_f"; fi
  done
  [ -z "$_env_files" ] || export COMPOSE_ENV_FILES="$_env_files"
  unset _env_files _f
fi

# pack_version: the version field of pack/pack.toml (the placeholder, by contract).
# Use as `v="$(pack_version)"`: the fail inside the substitution aborts the
# caller through the assignment's exit status under set -e.
pack_version() {
  local v
  v="$(sed -n 's/^version = "\(.*\)"$/\1/p' pack/pack.toml)"
  [ -n "$v" ] || fail "pack/pack.toml has no version field"
  printf '%s\n' "$v"
}

# The committed public server information (public-server-info spec).
PUBLIC_INFO_FILE="config/public.env"

# public_value KEY: SERVER_NAME or SERVER_PUBLIC_HOST for a pack build. The
# environment wins, for a one-off build (a staging pack with the staging port,
# for example); otherwise the value comes from config/public.env and from
# nowhere else: not .env, not the version file, not .env.example. Prints an
# empty line when the file has the key without a value or does not have it.
public_value() {
  local key="$1" line
  if [ -n "${!key:-}" ]; then
    printf '%s\n' "${!key}"
    return 0
  fi
  [ -f "$PUBLIC_INFO_FILE" ] || { echo "missing $PUBLIC_INFO_FILE" >&2; return 1; }
  line="$(grep -E "^${key}=" "$PUBLIC_INFO_FILE" | tail -n 1 || true)"
  line="${line#*=}"
  line="${line%\"}"
  line="${line#\"}"
  line="${line%\'}"
  line="${line#\'}"
  printf '%s\n' "$line"
}

# env_value KEY
# Prints KEY as Compose resolves it: from the environment, else from the files
# in COMPOSE_ENV_FILES with the later file winning (so PACK_VERSION comes from
# dist/cobblemon.env), else from .env.example.
# Not for UID or GID: bash's own read-only UID always wins; use id -u / id -g.
# The value is everything after the first '=', with one pair of surrounding
# quotes removed, which matches how docker compose reads .env files.
env_value() {
  local key="$1" file line i files=() order=()
  if [ -n "${!key:-}" ]; then
    printf '%s\n' "${!key}"
    return 0
  fi
  IFS=, read -r -a files <<< "${COMPOSE_ENV_FILES:-.env}"
  i=${#files[@]}
  while [ "$i" -gt 0 ]; do
    i=$((i - 1))
    order+=("${files[$i]}")
  done
  for file in ${order[@]+"${order[@]}"} .env.example; do
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
  echo "missing $key in the environment, ${COMPOSE_ENV_FILES:-.env} and .env.example" >&2
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
