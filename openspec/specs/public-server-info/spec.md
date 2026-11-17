# public-server-info Specification

## Purpose
Defines the server information that is published to players and supplied by the deployer: the display name, the public address, the icon and the MOTD text, and where each value comes from.

## Requirements

### Requirement: Display name
The deployer SHALL supply a display name for the server. It SHALL appear at the start of the MOTD and as the name of the pre-filled server entry in the pack. Without a supplied name, `Cobblemon Server` SHALL be used.

#### Scenario: Name in the server list
- **WHEN** a player who installed the pack opens the Multiplayer list
- **THEN** the pre-filled entry carries the display name, and the MOTD shown under it starts with the same name

### Requirement: Public address
The deployer SHALL supply the public address players connect to. It SHALL be the address of the pre-filled server entry. The committed example SHALL carry only the placeholder `mc.example.com`.

#### Scenario: Entry points at the server
- **WHEN** a release pack is built with a public address supplied
- **THEN** its pre-filled entry connects to that address

### Requirement: Server icon
The server SHALL show the 64 x 64 PNG icon at `config/server-icon.png`. The repository SHALL ship a placeholder icon that deployers replace.

#### Scenario: Icon in the server list
- **WHEN** a client lists the running server
- **THEN** it shows the icon from `config/server-icon.png`

### Requirement: MOTD text
The production MOTD SHALL be `<display name> | Pack <running pack version>`, so players can tell whether their pack matches the server. The staging MOTD SHALL add the prefix `[STAGING] `.

#### Scenario: Production MOTD
- **WHEN** production runs pack version `1.0.1` with the display name `My Cobblemon World`
- **THEN** the MOTD reads `My Cobblemon World | Pack 1.0.1`

#### Scenario: Staging MOTD
- **WHEN** the staging stack runs
- **THEN** its MOTD starts with `[STAGING] `

### Requirement: Where the values come from
The server SHALL read the display name from the deployment environment file. Pack builds SHALL take the display name and public address from the environment first (in CI, the repository secrets `SERVER_NAME` and `SERVER_PUBLIC_HOST`), then the deployment environment file, then the committed example.

#### Scenario: Secrets unset in CI
- **WHEN** a branch build runs without the two secrets
- **THEN** the pack is built with the placeholder values from the committed example

#### Scenario: Secrets set in CI
- **WHEN** a release build runs with both secrets set
- **THEN** the pack's pre-filled entry uses the secret values
