#!/usr/bin/env python3
"""Assert an exported .mrpack matches the committed pack exactly.

Usage: pack-inspect.py <file.mrpack> <expected-version> --name NAME --host HOST
                       [--pack /work/pack]

Two independent sources are compared against modrinth.index.json:

- pack/ (pack.toml and mods/*.pw.toml): the exact Minecraft and Fabric loader
  pins, and the exact filename of every mod. A mod whose version drifted
  (for example after `packwiz update --all`) therefore fails here.
- SIDES below: the side table approved in tasks/plan.md. It must list exactly
  the mods present in pack/, and each mod file's `side` must match it, so an
  unplanned dependency or a changed side fails here.

Every mod must come from cdn.modrinth.com, the overrides must be exactly
options.txt (identical to the committed file) and servers.dat (carrying the
name and host it was generated from). Standard library only.
"""
import argparse
import importlib.util
import json
import pathlib
import sys
import tomllib
import zipfile
from urllib.parse import urlparse

SIDES = {
    # required
    "cobblemon": "both",
    "fabric-api": "both",
    # performance
    "sodium": "client",
    "lithium": "both",
    "ferrite-core": "both",
    "immediatelyfast": "client",
    "entityculling": "client",
    # quality of life
    "modmenu": "client",
    "placeholder-api": "client",  # required by Mod Menu
    "emi": "client",
    "xaeros-minimap": "client",
    "xaeros-world-map": "client",
    "appleskin": "both",
    "mouse-tweaks": "client",
}
ENV = {
    "both": ("required", "required"),
    "client": ("required", "unsupported"),
    "server": ("unsupported", "required"),
}
ALLOWED_OVERRIDES = {"overrides/options.txt", "overrides/servers.dat"}
ALLOWED_MEMBERS = ALLOWED_OVERRIDES | {"modrinth.index.json"}
DOWNLOAD_HOST = "cdn.modrinth.com"


def nbt_reader():
    """The Reader class from make-servers-dat.py, loaded by path (hyphenated filename)."""
    path = pathlib.Path(__file__).with_name("make-servers-dat.py")
    spec = importlib.util.spec_from_file_location("make_servers_dat", path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module.Reader


def read_pack(pack_dir):
    pack = tomllib.loads((pack_dir / "pack.toml").read_text())
    mods = {}
    for path in sorted((pack_dir / "mods").glob("*.pw.toml")):
        mod = tomllib.loads(path.read_text())
        mods[path.name[: -len(".pw.toml")]] = (mod["filename"], mod.get("side", "both"))
    return pack, mods


def main(args):
    failures = []

    def check(cond, msg):
        if not cond:
            failures.append(msg)

    pack_dir = pathlib.Path(args.pack)
    pack, mods = read_pack(pack_dir)
    with zipfile.ZipFile(args.file) as z:
        members = {n for n in z.namelist() if not n.endswith("/")}
        check(members == ALLOWED_MEMBERS,
              f"archive members {sorted(members)} != expected {sorted(ALLOWED_MEMBERS)}")
        index = json.loads(z.read("modrinth.index.json"))
        overrides = {n: z.read(n) for n in members if n.startswith("overrides/")}

    # pack metadata and pins
    check(index.get("formatVersion") == 1, "formatVersion is not 1")
    check(index.get("game") == "minecraft", "game is not minecraft")
    # The expected version comes from the file name; pack.toml holds only a placeholder.
    check(index.get("versionId") == args.version,
          f"versionId {index.get('versionId')!r} != version in the file name {args.version!r}")
    deps = index.get("dependencies", {})
    versions = pack["versions"]
    check(deps.get("minecraft") == versions["minecraft"],
          f"index minecraft {deps.get('minecraft')!r} != pack.toml {versions['minecraft']!r}")
    check(deps.get("fabric-loader") == versions["fabric"],
          f"index fabric-loader {deps.get('fabric-loader')!r} != pack.toml {versions['fabric']!r}")

    # side table and pack/mods must list exactly the same mods, with the same sides
    check(set(mods) == set(SIDES),
          f"pack/mods and the side table differ: only in pack {sorted(set(mods) - set(SIDES))}, "
          f"only in table {sorted(set(SIDES) - set(mods))}")
    for name, (_, side) in mods.items():
        if name in SIDES:
            check(side == SIDES[name], f"{name}: side {side!r} in pack/mods != {SIDES[name]!r} in the side table")

    # every mod file must appear in the index exactly once, by exact filename, with the right env
    files = index.get("files", [])
    by_path = {}
    for f in files:
        check(f["path"] not in by_path, f"duplicate index entry {f['path']}")
        by_path[f["path"]] = f
    expected_paths = set()
    for name, (filename, side) in sorted(mods.items()):
        path = f"mods/{filename}"
        expected_paths.add(path)
        entry = by_path.get(path)
        if entry is None:
            failures.append(f"{name}: {path} missing from the index")
            continue
        env = entry.get("env", {})
        got = (env.get("client"), env.get("server"))
        want = ENV[SIDES.get(name, side)]
        check(got == want, f"{name}: env {got} != {want}")
    for path in sorted(set(by_path) - expected_paths):
        failures.append(f"unexpected index entry: {path}")
    for f in files:
        for url in f.get("downloads", []):
            check(urlparse(url).hostname == DOWNLOAD_HOST, f"{f['path']}: download host is not {DOWNLOAD_HOST}: {url}")
        check(bool(f.get("downloads")), f"{f['path']}: no download URL")

    # overrides
    check(set(overrides) == ALLOWED_OVERRIDES,
          f"overrides are {sorted(overrides)}, expected exactly {sorted(ALLOWED_OVERRIDES)}")
    expected_options = (pack_dir / "options.txt").read_bytes()
    check(overrides.get("overrides/options.txt") == expected_options,
          "overrides/options.txt differs from the committed pack/options.txt")
    # Without a leading "version:<data version>" line Minecraft treats the file
    # as a legacy format and its upgrade pass drops the mod key bindings.
    first = expected_options.decode("utf-8", "replace").splitlines()[:1]
    check(bool(first) and first[0].startswith("version:") and first[0][len("version:"):].isdigit(),
          "pack/options.txt must start with 'version:<Minecraft data version>' (1.21.1: 3955)")
    servers = overrides.get("overrides/servers.dat", b"")
    try:
        entries = nbt_reader()(servers).root().get("servers", [])
    except Exception as exc:  # any parse failure is a finding
        entries = []
        failures.append(f"servers.dat does not parse as NBT: {exc}")
    check(len(entries) == 1, f"servers.dat holds {len(entries)} entries, expected 1")
    if entries:
        check(entries[0].get("name") == args.name, f"servers.dat name {entries[0].get('name')!r} != {args.name!r}")
        check(entries[0].get("ip") == args.host, f"servers.dat ip {entries[0].get('ip')!r} != {args.host!r}")

    print(f"{args.file}: version {index.get('versionId')}, minecraft {deps.get('minecraft')}, "
          f"fabric-loader {deps.get('fabric-loader')}, {len(files)} files, {len(overrides)} overrides")
    for path in sorted(by_path):
        env = by_path[path].get("env", {})
        print(f"  {path}  client={env.get('client')} server={env.get('server')}")
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
    parser.add_argument("--pack", default="/work/pack")
    sys.exit(main(parser.parse_args()))
