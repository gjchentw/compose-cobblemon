# Proposal

## Why

The display name and the public address are set in two places that nothing keeps equal: the server reads the name from the deployment's `.env`, and CI builds the pack from two repository secrets. A deployment tested on 2026-11-20 showed the result: the pack's pre-filled entry was named after the secret and the MOTD after `.env`. Neither value is secret, since both are published inside the pack, yet a template owner has to find the secrets page to set them.

## What Changes

- **BREAKING** The display name and the public address live in one committed file, `config/public.env` (`SERVER_NAME`, `SERVER_PUBLIC_HOST`). The template commits the placeholders `Cobblemon Server` and `mc.example.com`; an owner edits the file, in the web editor if they like, and the push publishes their pack.
- **BREAKING** CI no longer reads the repository secrets `SERVER_NAME` and `SERVER_PUBLIC_HOST`. Existing copies move their values into `config/public.env` and can delete the secrets.
- **BREAKING** Both variables leave `.env.example`, and the deployment's `.env` is no longer a source for either.
- Export writes the display name into the version file: `dist/cobblemon.env` holds `PACK_VERSION` and `SERVER_NAME`. The server reads its MOTD name from there, through the `COMPOSE_ENV_FILES` setting administrators already have, so the pre-filled entry and the MOTD carry the name of the same build.
- The publish job treats a display name in the committed version file that differs from the built one as a change, so the version file follows a migration even when the pack's contents are equal.
- While `config/public.env` holds the placeholder address, the publish job skips with a message instead of failing, so the template's own `main` stays green. A published pack still never carries the placeholder.
- A one-off build can still override either value from the environment (the staging pack with the staging port, for example).
- The template's committed `dist/cobblemon.mrpack` and `dist/cobblemon.env` stay as they are (decided by the human): they are frozen at `2026.11.20-de55e63` until a copy publishes its own.
- README, the administrator, upgrade and acceptance documents, `.env.example` and `AGENTS.md` follow.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `public-server-info`: the values come from the committed file `config/public.env` instead of secrets and `.env`; the server takes the display name from the published version file; the committed placeholder moves from the example environment file to that file.
- `mrpack-distribution`: export writes the display name into the version file; the publish comparison includes that name; the publish job skips instead of failing on the placeholder address; template copies publish by editing the file instead of setting secrets.

## Impact

- New file `config/public.env`.
- `scripts/lib.sh`, `scripts/pack-export.sh`, `scripts/pack-inspect.sh`, `scripts/pack-publish.sh`, `.github/workflows/ci.yml`, `.env.example`.
- `README.md`, `docs/admin-guide.md`, `docs/upgrade.md`, `docs/acceptance-checklist.md`, `AGENTS.md`.
- `compose.yaml` and `compose.staging.yaml` are not changed: they already read `SERVER_NAME` with the default `Cobblemon Server`.
- Template owners: one file to edit instead of two secrets. Existing copies: commit their values to `config/public.env` once; the next publish adds the name to the version file. Administrators: no change to the `COMPOSE_ENV_FILES` setting; a `SERVER_NAME` or `SERVER_PUBLIC_HOST` left in `.env` is no longer used.
- The public address is committed in clear text. It is already public inside the published pack.
