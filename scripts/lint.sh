#!/usr/bin/env bash
# L1 static checks: hadolint, yamllint, shellcheck and actionlint, each run
# from a pinned container image. The host needs only Docker and bash (3.2+).
#
# Usage:
#   scripts/lint.sh              lint the whole repository
#   scripts/lint.sh --self-test  prove the harness passes clean files and
#                                fails known-bad ones, then exit
#
# Exit status is non-zero if any linter reports a finding.
set -euo pipefail

HADOLINT_IMAGE="ghcr.io/hadolint/hadolint:v2.15.1@sha256:32dac94127fd60b7b7e3fbfc65e1383b9b5e25c9bfd7b8536de7a539fe68a12d"
YAMLLINT_IMAGE="docker.io/pipelinecomponents/yamllint:0.35.27@sha256:f7f7b4f8824839e33690a880dbe20944128b0dc9c55522a0b92a29b3a905cecf"
SHELLCHECK_IMAGE="docker.io/koalaman/shellcheck:v0.11.0@sha256:61862eba1fcf09a484ebcc6feea46f1782532571a34ed51fedf90dd25f925a8d"
ACTIONLINT_IMAGE="docker.io/rhysd/actionlint:1.7.12@sha256:b1934ee5f1c509618f2508e6eb47ee0d3520686341fec936f3b79331f9315667"
PYTHON_IMAGE="docker.io/library/python:3.14-alpine@sha256:eb2c62658b8d51bff0acc408504b76521d02030de56a8a3c1e830083e89b89d2"

repo_root="$(cd "$(dirname "$0")/.." && pwd)"

log() { printf '%s\n' "$*" >&2; }

# Collect files under $1 matching the find expression in the remaining args,
# skipping runtime and build directories. Results go to the global array
# `found` (bash 3.2 has no mapfile and no nameref).
found=()
collect() {
  local root="$1"
  shift
  found=()
  while IFS= read -r -d '' f; do
    found+=("$f")
  done < <(
    cd "$root" && find . \
      \( -path ./.git -o -path ./data -o -path ./backups -o -path ./staging \
         -o -path ./dist -o -path ./.build \) -prune \
      -o -type f \( "$@" \) -print0
  )
}

# run_linter <tree> <image> <command...>
# Mounts <tree> read-only at /work and the repo's linter configs at /config.
run_linter() {
  local tree image
  tree="$(cd "$1" && pwd -P)"   # physical path: Docker cannot mount through macOS symlinks like /var
  image="$2"
  shift 2
  docker run --rm \
    -v "$tree:/work:ro" \
    -v "$repo_root/.hadolint.yaml:/config/hadolint.yaml:ro" \
    -v "$repo_root/.yamllint.yaml:/config/yamllint.yaml:ro" \
    -w /work \
    "$image" "$@"
}

# lint_tree <dir>: run every linter that has files to check under <dir>.
# Returns non-zero if any linter failed.
lint_tree() {
  local tree="$1" status=0

  collect "$tree" -name Dockerfile -o -name 'Dockerfile.*' -o -name '*.Dockerfile'
  if [ "${#found[@]}" -gt 0 ]; then
    log "== hadolint (${#found[@]} files)"
    run_linter "$tree" "$HADOLINT_IMAGE" hadolint --config /config/hadolint.yaml "${found[@]}" || status=1
  fi

  collect "$tree" -name '*.yml' -o -name '*.yaml'
  if [ "${#found[@]}" -gt 0 ]; then
    log "== yamllint (${#found[@]} files)"
    run_linter "$tree" "$YAMLLINT_IMAGE" yamllint --strict -c /config/yamllint.yaml "${found[@]}" || status=1
  fi

  collect "$tree" -name '*.sh'
  if [ "${#found[@]}" -gt 0 ]; then
    log "== shellcheck (${#found[@]} files)"
    run_linter "$tree" "$SHELLCHECK_IMAGE" --shell=bash --external-sources "${found[@]}" || status=1
  fi

  collect "$tree" -path './.github/workflows/*.yml' -o -path './.github/workflows/*.yaml'
  if [ "${#found[@]}" -gt 0 ]; then
    log "== actionlint (${#found[@]} files)"
    run_linter "$tree" "$ACTIONLINT_IMAGE" "${found[@]}" || status=1
  fi

  collect "$tree" -name '*.py'
  if [ "${#found[@]}" -gt 0 ]; then
    log "== python syntax (${#found[@]} files)"
    # ast.parse checks syntax without writing __pycache__ into the read-only mount.
    run_linter "$tree" "$PYTHON_IMAGE" python3 -c \
      'import ast, sys; [ast.parse(open(f).read(), f) for f in sys.argv[1:]]' "${found[@]}" || status=1
  fi

  return "$status"
}

