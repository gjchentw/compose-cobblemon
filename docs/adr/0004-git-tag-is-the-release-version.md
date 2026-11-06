# ADR 0004: The git tag is the release version

Status: accepted, 2026-11-06. Supersedes the "version committed in git" part of the
original version contract.

## Context

The first contract tied a release to a version committed in git: `pack/pack.toml` and
`.env.example` had to carry `X.Y.Z` before the tag `vX.Y.Z` was pushed, which a local
script did after building the pack with Docker. That is one tool too many for the people
this repository is a template for: someone who created a copy on GitHub and only wants a
pack for their server should not need a clone, Docker and bash to release. Publishing a
release from the GitHub web UI could not work under the old contract, because the tag
would point at a commit whose files named a different version.

## Decision

The tag is the only place a release version is written. `pack/pack.toml` and
`.env.example` hold the placeholder `0.0.0-dev`. When a GitHub release is published, CI
validates the tag (`vX.Y.Z` or `vX.Y.Z-rc.N`), substitutes its version into a build copy of
the pack, exports and inspects `cobblemon-X.Y.Z.mrpack`, uploads it to that release and
appends a pack contents table to the notes. `scripts/version-check.sh` fails if git ever
holds a release version. `scripts/smoke.sh` reads the version inside the mounted pack and
compares it with `PACK_VERSION`, so a renamed or mismatched file is caught on the host.

## Consequences

- Releasing needs a browser only; a template copy works after setting two secrets.
- One commit can carry several tags: a release candidate is promoted by publishing the
  final tag on the same commit, and the pack is rebuilt with the final version inside.
- The repository no longer records which commit was "version X" in a file; the tag and the
  GitHub release are the record, and the release notes carry the Minecraft, Fabric loader,
  Cobblemon and server image versions. `scripts/release.sh` and `docs/releases.md` were
  removed.
- A tag pushed without a GitHub release builds nothing; the release is the trigger.
- Local builds use the placeholder unless a version is passed to `scripts/pack-export.sh`.
