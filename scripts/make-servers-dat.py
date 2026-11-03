#!/usr/bin/env python3
"""Write or verify a Minecraft servers.dat with one pre-filled server entry.

Usage:
  make-servers-dat.py --name NAME --host HOST --out FILE
  make-servers-dat.py --verify FILE

servers.dat is uncompressed NBT: a root compound holding a "servers" list of
compounds, each with "name" and "ip" strings. Standard library only; runs
inside the tools image. --verify parses the file back with a small generic
NBT reader and prints every entry, so a file written here or by the game can
be checked the same way.
"""
import argparse
import struct
import sys

TAG_END, TAG_BYTE, TAG_SHORT, TAG_INT, TAG_LONG, TAG_FLOAT, TAG_DOUBLE = range(7)
TAG_BYTE_ARRAY, TAG_STRING, TAG_LIST, TAG_COMPOUND, TAG_INT_ARRAY, TAG_LONG_ARRAY = range(7, 13)


def nbt_string(text):
    data = text.encode("utf-8")
    return struct.pack(">H", len(data)) + data


def tag_header(kind, name):
    return struct.pack(">B", kind) + nbt_string(name)


def build(name, host):
    entry = (tag_header(TAG_STRING, "name") + nbt_string(name)
             + tag_header(TAG_STRING, "ip") + nbt_string(host)
             + struct.pack(">B", TAG_END))
    servers = tag_header(TAG_LIST, "servers") + struct.pack(">Bi", TAG_COMPOUND, 1) + entry
    return tag_header(TAG_COMPOUND, "") + servers + struct.pack(">B", TAG_END)


class Reader:
    SIZES = {TAG_BYTE: ">b", TAG_SHORT: ">h", TAG_INT: ">i", TAG_LONG: ">q",
             TAG_FLOAT: ">f", TAG_DOUBLE: ">d"}

    def __init__(self, data):
        self.data, self.pos = data, 0

    def take(self, fmt):
        value = struct.unpack_from(fmt, self.data, self.pos)[0]
        self.pos += struct.calcsize(fmt)
        return value

    def string(self):
        length = self.take(">H")
        value = self.data[self.pos:self.pos + length].decode("utf-8")
        self.pos += length
        return value

    def payload(self, kind):
        if kind in self.SIZES:
            return self.take(self.SIZES[kind])
        if kind == TAG_STRING:
            return self.string()
        if kind in (TAG_BYTE_ARRAY, TAG_INT_ARRAY, TAG_LONG_ARRAY):
            count = self.take(">i")
            fmt = {TAG_BYTE_ARRAY: ">b", TAG_INT_ARRAY: ">i", TAG_LONG_ARRAY: ">q"}[kind]
            return [self.take(fmt) for _ in range(count)]
        if kind == TAG_LIST:
            item_kind, count = self.take(">B"), self.take(">i")
            return [self.payload(item_kind) for _ in range(count)]
        if kind == TAG_COMPOUND:
            result = {}
            while True:
                child = self.take(">B")
                if child == TAG_END:
                    return result
                # Read the name before the payload: Python evaluates the
                # right-hand side of `d[k] = v` before the subscript.
                key = self.string()
                result[key] = self.payload(child)
        raise ValueError(f"unknown tag type {kind}")

    def root(self):
        kind = self.take(">B")
        if kind != TAG_COMPOUND:
            raise ValueError("root is not a compound")
        self.string()
        return self.payload(TAG_COMPOUND)


def verify(path):
    with open(path, "rb") as handle:
        root = Reader(handle.read()).root()
    servers = root.get("servers", [])
    for entry in servers:
        print(f"{entry.get('name')!r} -> {entry.get('ip')!r}")
    if not servers:
        print("no server entries found", file=sys.stderr)
        return 1
    return 0


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--name")
    parser.add_argument("--host")
    parser.add_argument("--out")
    parser.add_argument("--verify", metavar="FILE")
    args = parser.parse_args()
    if args.verify:
        return verify(args.verify)
    if not (args.name and args.host and args.out):
        parser.error("--name, --host and --out are required unless --verify is given")
    with open(args.out, "wb") as handle:
        handle.write(build(args.name, args.host))
    return verify(args.out)


if __name__ == "__main__":
    sys.exit(main())
