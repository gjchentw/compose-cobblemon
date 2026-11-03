#!/usr/bin/env python3
"""Assert an exported .mrpack matches the expected pack contents.

Usage: pack-inspect.py <file.mrpack> <expected-version>

Reads modrinth.index.json and checks the pack metadata, the Minecraft and
Fabric loader pins, and that every expected mod is present exactly once with
the client/server env markers packwiz derives from its `side`. Any mod in the
index that is not expected is a failure too, so the list stays exhaustive.
Standard library only; runs inside the tools image.
"""
import json
import sys
import zipfile

MINECRAFT = "1.21.1"

# name -> (filename token matched case-insensitively, (client env, server env))
EXPECTED = {
    "cobblemon": ("cobblemon-fabric-", ("required", "required")),
    "fabric-api": ("fabric-api-", ("required", "required")),
}


def main(path, version):
    failures = []
    with zipfile.ZipFile(path) as z:
        index = json.loads(z.read("modrinth.index.json"))

    def check(cond, msg):
        if not cond:
            failures.append(msg)

    check(index.get("formatVersion") == 1, "formatVersion is not 1")
    check(index.get("game") == "minecraft", "game is not minecraft")
    check(index.get("versionId") == version,
          f"versionId {index.get('versionId')!r} != expected {version!r}")
    deps = index.get("dependencies", {})
    check(deps.get("minecraft") == MINECRAFT,
          f"minecraft {deps.get('minecraft')!r} != {MINECRAFT!r}")
    check(bool(deps.get("fabric-loader")), "fabric-loader is not pinned")

    files = index.get("files", [])
    mods = [f for f in files if f["path"].lower().startswith("mods/")]
    matched = set()
    for name, (token, (client, server)) in EXPECTED.items():
        hits = [f for f in mods if token in f["path"].lower()]
        if len(hits) != 1:
            failures.append(f"{name}: expected 1 file matching {token!r}, found {len(hits)}")
            continue
        env = hits[0].get("env", {})
        got = (env.get("client"), env.get("server"))
        check(got == (client, server), f"{name}: env {got} != {(client, server)}")
        matched.add(hits[0]["path"])
    for f in mods:
        if f["path"] not in matched:
            failures.append(f"unexpected mod in index: {f['path']}")

    print(f"{path}: version {index.get('versionId')}, minecraft {deps.get('minecraft')}, "
          f"fabric-loader {deps.get('fabric-loader')}, {len(mods)} mods, "
          f"{len(files) - len(mods)} other files")
    for f in sorted(mods, key=lambda f: f["path"]):
        env = f.get("env", {})
        print(f"  {f['path']}  client={env.get('client')} server={env.get('server')}")
    if failures:
        print("FAIL")
        for msg in failures:
            print(f"  - {msg}")
        return 1
    print("OK")
    return 0


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print(__doc__)
        sys.exit(2)
    sys.exit(main(sys.argv[1], sys.argv[2]))
