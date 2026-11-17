# Tasks

Each task checks the requirements of one capability against the repository as it is. Where the repository and a requirement differ, the requirement is corrected to describe the repository; behaviour is not changed in this change.

## 1. compose-services

- [ ] 1.1 Render the production and the staging configurations and confirm the pinning, server-side install, game-settings defaults, public-information, access-control, RCON, secret, health, graceful-stop, log-rotation and ownership requirements against `compose.yaml`, `compose.staging.yaml` and `.env.example`; record any correction in the spec (verify: L1)
- [ ] 1.2 Run `scripts/smoke.sh`, `scripts/persist-test.sh` and `scripts/restore-drill.sh` on the local stack and confirm the smoke, persistence, backup and restore requirements, including the pack-version and checkout checks refusing a mismatch (verify: L3, L4)
- [ ] 1.3 Compare the rendered staging and production configurations, run `scripts/staging-clone-world.sh` with production running, and confirm the staging and clone requirements (verify: L1, L4)
- [ ] 1.4 Confirm the hosted Linux verification requirement from the latest `smoke/*` run and the administrator-documentation and rollback requirements against `docs/admin-guide.md`, `docs/upgrade.md` and `docs/rollback.md` (verify: L1, L3, L4)

## 2. mrpack-distribution

- [ ] 2.1 Run `packwiz refresh`, `scripts/version-check.sh`, `scripts/pack-export.sh` with and without a version, and `scripts/pack-inspect.sh` on a correct pack and on a renamed one, and confirm the tooling, consistency, placeholder, export, pre-filled-entry and inspection requirements (verify: L1, L2)
- [ ] 2.2 Confirm the release, release-candidate, release-notes, pack-check and least-privilege workflow requirements against `.github/workflows/ci.yml` and the runs for `v1.0.0-rc.5` and `v1.0.1` (verify: L1, L2)
- [ ] 2.3 Confirm the template and player-guide requirements against `README.md`, `docs/player-guide.md` and `docs/player-guide.zh-TW.md`, including that both guides have the same sections (verify: L1)

## 3. game-requirements

- [ ] 3.1 Confirm the platform-version and mod-set requirements against `pack/` and the index of an exported pack, and that the side table in the spec equals the one `scripts/pack-inspect.py` enforces (verify: L2)
- [ ] 3.2 Confirm the Java, key-mod and gameplay-default requirements from the rendered configuration and a smoke run (verify: L1, L3)
- [ ] 3.3 Confirm the client-default and key-binding requirements against `pack/options.txt` and the options shipped in the published `v1.0.1` pack (verify: L2)
- [ ] 3.4 Confirm the memory, first-minutes and acceptance-checklist requirements against both player guides and `docs/acceptance-checklist.md` (verify: L1)

## 4. public-server-info

- [ ] 4.1 Confirm the display-name, address, icon, MOTD and value-source requirements by rendering both configurations, reading the MOTD from a smoke run, and exporting with and without `SERVER_NAME` and `SERVER_PUBLIC_HOST` in the environment (verify: L1, L2, L3)

## 5. Retire SPEC.md

- [ ] 5.1 Run `openspec validate establish-baseline-specs --strict` and fix every finding (verify: L1)
- [ ] 5.2 Remove `SPEC.md` and update `AGENTS.md` and `README.md` so nothing outside `tasks/` and this change refers to it, confirmed with a repository-wide search (verify: L1)

## Workflow follow-up

- Present the verified change for the archive gate; after approval, archive it and confirm `openspec list --specs` shows the four capabilities.
- Open the follow-up changes listed in `design.md`, Migration Plan, one at a time.
