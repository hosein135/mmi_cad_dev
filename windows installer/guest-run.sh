#!/bin/bash
# Copy the CAD tree off the VirtualBox share onto ext4, then run ./run.sh.
# Nix and bubblewrap need a normal Linux filesystem.
set -eu
src=/mmi-src
dst="${HOME}/mmi-cad"
host_port="${MMI_NOVNC_HOST_PORT:-6080}"

if [ ! -f "${src}/run.sh" ]; then
  echo "[guest] The project is not mounted at ${src}." >&2
  echo "[guest] If VirtualBox was just installed, reboot Windows and run the installer again." >&2
  exit 1
fi
if ! command -v rsync >/dev/null 2>&1; then
  sudo DEBIAN_FRONTEND=noninteractive apt-get update
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y rsync
fi

mkdir -p "${dst}"
echo "[guest] Copying the CAD tree onto the VM disk..."
rsync -a --delete \
  --exclude '.vagrant/' \
  --exclude 'vendor/result' \
  --exclude 'vendor/result-*' \
  --exclude '.mmi-bootstrap/' \
  --exclude 'data/home/' \
  "${src}/" "${dst}/"

while IFS= read -r -d '' f; do
  sed -i 's/\r$//' "$f"
  chmod +x "$f"
done < <(find "${dst}" \( -path '*/vendor/*' -o -path '*/.git/*' \) -prune -o -type f -name '*.sh' -print0)
chmod +x "${dst}/run.sh"

cd "${dst}"
export MMI_USE_XVNC=1
export MMI_OPEN_BROWSER=0
export MMI_NOVNC_PORT=6080
echo "[guest] Starting ./run.sh"
echo "[guest] On Windows, open http://127.0.0.1:${host_port}/vnc.html?autoconnect=1&resize=remote"
exec ./run.sh "$@"
