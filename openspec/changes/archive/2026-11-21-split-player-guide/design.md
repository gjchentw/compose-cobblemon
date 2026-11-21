# Design

## Context

See proposal.md for the motivation. `docs/player-guide.md` and its Traditional Chinese copy have these sections: what you need, download, install, memory, play (join), first minutes, keys, updating, troubleshooting. The baseline design already assigned them: install and update to `mrpack-distribution`, memory, first minutes and keys to `game-requirements`. The troubleshooting table mixes both. `README.md`, `docs/upgrade.md` and `docs/acceptance-checklist.md` link to the guide, and the language exception in `AGENTS.md` names `docs/player-guide.zh-TW.md`.

## Goals / Non-Goals

**Goals:**
- Each guide holds only what its capability owns, so a mod change edits one guide and a delivery change edits the other.
- A player can still follow one path from the link to the first minutes in the game.
- Nothing the old guide says is lost, in either language.

**Non-Goals:**
- No rewriting of the instructions themselves beyond what the split needs (introductions, cross-links, step numbers).
- No new tooling to check the guides.
- The `Purpose` line of the `mrpack-distribution` spec, which still mentions GitHub releases, is not touched: a delta cannot change it, and it is unrelated to this change.

## Decisions

**1. Four files, new names, old files removed (option A, chosen by the human).** `docs/pack-install-guide.md` and `docs/play-guide.md`, each with a `.zh-TW.md` copy; `docs/player-guide.md` and `docs/player-guide.zh-TW.md` are deleted. "pack-install" instead of "install" keeps it apart from the administrator's installation of the server. `README.md` stays the entry point for players. Alternatives: keep the old files as pages that only link to the new ones (old links keep working, but two files would point at both capabilities); keep the `player-guide` prefix in the new names.

**2. Where each section goes.**

| Old section | New home |
|---|---|
| Introduction | both, each in its own words, each linking to the other |
| What you need: account, launcher, whitelist | install guide |
| What you need: the PC's memory | play guide, with the memory section |
| 1. Download the pack, 2. Install the pack | install guide |
| 3. Give the game enough memory | play guide |
| 4. Play (join from the pre-filled entry) | install guide, as "Join the server" |
| 5. Your first minutes, Keys worth knowing | play guide |
| Updating the pack | install guide |
| Troubleshooting: whitelist, version mismatch | install guide |
| Troubleshooting: crash while loading, low FPS, Pokémon do not appear | play guide |
| What to include in a problem report | both |

**3. Memory stays a step in the install path, as a link.** The install guide keeps a step between installing and the first start that tells the player to set the game's memory and links to that section of the play guide, without a figure. Alternative: repeat the figures in the install guide. Rejected: a mod change would then edit both guides, which is what the split removes.

**4. Each guide opens and closes with the other.** The install guide ends its path with "next: the play guide"; the play guide starts by sending a player without the pack to the install guide. Other cross-references name sections, not step numbers of the other file.

**5. The Chinese copies mirror their English file section by section.** The English files are the primary versions, as decided on 2026-11-03 for the single guide. The exception in `AGENTS.md` is reworded to name the two copies; it stays one exception, for the player guides only.

**6. Game troubleshooting gets its own requirement.** The install guide's requirement now covers troubleshooting installing and joining only, so the three rows about the game itself are stated in `game-requirements`, with the values the guide already gives.

**7. Verification is by one-off checks at apply, not new tooling.** Section parity between each English file and its copy; every instruction line of the old guide present in one of the new guides, apart from a listed set of lines the split rewrites; no memory figure or key table in the install guide; no reference to the old file names outside `tasks/` and archived changes.

## Risks / Trade-offs

- [Links to the old guide that administrators already sent stop working] → Accepted by the human. `README.md` links both guides; administrators send the new links.
- [A player reads only one guide] → Decision 4: each guide points at the other at the place a player would need it.
- [A Chinese copy drifts from its English file] → The rule in `AGENTS.md` that a task changing one changes its copy; the parity check at apply.
- [The install path now leaves the page once, for memory] → One link to a named section, and the play guide is the next document a new player reads anyway.

## Migration Plan

Merge. Nothing is published and nothing on a deployment changes. Administrators of copies replace the link they give to new players. Rollback: revert the merge.
