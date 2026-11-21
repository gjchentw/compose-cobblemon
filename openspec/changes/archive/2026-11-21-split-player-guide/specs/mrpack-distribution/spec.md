# Spec Delta

## MODIFIED Requirements

### Requirement: Player install and update guide
The repository SHALL provide a pack install and update guide for players, in English and a Traditional Chinese copy with the same sections, that covers what players need, downloading the pack from the fixed link the administrator sends, installing it in Modrinth App or Prism Launcher, joining from the pre-filled entry, updating by installing the new pack as a new profile when the version in the entry's name differs from the version in the MOTD, and troubleshooting installing and joining.

#### Scenario: Updating after a server upgrade
- **WHEN** the MOTD shows a pack version different from the one in a player's pre-filled entry name
- **THEN** the guide tells the player to download the pack again from the same link and install it as a new profile, and states that progress lives on the server

## ADDED Requirements

### Requirement: Install guide leaves game values to the play guide
The pack install and update guide SHALL NOT state what `game-requirements` declares (the game's memory, the PC's memory, the keys, the steps in the game). Where a player needs one of these, it SHALL link to the play guide.

#### Scenario: Memory before the first start
- **WHEN** a player following the install guide reaches the step before the first start
- **THEN** the guide links to the memory section of the play guide and states no memory figure itself

#### Scenario: A mod change that moves a key
- **WHEN** a change to the mod set changes a key or the recommended memory
- **THEN** only the play guide needs editing
