# Proposal

## Why

One player guide carries the documentation of two capabilities: installing, joining and updating the pack belongs to `mrpack-distribution`, while memory, first steps and keys belong to `game-requirements` (the `design.md` of the archived `establish-baseline-specs` change, decision 7). A mod change and a change to how the pack is delivered both edit the same file, and neither capability can be moved without the other's text.

## What Changes

- **BREAKING** `docs/player-guide.md` and `docs/player-guide.zh-TW.md` are removed. Links to them that were already sent to players stop working.
- New `docs/pack-install-guide.md` and its Traditional Chinese copy `docs/pack-install-guide.zh-TW.md` (`mrpack-distribution`): what players need, downloading the pack from the fixed link, installing it, joining from the pre-filled entry, updating, and troubleshooting installing and joining.
- New `docs/play-guide.md` and its Traditional Chinese copy `docs/play-guide.zh-TW.md` (`game-requirements`): what the PC needs and the game's memory, the first minutes in the game, the key table, and troubleshooting the game itself.
- Each guide states only what its capability owns and links to the other for the rest: the install guide has no memory figure and no key table; the play guide does not explain downloading or updating.
- No text is lost: every instruction of the old guide is in one of the two new ones, in both languages.
- `README.md`, `docs/upgrade.md` and `docs/acceptance-checklist.md` link to the new guides. The language exception in `AGENTS.md`, which names the one Chinese file, names the two Chinese copies instead.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `mrpack-distribution`: the player guide requirement becomes a pack install and update guide that leaves game values to the play guide.
- `game-requirements`: memory, first-minutes and key guidance are given in a play guide of their own; the troubleshooting of the game itself, until now covered by the install guide's requirement, gets a requirement here.

## Impact

- `docs/pack-install-guide.md`, `docs/pack-install-guide.zh-TW.md`, `docs/play-guide.md`, `docs/play-guide.zh-TW.md` (new); `docs/player-guide.md`, `docs/player-guide.zh-TW.md` (removed).
- `README.md`, `docs/upgrade.md`, `docs/acceptance-checklist.md`, `AGENTS.md`.
- No script, Compose file, workflow or pack content changes; nothing is published by this change.
- Players and administrators: two links instead of one. Administrators of copies that sent the old link send the new ones.
