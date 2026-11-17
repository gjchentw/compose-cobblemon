# compose-services Specification

## Purpose
Runs a Minecraft game server from a pack under Docker Compose on one Linux host, keeps it secure and observable, backs it up and restores it, provides a staging copy, and documents how an administrator operates it.

## Requirements

### Requirement: Pinned images
Every container image the stack pulls from a registry SHALL be referenced by tag and by multi-arch index digest covering linux/amd64 and linux/arm64. Floating tags such as `latest` or `stable` SHALL NOT be used. Images built locally from a Dockerfile are exempt; their base images are pinned instead.

#### Scenario: Rendered configuration pins every pulled image
- **WHEN** the production or the staging configuration is rendered with `docker compose config`
- **THEN** every `image:` reference that is pulled carries a version tag and an `@sha256:` digest

### Requirement: Server installs the server side of the configured pack
The main game service SHALL install the pack file named by the configured pack version from the local pack directory, installing only the entries marked for the server and none of the client-only override files.

#### Scenario: Only server-side mods are installed
- **WHEN** the stack starts with `PACK_VERSION` naming a pack in `dist/`
- **THEN** the server's mods directory contains exactly the pack's entries whose side is `both` or `server`, and no client-only override file such as `options.txt` or `servers.dat` is placed in the server data

### Requirement: Game settings come from the deployment with game defaults
The stack SHALL read the game server's settings (heap, player limit, view and simulation distance, difficulty, game mode, PvP) from the deployment environment file, falling back to the defaults that `game-requirements` declares.

#### Scenario: Unset settings take the declared defaults
- **WHEN** the deployment environment file does not set a game setting
- **THEN** the server runs with the default value `game-requirements` declares for it

### Requirement: Public server information reaches the server
The stack SHALL pass the display name, icon and MOTD text defined by `public-server-info` to the main game service.

#### Scenario: Players see the published information
- **WHEN** a player's client queries the running server
- **THEN** the response carries the MOTD text and icon that `public-server-info` defines

### Requirement: Only authenticated, whitelisted players join
The main game service SHALL run in online mode with the whitelist enabled and enforced. These settings SHALL NOT be changeable through the deployment environment file.

#### Scenario: A player who is not whitelisted is refused
- **WHEN** an authenticated player who is not on the whitelist tries to join
- **THEN** the server refuses the connection

#### Scenario: Security properties are checked
- **WHEN** `scripts/smoke.sh` runs against the started stack
- **THEN** it fails unless `online-mode`, `white-list` and `enforce-whitelist` are all `true` in the server properties

### Requirement: RCON stays internal
RCON SHALL be enabled for administration and reachable only inside the Compose network; its port SHALL NOT be published on the host. Administrators SHALL reach it through the running container.

#### Scenario: RCON port is not published
- **WHEN** the stack is running
- **THEN** no host port maps to the container's RCON port, and `scripts/smoke.sh` fails if one does

### Requirement: Secrets are supplied at deployment only
The stack SHALL refuse to start without an RCON password supplied in the deployment environment file. The committed example environment file SHALL contain no secret value.

#### Scenario: Missing password stops the stack
- **WHEN** `RCON_PASSWORD` is empty or unset
- **THEN** `docker compose config` and `docker compose up` fail with a message naming the missing variable

### Requirement: Health reflects a server that answers
The main game service SHALL report healthy only after the server answers status queries, allowing a startup grace period of 5 minutes and probing every 15 seconds with up to 20 retries.

#### Scenario: Health requires a fresh successful probe
- **WHEN** the stack is started or restarted
- **THEN** it is treated as healthy only after a status probe made since the start succeeds, and the smoke check waits up to 600 seconds for it

### Requirement: Graceful stop saves the world
On stop, the main game service SHALL save the world and exit with code 0 within a 2 minute grace period.

#### Scenario: Orderly stop
- **WHEN** the stack is stopped with `docker compose stop`
- **THEN** the log shows the server stopping and saving all dimensions, and the container exits with code 0

#### Scenario: A killed server fails the persistence check
- **WHEN** the container is configured to stop with SIGKILL and `scripts/persist-test.sh` runs
- **THEN** the check fails, naming exit code 137

### Requirement: World data survives restarts
World, configuration and admin files SHALL survive an orderly stop and start of the stack.

#### Scenario: Marker survives a restart
- **WHEN** `scripts/persist-test.sh` creates a scoreboard objective, stops and restarts the stack
- **THEN** the objective, `world/level.dat`, `whitelist.json` and `ops.json` are present after the restart, the objective is removed again, and a failure after the stop brings the stack back up

### Requirement: Bounded container logs
Each long-running service SHALL rotate its container log at 50 MB and keep at most 5 files.

#### Scenario: Log rotation is configured
- **WHEN** the configuration is rendered
- **THEN** every long-running service uses a json-file log with `max-size` 50m and `max-file` 5

### Requirement: Runtime files belong to the host administrator
The server data directory SHALL be owned by the configured host user and group, and the backup service SHALL run as that user, so administrators can manage data and archives without root.

#### Scenario: Archives are owned by the administrator
- **WHEN** a backup is taken on a Linux host with `UID` and `GID` set to the administrator's ids
- **THEN** the archive in `backups/` is owned by that user

### Requirement: Scheduled backups
A backup service SHALL start after the main game service is healthy and archive its data at a configurable interval (default 24 hours), skipping runs while no players are online (default) and coordinating with the server so saves are paused during the archive.

