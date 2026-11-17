# Spec Delta

## Purpose

Turns the packwiz pack source into a verified `.mrpack`, builds and publishes it as a downloadable file for each GitHub release, and guides players through installing and updating it.

## ADDED Requirements

### Requirement: Pack source and tooling
The pack source SHALL be a packwiz pack in `pack/`. Pack tooling SHALL run from a tools image built from a pinned packwiz commit, as the host user, so the host needs only Docker and bash.

#### Scenario: Tooling runs without host installs
- **WHEN** the tools image is built and packwiz is run through it on a host with only Docker and bash
- **THEN** packwiz runs, and files it writes are owned by the host user

### Requirement: Pack source stays consistent
Running `packwiz refresh` on `pack/` SHALL leave it unchanged. Only `pack.toml` and a mod's `side` field may be edited by hand, followed by a refresh.

#### Scenario: Refresh is a no-op
- **WHEN** CI runs `packwiz refresh` on a pushed commit
- **THEN** `git diff --exit-code pack/` passes

### Requirement: Git holds only the placeholder version
`pack/pack.toml` and the committed example environment file SHALL carry the placeholder version `0.0.0-dev`. A release version SHALL exist only in a tag and in the pack built for it.

#### Scenario: Release version committed by mistake
- **WHEN** `pack/pack.toml` holds a release version and `scripts/version-check.sh` runs
- **THEN** the check fails and says that git must hold only the placeholder

### Requirement: Export builds a versioned pack from a copy
Export SHALL build `dist/cobblemon-<version>.mrpack` from a copy of `pack/` with the given version substituted, without modifying `pack/`. Without a version it SHALL build the placeholder version. It SHALL reject a version that is not `X.Y.Z` or `X.Y.Z-rc.N`, and an explicitly empty one.

#### Scenario: Release version build
- **WHEN** `scripts/pack-export.sh 9.8.7` runs
- **THEN** `dist/cobblemon-9.8.7.mrpack` exists with internal version `9.8.7`, and `git status` shows `pack/` unchanged

#### Scenario: Malformed version
- **WHEN** `scripts/pack-export.sh 1.2` runs
- **THEN** export fails without writing a pack

### Requirement: Pre-filled server entry is generated at export
Export SHALL write into the pack one pre-filled server entry built from the display name and public address that `public-server-info` defines. The committed `pack/` SHALL NOT contain that entry.

#### Scenario: Entry carries the configured identity
- **WHEN** a pack is exported with a display name and public address supplied
- **THEN** the pack's `servers.dat` holds exactly one entry with that name and address, and `pack/` has no `servers.dat`

### Requirement: Releases never carry the placeholder address
A release build SHALL refuse to export while the public address is empty or the placeholder `mc.example.com`.

#### Scenario: Release without a configured address
- **WHEN** a release build runs and the public address is the placeholder
- **THEN** export fails with a message naming the missing setting, and no pack is attached

### Requirement: Pack contents are exact
Inspection SHALL fail unless the pack contains exactly the index and the two client overrides `options.txt` and `servers.dat`, and every download URL points to `cdn.modrinth.com`.

#### Scenario: Unexpected file in the pack
- **WHEN** a pack contains an extra override or a download from another host
- **THEN** `scripts/pack-inspect.sh` fails and names it

### Requirement: Pack matches its source
Inspection SHALL fail unless every mod file in `pack/` appears exactly once in the pack index under its exact file name, with the client and server markers its side requires, no other mod appears, and the Minecraft and loader pins equal those in `pack.toml`. The expected sides come from the side table `game-requirements` declares.

#### Scenario: Version drift
- **WHEN** a mod in the index has a different file name than its source entry, or the loader pin differs
- **THEN** inspection fails and names the mod or the pin

#### Scenario: Wrong side
- **WHEN** a client-only mod is marked as required on the server
- **THEN** inspection fails and names the mod

### Requirement: Pack version matches its file name
Inspection SHALL take the expected version from the file name `cobblemon-<version>.mrpack` and fail unless the pack's internal version equals it.

#### Scenario: Renamed pack
- **WHEN** a pack built as version 9.8.7 is renamed to `cobblemon-1.2.3.mrpack`
- **THEN** inspection fails and names both versions

### Requirement: Client overrides match the source
Inspection SHALL fail unless the pack's `options.txt` equals the committed one and starts with a numeric data version line, and its `servers.dat` parses with exactly one entry whose name and address equal the configured ones.

#### Scenario: Swapped name and address
- **WHEN** the entry's name and address are swapped
- **THEN** inspection fails and names both fields

### Requirement: Publishing a release builds and attaches the pack
Publishing a GitHub release with a new tag `vX.Y.Z` or `vX.Y.Z-rc.N` SHALL build the pack for that version, inspect it and attach `cobblemon-X.Y.Z.mrpack` to that release. A tag pushed without a release SHALL build nothing, and a tag in another format SHALL fail the build.

#### Scenario: Release published from the web interface
- **WHEN** a maintainer publishes release `v1.0.1` on `main` from the Releases page
- **THEN** within minutes the release carries `cobblemon-1.0.1.mrpack` with internal version `1.0.1`

### Requirement: Release candidates are pre-releases
A release whose tag contains `-rc.` SHALL be marked as a pre-release by a job that does not wait for the pack build.

#### Scenario: Checkbox forgotten
- **WHEN** `v1.0.0-rc.5` is published without the pre-release checkbox
- **THEN** CI marks it as a pre-release before the build finishes, and it does not become the latest release

### Requirement: Release notes describe the pack
The release build SHALL append, once, a table with the pack, Minecraft, Fabric loader, Cobblemon and server image versions, and a line telling players which file to install and administrators how to deploy it, keeping the publisher's text.

#### Scenario: Re-run does not duplicate the table
- **WHEN** the release job runs a second time for the same release
- **THEN** the notes still contain one contents table, and the attached pack is replaced by the new build

### Requirement: Pack checks on every push
CI SHALL check the version contract, export the placeholder pack and inspect it on every push and pull request.

#### Scenario: Branch push
- **WHEN** a commit is pushed to any branch
- **THEN** the version check, export and inspection run and the pack is kept as a build artifact

### Requirement: Least-privilege workflow
CI jobs SHALL run with a read-only repository token by default; only the release jobs SHALL get write access. Checkouts SHALL NOT persist credentials.

#### Scenario: Pull request from a fork
- **WHEN** CI runs for a pull request from a fork
- **THEN** it has read-only access, no publishing job runs, and the pack is built with placeholder public information

### Requirement: Template copies release without local tooling
A repository created from this template SHALL be able to publish its own pack after its owner sets the public server information secrets and publishes a release, without cloning the repository.

#### Scenario: New template copy
- **WHEN** an owner creates a repository from the template, adds the two secrets and publishes `v1.0.0`
- **THEN** CI attaches a pack whose pre-filled entry points at that owner's server

### Requirement: Player install and update guide
The repository SHALL provide a player guide, in English and a Traditional Chinese copy with the same sections, that covers what players need, downloading the pack from the link the administrator sends, installing it in Modrinth App or Prism Launcher, updating by installing a new version as a new profile, and troubleshooting.

#### Scenario: Updating after a server upgrade
- **WHEN** the MOTD shows a pack version different from the one a player installed
- **THEN** the guide tells the player to install the new pack as a new profile, and states that progress lives on the server
