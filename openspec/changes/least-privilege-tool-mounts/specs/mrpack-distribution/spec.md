# Spec Delta

## ADDED Requirements

### Requirement: Tool containers see only what they need
Pack tooling and the linters SHALL see only the files their task needs. The tools container SHALL get `pack/` writable, `scripts/` and `dist/` read-only, and, for one run, only the temporary directory that run works in. Each linter SHALL see, read-only, only the files it checks and its configuration. Neither SHALL see the deployment environment file, world data, backups, staging copies or git metadata.

#### Scenario: Deployment secrets stay outside the tool containers
- **WHEN** the tools container or a linter runs in a deployment checkout whose `.env` holds the RCON password
- **THEN** `.env`, the world data, the backups, the staging copies and `.git` do not exist inside the container

#### Scenario: The tools container writes only the pack and its run's directory
- **WHEN** a pack tool runs in the tools container
- **THEN** it can write `pack/` and the temporary directory of that run, and cannot write `scripts/` or `dist/`

#### Scenario: A linter sees only its files
- **WHEN** a linter runs
- **THEN** its container holds, read-only, the files it checks and its configuration, and nothing else from the checkout
