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

## `run.sh` options

| Command | Description |
|--------|-------------|
| `./run.sh` | Build (if needed) and start an interactive shell |
| `./run.sh <tool>` | Build (if needed) and launch a CAD tool |
| `./run.sh --build-only` | Build `mmi-cad:latest` only |
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

After a successful build you can produce a tar for machines that should **not** rebuild from the Dockerfile:

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
| `readme.txt` | Legacy host-install notes (older non-Docker flow) |

## Notes

- Motif tools need XLFD fonts on a path the **host** X server can read; `run.sh` handles this via `.mmi-xfonts`.
- Re-login (or `newgrp docker`) may be required after adding your user to the `docker` group on Linux.
- Do not commit large vendor archives or exported image tars unless you intend to; prefer release artifacts / external hosting.

## License / proprietary content

Micro Magic CAD binaries and the vendor tarball are subject to their own licenses. This repository’s scripts package and run that software in Docker; redistribute only what you are allowed to share.
