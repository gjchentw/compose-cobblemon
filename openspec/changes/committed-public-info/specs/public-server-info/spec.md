# Spec Delta

## ADDED Requirements

### Requirement: Public information file
The display name and the public address SHALL be read from the committed file `config/public.env` (`SERVER_NAME` and `SERVER_PUBLIC_HOST`), by local pack builds and by CI alike. A value set in the environment of a pack build SHALL override the file for that build. Repository secrets, the deployment environment file and the committed example environment file SHALL NOT be sources for either value.

#### Scenario: Owner edits the file
- **WHEN** `config/public.env` sets `SERVER_NAME=My Cobblemon World` and `SERVER_PUBLIC_HOST=mc.example.org` and a pack is built with neither variable in the environment
- **THEN** the pack's pre-filled entry is named `My Cobblemon World (<pack version>)` and connects to `mc.example.org`

#### Scenario: Value left in the deployment environment file
- **WHEN** the deployment's `.env` sets `SERVER_PUBLIC_HOST=old.example.org` and a pack is built
- **THEN** the pack uses the address from `config/public.env`

#### Scenario: One-off override
- **WHEN** `SERVER_PUBLIC_HOST=mc.example.org:25566 scripts/pack-export.sh` runs
- **THEN** the built pack's entry connects to `mc.example.org:25566` and `config/public.env` is unchanged

### Requirement: Server shows the published display name
The server SHALL take the display name for its MOTD from the version file `dist/cobblemon.env` that was written with the pack it installs, so the MOTD and the pack's pre-filled entry carry the name of the same build. A version file without a display name SHALL give `Cobblemon Server`.

#### Scenario: Name follows the published pack
- **WHEN** the display name in `config/public.env` is changed and merged, CI publishes the pack, and the deployment pulls and restarts
- **THEN** the MOTD starts with the new display name and the pulled pack's pre-filled entry starts with the same name

#### Scenario: Version file from before this change
- **WHEN** the server starts with a version file that holds only `PACK_VERSION`
- **THEN** the MOTD starts with `Cobblemon Server`

## MODIFIED Requirements

### Requirement: Public address
The deployer SHALL supply the public address players connect to. It SHALL be the address of the pre-filled server entry. The template's `config/public.env` SHALL carry only the placeholder `mc.example.com`.

#### Scenario: Entry points at the server
- **WHEN** a pack is built with a public address supplied
- **THEN** its pre-filled entry connects to that address

## REMOVED Requirements

### Requirement: Where the values come from
**Reason**: The environment file and the repository secrets are replaced by one committed file; two sources could disagree.
**Migration**: Put the two values in `config/public.env` and commit; delete the repository secrets and the two lines in `.env`. See "Public information file".
