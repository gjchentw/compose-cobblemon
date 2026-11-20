# Design

## Context

See proposal.md, Why. Today CI builds a pack only when a GitHub release is published, versions come from release tags, `dist/` is ignored, and the deployment downloads the pack from a release and checks that the checkout carries the release tag (`openspec/specs/mrpack-distribution`, `openspec/specs/compose-services`). The decisions below were made with the human one at a time on 2026-11-17; the human revised decision 4 the same day, and approved decision 6, which the agent proposed to close a gap the fixed file name creates.

## Goals / Non-Goals

**Goals:**
- One permanent player link that always serves the pack on `main`; merging to `main` is the release.
- No local tooling needed to publish, so template copies keep working from the browser.
- Acceptance happens before the merge, because the merge now reaches every player.

**Non-Goals:**
- Moving the public server information out of the repository secrets (follow-up change 3).
- Splitting the player guide or untangling shared files (follow-up changes 4 and 5).
- Deleting or editing the existing GitHub releases.

## Decisions

**1. The pack is a tracked file on `main`.** `dist/cobblemon.mrpack`, fixed name, served from the raw link of `main`, with its version file `dist/cobblemon.env` next to it (decision 4). `.gitignore` ignores the rest of `dist/`. Alternatives: a release with a constant tag whose asset is replaced (brief 404 during replacement), GitHub Pages (extra setup in every template copy). The human chose the tracked file.

**2. CI builds and commits the pack.** A new `publish` job runs only for pushes to `main` of the repository itself (not in forks; template copies are not forks), after `lint`, `validate` and `pack`, with `contents: write`. Its checkout does not persist credentials either: the token is given to the final push step only, the way `actions/checkout` authenticates, so the tool containers, which mount the repository with its `.git/`, never see a write token. Alternative: a checkout that keeps credentials. Rejected by the human: the token would sit in `.git/config` for the whole job, readable by the tool images. It builds the pack with the public information from the secrets and the real-host guard. To decide whether anything changed, it first rebuilds with the version of the committed pack and compares the archive members byte for byte; equal members mean nothing to publish. Otherwise it builds with the version of the pushed commit, inspects it against that version, commits only `dist/cobblemon.mrpack` and `dist/cobblemon.env` as `github-actions[bot]` with the message `pack <version> [skip ci]`, and pushes. Commits pushed with the workflow token do not start workflows, and `[skip ci]` makes that explicit. Publish runs on `main` are serialized and never cancelled; a push rejected because `main` moved fails the job, and the next push to `main` publishes. The comparison and the commit live in `scripts/pack-publish.sh`, which has a dry-run mode that reports what it would commit; the `pack` job runs the dry run on every push, so the logic is exercised on branches before it ever runs on `main`. Alternative: developers build and commit locally (CI stays read-only). Rejected by the human: template owners would need Docker.

**3. Version format.** `YYYY.MM.DD-<7 characters>` from the commit date in UTC and the commit hash, computed by a helper in `scripts/lib.sh`. The commit is the pushed one that changed the pack's contents; documentation-only commits produce no new pack, so the version keeps naming the last commit that changed it. The placeholder `0.0.0-dev` stays in `pack/pack.toml`; `.env.example` no longer sets `PACK_VERSION` (decision 4). Alternatives: a build counter (needs full history, jumps on history rewrites), the commit alone (no ordering for people).

**4. The version reaches Compose through a committed version file.** Export writes `dist/cobblemon.env`, holding only `PACK_VERSION=<version>`, next to the pack, and the publish job commits both in one bot commit, so `git pull` always brings a pack and its version from the same commit. The administrator sets `COMPOSE_ENV_FILES=.env,dist/cobblemon.env` once in the shell profile of the account that runs the server; Compose reads `.env` first and the version file second, and the later file wins. `PACK_VERSION` is removed from `.env.example`, and the server's MOTD keeps `${PACK_VERSION:?...}` with a message naming the setting, so a shell without it fails before anything starts. The scripts in `scripts/` use the same value when `COMPOSE_ENV_FILES` is unset, so they work without the profile. `scripts/ci-env.sh` writes the version file from the version helper when it is missing, so CI can render the configuration on a checkout with no published pack yet (this branch before its merge). The Compose service installs the fixed path `/packs/cobblemon.mrpack`; `PACK_VERSION` is used only for the MOTD and the smoke check. Verified with Compose 5.7.1: the setting works from the shell but is ignored inside `.env`; its relative paths resolve from the working directory, which lets a staging worktree use its own files (decision 7); with the setting, the version file overrides a `PACK_VERSION` left in `.env`; without it, a left-over value is used silently, which is why the smoke check refuses one. Alternatives: the administrator copies the version into `.env` after each pull (chosen first, then replaced by the human: easy to forget or mistype), a deploy script (everyday commands such as `restart` and `logs` would still need the version). The human chose the version file.

