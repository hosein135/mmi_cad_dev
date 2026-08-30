**`vendor/mmi/`** is the extracted CAD source tree (in git): flattened names and `src/`.

x86_64 binaries are **not** stored here. Build them with:

```bash
nix build .#mmi-vendor
# or
./run.sh --prep-only
```

`vendor/result` is a Nix symlink and is not committed.
