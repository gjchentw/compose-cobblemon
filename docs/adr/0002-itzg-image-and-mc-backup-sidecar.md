# ADR 0002: itzg images pinned by digest, a backup sidecar, and a packwiz image built from source

Status: accepted, 2026-11-03

## Context

Three ways to run the server were on the table: a custom Dockerfile on a JDK base, the
community `itzg/minecraft-server` image, or a bare JAR managed by scripts. Backups could
run from host cron or from a container. packwiz has no official container image, and the
host should need nothing but Docker and bash.

## Decision

- Server: `itzg/minecraft-server`, pinned by tag and by multi-arch index digest. It
  installs Modrinth packs, honours side markers, converts SIGTERM into an RCON stop
  (`STOP_DURATION`, with `stop_grace_period: 2m` in compose), and ships `mc-health`,
  `mc-monitor` and `rcon-cli`.
- Backups: `itzg/mc-backup` as a compose sidecar that depends on the server being
  healthy, coordinates `save-off`/`save-all flush`/`save-on` over RCON, writes tar
  archives to `./backups` and prunes only the top level, so `backups/keep/` is safe.
- Tooling: `tools/packwiz/Dockerfile` builds packwiz from a pinned commit in a Go stage
  and ships it on `python:3.14-alpine` (python3 is used by `scripts/make-servers-dat.py`).
  Linters run from pinned images too.

## Consequences

- No JVM, mod loader or backup logic to maintain; upgrades are digest bumps through
  `docs/upgrade.md`.
- Pins must be index digests: a per-platform digest does not pull on the other
  architecture (found when the amd64 digest failed on the arm64 dev machine).
- Tool containers run as the host user (`UID`/`GID` from `.env`) so generated files are
  not root-owned on Linux hosts.
- Docker's health status survives a stop/start until the next probe, so
  `scripts/lib.sh` waits for a fresh probe before trusting "healthy".
