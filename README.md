# Micro Magic CAD (Nix, native x86_64)

Reproducible Nix FHS environment on **x86_64 Linux**: bare metal, a VM, or WSL2. CAD tools are rebuilt from the public-domain sources as ELF 64-bit. **GUI uses a Nix-built TigerVNC X server**. View the desktop in a browser via noVNC.

nixpkgs is **NixOS 25.05**, locked by git revision + `narHash` in `flake.lock`. Evaluation is **pure** (`nix run` / `nix build` without `--impure`).

The CAD tree is **`vendor/mmi/`** (in git, sources only). Binaries are not committed; they live in the Nix store.

## Requirements

| Need | Notes |
|------|--------|
| x86_64 Linux | NixOS, Debian, Ubuntu, Fedora, etc. — install, VM, or **WSL2** |
| Nix (flakes) | [Install Nix](https://nixos.org/download.html); NixOS already has it |
| User namespaces | Needed by bubblewrap. Ubuntu 24.04+: if `nix run` fails, `sudo sysctl -w kernel.apparmor_restrict_unprivileged_userns=0` |
| Not WSL1 | WSL1 has no real kernel userns. `wsl --set-version <distro> 2` |

Windows-native is not a run target. Clone and run on x86_64 Linux (bare metal, VM, or WSL2).

## Layout

```
.
├── flake.nix / flake.lock
├── run.sh
├── vendor/mmi/                   # CAD sources + data (no store ELFs)
├── pdk/                          # MAX import Tcl, fetch script, Magic rc fallbacks
├── nix/rebuild/                  # patch + compile + install
├── nix/x11/                      # fonts, Xresources, Xvnc helper
├── nix/host-linux.sh             # distro/VM/WSL2 preflight
├── nix/launch.sh
└── data/{pdks,workspace,home}
```

## Quick start

```bash
chmod +x run.sh
./run.sh --prep-only     # optional: warm the Nix store
./run.sh max             # MAX on your desktop if DISPLAY is set, else noVNC
```

On a graphical VM the MAX/SUE/NST windows appear on the desktop. If you have no `DISPLAY`, open the printed URL (`http://127.0.0.1:6080/vnc.html?autoconnect=1`). Force the browser desktop with `MMI_USE_XVNC=1`.

## Commands

| Command | Action |
|---------|--------|
| `./run.sh` | CAD shell (Nix X + noVNC) |
| `./run.sh max` | Start MAX |
| `./run.sh sue` | Start SUE |
| `./run.sh nst` | Start NST |
| `./run.sh --prep-only` | Build into the Nix store |
| `nix flake check` | Verify required binaries |

| Environment | Action |
|-------------|--------|
| `MMI_NO_X=1` | Do not start X |
| `MMI_USE_HOST_X=1` | Require host `DISPLAY` (error if unset) |
| `MMI_USE_XVNC=1` | Always use TigerVNC + noVNC (ignore host DISPLAY) |
| `MMI_OPEN_BROWSER=0` | Do not auto-open noVNC |
| `MMI_CAD_ROOT=` | Writable overlay root (default: repo dir, or `~/.local/state/mmi-cad` for `nix run`) |

## Inside the FHS sandbox

| Path | Contents |
|------|----------|
| `/mmi-vendor/mmi` | Rebuilt 64-bit CAD + scripts/tech |
| `/mmi-bundle` | From `pdk/` |
| `/mmi-magic` | Magic VLSI (nixpkgs 25.05) |
| `/mmi-pdks` | Writable PDK overlay (`data/pdks`; empty until File → Import PDK in MAX) |
| `/mmi-xfonts` | Bitmap fonts for Nix Xvnc |
| `/mmi-home` | `data/home` |

## Reproducibility

- nixpkgs is `github:NixOS/nixpkgs/nixos-25.05`, locked to a commit + `narHash` (not a moving `nixos-unstable.tar.gz` URL).
- Vendor CAD sources are the git tree (`vendor/mmi`); the Nix derivation excludes `vendor/mmi/bin`.
- `SOURCE_DATE_EPOCH=315532800`, `LC_ALL=C`, `-frandom-seed=mmi-cad-040526`, deterministic `ar rcsD`, sorted `tar` and font indexes (`fonts.dir`).
- `.gitattributes` marks archives/images as binary and forces `eol=lf` on text so checkouts stay Linux line endings.

`nix build --rebuild --check .#mmi-vendor` on x86_64 Linux should reproduce the same output path.

Foundry PDKs are **not** in the flake. After `./run.sh max`, use **File → Import PDK** to download a compiled open_pdks tree (SkyWater, GF180MCU, or IHP) into `data/pdks`.
