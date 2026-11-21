# Spec Delta

## ADDED Requirements

### Requirement: Pack identity
The pack SHALL be named `Cobblemon Pack`. Its published file SHALL have the base name `cobblemon`; `mrpack-distribution` and `compose-services` write that name as `<pack>` in `dist/<pack>.mrpack` and `dist/<pack>.env`. A server whose deployer supplies no display name SHALL be called `Cobblemon Server`.

#### Scenario: Pack name
- **WHEN** the pack is exported
- **THEN** its index carries the name `Cobblemon Pack`

#### Scenario: Published file names
- **WHEN** the pack is published
- **THEN** the files are `dist/cobblemon.mrpack` and `dist/cobblemon.env`

#### Scenario: Default display name
- **WHEN** no display name is supplied
- **THEN** the MOTD starts with `Cobblemon Server`

## MODIFIED Requirements

### Requirement: Client defaults
The pack SHALL carry exactly one client settings file of its own, `options.txt`. It SHALL set render distance 10, simulation distance 6, entity distance 75 %, decreased particles, biome blend 2, fast clouds and a 120 FPS limit, and start with the data version line of the Minecraft version (`version:3955` for 1.21.1).

#### Scenario: Fresh profile
- **WHEN** a player installs the pack into a new profile and starts the game
- **THEN** these options are in effect

#### Scenario: Settings files the pack carries
- **WHEN** the pack is inspected
- **THEN** `options.txt` is the only client settings file accepted besides the server entry that export generates

### Requirement: Client memory guidance
Players SHALL be told, in the play guide, to give the game 4 GB of memory at minimum and 6 GB as recommended, and not more than 8 GB.

#### Scenario: Memory section
- **WHEN** a player reads the play guide
- **THEN** it states these limits and where to set them in each launcher the pack install and update guide covers

### Requirement: Gameplay acceptance checklist
The gameplay items of the player acceptance run that `compose-services` defines SHALL be: Pokémon spawn, starter selection, catch, battle, trade, ride, and death and respawn.

#### Scenario: Release sign-off
- **WHEN** a branch that changes the pack or the stack is accepted, which releases it
- **THEN** all seven gameplay items pass on staging before the merge and on production after the deployment
