#!/usr/bin/env bash
# Compatibility wrapper — this project is Nix-only (no Docker).
exec "$(cd "$(dirname "$0")" && pwd)/nix_run.sh" "$@"
