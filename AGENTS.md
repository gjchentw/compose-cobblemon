# AGENTS.md

Guidance for AI coding agents (Claude Code, Cursor, Copilot, OpenCode, etc.) and for the humans who work with them in this repository.

## Repository Overview

`compose-cobblemon` is a Docker Compose project. It contains only infrastructure artifacts:

- `compose.yaml` and the `compose.staging.yaml` override (the server runs a pinned upstream image)
- `pack/` — the packwiz pack, the single source of truth for the client pack and the server's mod set
- `tools/packwiz/Dockerfile` — the pack tooling image
- Settings and templates (`.env.example`, `config/`)
- Helper scripts (`scripts/`)
- `dist/cobblemon.mrpack` and `dist/cobblemon.env` — the published pack and its version file, committed by CI only
- CI (`.github/workflows/ci.yml`): checks on every push, and the pack publish on a push to `main`
- `openspec/` — the OpenSpec specs (`openspec/specs/`) and changes (`openspec/changes/`); the workflow skills live in `.claude/skills/` and `.agents/skills/`
- Documentation (`README.md`, `docs/`, and `tasks/`, the record of the work before OpenSpec)

There is no application code. "Tests" here are lint and config validation, pack inspection, smoke and persistence checks, and a gameplay checklist run by people, not unit tests.

## Language Policy

- Everything committed to this repository is written in English: documentation, OpenSpec artifacts (proposals, specs, designs, task lists), ADRs, comments in Dockerfiles, Compose files and scripts, commit messages and PR descriptions.
- Conversation between the agent and the human may be in whatever language the human uses. Questions, answers and discussion are not bound by the English rule; written artifacts are.
- When the human gives input in another language, the agent translates it into English before recording it in any file.
- One exception, decided 2026-11-03: `docs/player-guide.zh-TW.md` is a Traditional Chinese copy of `docs/player-guide.md` for players. The English file is the primary version; any task that changes one changes both.

## Collaboration Protocol: The Agent Asks, the Human Decides

The default mode of communication is the agent asking the human. The agent does not fill gaps with guesses.

### Agent responsibilities

1. **Surface assumptions before acting.** Before any non-trivial work, list them and wait for confirmation:

   ```
   ASSUMPTIONS I'M MAKING:
   1. ...
   2. ...
   → Please confirm or correct before I proceed.
   ```

2. **Ask one focused question at a time**, with a best guess and a recommended default attached:

   ```
   Q: <one question>
   GUESS: <likely answer and why>
   DEFAULT: <what I will do if you have no preference>
   ```

   Batch questions only when they are independent and there are three or fewer.

3. **Stop on confusion.** If the specs, the change artifacts and the existing files disagree, name the conflict and ask which takes precedence. Do not pick one silently.

4. **Push back when warranted.** State the concrete downside, propose an alternative, then accept the human's decision.

5. **Report, do not self-approve.** At every gate (see below) the agent presents the artifact and waits. The agent never marks a gate as passed on its own.

6. **In non-interactive contexts** (CI, scheduled runs, autonomous loops) where no human can answer, the agent stops at the first open question and reports it as a blocker instead of guessing.

### Human responsibilities

- Answer the agent's questions and settle the open points a change's proposal or design raises.
- Review and approve each gate: the change's artifacts after propose, each task's verification result during apply, and the archive.
- Make the calls listed under "Ask first" in the Boundaries section.

### What the agent may decide alone

Routine judgment calls inside an already-approved change: naming, ordering of YAML keys, comment wording, script structure. Anything that changes behaviour, scope, versions, ports, volumes or services is not routine and goes back to the human.

## Mandatory Workflow: OpenSpec

All work in this repository goes through an OpenSpec change. No file is created or changed outside a change, except typo-level fixes the human explicitly asks for.

```
EXPLORE ──→ PROPOSE ──→ APPLY ──→ ARCHIVE
optional      gate      per task     gate
```

| Phase | Skill | CLI | Artifact | Gate |
|---|---|---|---|---|
| Explore | `openspec-explore` | `openspec list`, `openspec show` | none: thinking only, nothing is written without the human's confirmation | none |
| Propose | `openspec-propose` | `openspec new change <name>`, `openspec status --change <name>`, `openspec validate <name>` | `openspec/changes/<name>/`: `proposal.md`, delta specs in `specs/<capability>/spec.md`, `design.md`, `tasks.md` | Human approves the change; nothing is implemented before that |
| Apply | `openspec-apply-change` | `openspec instructions apply --change <name>` | the code and docs the tasks call for; each finished task checked off in `tasks.md` | Each task's verification levels pass and the output is shown to the human |
| Archive | `openspec-archive-change` | `openspec archive <name>` | delta specs merged into `openspec/specs/`; the change moved to `openspec/changes/archive/` | Human approves the archive |

`openspec-sync-specs` merges a change's delta specs into the main specs before archiving when the human wants them in place early. Harnesses without the skills run the CLI directly and follow the same phases; `openspec instructions <artifact> --change <name>` prints the rules and template for each artifact.

Rules for changes:

- A change has a kebab-case name that says what it does, for example `bump-cobblemon-1-9`.
- Propose plans and stops. Apply starts only when the human asks for it.
- A change that alters no requirement (docs, tooling, a refactor) sets `skip_specs: true` in its `.openspec.yaml` instead of inventing a requirement.
- Decisions, with the alternatives considered, are recorded in the change's `design.md`.
- Every task in `tasks.md` names the verification levels it must pass (see below).
- `openspec validate <name>` passes before the change is presented at the propose gate and before archiving.
- New work is never added silently: a task that turns out to be needed is added to `tasks.md` and shown to the human.

