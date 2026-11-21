# Spec Delta

## ADDED Requirements

### Requirement: Pack file names
The published pack SHALL be `dist/<pack>.mrpack` and its version file `dist/<pack>.env`, where `<pack>` is the pack's base name that `game-requirements` declares. Nothing else in this capability SHALL be named after the game.

#### Scenario: Files carry the declared base name
- **WHEN** the pack is exported
- **THEN** it is written to `dist/<pack>.mrpack` and `dist/<pack>.env`, with `<pack>` equal to the base name `game-requirements` declares

## RENAMED Requirements

- FROM: `### Requirement: Template copies release without local tooling`
- TO: `### Requirement: Template copies publish without local tooling`

## MODIFIED Requirements

### Requirement: Git holds only the placeholder version
`pack/pack.toml` SHALL carry the placeholder version `0.0.0-dev`, and the committed example environment file SHALL NOT set `PACK_VERSION`. A real version SHALL exist only in a built pack and its version file in `dist/`, derived from the commit the pack was built from and committed only by CI.

#### Scenario: Release version committed by mistake
- **WHEN** `pack/pack.toml` holds any version other than the placeholder and `scripts/version-check.sh` runs
- **THEN** the check fails and says that git must hold only the placeholder

#### Scenario: Version in the example environment file
- **WHEN** `.env.example` sets `PACK_VERSION` and `scripts/version-check.sh` runs
- **THEN** the check fails and says that the version comes from `dist/<pack>.env`

### Requirement: Export builds a versioned pack from a copy
Export SHALL build `dist/<pack>.mrpack` from a copy of `pack/` with the version substituted, without modifying `pack/`, and SHALL write `dist/<pack>.env` holding only `PACK_VERSION=<version>` and `SERVER_NAME`, the display name the pack was built with. Without a version argument it SHALL use the checked-out commit's version. It SHALL reject a version in another format, an explicitly empty one, and a display name that cannot be written to the version file unchanged.

#### Scenario: Release version build
- **WHEN** `scripts/pack-export.sh 2026.11.17-dbb7da6` runs with the display name `My Server`
- **THEN** `dist/<pack>.mrpack` exists with internal version `2026.11.17-dbb7da6`, `dist/<pack>.env` sets `PACK_VERSION` to `2026.11.17-dbb7da6` and `SERVER_NAME` to `My Server`, and `git status` shows `pack/` unchanged

#### Scenario: Default version
- **WHEN** `scripts/pack-export.sh` runs without a version on a checkout of commit `dbb7da6` committed on 2026-11-17 UTC
- **THEN** the pack's internal version is `2026.11.17-dbb7da6`

#### Scenario: Malformed version
- **WHEN** `scripts/pack-export.sh 1.2` runs
- **THEN** export fails without writing a pack or a version file

#### Scenario: Display name with a quote character
- **WHEN** export runs with a display name that contains a single quote or a line break
- **THEN** export fails with a message naming the display name, without writing a pack or a version file

### Requirement: Pack contents are exact
Inspection SHALL fail unless the pack contains exactly the index, the server entry `servers.dat` that export generates and the client settings files that `game-requirements` declares, and every download URL points to `cdn.modrinth.com`.

#### Scenario: Unexpected file in the pack
- **WHEN** a pack contains an extra override or a download from another host
- **THEN** `scripts/pack-inspect.sh` fails and names it

### Requirement: Client overrides match the source
Inspection SHALL fail unless every client settings file in the pack equals its committed source, the pack's `options.txt` starts with a numeric data version line, and its `servers.dat` parses with exactly one entry whose address equals the configured one and whose name is the configured display name followed by the pack version in parentheses.

#### Scenario: Swapped name and address
- **WHEN** the entry's name and address are swapped
- **THEN** inspection fails and names both fields

### Requirement: Template copies publish without local tooling
A repository created from this template SHALL publish its own pack after its owner commits the display name and the public address to `config/public.env` on `main`, without cloning the repository and without setting repository secrets.

#### Scenario: New template copy
- **WHEN** an owner creates a public repository from the template and commits their values to `config/public.env` on `main` in the web editor
- **THEN** CI commits a `dist/<pack>.mrpack` whose pre-filled entry points at that owner's server

### Requirement: Every change on main republishes the pack
On every push to `main`, CI SHALL build the pack for the pushed commit and compare its contents, ignoring the version, with the committed `dist/<pack>.mrpack`, and the display name it was built with against the one in the committed `dist/<pack>.env`. When either differs, CI SHALL commit the new pack and its version file to `main` in one commit whose message names the version and skips CI. When both are equal, nothing SHALL be committed.

#### Scenario: A mod change is merged
- **WHEN** a commit that changes `pack/` is pushed to `main`
- **THEN** CI commits a new `dist/<pack>.mrpack` and a `dist/<pack>.env` naming the version derived from that commit, and the bot commit does not start another CI run

#### Scenario: A documentation change is merged
- **WHEN** a commit that changes only documentation is pushed to `main`
- **THEN** the rebuilt pack has the same contents as the committed one and nothing is committed

#### Scenario: Version file without the display name
- **WHEN** a push to `main` is built, the pack's contents equal the committed pack, and the committed version file has no display name
- **THEN** CI commits the pack and a version file that carries the display name

### Requirement: Fixed download link
Players SHALL download the current pack from one link that never changes: the raw file `dist/<pack>.mrpack` on `main`. The repository SHALL be public for the link to work.

#### Scenario: Link serves the new pack
- **WHEN** CI has committed a new pack to `main`
- **THEN** the raw link of `dist/<pack>.mrpack` on `main` serves it within the host's cache time
