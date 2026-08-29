# Micro Magic CAD (Nix)

Run Micro Magic CAD tools (`max`, `sue`, `nst`, and others) in a **Nix FHS environment** on x86_64 Linux. There is no Docker image.

The vendor tools are **32-bit Linux ELF** (i486). Nix supplies a filesystem layout (`/lib`, `/usr`, 32-bit Motif/X11/glibc) so those binaries run on a modern host. **Magic VLSI** comes from nixpkgs (`magic-vlsi`) instead of being compiled in a container.

## What is possible

| Host | Works? |
|------|--------|
| **x86_64 Linux** | Yes — native Nix FHS |
| **WSL2** (x86_64) | Yes — same, with VcXsrv/Xming on Windows |
| **macOS** | **No.** These are Linux ELF binaries. Docker used to be a Linux VM; Nix cannot execute them on Darwin. Use a Linux machine or WSL2. |
| **ARM Linux** | **No**, not without an x86_64 VM. |
| **WSL1** | **No** — bubblewrap / user namespaces need WSL2. |

## Requirements

- x86_64 Linux or WSL2
- An X11 display:
  - **Linux:** graphical session (`DISPLAY` set)
  - **WSL2:** VcXsrv/Xming (or similar) with access control disabled
- Vendor tarball **`mmi_pd_040526.tar.gz`** next to `flake.nix` (same archive the old Docker build copied in)
- First run installs **curl** (static binary if missing) and **Nix** via the official installer. No apt/dnf/pacman/brew.

## Quick start

```bash
chmod +x run.sh
./run.sh              # first time: install Nix if needed, then open a CAD shell
./run.sh max          # start MAX
```

Place `mmi_pd_040526.tar.gz` in this directory before the first CAD launch.

The first `./run.sh` downloads nixpkgs and realises the FHS environment. That can take a while; later runs reuse the Nix store.

## Import a PDK into MAX

MAX has **File → Import PDK from URL...** and **Local → Import PDK from URL...** (Tcl-only; no Python).

The dialog has **ready-to-download** choices:

| PDK | Source |
|-----|--------|
| **SKY130A** | https://github.com/google/skywater-pdk |
| **GF180MCU** | https://github.com/google/gf180mcu-pdk |
| **IHP SG13G2** | https://github.com/IHP-GmbH/IHP-Open-PDK |

Or pick **Custom URL...** for any GitHub repo, `.tar.gz` / `.zip`, or a local directory.

1. Choose a PDK (or paste a URL)
2. Progress window shows **download percent**, then unpacking, then converting
3. Layers are written to a MAX `.source` file and compiled with `make_tech`
4. A new MAX starts with `max -tech <name>`

This installs a usable MAX **technology** (layers, GDS numbers, basic connectivity). It is not a full Cadence PDK drop-in.

## Import a Magic design into MAX

MAX cannot read `.mag` natively (`db_magic` was removed). Use **File → Import Magic Design Folder...** (also on **Local**).

### Shared PDK folder (Magic + MAX)

`run.sh` bind-mounts host **`./pdks`** → **`/opt/pdks`** (`PDK_ROOT`) inside the FHS env. One tree, not two copies:

| Path in `/opt/pdks` | Used by |
|---------------------|---------|
| `sky130A/` `gf180mcuD/` `ihp-sg13g2/` (open_pdks layout) | **Magic** mag2gds (`libs.tech/magic/*.magicrc`) |
| `max/tech/<name>/` (`.source` + `make_tech` output) | **MAX** (`max -tech <name>`) |

Put designs in **`./workspace`** (mounted at `/home/caduser/work`).

Tapeout mag2gds needs a real open_pdks/volare install, for example:

```text
pdks/sky130A/libs.tech/magic/sky130A.magicrc
```

**File → Import PDK from URL...** still builds a MAX technology and copies what it can into `PDK_ROOT`. A GitHub `skywater-pdk` archive usually **does not** include that `.magicrc`; drop a volare/open_pdks tree into `./pdks` for Magic.

### Two Mag → GDS methods (both kept)

The dialog asks which converter to use:

