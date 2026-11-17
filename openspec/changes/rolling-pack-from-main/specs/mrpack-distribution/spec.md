# Spec Delta

## ADDED Requirements

### Requirement: Pack version format
A built pack's version SHALL be `YYYY.MM.DD-<commit>`, where the date is the UTC commit date and `<commit>` the first seven characters of the commit the pack was built from. The placeholder `0.0.0-dev` SHALL be the only other accepted version.

#### Scenario: Version from a commit
- **WHEN** a pack is built from commit `dbb7da6` committed on 2026-11-17 UTC
- **THEN** its internal version is `2026.11.17-dbb7da6`

### Requirement: Every change on main republishes the pack
On every push to `main`, CI SHALL build the pack for the pushed commit and compare its contents, ignoring the version, with the committed `dist/cobblemon.mrpack`. When they differ, CI SHALL commit the new pack and its version file to `main` in one commit whose message names the version and skips CI. When they are equal, nothing SHALL be committed.

#### Scenario: A mod change is merged
- **WHEN** a commit that changes `pack/` is pushed to `main`
- **THEN** CI commits a new `dist/cobblemon.mrpack` and a `dist/cobblemon.env` naming the version derived from that commit, and the bot commit does not start another CI run

#### Scenario: A documentation change is merged
- **WHEN** a commit that changes only documentation is pushed to `main`
- **THEN** the rebuilt pack has the same contents as the committed one and nothing is committed

### Requirement: Fixed download link
Players SHALL download the current pack from one link that never changes: the raw file `dist/cobblemon.mrpack` on `main`. The repository SHALL be public for the link to work.

#### Scenario: Link serves the new pack
- **WHEN** CI has committed a new pack to `main`
- **THEN** the raw link of `dist/cobblemon.mrpack` on `main` serves it within the host's cache time

### Requirement: Published packs never carry the placeholder address
The build that commits the pack to `main` SHALL refuse to export while the public address is empty or the placeholder `mc.example.com`.

#### Scenario: Main build without a configured address
- **WHEN** a push to `main` is built and the public address is the placeholder
- **THEN** export fails with a message naming the missing setting, and no pack is committed

### Requirement: Pack version matches the expected version
Inspection SHALL fail unless the pack's internal version has the pack version format and, when an expected version is given, equals it.

#### Scenario: Wrong expected version
- **WHEN** a pack built as `2026.11.17-dbb7da6` is inspected with the expected version `2026.11.16-0000000`
- **THEN** inspection fails and names both versions

## MODIFIED Requirements

### Requirement: Git holds only the placeholder version
`pack/pack.toml` SHALL carry the placeholder version `0.0.0-dev`, and the committed example environment file SHALL NOT set `PACK_VERSION`. A real version SHALL exist only in a built pack and its version file in `dist/`, derived from the commit the pack was built from and committed only by CI.

#### Scenario: Release version committed by mistake
- **WHEN** `pack/pack.toml` holds any version other than the placeholder and `scripts/version-check.sh` runs
- **THEN** the check fails and says that git must hold only the placeholder

#### Scenario: Version in the example environment file
- **WHEN** `.env.example` sets `PACK_VERSION` and `scripts/version-check.sh` runs
- **THEN** the check fails and says that the version comes from `dist/cobblemon.env`

### Requirement: Export builds a versioned pack from a copy
Export SHALL build `dist/cobblemon.mrpack` from a copy of `pack/` with the version substituted, without modifying `pack/`, and SHALL write `dist/cobblemon.env` holding only `PACK_VERSION=<version>` for the same version. Without a version argument it SHALL use the version derived from the checked-out commit. It SHALL reject a version in another format, and an explicitly empty one.

#### Scenario: Release version build
- **WHEN** `scripts/pack-export.sh 2026.11.17-dbb7da6` runs
- **THEN** `dist/cobblemon.mrpack` exists with internal version `2026.11.17-dbb7da6`, `dist/cobblemon.env` reads `PACK_VERSION=2026.11.17-dbb7da6`, and `git status` shows `pack/` unchanged

