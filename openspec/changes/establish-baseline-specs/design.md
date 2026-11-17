# Design

## Context

See proposal.md, Why. The behaviour these specs record is already implemented and verified; this change only writes it down in OpenSpec form and retires `SPEC.md`. The capability boundaries were settled with the human in an explore session on 2026-11-17. The deployment environment is fixed: Docker Compose on one Linux host, the itzg images, packwiz with Modrinth, GitHub Actions. Specs may name these tools.

## Goals / Non-Goals

**Goals:**
- Cut the repository into capabilities that another project on the same stack could take one at a time without carrying parts it does not need.
- Record today's behaviour exactly, including parts already scheduled to change, so every follow-up change is a reviewable delta.

**Non-Goals:**
- Changing any behaviour, file or published pack.
- Abstracting over other platforms (Kubernetes, other forges, other pack tools).
- Moving files to match the new boundaries; that is follow-up work.

## Decisions

**1. Four capabilities.** `compose-services` (how the stack runs), `mrpack-distribution` (how the pack is built, checked and published), `game-requirements` (what the game needs), `public-server-info` (what the public sees about the server). Alternative considered: cutting by platform layer (Compose, CI, backup tool). Rejected because the human's portability goal is reusing a capability in another project, not swapping a platform.

**2. Mechanisms are separate from values.** `compose-services` and `mrpack-distribution` state mechanisms; concrete game values live in `game-requirements`. Example: distribution checks every mod's side against "the side table"; the table itself is a `game-requirements` requirement.

**3. Which values are game values.** A value belongs to `game-requirements` when it changes with the mod set: mods, sides, Minecraft, loader and Java versions, gameplay settings, heap, client options and key bindings. Operational defaults (backup interval and retention, log rotation, health timing, stop grace period, ports) stay with their mechanism in `compose-services`. Alternative: all values in `game-requirements`. Rejected because it would become a catch-all and a project taking `compose-services` would lose sensible defaults.

**4. Public server information is its own capability.** Display name, public address, icon and MOTD text are deployer-supplied and published to players; `compose-services` and `mrpack-distribution` consume them. The MOTD format moves here from `compose-services` because it is what players read.

**5. Secrets never enter specs.** The RCON password and similar values are set by the deployer in `.env` at deployment. Specs state the security posture instead: the committed configuration is the least-privilege, most secure deployment, and development and CI run under the same rule (for example CI generates a one-off RCON password).

**6. Interfaces between capabilities.**

```
 public-server-info --(name, address, icon, MOTD)--> compose-services
 public-server-info --(name, address)--------------> mrpack-distribution
 game-requirements  --(mods, sides, versions, client options)--> mrpack-distribution
 game-requirements  --(gameplay defaults, Java, key mod)-------> compose-services
 mrpack-distribution --(pack file + version)-------------------> compose-services
```

**7. Documentation follows its capability.** The administrator guide, upgrade and rollback procedures belong to `compose-services`. The player guide's install and update parts belong to `mrpack-distribution`; its first-minutes, key and memory parts belong to `game-requirements`. Each check belongs to what it verifies.

**8. Baseline first.** Today's behaviour is recorded even where a follow-up change will replace it (tag-triggered releases, public information in secrets, the release-tag checkout check), so each later change shows its delta. Alternative: write the target design directly. Rejected: one large change whose specs would not match the repository until it is fully implemented.

## Risks / Trade-offs

- [Files do not yet follow the boundaries: `scripts/lib.sh` is shared by all scripts, `scripts/smoke.sh` checks several capabilities, `scripts/pack-inspect.py` holds the side table, `compose.yaml` hosts the packwiz tools service and names the main service `cobblemon`, and one CI workflow serves every capability.] → The specs describe behaviour only; untangling the files is a follow-up change.
- [Two current settings are not least-privilege: the packwiz tools container mounts the whole repository read-write and the linters mount it read-only, both including `.env`.] → Recorded as a follow-up change.
- [Removing `SPEC.md` drops a document some readers know.] → Its requirements move to the four specs, its decisions to this design and the ADRs, and git history keeps it.

## Migration Plan

1. Review and approve this change (propose gate).
2. Apply: verify each requirement against the repository, then remove `SPEC.md` and update `AGENTS.md` and `README.md`.
3. Archive: the four specs land in `openspec/specs/`.

Follow-up changes, in this order, each its own OpenSpec change:
1. Rolling pack from `main`: every change on `main` rebuilds the pack and overwrites one fixed download link; the version comes from the commit; tag releases, release candidates and release notes are retired; the checkout check compares commits instead of tags. Players use the MOTD to decide when to download again; administrators upgrade soon after a new pack is published.
2. Acceptance before merge: staging deploys a branch and its pack; merging to `main` publishes to players; a bad merge is reverted.
3. Committed public-information file read by both the server and CI, replacing the `.env` values and the repository secrets.
4. Player guide split into an install and update guide (`mrpack-distribution`) and a play guide (`game-requirements`), each in English and Traditional Chinese.
5. Untangle shared files so each capability's files can be moved on their own, including renaming the main service.
6. Least-privilege mounts for the tools and lint containers.

## Open Questions

- Where the fixed download link lives (a release with a constant name, GitHub Pages, or a branch), how the commit-derived version string looks, and the format of the public-information file: design questions for follow-up changes 1 and 3. They do not affect this baseline.
