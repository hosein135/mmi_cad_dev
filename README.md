# Micro Magic CAD (Nix, native x86_64)

Nix FHS environment on x86_64 Linux / WSL2. CAD tools are rebuilt from the public-domain source as ELF 64-bit.

Place `vendor/mmi_pd_040526.tar.gz` once. `./run.sh --prep-only` unpacks it, flattens the 2004 directory names (`max/` not `max4.2.11`, `bin/` not `bin.i486-linux`), rebuilds tools as x86_64, copies that runtime tree to `vendor/mmi`, and **deletes the tarball**.

Source stays on the Linux filesystem (`~/.cache/mmi-cad/vendor`) because the 2004 tree has names that NTFS cannot store.

## Layout

```
.
├── flake.nix
├── run.sh
├── vendor/mmi/                   # flattened runtime tree (gitignored)
├── pdk/                          # MAX PDK import Tcl
├── nix/rebuild/                  # extract + patch + compile + install
├── nix/x11/                      # XLFD fonts + Xresources
├── nix/launch.sh
└── data/{pdks,workspace,home}
```

## Quick start

```bash
# vendor/mmi_pd_040526.tar.gz must be present the first time
chmod +x run.sh
./run.sh --prep-only    # extract, delete .tar.gz, compile
./run.sh max
```

`run.sh` uses `nix --impure` so the gitignored `vendor/mmi` tree is still found.

## Commands

| Command | Action |
|---------|--------|
| `./run.sh` | CAD shell |
| `./run.sh max` | Start MAX |
| `./run.sh sue` | Start SUE |
| `./run.sh nst` | Start NST |
| `./run.sh --prep-only` | Extract (if needed) and build |

## Inside the FHS sandbox

| Path | Contents |
|------|----------|
| `/mmi-vendor/mmi` | Rebuilt 64-bit CAD + scripts/tech |
| `/mmi-bundle` | From `pdk/` |
| `/mmi-magic` | Magic VLSI (nixpkgs) |
| `/mmi-pdks` | `data/pdks` |
| `/mmi-home` | `data/home` |

If a tool failed to compile, `nix build .#mmi-vendor --impure` prints which binary is missing.
