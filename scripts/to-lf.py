#!/usr/bin/env python3
"""Rewrite CRLF/CR to LF in git-tracked text files. Skip known binaries."""
import os
import subprocess
import sys

SKIP_EXT = {
    ".a",
    ".so",
    ".o",
    ".exe",
    ".bin",
    ".gif",
    ".jpg",
    ".jpeg",
    ".png",
    ".pcf",
    ".pdf",
    ".gz",
    ".tgz",
    ".zip",
    ".tar",
}

repo = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
os.chdir(repo)
files = subprocess.check_output(["git", "ls-files"], text=True).splitlines()
converted = []
for rel in files:
    ext = os.path.splitext(rel)[1].lower()
    if ext in SKIP_EXT:
        continue
    path = os.path.join(repo, rel)
    try:
        with open(path, "rb") as fh:
            data = fh.read()
    except OSError:
        continue
    if b"\0" in data:
        continue
    if b"\r" not in data:
        continue
    new = data.replace(b"\r\n", b"\n").replace(b"\r", b"\n")
    if new == data:
        continue
    with open(path, "wb") as fh:
        fh.write(new)
    converted.append(rel)

print(f"converted {len(converted)} files to LF", file=sys.stderr)
for rel in converted:
    print(rel)
