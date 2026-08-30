**`vendor/mmi/`** is the extracted CAD tree (in git): flattened names, `src/`, and x86_64 tools in `bin/`.

On **Windows**, run once before `git add`:

```powershell
powershell -File scripts/setup-git.ps1
```

That sets `core.protectNTFS=false` so paths like `maxaux/` (renamed from reserved `aux/`) can be indexed. The tree also has no symlinks (expanded for Windows git).

`vendor/result` is a Nix symlink and is not committed.
