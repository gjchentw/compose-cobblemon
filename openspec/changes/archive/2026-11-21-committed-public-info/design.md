# Design

## Context

See proposal.md for the motivation. Today `scripts/lib.sh` resolves `SERVER_NAME` and `SERVER_PUBLIC_HOST` for pack builds in Compose's order (environment, the `COMPOSE_ENV_FILES` files, `.env.example`), CI supplies them from two repository secrets, and `compose.yaml` builds the MOTD from `${SERVER_NAME:-Cobblemon Server}`, which Compose reads from `.env`. The pack and its version file `dist/cobblemon.env` are committed to `main` by the publish job, and deployments read the version file through `COMPOSE_ENV_FILES=.env,dist/cobblemon.env`.

This repository is the template and a test environment, not a deployment for players (confirmed by the human, 2026-11-20).

## Goals / Non-Goals

**Goals:**
- One committed source for the display name and the public address, used by local builds and CI.
- The MOTD name and the pack's entry name cannot disagree.
- No change to what administrators set in their shell profile.
- The template's own `main` stays green with placeholders.

**Non-Goals:**
- The server icon and the MOTD format stay as they are.
- No new settings in the file beyond the two values.
- The template's committed pack is not removed or rebuilt.

## Decisions

**1. The file is `config/public.env`, in env format, with the existing variable names.** `config/` already holds the other public artifact, the server icon. Env format needs no parser beyond the helper that exists, and the names match what `compose.yaml` and the scripts already use. The template commits `SERVER_NAME=Cobblemon Server` and `SERVER_PUBLIC_HOST=mc.example.com`. Chosen by the human. Alternatives: YAML or TOML (a parser on the host or a container run for two values).

**2. Pack builds read the environment first, then the file, and nothing else.** A new helper in `scripts/lib.sh` replaces `env_value` for these two keys; `.env`, the version file and `.env.example` are no longer consulted, so a value left in a deployment's `.env` cannot leak into a pack. The environment override stays because `docs/upgrade.md` and the acceptance checklist use it to build a staging pack with the staging port. CI stops passing the two secrets, so in CI the file is the only source. Alternative: file only. Rejected: the staging pack would need an edit to a tracked file.

**3. The server gets the display name from the version file (option A, chosen by the human).** Export writes `dist/cobblemon.env` with two lines, `PACK_VERSION=<version>` and `SERVER_NAME='<name>'`, and the publish job commits it with the pack. `compose.yaml` is unchanged: `${SERVER_NAME:-Cobblemon Server}` now resolves from the version file, which Compose reads after `.env`, so it also wins over a `SERVER_NAME` left in `.env`. The name is written in single quotes so Compose takes it literally (no `$` interpolation); export refuses a name containing a single quote or a line break, the two things that form cannot hold. Alternative B: Compose reads `config/public.env` as a third env file. Rejected by the human: administrators would change the profile setting again, and a renamed server would show the new name before players have the pack that carries it.

**4. The publish comparison includes the display name.** `scripts/pack-publish.sh` already rebuilds with the committed version and compares archive members. It also compares the `SERVER_NAME` in the committed version file with the one just built; a difference publishes. Without this, a copy that moves the same values from secrets to the file would build an identical pack, publish nothing, and keep a version file without the name, so its MOTD would fall back to `Cobblemon Server`.

**5. The publish job skips on the placeholder address.** Before building, `scripts/pack-publish.sh` in publish mode checks the address; when it is empty or `mc.example.com` it prints `PUBLISH: skipped; set SERVER_PUBLIC_HOST in config/public.env` and exits 0, and the workflow's push step finds no new commit. The dry run reports the same as "would skip". The guard inside `scripts/pack-export.sh` (`PACK_REQUIRE_REAL_HOST`) stays as a second line. Alternative: keep failing. Rejected: the template itself would fail on every push to `main`.

**6. The template's committed pack stays (option B, chosen by the human).** `dist/cobblemon.mrpack` and `dist/cobblemon.env` on the template's `main` remain at `2026.11.20-de55e63`, built from the former secrets. Alternatives: delete them (the template would carry no pack; recommended by the agent), publish with the placeholder (breaks "never carry the placeholder").

**7. `.env.example` drops both variables.** `AGENTS.md` extends the exception to its "every variable the stack reads" rule: `PACK_VERSION` and `SERVER_NAME` come from `dist/cobblemon.env`. `SERVER_PUBLIC_HOST` is not read by the stack at all.

## Risks / Trade-offs

- [The template's frozen pack points at the former test address, and its dry run will always report a difference] → README already tells owners not to send the link before their first pack commit; the dry-run report is informational.
- [A copy inherits the template's pack until its first publish] → Same README note; the first commit to `config/public.env` publishes.
- [The public address is committed in clear text] → It is already inside the published pack in a public repository.
- [An exported `SERVER_NAME` in an administrator's shell overrides the version file for Compose, and the file for pack builds] → Documented as the one-off override; nothing sets it permanently.
- [A deployment still on a version file without `SERVER_NAME` and a name in `.env`] → Works as before until the next publish, then the version file wins; the migration removes the `.env` lines.
- [Local export rewrites the tracked `dist/` files with placeholder values] → Unchanged from today: `git restore dist/`.

## Migration Plan

For an existing copy with secrets:
1. Commit the two values to `config/public.env` on `main`. CI publishes a pack and a version file that carries the name (decision 4), even when the pack's contents are equal.
2. Delete the repository secrets `SERVER_NAME` and `SERVER_PUBLIC_HOST`.
3. On the deployment: `git pull`, remove `SERVER_NAME` and `SERVER_PUBLIC_HOST` from `.env`, restart, run the smoke check.

For this template: merge; the publish job skips. The human may delete the two secrets.

Rollback: revert the merge; secrets that were not deleted work again, and `.env.example` gets the two variables back.
