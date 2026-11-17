# Spec Delta

## MODIFIED Requirements

### Requirement: Gameplay acceptance checklist
A gameplay checklist SHALL be completed by at least two players on staging, running the branch to be merged, before the merge, and again on production after the deployment: login, Pokémon spawn, starter selection, catch, battle, trade, ride, death and respawn, server restart, world persistence, and reaching the server from another network. The two runs SHALL use Modrinth App and Prism Launcher.

#### Scenario: Release sign-off
- **WHEN** a branch that changes the pack or the stack is ready to merge, which releases it
- **THEN** all eleven items pass on staging before the merge and on production after the deployment, and the launcher used for each run is recorded
