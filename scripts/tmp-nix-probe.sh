#!/usr/bin/env bash
set +e
# shellcheck disable=SC1091
. /home/os/.nix-profile/etc/profile.d/nix.sh
echo "NIX_PATH=${NIX_PATH-<unset>}"
echo "=== config system ==="
nix --extra-experimental-features 'nix-command flakes' config show system 2>&1
echo "=== config max-jobs ==="
nix --extra-experimental-features 'nix-command flakes' config show max-jobs 2>&1
echo "=== config restrict-eval ==="
nix --extra-experimental-features 'nix-command flakes' config show restrict-eval 2>&1
echo "=== store ping ==="
nix --extra-experimental-features 'nix-command flakes' store ping 2>&1
echo "=== store ping json ==="
nix --extra-experimental-features 'nix-command flakes' store ping --json 2>&1
echo "=== channel list ==="
nix-channel --list 2>&1
echo "=== version file bytes ==="
od -c "$HOME/.nix-defexpr/channels/nixpkgs/.version" | head
