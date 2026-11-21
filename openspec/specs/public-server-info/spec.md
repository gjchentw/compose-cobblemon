# public-server-info Specification

## Purpose
Defines the server information that is published to players and supplied by the deployer: the display name, the public address, the icon and the MOTD text, and where each value comes from. It names no game and assumes no platform of its own; the default display name comes from `game-requirements`.

## Requirements

### Requirement: Display name
The deployer SHALL supply a display name for the server. It SHALL appear at the start of the MOTD, and the pre-filled server entry in the pack SHALL be named `<display name> (<pack version>)`. Without a supplied name, `Cobblemon Server` SHALL be used.

#### Scenario: Name in the server list
- **WHEN** a player who installed pack `2026.11.17-dbb7da6` opens the Multiplayer list
- **THEN** the pre-filled entry is named `<display name> (2026.11.17-dbb7da6)`, and the MOTD shown under it starts with the same display name and ends with the server's pack version

### Requirement: Public address
The deployer SHALL supply the public address players connect to. It SHALL be the address of the pre-filled server entry. The template's `config/public.env` SHALL carry only the placeholder `mc.example.com`.

#### Scenario: Entry points at the server
- **WHEN** a pack is built with a public address supplied
- **THEN** its pre-filled entry connects to that address

### Requirement: Server icon
The server SHALL show the 64 x 64 PNG icon at `config/server-icon.png`. The repository SHALL ship a placeholder icon that deployers replace.

#### Scenario: Icon in the server list
- **WHEN** a client lists the running server
- **THEN** it shows the icon from `config/server-icon.png`

### Requirement: MOTD text
The production MOTD SHALL be `<display name> | Pack <running pack version>`, so players can tell whether their pack matches the server. The staging MOTD SHALL add the prefix `[STAGING] `.

#### Scenario: Production MOTD
- **WHEN** production runs pack version `2026.11.17-dbb7da6` with the display name `My Cobblemon World`
- **THEN** the MOTD reads `My Cobblemon World | Pack 2026.11.17-dbb7da6`

#### Scenario: Staging MOTD
- **WHEN** the staging stack runs
- **THEN** its MOTD starts with `[STAGING] `

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