### Phase detection at session start

1. Read this file, then run `openspec list` (active changes) and `openspec list --specs`.
2. If an active change has unchecked tasks, continue applying it. If it has incomplete artifacts, continue proposing it. Otherwise wait for a new request.
3. Confirm the detected phase with the human before doing anything else.

### Specs

- `openspec/specs/` is the source of truth for what the system must do. Changes carry delta specs; archiving merges them.
- There are four capabilities: `compose-services`, `mrpack-distribution`, `game-requirements` and `public-server-info`. The rules that separate them (mechanisms apart from values, game values versus operational defaults, secrets never in specs) are in the `design.md` of the archived `establish-baseline-specs` change. A new requirement goes to the capability whose rule it matches.
- `tasks/` is the record of the 1.0.x work done before OpenSpec (Tasks 1 to 22). It receives no new tasks.
- A decision that changes versions, structure, services or scope goes into a change's proposal and design first, then is implemented.

## Verification Ladder

The ladder has five levels, four automated and one run by people. Each task in a change's `tasks.md` names which levels it must pass.

| Level | Check | Typical means |
|---|---|---|
| L1 Static | Both compose file sets are valid; Dockerfile, YAML, shell, workflow and Python lint clean; `packwiz refresh` leaves `pack/` unchanged | `scripts/lint.sh`, `docker compose config -q` |
| L2 Build | The tools image builds; the pack exports and passes inspection; git holds only the placeholder version | `scripts/pack-export.sh`, `scripts/pack-inspect.sh`, `scripts/version-check.sh` |
| L3 Smoke | `.env` sets no `PACK_VERSION`, and the pack file and `dist/cobblemon.env` name the same version; the stack becomes healthy within the timeout; the server-side mod set is exact; the port answers; RCON is not published | `scripts/smoke.sh` |
| L4 Persistence | The stack stops in order and restarts with the world intact; the newest backup restores | `scripts/persist-test.sh`, `scripts/restore-drill.sh` |
| L5 Acceptance | Players complete the gameplay checklist on staging with the branch before it is merged, then on production after the upgrade | `docs/acceptance-checklist.md` |

CI runs L1 and L2 on every push. L3 and L4 run on a hosted Linux runner on manual dispatch or when a `smoke/*` branch is pushed.

Test-driven development applies to infrastructure in this form:

- **RED** — write or extend a check that fails before the change (a smoke step, a lint rule, a config assertion).
- **GREEN** — make the smallest change that turns it green.
- **Regression** — run every level the task names, plus `docker compose config` for both the production and the staging file sets.

A task is not done until its named levels pass and the output is shown to the human. "It looks right" is never evidence.

## Boundaries

**Always**

- Follow the OpenSpec workflow above; every commit maps to a task in an approved change's `tasks.md`.
- Run L1 and L2 before every commit, plus every level the task names; run L3 and L4 on staging before every merge that changes the pack or the stack (`docs/upgrade.md`).
- Pin every image by tag and multi-arch digest, and every mod and loader version in `pack/`.
- Keep `.env.example` complete: every variable the stack reads, with a safe default or a placeholder, except `PACK_VERSION`, which comes from `dist/cobblemon.env`.
- Write in English in every committed file, except `docs/player-guide.zh-TW.md`.

**Ask first**

- Adding or removing a mod in `pack/`.
- Adding, removing or renaming a service.
- Changing port mappings, volume mappings or the base image.
- Bumping a pinned version.
- Adding tooling (linters, CI workflows, helper images).
- Deleting any file.
- Anything that touches secrets, RCON, user or group IDs, or container privileges.

**Never**

- Commit `.env`, secrets, tokens or RCON passwords.
- Commit runtime data or build output (world saves, backups, staging copies, logs, caches, anything else in `dist/`).
- Commit `dist/cobblemon.mrpack` or `dist/cobblemon.env`: CI alone commits them, on `main`. After a local export, `git restore dist/` puts them back.
- Commit a version other than the placeholder `0.0.0-dev` to `pack/pack.toml`, or a `PACK_VERSION` to `.env.example`: the pack version is derived from the commit (`mrpack-distribution` spec).
- Use `latest` or any floating tag.
- Publish the RCON port, or turn off online mode or the whitelist.
- Hand-edit packwiz-generated files, other than `pack.toml` and a mod's `side` field followed by `packwiz refresh`.
- Skip or self-approve a gate.
- Touch files the current change's tasks do not call for.
- Remove or weaken a check to make it pass.

## Scope and Simplicity

- Touch only what the current task names. No drive-by cleanup, refactoring or comment removal.
- Prefer the boring Compose feature over a clever script. If a one-line `healthcheck` does the job, do not write a sidecar.
- The staging override stays a minimal diff over production: names, port, paths and MOTD only.

## Git Conventions

- Work on a branch unless the human says otherwise.
- One commit per completed task, in English, naming the change and the task number (for example `bump-cobblemon-1-9 2.1`).
- Commit a change's artifacts, including the checked-off `tasks.md`, together with the files they describe; archiving is its own commit.
- Never write a literal CI skip marker (`[skip ci]`, `[ci skip]`, `[no ci]`, `[skip actions]`, `[actions skip]`) anywhere in a commit message, not even when quoting it: GitHub then runs no workflow for that push, and a squash merge carries the text to `main`, where it would skip the pack publish. Only CI's own `pack <version>` commit carries the marker.
- A release is a merge to `main`: CI builds the pack and, when its contents changed, commits it to `main`. Merging is the human's call: the agent prepares the branch and reports its verification, and the human merges.
