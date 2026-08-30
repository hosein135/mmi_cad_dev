# Micro Magic CAD (Nix, native x86_64)

Nix FHS environment on x86_64 Linux / WSL2. CAD tools are rebuilt from the public-domain source as ELF 64-bit.

The extracted CAD tree is **`vendor/mmi/`** (in git). `./run.sh --prep-only` rebuilds x86_64 tools into `vendor/mmi/bin` if needed.

If you only have the original archive, put `vendor/mmi_pd_040526.tar.gz` here once; `./run.sh --prep-only` unpacks it into `vendor/mmi`, flattens names, and deletes the tarball.

`vendor/mmi` is a case-sensitive NTFS folder so names like `aux/` work on Windows. Do not commit `vendor/result` (Nix store symlink).

## Layout

```
.
├── flake.nix
├── run.sh
├── vendor/mmi/                   # extracted CAD tree + x64 bins
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

`run.sh` uses `nix --impure` so local vendor paths resolve on WSL.

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
