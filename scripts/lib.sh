#!/usr/bin/env bash
# Shared helpers for scripts/. Source with:
#   # shellcheck source=scripts/lib.sh
#   . "$repo_root/scripts/lib.sh"

log() { printf '%s\n' "$*" >&2; }
fail() { log "FAIL: $*"; exit 1; }

# pack_version: the version field of pack/pack.toml (the release version).
pack_version() {
  local v
  v="$(sed -n 's/^version = "\(.*\)"$/\1/p' pack/pack.toml)"
  [ -n "$v" ] || fail "pack/pack.toml has no version field"
  printf '%s\n' "$v"
}

# env_value KEY
# Prints KEY from the environment, else from .env, else from .env.example.
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