#### Scenario: Default version
- **WHEN** `scripts/pack-export.sh` runs without a version on a checkout of commit `dbb7da6` committed on 2026-11-17 UTC
- **THEN** the pack's internal version is `2026.11.17-dbb7da6`

#### Scenario: Malformed version
- **WHEN** `scripts/pack-export.sh 1.2` runs
- **THEN** export fails without writing a pack or a version file

### Requirement: Pre-filled server entry is generated at export
Export SHALL write into the pack one pre-filled server entry built from the display name, the pack version and the public address, as `public-server-info` defines. The committed `pack/` SHALL NOT contain that entry.

#### Scenario: Entry carries the configured identity
- **WHEN** a pack is exported with a display name and public address supplied
- **THEN** the pack's `servers.dat` holds exactly one entry named after the display name and the pack version, connecting to that address, and `pack/` has no `servers.dat`

### Requirement: Client overrides match the source
Inspection SHALL fail unless the pack's `options.txt` equals the committed one and starts with a numeric data version line, and its `servers.dat` parses with exactly one entry whose address equals the configured one and whose name is the configured display name followed by the pack version in parentheses.

#### Scenario: Swapped name and address
- **WHEN** the entry's name and address are swapped
- **THEN** inspection fails and names both fields

### Requirement: Pack checks on every push
CI SHALL check the version contract, export the pack with the version derived from the pushed commit and inspect it on every push and pull request.

#### Scenario: Branch push
- **WHEN** a commit is pushed to any branch
- **THEN** the version check, export and inspection run and the pack is kept as a build artifact

### Requirement: Least-privilege workflow
CI jobs SHALL run with a read-only repository token by default. Only the job that commits the pack to `main` SHALL get write access, and it SHALL run only for pushes to `main` of the repository itself. Checkouts SHALL NOT persist credentials, except in that job, which needs them to push.

#### Scenario: Pull request from a fork
- **WHEN** CI runs for a pull request from a fork
- **THEN** it has read-only access, the publishing job does not run, and the pack is built with placeholder public information

### Requirement: Template copies release without local tooling
A repository created from this template SHALL publish its own pack after its owner sets the public server information secrets and pushes any commit to `main`, without cloning the repository.

#### Scenario: New template copy
- **WHEN** an owner creates a public repository from the template, adds the two secrets and commits any edit to `main` in the web editor
- **THEN** CI commits a `dist/cobblemon.mrpack` whose pre-filled entry points at that owner's server

### Requirement: Player install and update guide
The repository SHALL provide a player guide, in English and a Traditional Chinese copy with the same sections, that covers what players need, downloading the pack from the fixed link the administrator sends, installing it in Modrinth App or Prism Launcher, updating by installing the new pack as a new profile when the version in the pre-filled entry's name differs from the version in the MOTD, and troubleshooting.

#### Scenario: Updating after a server upgrade
- **WHEN** the MOTD shows a pack version different from the one in a player's pre-filled entry name
- **THEN** the guide tells the player to download the pack again from the same link and install it as a new profile, and states that progress lives on the server

## REMOVED Requirements

### Requirement: Publishing a release builds and attaches the pack
**Reason**: Releases are replaced by the rolling build on `main`; merging is the release.
**Migration**: Merge to `main`. CI commits `dist/cobblemon.mrpack`; players use the fixed link. Existing GitHub releases stay as they are.

### Requirement: Release candidates are pre-releases
**Reason**: There are no release candidates; candidates are accepted on staging from their branch before the merge.
**Migration**: Run the branch on staging as `compose-services` describes.

### Requirement: Release notes describe the pack
**Reason**: There are no release pages. The bot commit names the version, and `pack/` at that commit shows the contents.
**Migration**: Read the bot commit and `pack/` in the git history.

### Requirement: Releases never carry the placeholder address
**Reason**: Replaced by "Published packs never carry the placeholder address", which guards the build that commits to `main`.
**Migration**: None.

### Requirement: Pack version matches its file name
**Reason**: The file name no longer carries the version.
**Migration**: Replaced by "Pack version matches the expected version".
