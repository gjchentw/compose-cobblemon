# Tasks

## 1. Source of the values

- [x] 1.1 Add `config/public.env` with the placeholders, and a helper in `scripts/lib.sh` that resolves the two keys from the environment, then that file, and nothing else; `scripts/pack-export.sh` and `scripts/pack-inspect.sh` use it. Show that a value in `.env` is ignored, the file is used, and the environment overrides it (verify: L1, L2)
- [x] 1.2 Remove `SERVER_NAME` and `SERVER_PUBLIC_HOST` from `.env.example` and from the workflow's `env` (the two secrets); show both compose file sets still render and the pack job's steps pass in a fresh checkout (verify: L1, L2)

## 2. Display name in the version file

- [x] 2.1 Export writes `PACK_VERSION` and a single-quoted `SERVER_NAME` to `dist/cobblemon.env` and refuses a name with a single quote or a line break before writing anything; show the rendered MOTD carries a name with spaces and a `$` unchanged, and that a `SERVER_NAME` left in `.env` loses to the version file (verify: L1, L2)
- [x] 2.2 Run the stack on a pack built with a non-default name and show the MOTD and the pack's entry start with it; run persistence and restore on the rebuilt stack (verify: L3, L4)

## 3. Publish

- [x] 3.1 `scripts/pack-publish.sh` skips with a message and exit 0 on an empty or placeholder address, in publish mode and as "would skip" in the dry run, and treats a differing or missing display name in the committed version file as a change. Simulate against a local bare remote: placeholder skips and pushes nothing; a real address publishes; an equal pack with a version file lacking the name publishes; a documentation-only push after that publishes nothing (verify: L1, L2)
- [x] 3.2 Update the workflow's comments and the publish step's name for the skip; push the branch and a `smoke/*` branch and confirm lint, validate, pack with its dry-run report, and the hosted smoke, persistence and restore jobs pass (verify: L1, L2, L3, L4)

## 4. Documents and rules

- [x] 4.1 Update `README.md` ("Make it yours": edit `config/public.env` instead of setting secrets; quick start; version contract; layout), `docs/admin-guide.md` (first deployment no longer sets the two values in `.env`), `docs/upgrade.md` and `docs/acceptance-checklist.md` (the one-off override for a staging pack; the migration from secrets) (verify: L1)
- [ ] 4.2 Update `AGENTS.md` (`.env.example` exception covers `SERVER_NAME`; the overview lists `config/public.env`) and confirm with a search that no document or script still presents the secrets or `.env` as the source of the two values; the search found one, fixed here: the source and the placeholder sentences of ADR 0003, with a dated amendment note (verify: L1)

## Workflow follow-up

- After the merge to `main`: confirm the template's publish job reports the skip and succeeds, and that nothing is committed to `dist/`.
- The human may delete the repository secrets `SERVER_NAME` and `SERVER_PUBLIC_HOST`.
- Archive the change.
