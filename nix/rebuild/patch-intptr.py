#!/usr/bin/env python3
"""Rewrite pointer-as-int packing so MAX can compile as LP64 (x86_64)."""
from __future__ import annotations

import pathlib
import re
import sys

ROOT = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else ".")

# Store small integers in ClientData (void*) fields — use intptr_t, not int.
CASTS = [
    (
        re.compile(r"\(\s*int\s*\)\s*(\([^)]+\)->ti_(?:body|client|groups))"),
        r"(intptr_t) \1",
    ),
    (
        re.compile(r"\(\s*TileType\s*\)\s*(\([^)]+\)->ti_body)"),
        r"(intptr_t) \1",
    ),
    (
        re.compile(r"\(\s*int\s*\)\s*(tilep->ti_groups)"),
        r"(intptr_t) \1",
    ),
]

# GNU lvalue-cast |= / &= on truncated pointer — invalid on modern GCC.
LVALUE = [
    (
        re.compile(
            r"\(\(\(int\)\s*\(([^)]+)\)->ti_body\)\s*\|= \(([^)]+)\)\)"
        ),
        r"((\1)->ti_body = (ClientData)(((intptr_t)(\1)->ti_body) | (intptr_t)(\2)))",
    ),
    (
        re.compile(
            r"\(\(\(int\)\s*\(([^)]+)\)->ti_body\)\s*&= ~\(([^)]+)\)\)"
        ),
        r"((\1)->ti_body = (ClientData)(((intptr_t)(\1)->ti_body) & ~(intptr_t)(\2)))",
    ),
]

# GCC 14 rejects unescaped newlines inside string literals (old GCC extension).
def fix_c_multiline_strings(src: str) -> str:
    out: list[str] = []
    i = 0
    n = len(src)
    while i < n:
        c = src[i]
        if c == "/" and i + 1 < n and src[i + 1] == "/":
            j = src.find("\n", i)
            if j < 0:
                out.append(src[i:])
                break
            out.append(src[i:j])
            i = j
            continue
        if c == "/" and i + 1 < n and src[i + 1] == "*":
            j = src.find("*/", i + 2)
            if j < 0:
                out.append(src[i:])
                break
            out.append(src[i : j + 2])
            i = j + 2
            continue
        if c == "'":
            j = i + 1
            while j < n:
                if src[j] == "\\" and j + 1 < n:
                    j += 2
                    continue
                if src[j] == "'":
                    j += 1
                    break
                if src[j] == "\n":
                    break
                j += 1
            out.append(src[i:j])
            i = j
            continue
        if c == '"':
            chunk = ['"']
            j = i + 1
            while j < n:
                if src[j] == "\\" and j + 1 < n:
                    chunk.append(src[j : j + 2])
                    j += 2
                    continue
                if src[j] == '"':
                    chunk.append('"')
                    j += 1
                    break
                if src[j] == "\n":
                    chunk.append("\\n")
                    j += 1
                    continue
                chunk.append(src[j])
                j += 1
            out.append("".join(chunk))
            i = j
            continue
        out.append(c)
        i += 1
    return "".join(out)


def patch_text(text: str) -> str:
    for rx, repl in LVALUE + CASTS:
        text = rx.sub(repl, text)
    return text


def inject_stdint(text: str) -> str:
    if "#include <stdint.h>" in text:
        return text
    needle = "/* --------------------- Universal pointer type ----------------------- */"
    extra = '#include <stdint.h>\n\n'
    if needle in text:
        return text.replace(needle, extra + needle, 1)
    return text


changed = 0
for path in ROOT.rglob("*"):
    if not path.is_file():
        continue
    if path.suffix not in {".c", ".h", ".cc"}:
        continue
    try:
        orig = path.read_text(encoding="latin-1")
    except OSError:
        continue
    new = patch_text(orig)
    new = fix_c_multiline_strings(new)
    if path.name == "magic.h":
        new = inject_stdint(new)
    if new != orig:
        path.write_text(new, encoding="latin-1")
        changed += 1
        print(f"patched {path}")

print(f"intptr patches: {changed} files")
