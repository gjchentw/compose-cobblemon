# Tasks

## 1. Tools container

- [x] 1.1 Extend `scripts/config-check.sh` to require that the `packwiz` service in both rendered configurations bind-mounts exactly `pack/` writable and `scripts/` and `dist/` read-only; show it fails on the current `compose.yaml` and names the repository-root mount (verify: L1)
- [x] 1.2 Mount the three directories in `compose.yaml` instead of the repository, and give each run its own working directory under `.build/`: the export's build directory, the copy of the committed pack in the publish comparison, and a copy of a pack inspected from outside `dist/`; update the tools service's comment and the usage comment of `scripts/pack-inspect.sh`. Show that `scripts/config-check.sh` passes; that the `minecraft` and `backup` services render identically before and after for both file sets; that L2 passes; that the publish dry run with a non-placeholder address rebuilds and compares; and, with a probe, that during each run the container sees no `.env`, `data/`, `backups/`, `staging/`, `.git/` or `config/`, can write `pack/` and its run directory (files owned by the host user), and cannot write `scripts/` or `dist/` (verify: L1, L2)

## 2. Linters

- [x] 2.1 Add a self-test case to `scripts/lint.sh`: a scratch tree with a file to check and decoy `.env`, `data/` and `.git/` files, which fails if the linter container sees anything but the staged file; show it fails with the current mounts (verify: L1)
- [ ] 2.2 Stage each linter's files into a fresh directory under `.build/` and mount only that copy, read-only; update the `run_linter` comment in `scripts/lint.sh` and the `persist-credentials` comments in `.github/workflows/ci.yml`, keeping `persist-credentials: false` on every checkout. Show that the self-test passes, including the new case and every known-bad case; and that `scripts/lint.sh` checks the same number of files per linter as before, with no findings (verify: L1)

## 3. Hosted runner

- [ ] 3.1 Push the branch and a `smoke/*` branch; confirm that lint, validate with the extended check, pack with the publish dry run, and the hosted smoke, persistence and restore jobs pass (verify: L1, L2, L3, L4)

## Workflow follow-up

- Merge to `main`; the publish job is expected to skip.
- Archive the change.