# self_test: the harness must pass a clean tree, and for each linter it must
# report the expected rule on a file with exactly one known violation.
# The scratch tree lives under the repo's .build/ (gitignored) because Docker
# can only bind-mount paths the daemon's VM shares; system temp dirs may not be.
selftest_tmp=""
self_test() {
  local tmp good bad status=0 out
  mkdir -p "$repo_root/.build"
  selftest_tmp="$(mktemp -d "$repo_root/.build/lint-selftest.XXXXXX")"
  tmp="$selftest_tmp"
  trap 'rm -rf "$selftest_tmp"' EXIT
  good="$tmp/good"
  bad="$tmp/bad"
  mkdir -p "$good" "$bad"

  cat > "$good/Dockerfile" <<'GOOD'
FROM alpine:3.20
CMD ["sh"]
GOOD
  cat > "$good/ok.yaml" <<'GOOD'
key: value
GOOD
  cat > "$good/ok.sh" <<'GOOD'
#!/usr/bin/env bash
set -euo pipefail
echo "ok"
GOOD
  printf 'print("ok")\n' > "$good/ok.py"
  printf 'def (:\n' > "$bad/bad.py"
  mkdir -p "$good/.github/workflows" "$bad/.github/workflows"
  cat > "$good/.github/workflows/ok.yml" <<'GOOD'
on: push
jobs:
  ok:
    runs-on: ubuntu-latest
    steps:
      - run: echo ok
GOOD

  cat > "$bad/Dockerfile" <<'BAD'
FROM alpine
CMD ["sh"]
BAD
  cat > "$bad/dup.yaml" <<'BAD'
key: value
key: again
BAD
  cat > "$bad/unquoted.sh" <<'BAD'
#!/usr/bin/env bash
cat $1
BAD
  cat > "$bad/.github/workflows/bad.yml" <<'BAD'
on: push
jobs:
  bad:
    steps:
      - run: echo bad
BAD

  log "-- self-test: clean tree must pass"
  if lint_tree "$good"; then
    log "PASS clean tree"
  else
    log "FAIL clean tree reported findings"
    status=1
  fi

  log "-- self-test: each linter must report the expected rule"
  local n=0
  for pair in "Dockerfile:DL3006" "dup.yaml:key-duplicates" "unquoted.sh:SC2086" ".github/workflows/bad.yml:runs-on" "bad.py:SyntaxError"; do
    local file="${pair%%:*}" rule="${pair#*:}" case_dir
    # One directory per case: Docker Desktop may serve stale contents for a
    # path that was deleted and recreated while the daemon still has it cached.
    n=$((n + 1))
    case_dir="$tmp/case-$n"
    mkdir -p "$case_dir/$(dirname "$file")"
    cp "$bad/$file" "$case_dir/$file"
    if out="$(lint_tree "$case_dir" 2>&1)"; then
      log "FAIL $file was not flagged"
      status=1
    elif grep -q "$rule" <<< "$out"; then
      log "PASS $file flagged with $rule"
    else
      log "FAIL $file failed for another reason than $rule:"
      log "$out"
      status=1
    fi
  done

  return "$status"
}

case "${1:-}" in
  --self-test)
    self_test
    ;;
  "")
    lint_tree "$repo_root"
    ;;
  *)
    log "usage: scripts/lint.sh [--self-test]"
    exit 2
    ;;
esac
