# mrpack-distribution Specification

## Purpose
Turns the packwiz pack source into a verified `.mrpack`, publishes it from `main` as one file behind a link that never changes, and guides players through installing and updating it. It assumes a packwiz pack whose mods are all downloaded from Modrinth's CDN, players on Modrinth App or Prism Launcher, and GitHub Actions in a public repository. It names no game: the mods, sides, versions, client settings files and the pack's base name come from `game-requirements`, and the display name and address from `public-server-info`.

## Requirements

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

### Requirement: Pre-filled server entry is generated at export
Export SHALL write into the pack one pre-filled server entry built from the display name, the pack version and the public address, as `public-server-info` defines. The committed `pack/` SHALL NOT contain that entry.

#### Scenario: Entry carries the configured identity
- **WHEN** a pack is exported with a display name and public address supplied
- **THEN** the pack's `servers.dat` holds exactly one entry named after the display name and the pack version, connecting to that address, and `pack/` has no `servers.dat`

### Requirement: Pack contents are exact
Inspection SHALL fail unless the pack contains exactly the index, the server entry `servers.dat` that export generates and the client settings files that `game-requirements` declares, and every download URL points to `cdn.modrinth.com`.

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

### Requirement: Client overrides match the source
Inspection SHALL fail unless every client settings file in the pack equals its committed source, the pack's `options.txt` starts with a numeric data version line, and its `servers.dat` parses with exactly one entry whose address equals the configured one and whose name is the configured display name followed by the pack version in parentheses.

#### Scenario: Swapped name and address
- **WHEN** the entry's name and address are swapped
- **THEN** inspection fails and names both fields

### Requirement: Pack checks on every push
CI SHALL check the version contract, export the pack with the version derived from the pushed commit and inspect it on every push and pull request.

#### Scenario: Branch push
- **WHEN** a commit is pushed to any branch
- **THEN** the version check, export and inspection run and the pack is kept as a build artifact

### Requirement: Least-privilege workflow
CI jobs SHALL run with a read-only repository token by default. Only the job that commits the pack to `main` SHALL get write access, and it SHALL run only for pushes to `main` of the repository itself. Checkouts SHALL NOT persist credentials; the job that commits the pack SHALL give its token only to the step that pushes.

#### Scenario: Pull request from a fork
- **WHEN** CI runs for a pull request from a fork
- **THEN** it has read-only access, the publishing job does not run, and the pack is built with placeholder public information

### Requirement: Template copies publish without local tooling
A repository created from this template SHALL publish its own pack after its owner commits the display name and the public address to `config/public.env` on `main`, without cloning the repository and without setting repository secrets.

#### Scenario: New template copy
- **WHEN** an owner creates a public repository from the template and commits their values to `config/public.env` on `main` in the web editor
- **THEN** CI commits a `dist/<pack>.mrpack` whose pre-filled entry points at that owner's server

### Requirement: Player install and update guide
The repository SHALL provide a pack install and update guide for players, in English and a Traditional Chinese copy with the same sections, that covers what players need, downloading the pack from the fixed link the administrator sends, installing it in Modrinth App or Prism Launcher, joining from the pre-filled entry, updating by installing the new pack as a new profile when the version in the entry's name differs from the version in the MOTD, and troubleshooting installing and joining.

#### Scenario: Updating after a server upgrade
- **WHEN** the MOTD shows a pack version different from the one in a player's pre-filled entry name
- **THEN** the guide tells the player to download the pack again from the same link and install it as a new profile, and states that progress lives on the server

### Requirement: Pack version format
A built pack's version SHALL be `YYYY.MM.DD-<commit>`, where the date is the UTC commit date and `<commit>` the first seven characters of the commit the pack was built from. The placeholder `0.0.0-dev` SHALL be the only other accepted version.

#### Scenario: Version from a commit
- **WHEN** a pack is built from commit `dbb7da6` committed on 2026-11-17 UTC
- **THEN** its internal version is `2026.11.17-dbb7da6`

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

### Requirement: Published packs never carry the placeholder address
The job that commits the pack to `main` SHALL publish nothing while the public address is empty or the placeholder `mc.example.com`: it SHALL finish successfully with a message naming `config/public.env`. Export SHALL refuse to build a pack for publishing with such an address.

#### Scenario: Main build without a configured address
- **WHEN** a push to `main` is built and the public address is the placeholder
- **THEN** the publish job reports that it skipped and why, succeeds, and no pack is committed

### Requirement: Pack version matches the expected version
Inspection SHALL fail unless the pack's internal version has the pack version format and, when an expected version is given, equals it.

#### Scenario: Wrong expected version
- **WHEN** a pack built as `2026.11.17-dbb7da6` is inspected with the expected version `2026.11.16-0000000`
- **THEN** inspection fails and names both versions

### Requirement: Install guide leaves game values to the play guide
The pack install and update guide SHALL NOT state what `game-requirements` declares (the game's memory, the PC's memory, the keys, the steps in the game). Where a player needs one of these, it SHALL link to the play guide.

#### Scenario: Memory before the first start
- **WHEN** a player following the install guide reaches the step before the first start
- **THEN** the guide links to the memory section of the play guide and states no memory figure itself

#### Scenario: A mod change that moves a key
- **WHEN** a change to the mod set changes a key or the recommended memory
- **THEN** only the play guide needs editing

### Requirement: Pack file names
The published pack SHALL be `dist/<pack>.mrpack` and its version file `dist/<pack>.env`, where `<pack>` is the pack's base name that `game-requirements` declares. Nothing else in this capability SHALL be named after the game.

#### Scenario: Files carry the declared base name
- **WHEN** the pack is exported
- **THEN** it is written to `dist/<pack>.mrpack` and `dist/<pack>.env`, with `<pack>` equal to the base name `game-requirements` declares

### Requirement: Tool containers see only what they need
Pack tooling and the linters SHALL see only the files their task needs. The tools container SHALL get `pack/` writable, `scripts/` and `dist/` read-only, and, for one run, only the temporary directory that run works in. Each linter SHALL see, read-only, only the files it checks and its configuration. Neither SHALL see the deployment environment file, world data, backups, staging copies or git metadata.

#### Scenario: Deployment secrets stay outside the tool containers
- **WHEN** the tools container or a linter runs in a deployment checkout whose `.env` holds the RCON password
- **THEN** `.env`, the world data, the backups, the staging copies and `.git` do not exist inside the container

#### Scenario: The tools container writes only the pack and its run's directory
- **WHEN** a pack tool runs in the tools container
- **THEN** it can write `pack/` and the temporary directory of that run, and cannot write `scripts/` or `dist/`

#### Scenario: A linter sees only its files
- **WHEN** a linter runs
- **THEN** its container holds, read-only, the files it checks and its configuration, and nothing else from the checkout
