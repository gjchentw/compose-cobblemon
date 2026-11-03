# ADR 0001: One packwiz pack feeds both the client and the server

Status: accepted, 2026-11-03

## Context

Players need a client pack; the server needs the server-side subset of the same mods at
the same versions. Maintaining two artifacts invites drift: a server mod that requires a
client counterpart, or a Cobblemon bump applied on one side only. The original plan ran
the official Cobblemon modpack on the server (`MODRINTH_MODPACK=5FFgwNNP`) and a separate
hand-made client pack.

## Decision

The repository holds one packwiz pack under `pack/`. Every mod carries an explicit
`side` (`client`, `server` or `both`). `packwiz modrinth export` writes one `.mrpack`
whose index marks each file with client/server env flags. Players install that file.
The server mounts the same file (`MODRINTH_MODPACK=/packs/cobblemon-<version>.mrpack`)
and `itzg/minecraft-server` installs only entries whose server flag is not
`unsupported`. Client-only override files are excluded with
`MODRINTH_OVERRIDES_EXCLUSIONS`.

## Consequences

- The version contract holds by construction: whatever the server runs, the client has.
- The mod list is ours to maintain; `scripts/pack-inspect.py` asserts it exhaustively,
  including the side of each mod, so an unplanned dependency cannot slip in unnoticed.
- The server installs five mods (Cobblemon, Fabric API, Lithium, FerriteCore, AppleSkin);
  everything else is client only.
- Mod sides are set by editing the `side` field of a mod file followed by
  `packwiz refresh`; this is the one allowed hand edit of packwiz output.
