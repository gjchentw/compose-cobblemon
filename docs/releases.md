# Releases

The version contract: one release is one git tag `vX.Y.Z`, one `pack/pack.toml`
version, one `dist/cobblemon-X.Y.Z.mrpack`, one `PACK_VERSION` in `.env.example`
and the MOTD "Cobblemon Server | Pack X.Y.Z". `scripts/version-check.sh` asserts
the contract; `scripts/release.sh` cuts a release and appends a row below.

| Date | Pack | Minecraft | Fabric loader | Cobblemon | Server image | Notes |
|---|---|---|---|---|---|---|
| 2026-11-03 | 1.0.0-rc.1 | 1.21.1 | 0.20.1 | 1.8.4 | 2026.10.1-java21 | Release pipeline exercised end to end (CI run 41644430544). Client test: pack mods launched with portablemc (Fabric 1.21.1/0.20.1, Mojang Java 21) and joined the local server with the gjchen account; Cobblemon requires Java 21 exactly. Pack carried the placeholder host (repository variables unset). |
| 2026-11-03 | 1.0.0-rc.2 | 1.21.1 | 0.20.1 | 1.8.4 | 2026.10.1-java21 | Not published: the new placeholder-host guard stopped the tag build (run 41661137835) because the workflow saw empty SERVER_NAME/SERVER_PUBLIC_HOST. Superseded by rc.3. |
| 2026-11-04 | 1.0.0-rc.3 | 1.21.1 | 0.20.1 | 1.8.4 | 2026.10.1-java21 | Published as a pre-release by CI (run 41764616692) with the server name and host from repository secrets; the attached pack's servers.dat verified to carry a real host. Review fixes included (see commits 93508c4, 07137e1, c48c689, b74c90a). |
