# Micro Magic CAD (Nix, native x86_64)

Reproducible Nix FHS environment on **x86_64 Linux**: bare metal, a VM, or WSL2. CAD tools are rebuilt from the public-domain sources as ELF 64-bit. **GUI uses a Nix-built TigerVNC X server**. View the desktop in a browser via noVNC.

nixpkgs is **NixOS 25.05**, locked by git revision + `narHash` in `flake.lock`. Evaluation is **pure** (`nix run` / `nix build` without `--impure`).

The CAD tree is **`vendor/mmi/`** (in git, sources only). Binaries are not committed; they live in the Nix store.

## Requirements

| Need | Notes |
|------|--------|
| x86_64 Linux | NixOS, Debian, Ubuntu, Fedora, etc. — install, VM, or **WSL2** |
| GUI desktop | Required on bare metal and VMs (GNOME, KDE, XFCE, ...). WSL must be **WSL2** (not WSL1) |
| ~6 GiB free | First `./run.sh` / `--prep-only` (~1 GiB stays in the Nix store after install) |
| Nix 2.28+ | Nix shipped with NixOS 25.05. An older Nix already on the machine is rejected; other nixpkgs channels are ignored |
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

On a graphical VM the MAX/SUE/NST windows appear on the desktop. `./run.sh` checks for WSL2, a GUI desktop on Linux, and free disk before it starts. If CAD starts Nix Xvnc instead of your session, open the printed URL (`http://127.0.0.1:6080/vnc.html?autoconnect=1`). Force the browser desktop with `MMI_USE_XVNC=1`.

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
| `/mmi-magic` | nixpkgs **`magic-vlsi`** (not built from this repo) |
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

## Magic VLSI (`magic-vlsi`)

Magic is the **nixpkgs 25.05 `magic-vlsi` package**. The flake does not compile Magic; it puts that package on `PATH` and bind-mounts it at `/mmi-magic` inside the FHS sandbox (`/mmi-magic/bin/magic`).

**File → Import Magic Design Folder** converts `.mag` → GDS (via Magic `cifoutput`) → MAX `.max`. When the convert finishes, MAX also starts Magic on the **original** `.mag` (same X/Xvnc display) so you can compare Magic’s layout with the converted MAX view. Uncheck *Also open original Mag in Magic VLSI* in the import dialog to skip that.

**File → Import Image as Layout** traces a bitmap onto the open edit cell. Dark pixels become rectangles on a layer you pick. Touching pixels are merged, so a logo is a few hundred shapes instead of one rectangle per pixel. PBM, PGM, PPM, and GIF are read in MAX. PNG and JPEG are resized with ImageMagick (`imagemagick` in the CAD environment). Undo removes the paste.
