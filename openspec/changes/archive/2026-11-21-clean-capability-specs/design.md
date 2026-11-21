# Design

## Context

See proposal.md for the motivation. The baseline (`design.md` of the archived `establish-baseline-specs` change) cut the repository into four capabilities so that "another project on the same stack could take one at a time", and left "untangling the files" as follow-up work. On 2026-11-21 the human stated how that reuse will happen: this repository stays a template for Cobblemon; another pack (MMC3 is planned) gets a template repository of its own, which an agent builds from these specs. Files in this repository may therefore name the game. What must be clean is the cut between the specs.

A review of all 63 requirements, and a keyword scan, found:

| Finding | Where |
|---|---|
| Versions, mod names, the Java version and memory figures appear only in `game-requirements` | the baseline cut holds |
| The published file is spelled `dist/cobblemon.mrpack` and `dist/cobblemon.env` | `compose-services` 8 lines, `mrpack-distribution` 9, `public-server-info` 1 |
| The default display name `Cobblemon Server` and the example `My Cobblemon World` | `public-server-info` 6 lines, `mrpack-distribution` 1 |
| "Exactly the two client overrides `options.txt` and `servers.dat`" fixes a list that depends on the pack | `mrpack-distribution`, "Pack contents are exact" |
| The acceptance requirement holds the run's rules, four items that do not depend on the game, and seven gameplay items | `game-requirements` |
| The launchers are named in the game's memory guidance and acceptance requirement | `game-requirements` |
| The pack's name, the base name of its file and the default display name are declared nowhere | only in files |
| The Purpose of `mrpack-distribution` mentions GitHub releases; one requirement name says "release"; one scenario is named "from before this change" | wording |
| No spec lists what it assumes about the platform | all three mechanism specs |

The scan finds 24 lines with a game value in the three mechanism specs today.

## Goals / Non-Goals

**Goals:**
- `compose-services`, `mrpack-distribution` and `public-server-info` contain no value that changes with the mod pack, so a repository for another pack can copy them unchanged.
- `game-requirements` declares every value the other three refer to, and is the only spec to rewrite.
- Each spec says what it assumes, so an agent can tell whether a pack fits before copying it.

**Non-Goals:**
- Changing behaviour, scripts, Compose files, the workflow, documents or the pack. Files keep naming the game.
- Making file names configurable. `<pack>` in a spec is a way to write the name, not a setting.
- Supporting other loaders, mod hosts or pack tools. The assumptions are stated, not removed.
- Judging whether MMC3 meets the assumptions: its loader and mod sources are not known here.

## Decisions

**1. The rule, and its test.** Mechanisms belong to `compose-services`, `mrpack-distribution` and `public-server-info`; values belong to `game-requirements` (baseline decisions 2 and 3). The test applied to every sentence: "does it change when the mod pack is replaced and the infrastructure stays?" If it does, it belongs to `game-requirements`.

**2. Game-named things are declared once and referred to (option A, chosen by the human).** A new requirement "Pack identity" in `game-requirements` declares the pack's name (`Cobblemon Pack`), the base name of its published file (`cobblemon`) and the default display name (`Cobblemon Server`). The mechanism specs write `dist/<pack>.mrpack` and `dist/<pack>.env`, each capability saying once that `<pack>` is that base name, and they refer to "the default display name that `game-requirements` declares". Their examples use `My Server`. Alternatives: rename the files to neutral names (cleanest specs, but it changes files and the players' link, against "files may name the game"); leave the specs and list the places in a separate note (the specs would still not be reusable as they are).

**3. What the pack gives the client is the game's to define (stated by the human).** `game-requirements` already declares every line of `options.txt`. It now also declares that `options.txt` is the pack's only client settings file. `mrpack-distribution` keeps the mechanism: a pack holds the index, the server entry that export generates, and the settings files `game-requirements` declares, nothing else. A pack with many mod configurations lists them in its own `game-requirements`.

**4. The acceptance run is split (option A, chosen by the human).** `compose-services` gains "Player acceptance": at least two players, on staging with the branch before the merge and on production after the deployment, covering every launcher the install guide covers, with four items that do not depend on the game (logging in, a server restart, world persistence, reaching the server from another network). `game-requirements` keeps "Gameplay acceptance checklist" with its seven items. `docs/acceptance-checklist.md` stays one table of eleven items.