**5. No release-tag checks.** The pack comes from the deployment's own checkout, so the configuration and the pack are from the same commit by construction. `check_release_checkout` and the tag handling in `scripts/version-check.sh` are removed; the version check keeps "git holds only the placeholder" and validates the format of a given version.

**6. The pre-filled entry names the pack version.** With a fixed file name, players can no longer read their version from the file. Export names the entry `<display name> (<version>)`, so the Multiplayer list shows the player's version above the server's MOTD. Inspection expects that name. Proposed by the agent and approved by the human. Alternative: keep the bare display name, which leaves players no way to read their pack version in the game.

**7. Acceptance on staging from a separate checkout.** The production checkout stays on `main`. The administrator adds a git worktree of the branch next to it, copies the production `.env` there, builds the branch's pack there, which also writes the worktree's version file, clones the production world into the worktree's staging data, and runs the staging stack and its checks from the worktree, where the relative `COMPOSE_ENV_FILES` picks up the worktree's own `.env` and version file. `scripts/staging-clone-world.sh` gains an option naming the production checkout, so it pauses saves and reads the world there. Alternative: checking out the branch in the production directory, which would change production's compose files under the running server.

**8. Documentation and rules follow.** `AGENTS.md` allows committing `dist/cobblemon.mrpack` and `dist/cobblemon.env` and says only CI commits them, exempts `PACK_VERSION` from the rule that `.env.example` lists every variable, replaces the release-tag rule with the placeholder rule, describes a release as a merge to `main`, and updates the L3 and L5 descriptions. ADR 0004 is marked superseded. README, the administrator guide, the upgrade and rollback procedures, both player guides and the acceptance checklist describe the new flow.

## Risks / Trade-offs

- [Two merges land while a publish job runs and its push is rejected] → The job fails visibly; the next push to `main` publishes. Runs are serialized to make this rare.
- [The raw link is cached for a few minutes] → A player may download the previous pack briefly; the version in the entry name against the MOTD shows it.
- [Template copies that are private cannot serve the raw link; branch protection can block the bot's push] → README states both requirements.
- [`COMPOSE_ENV_FILES` in the profile applies to every Compose command of that account: in another project directory without `dist/cobblemon.env`, Compose fails with "couldn't find env file"] → The administrator guide recommends an account dedicated to the server and shows `COMPOSE_ENV_FILES= docker compose ...`, which restores the default `.env` for one command (verified).
- [An existing deployment's `.env` still sets `PACK_VERSION`] → With the setting the version file wins; without it Compose would use the stale value, so the smoke check refuses a `PACK_VERSION` in `.env`, and the migration removes it.
- [A local export rewrites the two tracked files in `dist/`] → `git restore dist/` puts them back; `AGENTS.md` says only CI commits them, and the bot's content comparison would replace a hand-committed pack on the next push to `main`.
- [Between the merge and the deployment, players with the new pack cannot join the old server] → Accepted by the human; administrators deploy soon after a publish, and the MOTD shows the mismatch.
- [The first publish after this change renames every player's server entry] → Players install the new pack as a new profile once; the announcement says so.

## Migration Plan

1. Apply the change on its branch and run the staging acceptance from a worktree once, as the new procedure describes.
2. Merge to `main`. The first `publish` run commits `dist/cobblemon.mrpack` with the version of the merge commit.
3. On production: `git pull`, remove `PACK_VERSION` from `.env`, set `COMPOSE_ENV_FILES=.env,dist/cobblemon.env` in the profile once, run the smoke check.
4. Send players the fixed link; they install the pack as a new profile.

Rollback: revert the merge on `main`; on production, check out `v1.0.1`, remove `COMPOSE_ENV_FILES` from the profile, put `PACK_VERSION=1.0.1` back in `.env` and download that release's pack into `dist/` as before; the v1.0.1 release and its pack are untouched.

## Open Questions

- Whether CI should also fail a pull request that edits `dist/cobblemon.mrpack` by hand. The rule in `AGENTS.md` covers it for now; a check can be added later without changing these specs.