| | **Magic mag2gds** (default) | **Tcl paint dump** |
|--|-----------------------------|---------------------|
| Who writes GDS | **Magic VLSI** (`magic` from nixpkgs, also `/opt/magic/bin/magic`) | Tcl inside MAX (`mag_import.tcl`) |
| Layer rules | PDK **cifoutput** (contacts, implants, derived layers, units) | Fixed name → GDS layer table |
| Stdcells | Loaded from `$PDK_ROOT/.../libs.ref/*/mag` | Missing `.mag` → empty box |
| Needs | Magic 8.3 + `.magicrc` under `PDK_ROOT` | Nothing extra |
| Tapeout | **Yes** (same path as Caravel/OpenLane) | **No** — preview / interchange only |

Then MAX `gds_read` turns that GDS into `.max` (same for both).

1. Pick a source (Caravel analog sample, or a folder of `.mag` files)
2. Pick **GDS conversion method** (see table)
3. Pick the destination MAX technology
4. Output: `<design>/max_import/` (`*.gds`, `*.max`)

## `run.sh` options

| Command | Description |
|--------|-------------|
| `./run.sh` | Prepare Nix (if needed) and start an interactive CAD shell |
| `./run.sh <tool>` | Prepare (if needed) and launch a CAD tool |
| `./run.sh --prep-only` | Install/lock Nix and realise the FHS env; do not start CAD |
| `./run.sh --force-setup` | Re-run curl/Nix/flake prep even if `.mmi-nix-ready` exists |
| `./run.sh --force-install` | Re-extract `mmi_pd_040526.tar.gz` into `.mmi-prefix` |
| `./run.sh --force-fonts` | Re-copy Motif XLFD fonts into `.mmi-xfonts` |
| `./run.sh --clean` | Remove local prefix, fonts, bootstrap, and ready marker |
| `./run.sh --help` | Show help |

You can also enter the env with Nix directly (after the first `./run.sh --prep-only`):

```bash
export MMI_CAD_ROOT="$PWD"
nix run .#mmi-cad
nix run .#mmi-cad -- max
nix develop
```

## What the launcher does

1. Ensures **curl** and **Nix** (official installer; flakes enabled)
2. Creates `flake.lock` on first run
3. Sets `DISPLAY` (native X11 or WSL2 → Windows host)
4. `nix run .#mmi-cad` — FHS namespace with 32-bit X11/Motif libs
5. Extracts the vendor tarball into `.mmi-prefix` (once)
6. Points the X server at Motif bitmap fonts in `.mmi-xfonts`

## Layout

| Path | Role |
|------|------|
| `flake.nix` | Nix FHS env, fonts, Magic VLSI, PDK scripts |
| `run.sh` | Host bootstrap + launch |
| `nix/mmi-launch.sh` | Entrypoint inside the FHS env |
| `mmi_pd_040526.tar.gz` | Upstream Micro Magic package (required to run CAD) |
| `max_pdk/` | MAX menus: Import PDK; Import Magic; Caravel sample |
| `pdks/` | Host shared `PDK_ROOT` (created by the launcher) |
| `workspace/` | Host design folder → `/home/caduser/work` |
| `.mmi-prefix/` | Extracted CAD tree (not committed) |

## Libraries that changed vs the old Ubuntu 20.04 image

These substitutions are intentional so the stack is Nix-only:

- **glibc / libstdc++** — current nixpkgs (still ABI-compatible for the old binaries; `libstdc++.so.5` is included when nixpkgs provides it)
- **OpenSSL 3** instead of 1.1, with OpenSSL 1.1 added only if nixpkgs still has it
- **OpenMotif** (`motif`) for Motif widgets instead of whatever Ubuntu pulled in
- **Magic VLSI** from nixpkgs (`magic-vlsi`) instead of a git build in Docker
- **XLFD fonts** from nixpkgs `xorg.fontadobe75dpi` / `fontmiscmisc` / … instead of `apt xfonts-*`
- **curl/wget/file/tar** from Nix instead of Ubuntu

If a 32-bit binary still misses a `.so`, run `mmi-cad` then `ldd $(command -v max)` and we can add that library to `multiPkgs` in `flake.nix`.

## Notes

- Motif tools need XLFD fonts on a path the **host** X server can read; the launcher copies them to `.mmi-xfonts` (on WSL, a Windows path is passed to VcXsrv).
- Do not commit the vendor tarball or `.mmi-prefix` unless you intend to.
- User namespaces must be available (needed by bubblewrap). On Debian/Ubuntu that is the default; some hardened kernels disable them.

## License / proprietary content

Micro Magic CAD binaries and the vendor tarball are subject to their own licenses. This repository’s Nix files only wrap that software; redistribute only what you are allowed to share.