**5. Launchers are named by `mrpack-distribution` only.** The memory guidance and the acceptance run refer to "each launcher the pack install and update guide covers". Decided by the agent as part of the same cut: the choice of launchers follows the pack format, not the game.

**6. Each Purpose states assumptions and sources (option A, chosen by the human).** A delta cannot change the Purpose of an existing spec, and archiving keeps it as it is, so the four paragraphs are edited in `openspec/specs/` directly during apply. The human approved this exception to "specs change through deltas". The texts:

- `compose-services`: Runs a Minecraft game server from a pack under Docker Compose on one Linux host, keeps it secure and observable, backs it up and restores it, provides a staging copy, defines the players' acceptance run, and documents how an administrator operates it. It assumes the itzg server image, which installs the server side of a `.mrpack`, and the itzg backup image. It names no game: the game's values come from `game-requirements`, the pack and its version from `mrpack-distribution`, and the name, address and icon from `public-server-info`.
- `mrpack-distribution`: Turns the packwiz pack source into a verified `.mrpack`, publishes it from `main` as one file behind a link that never changes, and guides players through installing and updating it. It assumes a packwiz pack whose mods are all downloaded from Modrinth's CDN, players on Modrinth App or Prism Launcher, and GitHub Actions in a public repository. It names no game: the mods, sides, versions, client settings files and the pack's base name come from `game-requirements`, and the display name and address from `public-server-info`.
- `game-requirements`: Declares the values the game dictates, which change when the mod set changes: the pack's identity, the mods and their sides, the Minecraft, loader, Cobblemon and Java versions, the server's gameplay defaults and heap, the client settings files and their defaults, what players are taught, and the gameplay items of the acceptance run. It is the only capability to rewrite for another mod pack; the other three take every game value from here.
- `public-server-info`: Defines the server information that is published to players and supplied by the deployer: the display name, the public address, the icon and the MOTD text, and where each value comes from. It names no game and assumes no platform of its own; the default display name comes from `game-requirements`.

No mechanism spec names a loader: inspection compares "the loader pin" with `pack.toml`, and the smoke check looks for "the key mod". Fabric appears in `game-requirements` only. The loader is therefore not listed as an assumption.

**7. History-dependent wording is made timeless.** The requirement "Template copies release without local tooling" is renamed "Template copies publish without local tooling". The scenario condition "as deployments did before the version file existed" is dropped. The scenario "Version file from before this change" cannot be renamed by a MODIFIED block, so its requirement, "Server shows the published display name", is removed and added again as "Server shows the display name its pack was built with", with the scenario named "Version file without a display name". The behaviour is the same in all three.

**8. The merge was rehearsed before this change was presented.** In a throwaway clone, with the four Purposes edited, `openspec archive` applied 4 added, 16 modified, 1 removed and 1 renamed requirement; `openspec validate --specs --strict` passed for all four specs; the scan found no game value in the three mechanism specs (24 lines before) and found the five values they refer to declared in `game-requirements`. The lesson of the `committed-public-info` archive, where a requirement turned out too long only after approval, is applied here.

**9. The two changes planned before are dropped.** `game-values-out-of-mechanisms` (the side table and the smoke check's expectations out of the scripts) and `split-shared-scripts` (the shared library, the smoke check, the tools service, the workflow) served a reuse of files. With specs as the unit of reuse they bring no benefit, and the scripts may keep the game's values. `neutral-stack-names` stays: it made the names in `compose-services` neutral, which this cut needs, and a repository built from these specs gets the same defaults, so its rules for two deployments on one host apply there too.

## Risks / Trade-offs

- [A reader of a mechanism spec must look up `<pack>` in another spec] → Each capability says once where it comes from; the Purpose names the source of every value.
- [The specs say `<pack>` while the files spell `cobblemon`] → Intended: the file names are this repository's instance of the rule. "Pack identity" states the concrete names.
- [Purposes are changed outside the delta mechanism] → Approved by the human; done as one explicit task that shows each text before and after; the archived change records the new texts in this design.
- [The scan is a list of keywords, not a proof] → It backs a review of every requirement; the list covers the game's name, its mods, its versions and its settings.
- [A repository for another pack may not meet the stated assumptions] → That is what stating them is for: the agent there sees at once which mechanism spec it cannot copy unchanged.
- [`docs/acceptance-checklist.md` is one file described by two specs] → The file is not split; each spec describes its rows.

## Migration Plan

Merge and archive. Nothing is deployed or published. Rollback: revert the merge; the Purposes return with it.
