# Spec Delta

## MODIFIED Requirements

### Requirement: Export builds a versioned pack from a copy
Export SHALL build `dist/cobblemon.mrpack` from a copy of `pack/` with the version substituted, without modifying `pack/`, and SHALL write `dist/cobblemon.env` holding `PACK_VERSION=<version>` for the same version and `SERVER_NAME` with the display name the pack was built with, and nothing else. Without a version argument it SHALL use the version derived from the checked-out commit. It SHALL reject a version in another format, and an explicitly empty one. It SHALL reject a display name that cannot be written to the version file unchanged.

#### Scenario: Release version build
- **WHEN** `scripts/pack-export.sh 2026.11.17-dbb7da6` runs with the display name `My Cobblemon World`
- **THEN** `dist/cobblemon.mrpack` exists with internal version `2026.11.17-dbb7da6`, `dist/cobblemon.env` sets `PACK_VERSION` to `2026.11.17-dbb7da6` and `SERVER_NAME` to `My Cobblemon World`, and `git status` shows `pack/` unchanged

#### Scenario: Default version
- **WHEN** `scripts/pack-export.sh` runs without a version on a checkout of commit `dbb7da6` committed on 2026-11-17 UTC
- **THEN** the pack's internal version is `2026.11.17-dbb7da6`

#### Scenario: Malformed version
- **WHEN** `scripts/pack-export.sh 1.2` runs
- **THEN** export fails without writing a pack or a version file

#### Scenario: Display name with a quote character
- **WHEN** export runs with a display name that contains a single quote or a line break
- **THEN** export fails with a message naming the display name, without writing a pack or a version file

### Requirement: Every change on main republishes the pack
On every push to `main`, CI SHALL build the pack for the pushed commit and compare its contents, ignoring the version, with the committed `dist/cobblemon.mrpack`, and the display name it was built with against the one in the committed `dist/cobblemon.env`. When either differs, CI SHALL commit the new pack and its version file to `main` in one commit whose message names the version and skips CI. When both are equal, nothing SHALL be committed.

#### Scenario: A mod change is merged
- **WHEN** a commit that changes `pack/` is pushed to `main`
- **THEN** CI commits a new `dist/cobblemon.mrpack` and a `dist/cobblemon.env` naming the version derived from that commit, and the bot commit does not start another CI run

#### Scenario: A documentation change is merged
- **WHEN** a commit that changes only documentation is pushed to `main`
- **THEN** the rebuilt pack has the same contents as the committed one and nothing is committed

#### Scenario: Version file without the display name
- **WHEN** a push to `main` is built, the pack's contents equal the committed pack, and the committed version file has no display name
- **THEN** CI commits the pack and a version file that carries the display name

### Requirement: Published packs never carry the placeholder address
The job that commits the pack to `main` SHALL publish nothing while the public address is empty or the placeholder `mc.example.com`: it SHALL finish successfully with a message naming `config/public.env`. Export SHALL refuse to build a pack for publishing with such an address.

#### Scenario: Main build without a configured address
- **WHEN** a push to `main` is built and the public address is the placeholder
- **THEN** the publish job reports that it skipped and why, succeeds, and no pack is committed

### Requirement: Template copies release without local tooling
A repository created from this template SHALL publish its own pack after its owner commits the display name and the public address to `config/public.env` on `main`, without cloning the repository and without setting repository secrets.

#### Scenario: New template copy
- **WHEN** an owner creates a public repository from the template and commits their values to `config/public.env` on `main` in the web editor
- **THEN** CI commits a `dist/cobblemon.mrpack` whose pre-filled entry points at that owner's server
