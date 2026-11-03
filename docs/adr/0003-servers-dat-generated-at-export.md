# ADR 0003: servers.dat is generated at export time, never committed

Status: accepted, 2026-11-03

## Context

The client pack pre-fills the Multiplayer list so players never type an address. That
needs a `servers.dat` (NBT) carrying the real hostname. The repository must not contain
real hostnames (placeholders only), and packwiz hashes every file in `pack/` into
`index.toml`, so a generated file inside `pack/` would make `packwiz refresh` dirty.

## Decision

`scripts/pack-export.sh` copies `pack/` to a fresh build directory, writes
`servers.dat` there with `scripts/make-servers-dat.py` (standard-library NBT writer with a
`--verify` reader), refreshes and exports from that directory. The name and host come from
`SERVER_NAME` and `SERVER_PUBLIC_HOST` with the precedence environment variable, then
`.env`, then `.env.example`. CI supplies them as repository variables.

## Consequences

- `pack/` stays placeholder-free and `packwiz refresh` on it is always a no-op.
- The mrpack attached to a GitHub Release carries the real host only if the repository
  variables are set; otherwise players add the server by hand (documented in the guide).
- Players update by installing a new profile from the new mrpack, so the launcher
  overwriting `servers.dat` on in-place updates is not a concern.
- The export writes into `.build/` under the repository, not the system temp directory,
  because Docker Desktop cannot see sandboxed temp paths.