#### Scenario: Startup and scheduled archives
- **WHEN** the stack starts
- **THEN** the backup service writes an archive to `backups/` once the server is healthy, and again after each interval in which players were online

### Requirement: Backup retention and kept archives
Archives in the top level of the backup directory SHALL be pruned after a configurable age (default 14 days). Archives in `backups/keep/` SHALL never be pruned.

#### Scenario: Kept archives are not pruned
- **WHEN** pruning runs
- **THEN** only top-level archives older than the configured age are deleted and nothing under `backups/keep/` is touched

### Requirement: Backups carry no secrets
Backup archives SHALL exclude files that hold the RCON password: `server.properties`, `.rcon-cli.env` and `.rcon-cli.yaml`. They are regenerated from the deployment environment on every start.

#### Scenario: Restore drill rejects an archive with secrets
- **WHEN** `scripts/restore-drill.sh` restores an archive that contains `server.properties`
- **THEN** the drill fails and names the file

### Requirement: Restore drill
Administrators SHALL be able to prove that an archive restores: the drill takes a fresh backup, or uses an archive named relative to `backups/`, extracts it into a scratch directory and checks its contents.

#### Scenario: Successful drill
- **WHEN** `scripts/restore-drill.sh` runs, with or without an archive argument such as `keep/<archive>`
- **THEN** it extracts the archive and passes only if `world/level.dat`, `whitelist.json` and `ops.json` are present and no secret-bearing file is

#### Scenario: Backup produced nothing new
- **WHEN** the drill requests a backup and no archive newer than the request appears
- **THEN** the drill fails instead of restoring an older archive

### Requirement: Staging environment
A staging stack SHALL run next to production on the same host with its own project name, container names, published port (default 25566), data and backup directories, and a `[STAGING]` MOTD prefix, and SHALL otherwise use the production configuration.

#### Scenario: Staging differs only where it must
- **WHEN** the production and the staging configurations are rendered and compared
- **THEN** they differ only in names, the published port, the data and backup paths and the MOTD

### Requirement: Clone the production world into staging
Administrators SHALL be able to copy the production world, configuration and admin files into the staging data directory. When production is running its saves SHALL be paused during the copy and resumed afterwards, also when the copy fails. The copy SHALL refuse to run while staging is running.

#### Scenario: Saves resume after the copy
- **WHEN** the world is cloned while production is running
- **THEN** production saves are switched off, the files are copied, and saves are switched back on even if the copy is interrupted

### Requirement: Deployed pack matches the configured version
Before starting the stack, the smoke check SHALL refuse a malformed configured version, a missing pack file, or a pack whose embedded version differs from the configured version, so a mislabeled pack is never installed.

#### Scenario: Embedded version differs
- **WHEN** `PACK_VERSION` names a file whose embedded version is different
- **THEN** `scripts/smoke.sh` fails before the server starts and names both versions

#### Scenario: Malformed version
- **WHEN** `PACK_VERSION` is not `X.Y.Z`, `X.Y.Z-rc.N` or the placeholder `0.0.0-dev`
- **THEN** `scripts/smoke.sh` fails before starting anything

### Requirement: Deployed configuration matches the release
When the configured version is a release version and the checkout is a git work tree that knows the tag `v<version>`, the smoke check SHALL fail unless that tag points at the checked-out commit. An unknown tag SHALL only warn; the placeholder version and non-git directories SHALL NOT be checked.

#### Scenario: Wrong checkout
- **WHEN** `PACK_VERSION` is a release version whose tag points at another commit
- **THEN** `scripts/smoke.sh` fails and tells the administrator to fetch tags and check out that tag

### Requirement: Smoke check of a running server
The smoke check SHALL start the stack and verify that it becomes healthy, reports the Minecraft version and MOTD `game-requirements` and `public-server-info` define, loads the key mod, installs exactly the server-side mod set, runs the declared Java version, keeps the backup service running and accepts connections on the published port.

#### Scenario: Healthy stack passes
- **WHEN** `scripts/smoke.sh` runs on a correctly deployed stack
- **THEN** it reports `SMOKE OK`

#### Scenario: Client-only mod on the server
- **WHEN** the server's mods directory differs from the pack's server-side set
- **THEN** the smoke check fails and shows the difference

### Requirement: Hosted Linux verification of the stack
CI SHALL validate the production and the staging configurations on every push and pull request, and SHALL run the smoke, persistence and restore checks on a hosted Linux runner on manual dispatch or when a `smoke/*` branch is pushed.

#### Scenario: Smoke branch push
- **WHEN** a branch named `smoke/<name>` is pushed
- **THEN** the hosted runner creates the runtime directories as the runner user, builds the pack, and runs `scripts/smoke.sh`, `scripts/persist-test.sh` and `scripts/restore-drill.sh`

### Requirement: Administrator documentation
The repository SHALL provide an administrator guide covering first deployment, everyday commands, where runtime files live, backups, performance triage and security, and procedures for upgrading and rolling back.

#### Scenario: First deployment from the guide
- **WHEN** an administrator follows the first-deployment steps on a fresh Linux host
- **THEN** the runtime directories are created by the administrator with mode 750 before the first start, and the stack passes the smoke check

### Requirement: Rollback never loses the live world first
The rollback procedure SHALL open and verify the archive before touching the live world, move the live world aside instead of deleting it, and remove the aside copy only after the smoke check passes.

#### Scenario: Wrong archive name
- **WHEN** the administrator names an archive that does not exist during a world rollback
- **THEN** extraction fails before the live world is moved, and the live world is unchanged
