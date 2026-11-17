# Spec Delta

## MODIFIED Requirements

### Requirement: Display name
The deployer SHALL supply a display name for the server. It SHALL appear at the start of the MOTD, and the pre-filled server entry in the pack SHALL be named `<display name> (<pack version>)`. Without a supplied name, `Cobblemon Server` SHALL be used.

#### Scenario: Name in the server list
- **WHEN** a player who installed pack `2026.11.17-dbb7da6` opens the Multiplayer list
- **THEN** the pre-filled entry is named `<display name> (2026.11.17-dbb7da6)`, and the MOTD shown under it starts with the same display name and ends with the server's pack version

### Requirement: MOTD text
The production MOTD SHALL be `<display name> | Pack <running pack version>`, so players can tell whether their pack matches the server. The staging MOTD SHALL add the prefix `[STAGING] `.

#### Scenario: Production MOTD
- **WHEN** production runs pack version `2026.11.17-dbb7da6` with the display name `My Cobblemon World`
- **THEN** the MOTD reads `My Cobblemon World | Pack 2026.11.17-dbb7da6`

#### Scenario: Staging MOTD
- **WHEN** the staging stack runs
- **THEN** its MOTD starts with `[STAGING] `
