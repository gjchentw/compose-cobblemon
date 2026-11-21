# game-requirements Specification

## Purpose
Declares the values the game dictates, which change when the mod set changes: the pack's identity, the mods and their sides, the Minecraft, loader, Cobblemon and Java versions, the server's gameplay defaults and heap, the client settings files and their defaults, what players are taught, and the gameplay items of the acceptance run. It is the only capability to rewrite for another mod pack; the other three take every game value from here.

## Requirements

### Requirement: Game platform versions
The game SHALL be Minecraft 1.21.1 on the Fabric loader 0.20.1 with Cobblemon 1.8.4.

#### Scenario: Pack pins the platform
- **WHEN** the pack is exported
- **THEN** its index pins Minecraft `1.21.1` and `fabric-loader` `0.20.1`, and it contains `Cobblemon-fabric-1.8.4+1.21.1.jar`

### Requirement: Mod set and sides
The pack SHALL contain exactly these mods with these sides. Both sides: Cobblemon, Fabric API, Lithium, FerriteCore, AppleSkin. Client only: Sodium, ImmediatelyFast, Entity Culling, Mod Menu, Text Placeholder API (required by Mod Menu), EMI, Xaero's Minimap, Xaero's World Map, Mouse Tweaks.

#### Scenario: Server installs five mods
- **WHEN** the server installs the server side of the pack
- **THEN** it installs exactly Cobblemon, Fabric API, Lithium, FerriteCore and AppleSkin

#### Scenario: Side table is the inspection reference
- **WHEN** the pack is inspected
- **THEN** the side of every mod is checked against this table, and a mod missing from it or present only in it fails inspection

### Requirement: Java 21 exactly
The server and the players' launchers SHALL run Java 21, because Cobblemon 1.8.4 refuses any other major version.

#### Scenario: Server JVM
- **WHEN** the smoke check queries the server's JVM
- **THEN** it reports version 21

#### Scenario: Wrong Java on a client
- **WHEN** a client starts the pack on Java 23
- **THEN** Fabric refuses to load Cobblemon and names Java 21 as the requirement

### Requirement: Key mod is loaded
The server SHALL load Cobblemon at the version the pack pins; this is the mod the smoke check uses to tell that the game, not just Minecraft, is running.

#### Scenario: Boot log lists Cobblemon
- **WHEN** the server finishes starting
- **THEN** Fabric's mod list in the boot log contains `cobblemon` at the pinned version

### Requirement: Server gameplay defaults
Unless the deployment overrides them, the server SHALL run with a 6 GB heap, at most 12 players, view distance 10, simulation distance 6, normal difficulty, survival mode and PvP off. A host with 8 GB of RAM SHALL use a 4 GB heap.

#### Scenario: Defaults applied
- **WHEN** the deployment environment file sets none of these values
- **THEN** the server runs with exactly these defaults

### Requirement: Client defaults
The pack SHALL carry exactly one client settings file of its own, `options.txt`. It SHALL set render distance 10, simulation distance 6, entity distance 75 %, decreased particles, biome blend 2, fast clouds and a 120 FPS limit, and start with the data version line of the Minecraft version (`version:3955` for 1.21.1).

#### Scenario: Fresh profile
- **WHEN** a player installs the pack into a new profile and starts the game
- **THEN** these options are in effect

#### Scenario: Settings files the pack carries
- **WHEN** the pack is inspected
- **THEN** `options.txt` is the only client settings file accepted besides the server entry that export generates

### Requirement: Key bindings do not conflict
Cobblemon's starter and summary screen SHALL stay on M, and Xaero's World Map SHALL open with V instead of its default M. The binding SHALL survive the first launch of a fresh profile.

#### Scenario: Starter screen on a fresh profile
- **WHEN** a new player presses M in their first session
- **THEN** the Cobblemon starter screen opens, and V opens the world map

#### Scenario: Binding written back
- **WHEN** a fresh profile has been played and closed
- **THEN** its options file still binds the world map to V

### Requirement: Client memory guidance
Players SHALL be told, in the play guide, to give the game 4 GB of memory at minimum and 6 GB as recommended, and not more than 8 GB.

#### Scenario: Memory section
- **WHEN** a player reads the play guide
- **THEN** it states these limits and where to set them in each launcher the pack install and update guide covers

### Requirement: First-minutes guidance
Players SHALL be taught, in a play guide in English and a Traditional Chinese copy with the same sections, how to choose a starter, send out and recall Pokémon, battle, catch (finding recipes with EMI), heal, store Pokémon in a PC, ride, trade or battle other players and get unstuck, with a table of the keys involved. The play guide SHALL leave downloading, installing, joining and updating the pack to the pack install and update guide and link to it.

#### Scenario: New player
- **WHEN** a player reads the first-minutes section and the key table
- **THEN** each step names the key or action it uses, matching the key bindings above

#### Scenario: Player who has not installed the pack
- **WHEN** a player opens the play guide first
- **THEN** it sends them to the pack install and update guide and explains none of its steps itself

### Requirement: Gameplay acceptance checklist
The gameplay items of the player acceptance run that `compose-services` defines SHALL be: Pokémon spawn, starter selection, catch, battle, trade, ride, and death and respawn.

#### Scenario: Release sign-off
- **WHEN** a branch that changes the pack or the stack is accepted, which releases it
- **THEN** all seven gameplay items pass on staging before the merge and on production after the deployment

### Requirement: Game troubleshooting
The play guide SHALL tell players what to do when the game crashes while loading, when the frame rate is low, and when Pokémon do not appear or battles do nothing.

#### Scenario: Low frame rate
- **WHEN** a player's frame rate is low with the pack's defaults
- **THEN** the play guide tells them to lower the render distance to 8 and the simulation distance to 5

#### Scenario: Crash while loading
- **WHEN** the game crashes while loading
- **THEN** the play guide tells the player to set the maximum memory to the recommended value and to update the graphics driver

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
