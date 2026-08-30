#!/usr/bin/env python3
import os
from collections import defaultdict

root = "vendor/mmi"
by_lower = defaultdict(list)
for dirpath, _, files in os.walk(root):
    for f in files:
        p = os.path.join(dirpath, f).replace("\\", "/")
        by_lower[p.lower()].append(p)

dups = [v for v in by_lower.values() if len(v) > 1]
print("case_duplicate_groups", len(dups))
for g in sorted(dups):
    print("---")
    for p in g:
        print(p)
