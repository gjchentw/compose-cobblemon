# Releases

The version contract: one release is one git tag `vX.Y.Z`, one `pack/pack.toml`
version, one `dist/cobblemon-X.Y.Z.mrpack`, one `PACK_VERSION` in `.env.example`
and the MOTD "Cobblemon Server | Pack X.Y.Z". `scripts/version-check.sh` asserts
the contract; `scripts/release.sh` cuts a release and appends a row below.

| Date | Pack | Minecraft | Fabric loader | Cobblemon | Server image | Notes |
|---|---|---|---|---|---|---|
| 2026-11-03 | 1.0.0-rc.1 | 1.21.1 | 0.20.1 | 1.8.4 | 2026.10.1-java21 | |
