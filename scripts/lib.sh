#!/usr/bin/env bash
# Shared helpers for scripts/. Source with:
#   # shellcheck source=scripts/lib.sh
#   . "$repo_root/scripts/lib.sh"

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
