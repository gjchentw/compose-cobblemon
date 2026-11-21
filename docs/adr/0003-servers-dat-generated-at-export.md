# ADR 0003: servers.dat is generated at export time, never committed

Status: accepted, 2026-11-03. Amended 2026-11-21 by the OpenSpec change
`committed-public-info`: the name and host come from the committed `config/public.env`
instead of repository secrets and `.env`. The template still commits only placeholders; a
copy commits its own public address, which its published pack carries anyway.

## Context

The client pack pre-fills the Multiplayer list so players never type an address. That
needs a `servers.dat` (NBT) carrying the real hostname. The repository must not contain
real hostnames (placeholders only), and packwiz hashes every file in `pack/` into
`index.toml`, so a generated file inside `pack/` would make `packwiz refresh` dirty.

## Decision

`scripts/pack-export.sh` copies `pack/` to a fresh build directory, writes
`servers.dat` there with `scripts/make-servers-dat.py` (standard-library NBT writer with a
`--verify` reader), refreshes and exports from that directory. The name and host come from
`SERVER_NAME` and `SERVER_PUBLIC_HOST` in the committed `config/public.env`; a value in the
environment overrides the file for one build. Every repository created from this template
builds a pack pointing at its own server by editing that one file.

## Consequences

- `pack/` stays placeholder-free and `packwiz refresh` on it is always a no-op.
- The job that publishes the pack on `main` publishes nothing while the host is the
  placeholder, so a published pack can only carry a real host; builds of a repository that
  has not set its address still export with the placeholder.
- Players update by installing a new profile from the new mrpack, so the launcher
  overwriting `servers.dat` on in-place updates is not a concern.
- The export writes into `.build/` under the repository, not the system temp directory,
  because Docker Desktop cannot see sandboxed temp paths.
