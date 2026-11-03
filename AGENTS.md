# AGENTS.md

Guidance for AI coding agents (Claude Code, Cursor, Copilot, OpenCode, etc.) and for the humans who work with them in this repository.

## Repository Overview

`compose-cobblemon` is a Docker Compose project. It contains only infrastructure artifacts:

- `Dockerfile` — server image definition
- Compose files (`compose.yaml` and overrides under `examples/`)
- Settings and templates (`.env.example`, `config/`)
- Helper scripts (`scripts/`)
- Documentation (`README.md`, `SPEC.md`, `tasks/`, `docs/`)

There is no application code. "Tests" here are validation, build, smoke and persistence checks, not unit tests.

## Language Policy

- Everything committed to this repository is written in English: documentation, `SPEC.md`, task files, ADRs, comments in Dockerfiles, Compose files and scripts, commit messages and PR descriptions.
- Conversation between the agent and the human may be in whatever language the human uses. Questions, answers and discussion are not bound by the English rule; written artifacts are.
- When the human gives input in another language, the agent translates it into English before recording it in any file.

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

3. **Stop on confusion.** If the spec, the task list and the existing files disagree, name the conflict and ask which takes precedence. Do not pick one silently.

4. **Push back when warranted.** State the concrete downside, propose an alternative, then accept the human's decision.

5. **Report, do not self-approve.** At every gate (see below) the agent presents the artifact and waits. The agent never marks a gate as passed on its own.

6. **In non-interactive contexts** (CI, scheduled runs, autonomous loops) where no human can answer, the agent stops at the first open question and reports it as a blocker instead of guessing.

### Human responsibilities

- Answer the agent's questions and resolve `Open Questions` in `SPEC.md`.
- Review and approve each gate artifact: `SPEC.md`, `tasks/plan.md`, `tasks/todo.md`, and each task's verification result.
- Make the calls listed under "Ask first" in the Boundaries section.

### What the agent may decide alone

Routine judgment calls inside an already-approved task: naming, ordering of YAML keys, comment wording, script structure. Anything that changes behaviour, scope, versions, ports, volumes or services is not routine and goes back to the human.

## Mandatory Workflow: Spec-Driven Development with agent-skills

All work in this repository follows the SDD cycle from the `agent-skills` plugin. No file is created or changed outside of this cycle, except typo-level fixes the human explicitly asks for.

```
SPECIFY ──→ PLAN ──→ TASKS ──→ IMPLEMENT ──→ REVIEW ──→ SHIP
  gate        gate      gate      per task      gate      gate
```

Every gate requires human approval before moving on.

| Phase | Claude Code command | Skill | Artifact | Gate |
|---|---|---|---|---|
| Specify | `/agent-skills:spec` | `spec-driven-development` | `SPEC.md` | Human approves the spec |
| Plan | `/agent-skills:plan` | `planning-and-task-breakdown` | `tasks/plan.md` | Human approves the approach |
| Tasks | `/agent-skills:plan` | `planning-and-task-breakdown` | `tasks/todo.md` | Human approves the task list |
| Implement | `/agent-skills:build` | `incremental-implementation` + `test-driven-development` | one commit per task | Verification ladder passes |
| Review | `/agent-skills:review` | `code-review-and-quality` | review report | Human accepts or requests changes |
| Simplify | `/agent-skills:code-simplify` | `code-simplification` | reduced diff | Behaviour unchanged, checks still pass |
| Ship | `/agent-skills:ship` | `shipping-and-launch` | GO / NO-GO with rollback plan | Human makes the ship decision |

Supporting skills, applied when their trigger matches:

- `interview-me` — when the ask is missing who, why, success criteria or the binding constraint. Use before `/spec` if needed.
- `source-driven-development` — verify Docker, Compose and upstream image behaviour against official documentation before relying on it.
- `debugging-and-error-recovery` — whenever a build, validation or smoke check fails unexpectedly.
- `documentation-and-adrs` — record architectural decisions (base image choice, mod delivery strategy, volume layout) in `docs/adr/`.
- `git-workflow-and-versioning` — commit and branch hygiene.
- `security-and-hardening` — anything touching secrets, exposed ports, privileges or user IDs in containers.

Harnesses without slash commands invoke the skill by name and follow the same phase order.

### Phase detection at session start

1. Read this file, then `SPEC.md` and `tasks/todo.md` if they exist.
2. If there is no `SPEC.md`, start at Specify. If there is a spec but no `tasks/`, start at Plan. If there are unchecked tasks, continue at Implement with the next one.
3. Confirm the detected phase with the human before doing anything else.

### Keeping the spec alive

- A decision that changes versions, structure, services or scope is written into `SPEC.md` first, then implemented.
- `tasks/todo.md` is updated as tasks complete. Tasks are never silently added; new work goes through the human.
- `SPEC.md`, `tasks/` and ADRs are committed alongside the files they describe.

## Verification Ladder

The exact commands live in the `Commands` section of `SPEC.md`. The ladder has four levels; each task's `Verify` line names which levels it must pass.

| Level | Check | Typical means |
|---|---|---|
| L1 Static | Compose file is valid, Dockerfile and YAML lint clean | `docker compose config`, Dockerfile linter, YAML linter |
| L2 Build | Image builds | `docker compose build` |
| L3 Smoke | Stack starts, becomes healthy within the timeout, the server port answers | smoke script |
| L4 Persistence | Stack is stopped and restarted, data survives | down, up, check |

Test-driven development applies to infrastructure in this form:

- **RED** — write or extend a check that fails before the change (a smoke step, a lint rule, a config assertion).
- **GREEN** — make the smallest change that turns it green.
- **Regression** — run every level the task names, plus `docker compose config` on every file under `examples/`.

A task is not done until its named levels pass and the output is shown to the human. "It looks right" is never evidence.

## Boundaries

**Always**

- Follow the SDD cycle above; every change maps to a task in `tasks/todo.md`.
- Run the verification ladder before every commit.
- Pin every image tag and every mod and loader version.
- Keep `.env.example` complete: every variable the stack reads, with a safe default or a placeholder.
- Write in English in every committed file.

**Ask first**

- Adding, removing or renaming a service.
- Changing port mappings, volume mappings or the base image.
- Bumping a pinned version.
- Adding tooling (linters, CI workflows, helper images).
- Deleting any file.
- Anything that touches secrets, RCON, user or group IDs, or container privileges.

**Never**

- Commit `.env`, secrets, tokens or RCON passwords.
- Commit runtime data (world saves, logs, caches).
- Use `latest` or any floating tag.
- Skip or self-approve a gate.
- Touch files outside the current task's `Files` list.
- Remove or weaken a check to make it pass.

## Scope and Simplicity

- Touch only what the current task names. No drive-by cleanup, refactoring or comment removal.
- Prefer the boring Compose feature over a clever script. If a one-line `healthcheck` does the job, do not write a sidecar.
- Each example under `examples/` must stand alone and pass L1 on its own.

## Git Conventions

- Work on a branch unless the human says otherwise.
- One commit per completed task, in English, referencing the task.
- Commit `SPEC.md` and `tasks/` changes together with the files they describe.
