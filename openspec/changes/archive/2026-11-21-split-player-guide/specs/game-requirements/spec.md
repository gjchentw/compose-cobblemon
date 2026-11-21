# Spec Delta

## MODIFIED Requirements

### Requirement: Client memory guidance
Players SHALL be told, in the play guide, to give the game 4 GB of memory at minimum and 6 GB as recommended, and not more than 8 GB.

#### Scenario: Memory section
- **WHEN** a player reads the play guide
- **THEN** it states these limits and where to set them in Modrinth App and Prism Launcher

### Requirement: First-minutes guidance
Players SHALL be taught, in a play guide in English and a Traditional Chinese copy with the same sections, how to choose a starter, send out and recall Pokémon, battle, catch (finding recipes with EMI), heal, store Pokémon in a PC, ride, trade or battle other players and get unstuck, with a table of the keys involved. The play guide SHALL leave downloading, installing, joining and updating the pack to the pack install and update guide and link to it.

#### Scenario: New player
- **WHEN** a player reads the first-minutes section and the key table
- **THEN** each step names the key or action it uses, matching the key bindings above

#### Scenario: Player who has not installed the pack
- **WHEN** a player opens the play guide first
- **THEN** it sends them to the pack install and update guide and explains none of its steps itself

## ADDED Requirements

### Requirement: Game troubleshooting
The play guide SHALL tell players what to do when the game crashes while loading, when the frame rate is low, and when Pokémon do not appear or battles do nothing.

#### Scenario: Low frame rate
- **WHEN** a player's frame rate is low with the pack's defaults
- **THEN** the play guide tells them to lower the render distance to 8 and the simulation distance to 5

#### Scenario: Crash while loading
- **WHEN** the game crashes while loading
- **THEN** the play guide tells the player to set the maximum memory to the recommended value and to update the graphics driver
