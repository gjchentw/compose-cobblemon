# Spec Delta

## ADDED Requirements

### Requirement: Server shows the display name its pack was built with
The server SHALL take the display name for its MOTD from the version file `dist/<pack>.env` that was written with the pack it installs, so the MOTD and the pack's pre-filled entry carry the name of the same build. A version file without a display name SHALL give the default display name that `game-requirements` declares.

#### Scenario: Name follows the published pack
- **WHEN** the display name in `config/public.env` is changed and merged, CI publishes the pack, and the deployment pulls and restarts
- **THEN** the MOTD starts with the new display name and the pulled pack's pre-filled entry starts with the same name

#### Scenario: Version file without a display name
- **WHEN** the server starts with a version file that holds only `PACK_VERSION`
- **THEN** the MOTD starts with the default display name

## MODIFIED Requirements

### Requirement: Display name
The deployer SHALL supply a display name for the server. It SHALL appear at the start of the MOTD, and the pre-filled server entry in the pack SHALL be named `<display name> (<pack version>)`. Without a supplied name, the default display name that `game-requirements` declares SHALL be used.

#### Scenario: Name in the server list
- **WHEN** a player who installed pack `2026.11.17-dbb7da6` opens the Multiplayer list
- **THEN** the pre-filled entry is named `<display name> (2026.11.17-dbb7da6)`, and the MOTD shown under it starts with the same display name and ends with the server's pack version

### Requirement: MOTD text
The production MOTD SHALL be `<display name> | Pack <running pack version>`, so players can tell whether their pack matches the server. The staging MOTD SHALL add the prefix `[STAGING] `.

#### Scenario: Production MOTD
- **WHEN** production runs pack version `2026.11.17-dbb7da6` with the display name `My Server`
- **THEN** the MOTD reads `My Server | Pack 2026.11.17-dbb7da6`

#### Scenario: Staging MOTD
- **WHEN** the staging stack runs
- **THEN** its MOTD starts with `[STAGING] `

### Requirement: Public information file
The display name and the public address SHALL be read from the committed file `config/public.env` (`SERVER_NAME` and `SERVER_PUBLIC_HOST`), by local pack builds and by CI alike. A value set in the environment of a pack build SHALL override the file for that build. Repository secrets, the deployment environment file and the committed example environment file SHALL NOT be sources for either value.

#### Scenario: Owner edits the file
- **WHEN** `config/public.env` sets `SERVER_NAME=My Server` and `SERVER_PUBLIC_HOST=mc.example.org` and a pack is built with neither variable in the environment
- **THEN** the pack's pre-filled entry is named `My Server (<pack version>)` and connects to `mc.example.org`

#### Scenario: Value left in the deployment environment file
- **WHEN** the deployment's `.env` sets `SERVER_PUBLIC_HOST=old.example.org` and a pack is built
- **THEN** the pack uses the address from `config/public.env`

#### Scenario: One-off override
- **WHEN** `SERVER_PUBLIC_HOST=mc.example.org:25566 scripts/pack-export.sh` runs
- **THEN** the built pack's entry connects to `mc.example.org:25566` and `config/public.env` is unchanged

## REMOVED Requirements

### Requirement: Server shows the published display name
**Reason**: One of its scenarios was named after this repository's history ("Version file from before this change"), and a MODIFIED block cannot rename a scenario. The behaviour is unchanged.
**Migration**: See "Server shows the display name its pack was built with", which states the same behaviour with the default display name taken from `game-requirements`.
