# Proposal

## Why

This repository is a template for Cobblemon only. Another mod pack gets a template repository of its own, built by an agent from these specs, so the unit of reuse is the spec, not the files (the human, 2026-11-21). For that to work, `compose-services`, `mrpack-distribution` and `public-server-info` must be usable as they are, and `game-requirements` must be the one spec to rewrite. A review of all 63 requirements found the values already in the right place, but the three mechanism specs still carry a game name in 24 lines, fix one pack-specific list, and leave three game-named values declared nowhere.

## What Changes

- `game-requirements` declares the pack's identity: its name, the base name of its published file and the default display name. The three mechanism specs write the file as `dist/<pack>.mrpack` and `dist/<pack>.env` and refer to the default display name instead of spelling either out; their examples use a neutral display name.
- `game-requirements` declares which client settings files the pack carries, next to the values it already declares for them. `mrpack-distribution` keeps the rule that a pack holds nothing else.
- The acceptance run is split: who runs it, when, with which launchers, and the four items that do not depend on the game move to `compose-services`; `game-requirements` keeps the seven gameplay items.
- `game-requirements` no longer names the launchers; it refers to the ones the install guide covers.
- Each Purpose states what the capability assumes about the platform and where its values come from; the Purpose of `game-requirements` says it is the only capability to rewrite for another pack. The Purpose of `mrpack-distribution` no longer mentions GitHub releases. A delta cannot change a Purpose, so the four are edited in the main specs directly (approved by the human).
- Wording that only makes sense with this repository's history is made timeless: one requirement name, one scenario name and one scenario condition.
- No behaviour changes. No script, Compose file, workflow, document or pack content changes: the files may name the game.
- The two changes planned before, `game-values-out-of-mechanisms` and `split-shared-scripts`, are dropped: they untangled files, which the reuse of specs does not need.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `game-requirements`: adds the pack's identity and the client settings files it carries; the acceptance requirement keeps only the gameplay items; the memory guidance stops naming launchers.
- `mrpack-distribution`: pack file names are written with the declared base name; the set of client settings files comes from `game-requirements`; one requirement is renamed.
- `compose-services`: pack file names are written with the declared base name; a requirement for the player acceptance run is added.
- `public-server-info`: the default display name comes from `game-requirements`; examples use a neutral name; one scenario is renamed.

## Impact

- `openspec/specs/` only: four delta specs and four Purpose paragraphs.
- Nothing is built, published or deployed differently.
- A repository for another pack copies three specs unchanged, when the pack meets the assumptions their Purposes state, and rewrites `game-requirements`.
