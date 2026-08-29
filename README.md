# Micro Magic CAD (Docker)

Run Micro Magic CAD tools (`max`, `sue`, `nst`, and others) inside a Docker image based on Ubuntu 20.04, with X11 GUI forwarding to the host.

This directory is the **build & development** tree: `Dockerfile` + `run.sh`.

For **offline / end-user launchers** (load a pre-built image tar, no Dockerfile needed), see the sibling project [`mmi_cad`](../mmi_cad/).

## Requirements

- [Docker](https://docs.docker.com/get-docker/) Engine (daemon running)
- An X11 display:
  - **Linux:** graphical session (`DISPLAY` set)
  - **WSL2:** VcXsrv/Xming (or similar) with access control disabled
  - **macOS:** [XQuartz](https://www.xquartz.org/) with network clients allowed
- Vendor tarball used by the image build: `mmi_pd_040526.tar.gz` (must sit next to the `Dockerfile`)

## Quick start

```bash
chmod +x run.sh
./run.sh              # build image (first time), then open a shell in the container
./run.sh max          # build (if needed), then start a specific tool
```

## Import a PDK into MAX

After rebuilding the image, MAX has **File → Import PDK from URL...** and **Local → Import PDK from URL...** (Tcl-only; no Python).

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

`run.sh` bind-mounts host **`./pdks`** → container **`/opt/pdks`** (`PDK_ROOT`). One tree, not two copies:

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
| Who writes GDS | **Magic VLSI** (`/opt/magic/bin/magic`) | Tcl inside MAX (`mag_import.tcl`) |
| Layer rules | PDK **cifoutput** (contacts, implants, derived layers, units) | Fixed name → GDS layer table |
| Stdcells | Loaded from `$PDK_ROOT/.../libs.ref/*/mag` | Missing `.mag` → empty box |
| Needs | Magic 8.3 + `.magicrc` under `PDK_ROOT` | Nothing extra |
| Tapeout | **Yes** (same path as Caravel/OpenLane) | **No** — preview / interchange only |

Then MAX `gds_read` turns that GDS into `.max` (same for both).

1. Pick a source (Caravel analog sample, or a folder of `.mag` files)
2. Pick **GDS conversion method** (see table)
3. Pick the destination MAX technology
4. Output: `<design>/max_import/` (`*.gds`, `*.max`)

Rebuild once:

```bash
./run.sh --build-only
./run.sh max
```

## `run.sh` options

| Command | Description |
|--------|-------------|
| `./run.sh` | Build (if needed) and start an interactive shell |
| `./run.sh <tool>` | Build (if needed) and launch a CAD tool |
| `./run.sh --build-only` | Build `mmi-cad:latest` only |
| `./run.sh --save-tar` | Build (quietly) and write `mmi-cad-offline.tar` next to `run.sh` — does not start MAX |
| `./run.sh --no-build` | Skip build; run an existing image |
| `./run.sh --clean` | Remove image/containers/build cache, then rebuild |
| `./run.sh --help` | Show help |

Image name: **`mmi-cad:latest`**  
Container name: **`mmi-cad-session`**

## What the launcher does

1. Builds the Docker image from `Dockerfile` (unless skipped)
2. Configures X11 (`DISPLAY`, optional Xauthority, socket mounts)
3. Extracts Motif/X11 fonts from the image to `.mmi-xfonts` on the host and bind-mounts them (required for Motif GUI apps)
4. Starts the container with `--ipc=host` and display env vars

## Export an offline image archive

After a successful build you can produce a tar for machines that should **not** rebuild from the Dockerfile. This writes `mmi-cad-offline.tar` in this directory and does **not** start MAX:

```bash
./run.sh --save-tar
```

Same thing by hand:

```bash
docker save -o mmi-cad-offline.tar mmi-cad:latest
```

Copy that file into the [`mmi_cad`](../mmi_cad/) project (or let the offline launchers download the published archive).

## Layout

| Path | Role |
|------|------|
| `Dockerfile` | Image definition (Ubuntu 20.04 + MMI install) |
| `run.sh` | Build + run with X11 forwarding |
| `mmi_pd_040526.tar.gz` | Upstream Micro Magic package (required to build) |
| `.dockerignore` | Build context filter |
| `max_pdk/` | MAX menus: Import PDK; Import Magic (mag2gds + Tcl dump); Caravel sample |
| `pdks/` | Host shared `PDK_ROOT` (created by `run.sh`; not in the image) |
| `workspace/` | Host design folder → `/home/caduser/work` |
| `readme.txt` | Legacy host-install notes (older non-Docker flow) |

## Notes

- Motif tools need XLFD fonts on a path the **host** X server can read; `run.sh` handles this via `.mmi-xfonts`.
- Re-login (or `newgrp docker`) may be required after adding your user to the `docker` group on Linux.
- Do not commit large vendor archives or exported image tars unless you intend to; prefer release artifacts / external hosting.

## License / proprietary content

Micro Magic CAD binaries and the vendor tarball are subject to their own licenses. This repository’s scripts package and run that software in Docker; redistribute only what you are allowed to share.
