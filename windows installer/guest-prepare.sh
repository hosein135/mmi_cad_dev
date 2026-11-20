#!/bin/bash
# Prepare the Ubuntu VM so ./run.sh accepts it: desktop session files,
# user namespaces, and enough free disk for the Nix store.
set -eu
export DEBIAN_FRONTEND=noninteractive

echo "[guest] Installing an XFCE session so CAD accepts this virtual machine."
apt-get update
apt-get install -y xfce4-session rsync cloud-guest-utils

if ! compgen -G '/usr/share/xsessions/*.desktop' >/dev/null; then
  apt-get install -y xfce4
fi
if ! compgen -G '/usr/share/xsessions/*.desktop' >/dev/null; then
  echo "[guest] ERROR: no GUI desktop session is installed." >&2
  exit 1
fi

if [ -f /proc/sys/kernel/apparmor_restrict_unprivileged_userns ]; then
  sysctl -w kernel.apparmor_restrict_unprivileged_userns=0
  printf '%s\n' 'kernel.apparmor_restrict_unprivileged_userns=0' \
    > /etc/sysctl.d/99-mmi-cad-userns.conf
fi
if [ -f /proc/sys/kernel/unprivileged_userns_clone ]; then
  sysctl -w kernel.unprivileged_userns_clone=1
  printf '%s\n' 'kernel.unprivileged_userns_clone=1' \
    > /etc/sysctl.d/99-mmi-cad-userns-clone.conf
fi

split_disk_part() {
  local src="$1"
  DISK=""
  PART=""
  if [[ "${src}" =~ ^(/dev/nvme[0-9]+n[0-9]+)p([0-9]+)$ ]]; then
    DISK="${BASH_REMATCH[1]}"
    PART="${BASH_REMATCH[2]}"
  elif [[ "${src}" =~ ^(/dev/[a-z]+)([0-9]+)$ ]]; then
    DISK="${BASH_REMATCH[1]}"
    PART="${BASH_REMATCH[2]}"
  fi
}

grow_root() {
  local src pv
  src="$(findmnt -n -o SOURCE /)"
  echo "[guest] Root filesystem is ${src}"
  if [[ "${src}" == /dev/mapper/* ]]; then
    if ! command -v pvs >/dev/null 2>&1; then
      apt-get install -y lvm2
    fi
    pv="$(pvs --noheadings -o pv_name | awk 'NR==1 { gsub(/ /, ""); print }')"
    split_disk_part "${pv}"
    if [ -n "${DISK}" ]; then
      growpart "${DISK}" "${PART}" || true
      pvresize "${pv}" || true
      lvextend -l +100%FREE "${src}" || true
      resize2fs "${src}" || true
    fi
    return 0
  fi
  split_disk_part "${src}"
  if [ -n "${DISK}" ]; then
    growpart "${DISK}" "${PART}" || true
    resize2fs "${src}" || true
  fi
}
grow_root || true

avail_kb="$(df -P -k / | awk 'NR==2 { print $4 }')"
echo "[guest] Free space on / is ${avail_kb} KiB."
if [ "${avail_kb}" -lt $((8 * 1024 * 1024)) ]; then
  echo "[guest] ERROR: need at least 8 GiB free on / for Nix and the CAD build." >&2
  exit 1
fi

install -d -o vagrant -g vagrant /home/vagrant/mmi-cad
echo "[guest] Virtual machine is ready for CAD."
