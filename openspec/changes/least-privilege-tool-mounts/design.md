# Design

## Context

See proposal.md for the motivation. Two kinds of tool container run against a checkout:

- The `packwiz` service in `compose.yaml` (profile `tools`) mounts `./` at `/work`, writable, with `/work/pack` as its working directory. `scripts/pack-export.sh`, `scripts/pack-inspect.sh` and `scripts/pack-publish.sh` run it with other working directories under `/work`, and administrators run it to add or update mods (`docs/upgrade.md`).
- `scripts/lint.sh` runs hadolint, yamllint, shellcheck, actionlint and a Python syntax check, each with `docker run -v <tree>:/work:ro` plus the two linter configuration files.

What each run needs, found by reading the scripts on 2026-11-21:

| Run | Reads | Writes |
|---|---|---|
| export: `make-servers-dat.py`, `packwiz refresh`, `packwiz modrinth export` | `scripts/`, its build directory | its build directory under `.build/` |
| inspect | `scripts/`, `pack/`, the pack file (default `dist/<pack>.mrpack`) | nothing |
| publish comparison | `dist/<pack>.mrpack`, a copy of the committed pack under `.build/` | nothing |
| CI refresh check; adding or updating a mod | `pack/` | `pack/` |
| each linter | the files it checks, its configuration | nothing |

The display name and the public address are passed as arguments, so no tool container reads `config/`.

## Goals / Non-Goals

**Goals:**
- No tool container can read the deployment environment file, world data, backups, staging copies or git metadata, and the tools container can write only `pack/` and the directory of its run.
- The same commands keep working: the scripts' interfaces, the administrator's packwiz commands, the CI steps.
- Each restriction is held by a check that failed before the change.

**Non-Goals:**
- Network access of the containers. A probe on 2026-11-21 showed the five linters pass with `--network none`, but this change is about mounts only.
- Capabilities, a read-only root filesystem, or other container hardening.
- The `minecraft` and `backup` services, which mount what they serve.

## Decisions

**1. The tools service mounts three directories (option A, chosen by the human).** `./pack` at `/work/pack` writable, `./scripts` at `/work/scripts` and `./dist` at `/work/dist` read-only. The paths inside the container stay where they were, so the working directory `/work/pack`, `/work/scripts/make-servers-dat.py`, `--pack /work/pack` and the documented `docker compose --profile tools run --rm packwiz modrinth install ...` keep working unchanged. All three are tracked directories that exist in every checkout, so Compose never creates a missing source as root on Linux. Alternatives: also mount `.build/` writable (no script change, but `.build/` is a shared scratch area that has held local client installs and a staging worktree with its own `.env`); keep `pack/` read-only and grant writes per command (longer documented commands, little gain, since every write to `pack/` shows in `git diff`).

**2. A run gets its working directory with `docker compose run -v`.** A volume given to `run` is added to the service's own mounts (tested on Compose 5.7.1, 2026-11-21). The source is always a fresh `mktemp -d` directory under `.build/`, created by the script as the host user and named by its physical path (`pwd -P`), as `scripts/lint.sh` already does for Docker Desktop on macOS.

- Export mounts its build directory at `/build`, writable, works in `/build/pack` and writes `/build/<pack>.mrpack`.
- The publish comparison copies the committed pack into a fresh directory and mounts it read-only.
- Inspection reads `dist/` through the service's mount. A file outside `dist/` is copied into a fresh directory that is mounted read-only. It is copied, not mounted where it lies, because the directory of an arbitrary file can be the repository root, which would bring `.env` back.

**3. Each linter sees a staged copy of its files (option A, chosen by the human).** For every linter, `scripts/lint.sh` copies the files it checks, keeping their relative paths, into a fresh directory under `.build/`, mounts only that directory read-only at `/work`, and removes it on exit. The configuration files stay single-file mounts. A probe on 2026-11-21 ran all five linters this way: the results matched the full mount, and shellcheck still followed `source` to `scripts/lib.sh` (it reported SC2086 on a broken script and no SC1091). `.build/` is already excluded from the files the linters check, so a staged copy is never linted itself. Alternatives: one read-only mount per file (the same allowlist, but as many mounts as files), or the repository mount with empty mounts over the known secrets (a denylist: a new secret file would be visible until someone lists it).

**4. Checks that fail first.**

- `scripts/config-check.sh` reads the bind mounts of the `packwiz` service in both rendered configurations and requires exactly `pack` writable, `scripts` and `dist` read-only. It fails on the repository-root mount today.
- `scripts/lint.sh --self-test` gains a case with decoy `.env`, `data/` and `.git/` files next to a file to check. The case runs the Python image through the harness's own mount path and lists what the container sees. It fails if the container sees anything but the staged file, which it does today.
- The scripts' per-run mounts are each one argument. They are shown by a probe at verification (what the container can read and write during export, inspection and the comparison) and exercised by L2 and the publish dry run. A permanent runtime check would be new tooling, which this change does not add.

**5. The requirement goes to `mrpack-distribution` (option A, chosen by the human).** One requirement covers both kinds of container: they follow the same rule, and the capability already holds the workflow's least-privilege rule and assumes GitHub Actions. A repository built from these specs gets the restriction with the capability.

**6. Comments that describe the old mounts are corrected.** `.github/workflows/ci.yml` gives "the repo is bind-mounted into tool containers" as the reason for `persist-credentials: false`. That stops being true. The new comment gives the reason that remains: no step needs a token stored in `.git/config`, and the publish job gives its write token only to the push step. `persist-credentials: false` stays on every checkout. The header comments of `run_linter` in `scripts/lint.sh` and of the tools service in `compose.yaml` are updated too.

**7. Verification of the stack.** The `minecraft` and `backup` services must render identically before and after the change; this is shown with a diff of `docker compose config` for both file sets. L3 and L4 run on the hosted Linux runner from a `smoke/*` branch, which also runs export on Linux with the new mounts. A local staging run is not added: the served services do not change.

## Risks / Trade-offs

- [A future pack tool needs a file outside `pack/`, `scripts/` or `dist/`] → It fails at once with "no such file". The change that adds the tool adds the mount and amends this requirement.
- [An administrator's own ad hoc use of the tools container with `-w /work` to reach other files stops working] → None of the documents does this (checked); the documented commands work in `pack/`.
- [Docker Desktop serves stale contents for a re-created path] → Every run uses a fresh `mktemp -d` path, as the scripts already do.
- [A killed run leaves a staged copy or a working directory under `.build/`] → `.build/` is gitignored, never mounted by the service, and excluded from linting; the trap removes it on a normal exit.
- [The Purpose of `mrpack-distribution` does not mention linters] → The capability already holds the workflow's least-privilege rule. The Purpose is left as it is, since changing it needs a direct edit the human approves.

## Migration Plan

Merge and archive. Existing deployments need no step: the tools service runs only on demand, and the next run uses the new mounts. Nothing is published. Rollback: revert the merge.
