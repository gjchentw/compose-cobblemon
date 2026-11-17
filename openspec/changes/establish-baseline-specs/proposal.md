# Proposal

## Why

The repository has no OpenSpec specs yet: current behaviour is described in `SPEC.md`, which mixes requirements, decisions and plans, and AGENTS.md now makes `openspec/specs/` the source of truth. A baseline that records what the repository does today, cut into capabilities that another project of the same stack could take one at a time without dragging along parts it does not need, is the reference every later change modifies.

## What Changes

- Add four baseline specs that describe the repository's current behaviour, with no behaviour change.
- Record the boundary rules agreed with the human in `design.md`: mechanisms are separate from values; values decided by the game belong to `game-requirements`, operational defaults stay with their mechanism; secrets never appear in specs and the committed configuration is the least-privilege deployment.
- Remove `SPEC.md` once the baseline is archived, and update the files that reference it. **BREAKING** for readers who rely on `SPEC.md`: its content moves to `openspec/specs/` and the decisions to `design.md` and the ADRs.
- List the follow-up changes already decided (rolling pack from `main`, acceptance before merge, a committed public-information file, split player guide, untangling shared files, least-privilege mounts). They are not part of this change.

## Capabilities

### New Capabilities
- `compose-services`: how the Docker Compose stack runs a game server from a pack, keeps it safe and observable, backs it up and restores it, provides a staging copy, and how an administrator operates it.
- `mrpack-distribution`: how the pack source becomes a verified `.mrpack`, how a release is built and published as a downloadable file, and the player-facing install and update guide.
- `game-requirements`: the values the game dictates: the mod set and each mod's side, the Minecraft, loader and Java versions, the server's gameplay settings and heap, the client defaults shipped in the pack, and the gameplay acceptance checklist.
- `public-server-info`: the server information published to players and supplied by the deployer: display name, public address, icon and the MOTD text.

### Modified Capabilities

None; no specs exist yet.

## Impact

- New files under `openspec/changes/establish-baseline-specs/`; after archive, four specs under `openspec/specs/`.
- `SPEC.md` is removed; `AGENTS.md` and `README.md` stop referring to it.
- No change to `compose.yaml`, `pack/`, `scripts/`, `.github/` or the published packs.
