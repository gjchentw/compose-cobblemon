# Proposal

## Why

The tool containers see far more of a checkout than their work needs. The packwiz tools service mounts the whole repository writable, and each linter mounts it read-only. Tests on 2026-11-21 showed that both can read `.env` with the RCON password, the world data including `data/.rcon-cli.env`, the backups, the staging copies and `.git`, and the tools container can also write all of them. The baseline (`design.md` of the archived `establish-baseline-specs` change) recorded this as follow-up change 6. No spec requires it today, so a repository built from these specs for another pack would repeat it.

## What Changes

- The tools service mounts three directories that every checkout has: `pack/` writable, `scripts/` and `dist/` read-only. It no longer mounts the repository root.
- Each run that needs a working directory gets exactly that directory, given to `docker compose run` with `-v`: the export's build directory, the copy of the committed pack that publish compares, and a copy of a pack that inspection is asked to read from outside `dist/`.
- `scripts/lint.sh` copies the files each linter checks into a fresh directory under `.build/` and mounts only that copy, read-only, with the two linter configuration files. The files checked and the findings stay the same.
- `scripts/config-check.sh` (L1) asserts the tools service's mounts, and `scripts/lint.sh --self-test` asserts that a linter container cannot see a decoy `.env` or data directory. Both fail before the change.
- Comments that state the whole repository is mounted into the tool containers are corrected (`.github/workflows/ci.yml`, `scripts/lint.sh`, `compose.yaml`); every checkout keeps `persist-credentials: false`.
- Not changed: the `minecraft` and `backup` mounts, images, networks, container capabilities, the service names, and the administrator's packwiz commands in the documents, which keep running in `pack/`.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `mrpack-distribution`: new requirement "Tool containers see only what they need", in the capability that holds "Least-privilege workflow". Archiving adds it at the end of the spec.

## Impact

- `compose.yaml` (the `packwiz` service's volumes; a mapping change the human approves at this gate).
- `scripts/pack-export.sh`, `scripts/pack-inspect.sh`, `scripts/pack-publish.sh`, `scripts/lint.sh`, `scripts/config-check.sh`.
- `.github/workflows/ci.yml`: comments only.
- Administrators and players: nothing changes. Existing deployments need no step at the upgrade. No pack is published by this change, and the pack it builds has the same contents.
