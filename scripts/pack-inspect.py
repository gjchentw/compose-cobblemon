#!/usr/bin/env python3
"""Assert an exported .mrpack matches the expected pack contents.

Usage: pack-inspect.py <file.mrpack> <expected-version> --name NAME --host HOST
                       [--options /work/pack/options.txt]

Reads modrinth.index.json and checks the pack metadata, the Minecraft and
Fabric loader pins, and that every expected mod is present exactly once with
the client/server env markers packwiz derives from its `side`. Any mod in the
index that is not expected is a failure too, so the list stays exhaustive.
Also checks the client overrides: options.txt must equal the committed file
and servers.dat must carry the server name and host it was generated from.
Standard library only; runs inside the tools image.
"""
import argparse
import json
import sys
import zipfile

MINECRAFT = "1.21.1"

# name -> (filename token matched case-insensitively, (client env, server env))
BOTH = ("required", "required")
CLIENT = ("required", "unsupported")
EXPECTED = {
    # required
    "cobblemon": ("cobblemon-fabric-", BOTH),
    "fabric-api": ("fabric-api-", BOTH),
    # performance
    "sodium": ("sodium-fabric-", CLIENT),
    "lithium": ("lithium-fabric-", BOTH),
    "ferrite-core": ("ferritecore-", BOTH),
    "immediatelyfast": ("immediatelyfast-fabric-", CLIENT),
    "entityculling": ("entityculling-fabric-", CLIENT),
    # quality of life
    "modmenu": ("modmenu-", CLIENT),
    "placeholder-api": ("placeholder-api-", CLIENT),  # required by Mod Menu
    "emi": ("emi-", CLIENT),
    "xaeros-minimap": ("xaerominimap-", CLIENT),
    "xaeros-world-map": ("xaeroworldmap-", CLIENT),
    "appleskin": ("appleskin-fabric-", BOTH),
    "mouse-tweaks": ("mousetweaks-fabric-", CLIENT),
}


def main(path, version, name, host, options_path):
    failures = []
    with zipfile.ZipFile(path) as z:
        index = json.loads(z.read("modrinth.index.json"))
        names = set(z.namelist())
        overrides = {n: z.read(n) for n in names if n.startswith("overrides/") and not n.endswith("/")}

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
    for mod, (token, (client, server)) in EXPECTED.items():
        hits = [f for f in mods if token in f["path"].lower()]
        if len(hits) != 1:
            failures.append(f"{mod}: expected 1 file matching {token!r}, found {len(hits)}")
            continue
        env = hits[0].get("env", {})
        got = (env.get("client"), env.get("server"))
        check(got == (client, server), f"{mod}: env {got} != {(client, server)}")
        matched.add(hits[0]["path"])
    for f in mods:
        if f["path"] not in matched:
            failures.append(f"unexpected mod in index: {f['path']}")

    with open(options_path, "rb") as handle:
        expected_options = handle.read()
    check(overrides.get("overrides/options.txt") == expected_options,
          "overrides/options.txt missing or differs from the committed options.txt")
    servers = overrides.get("overrides/servers.dat", b"")
    check(bool(servers), "overrides/servers.dat missing")
    check(name.encode("utf-8") in servers, f"servers.dat does not contain name {name!r}")
    check(host.encode("utf-8") in servers, f"servers.dat does not contain host {host!r}")

    print(f"{path}: version {index.get('versionId')}, minecraft {deps.get('minecraft')}, "
          f"fabric-loader {deps.get('fabric-loader')}, {len(mods)} mods, "
          f"{len(files) - len(mods)} other files")
    for f in sorted(mods, key=lambda f: f["path"]):
        env = f.get("env", {})
        print(f"  {f['path']}  client={env.get('client')} server={env.get('server')}")
    for n in sorted(overrides):
        print(f"  {n}  ({len(overrides[n])} bytes)")
    if failures:
        print("FAIL")
        for msg in failures:
            print(f"  - {msg}")
        return 1
    print("OK")
    return 0


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("file")
    parser.add_argument("version")
    parser.add_argument("--name", required=True)
    parser.add_argument("--host", required=True)
    parser.add_argument("--options", default="/work/pack/options.txt")
    a = parser.parse_args()
    sys.exit(main(a.file, a.version, a.name, a.host, a.options))
