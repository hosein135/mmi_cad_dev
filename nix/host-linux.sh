#!/usr/bin/env bash
# x86_64 Linux preflight: bare metal, VM, or WSL2 (not WSL1, not Windows-native).
# Sourced from run.sh. Expects info/warn/error.
# Missing git and curl are installed with the distro package manager. If that
# cannot provide curl, a static binary is used. Nix is pinned to 2.28.5
# (the NixOS 25.05 package manager). Any other Nix is replaced. On NixOS,
# /nix is kept and 2.28.5 is installed into the user profile.

# Completed `nix run .#mmi-cad` runtime closure (nixos-25.05), measured:
# 934120792 bytes ≈ 891 MiB across 258 store paths. About 1 GiB remains
# on disk after install. First run also unpacks NARs, copies vendor
# sources (~313 MiB), and compiles CAD — keep several extra GiB free.
MMI_STORE_AFTER_INSTALL_BYTES=$((1024 * 1024 * 1024))
MMI_FIRST_INSTALL_FREE_BYTES=$((6 * 1024 * 1024 * 1024))
MMI_RUNTIME_FREE_BYTES=$((1024 * 1024 * 1024))

# stunnel/static-curl release used when the distro cannot install curl.
MMI_CURL_STATIC_VERSION="8.20.0"
# NixOS 25.05's package manager is Nix 2.28.5 (nixpkgs nixVersions.stable).
# Any other Nix, including a newer 2.35, is replaced. nix upgrade-nix is not
# used: it installs the latest manager and changes flake.lock behavior.
MMI_NIX_PIN_VERSION="2.28.5"
MMI_NIX_PIN_MAJOR=2
MMI_NIX_PIN_MINOR=28
MMI_NIX_PIN_PATCH=5
MMI_NIX_INSTALL_URL="https://releases.nixos.org/nix/nix-${MMI_NIX_PIN_VERSION}/install"
MMI_BOOTSTRAP_DIR="${SCRIPT_DIR}/.mmi-bootstrap"
MMI_BOOTSTRAP_BIN="${MMI_BOOTSTRAP_DIR}/bin"

mmi_is_wsl() {
  if [ -n "${WSL_DISTRO_NAME:-}" ] || [ -n "${WSL_INTEROP:-}" ]; then
    return 0
  fi
  [ -f /proc/sys/fs/binfmt_misc/WSLInterop ] && return 0
  grep -qi microsoft /proc/version 2>/dev/null && return 0
  grep -qi microsoft /proc/sys/kernel/osrelease 2>/dev/null && return 0
  return 1
}

mmi_is_wsl2() {
  [ -d /run/WSL ] && return 0
  uname -r | grep -qiE 'microsoft-standard|WSL2' && return 0
  grep -qiE 'microsoft-standard|WSL2' /proc/version 2>/dev/null && return 0
  return 1
}

mmi_is_wsl1() {
  mmi_is_wsl && ! mmi_is_wsl2
}

# True if this Linux install has a GUI desktop (session files, DM, or live X/Wayland).
mmi_has_gui_desktop() {
  local f unit
  [ -n "${WAYLAND_DISPLAY:-}" ] && return 0
  [ -n "${DISPLAY:-}" ] && return 0
  [ -n "${XDG_CURRENT_DESKTOP:-}" ] && return 0
  [ -n "${DESKTOP_SESSION:-}" ] && return 0

  for f in \
    /usr/share/xsessions/*.desktop \
    /usr/share/wayland-sessions/*.desktop \
    /usr/local/share/xsessions/*.desktop \
    /usr/local/share/wayland-sessions/*.desktop \
    /run/current-system/sw/share/xsessions/*.desktop \
    /run/current-system/sw/share/wayland-sessions/*.desktop
  do
    [ -f "$f" ] && return 0
  done

  for f in /tmp/.X11-unix/X[0-9]*; do
    [ -S "$f" ] && return 0
  done

  if command -v systemctl >/dev/null 2>&1; then
    for unit in display-manager gdm gdm3 sddm lightdm lxdm xdm greetd; do
      systemctl is-active --quiet "$unit" 2>/dev/null && return 0
    done
  fi

  return 1
}

mmi_fs_free_bytes() {
  local kb
  kb="$(df -P -k "$1" 2>/dev/null | awk 'NR==2 {print $4}')"
  if [ -z "${kb}" ] || ! [ "${kb}" -ge 0 ] 2>/dev/null; then
    return 1
  fi
  printf '%s' $((kb * 1024))
}

mmi_fs_mount() {
  df -P -k "$1" 2>/dev/null | awk 'NR==2 {print $6}'
}

mmi_fmt_bytes() {
  awk -v b="$1" 'BEGIN {
    if (b >= 1073741824) printf "%.1f GiB", b / 1073741824
    else if (b >= 1048576) printf "%.0f MiB", b / 1048576
    else printf "%s B", b
  }'
}

# vendor/result is created by ./run.sh --prep-only (not by plain nix run).
mmi_cad_already_built() {
  [ -x "${SCRIPT_DIR}/vendor/result/mmi/bin/max.bin" ] \
    || [ -x "${SCRIPT_DIR}/vendor/result/mmi/bin/max" ]
}

mmi_check_free_space() {
  local store_need work_need tmp_need
  local store_path store_mnt tmp_mnt
  local path mount free need fail seen
  local -a check_paths

  if mmi_cad_already_built; then
    store_need="${MMI_RUNTIME_FREE_BYTES}"
  else
    store_need="${MMI_FIRST_INSTALL_FREE_BYTES}"
  fi
  work_need="${MMI_RUNTIME_FREE_BYTES}"
  tmp_need=$((512 * 1024 * 1024))

  if [ -d /nix/store ]; then
    store_path=/nix/store
  elif [ -d /nix ]; then
    store_path=/nix
  else
    store_path=/
  fi
  store_mnt="$(mmi_fs_mount "${store_path}" || true)"
  tmp_mnt="$(mmi_fs_mount /tmp || true)"

  check_paths=("${store_path}" "${SCRIPT_DIR}" /tmp)
  seen="|"
  fail=0
  for path in "${check_paths[@]}"; do
    mount="$(mmi_fs_mount "${path}" || true)"
    [ -n "${mount}" ] || mount="${path}"
    case "${seen}" in
      *"|${mount}|"*) continue ;;
    esac
    seen="${seen}${mount}|"

    need="${work_need}"
    if [ -n "${tmp_mnt}" ] && [ "${mount}" = "${tmp_mnt}" ]; then
      need="${tmp_need}"
    fi
    # Nix store filesystem wins when it shares a mount with /tmp or the repo.
    if [ -n "${store_mnt}" ] && [ "${mount}" = "${store_mnt}" ]; then
      need="${store_need}"
    fi

    if ! free="$(mmi_fs_free_bytes "${path}")"; then
      warn "Could not measure free space on ${path}."
      continue
    fi
    if [ "${free}" -lt "${need}" ]; then
      if [ "${fail}" -eq 0 ]; then
        error "Not enough free space is available."
        error "Need $(mmi_fmt_bytes "${store_need}") free for the Nix store (about $(mmi_fmt_bytes "${MMI_STORE_AFTER_INSTALL_BYTES}") stays after install)."
      fi
      error "  ${path}: $(mmi_fmt_bytes "${free}") free, need $(mmi_fmt_bytes "${need}")"
      fail=1
    fi
  done

  if [ "${fail}" -ne 0 ]; then
    error "Free disk space and retry."
    return 1
  fi

  info "Disk: Nix store needs $(mmi_fmt_bytes "${store_need}") free (~$(mmi_fmt_bytes "${MMI_STORE_AFTER_INSTALL_BYTES}") remains after install)"
  return 0
}

# Ubuntu/Debian set this to 1, which makes bubblewrap fail with
# "bwrap: setting up uid map: Permission denied".
mmi_relax_apparmor_userns() {
  local proc="/proc/sys/kernel/apparmor_restrict_unprivileged_userns"
  local key="kernel.apparmor_restrict_unprivileged_userns"
  local dropin="/etc/sysctl.d/99-mmi-cad-userns.conf"
  local value

  [ -f "$proc" ] || return 0
  value="$(cat "$proc" 2>/dev/null || echo 0)"
  [ "$value" = "1" ] || return 0

  info "AppArmor is blocking unprivileged user namespaces (bubblewrap needs them)."
  if [ "$(id -u)" -ne 0 ]; then
    info "Setting ${key}=0. This may ask for your sudo password."
  fi
  if ! mmi_as_root sysctl -w "${key}=0"; then
    error "Could not set ${key}=0."
    error "Run:  sudo sysctl -w ${key}=0"
    return 1
  fi
  value="$(cat "$proc" 2>/dev/null || echo 1)"
  if [ "$value" != "0" ]; then
    error "${key} is still ${value} after sysctl."
    return 1
  fi

  if [ ! -f "$dropin" ] || ! grep -qx "${key}=0" "$dropin" 2>/dev/null; then
    if printf '%s\n' "${key}=0" | mmi_as_root tee "$dropin" >/dev/null; then
      info "Saved ${key}=0 in ${dropin} (kept across reboot)."
    else
      warn "The setting applies until reboot. To keep it:"
      warn "  echo '${key}=0' | sudo tee ${dropin}"
    fi
  fi
  return 0
}

mmi_check_linux_host() {
  local os arch
  os="$(uname -s)"
  arch="$(uname -m)"

  case "${os}" in
    Linux) ;;
    *)
      error "Need x86_64 Linux (bare metal, VM, or WSL2). This OS is ${os}."
      error "On Windows: use WSL2 (not WSL1) or an x86_64 Linux VM, then run ./run.sh there."
      return 1
      ;;
  esac

  if [ "${arch}" != "x86_64" ] && [ "${arch}" != "amd64" ]; then
    error "CAD binaries are ELF x86_64. This CPU is ${arch}."
    error "Use an x86_64 machine or an x86_64 VM (qemu/KVM, VirtualBox, Hyper-V, cloud)."
    return 1
  fi

  if mmi_is_wsl && ! mmi_is_wsl2; then
    error "WSL1 is not supported (kernel $(uname -r)). Use WSL2."
    error "Switch this distro to WSL2:  wsl --set-version <distro> 2"
    error "Then open that WSL2 distro and run ./run.sh there."
    return 1
  fi

  if mmi_is_wsl2; then
    info "Host: WSL2 x86_64"
  else
    if ! mmi_has_gui_desktop; then
      error "This Linux system has no GUI desktop (no X/Wayland session and no desktop environment)."
      error "Install a desktop (GNOME, KDE Plasma, XFCE, Cinnamon, MATE, ...) or use a graphical VM."
      error "Headless servers are not supported. WSL users must use WSL2."
      return 1
    fi
    if [ -f /sys/class/dmi/id/product_name ] || [ -d /sys/hypervisor ]; then
      info "Host: x86_64 Linux (bare metal or VM) with GUI desktop"
    else
      info "Host: x86_64 Linux with GUI desktop"
    fi
  fi

  if [ -f /proc/sys/kernel/unprivileged_userns_clone ]; then
    if [ "$(cat /proc/sys/kernel/unprivileged_userns_clone 2>/dev/null || echo 1)" = "0" ] \
      && [ "$(id -u)" != "0" ]; then
      error "Unprivileged user namespaces are disabled (needed by Nix FHS/bubblewrap)."
      error "Fix (then retry):  sudo sysctl -w kernel.unprivileged_userns_clone=1"
      return 1
    fi
  fi

  mmi_relax_apparmor_userns || return 1

  if [ ! -w /tmp ]; then
    error "/tmp is not writable. The X11 socket and Nix builds need it."
    return 1
  fi

  return 0
}

mmi_is_nixos() {
  [ -f /etc/os-release ] && grep -q '^ID=nixos$' /etc/os-release
}

# sudo sets USER=root and hides the caller's Nix profile. The account that
# ran sudo is SUDO_USER; assign that to USER and continue as $USER.
mmi_rerun_as_desktop_user() {
  local home uid quoted a login
  [ "$(id -u)" -eq 0 ] || return 0
  if [ "${MMI_AS_DESKTOP_USER:-}" = "1" ]; then
    error "Could not switch from root to \$USER."
    return 1
  fi
  if [ -n "${SUDO_USER:-}" ] && [ "${SUDO_USER}" != "root" ]; then
    USER="${SUDO_USER}"
  else
    login=""
    if command -v logname >/dev/null 2>&1; then
      login="$(logname 2>/dev/null || true)"
    fi
    if [ -n "$login" ] && [ "$login" != "root" ]; then
      USER="$login"
    else
      error "Run ./run.sh as your own user. Under sudo, \$USER is root."
      error "The account that ran sudo was not in \$SUDO_USER."
      return 1
    fi
  fi
  export USER
  export LOGNAME="$USER"
  home="$(getent passwd "$USER" | awk -F: '{ print $6; exit }')"
  if [ -z "$home" ] || [ ! -d "$home" ]; then
    error "No home directory for \$USER (${USER})."
    return 1
  fi
  uid="$(id -u "$USER")"
  info "Continuing as \$USER (${USER})."
  export MMI_AS_DESKTOP_USER=1
  export HOME="$home"
  export PATH="${home}/.nix-profile/bin:/nix/var/nix/profiles/default/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
  if [ -z "${XDG_RUNTIME_DIR:-}" ] || [ ! -d "${XDG_RUNTIME_DIR}" ]; then
    if [ -d "/run/user/${uid}" ]; then
      export XDG_RUNTIME_DIR="/run/user/${uid}"
    fi
  fi
  cd "$SCRIPT_DIR"
  if command -v runuser >/dev/null 2>&1; then
    exec runuser -u "$USER" --preserve-environment -- "$SCRIPT_DIR/run.sh" "$@"
  fi
  quoted=""
  for a in "$@"; do
    quoted="${quoted} $(printf '%q' "$a")"
  done
  exec su -m "$USER" -s /bin/bash -c "cd $(printf '%q' "$SCRIPT_DIR") && exec ./run.sh${quoted}"
  error "Could not switch from root to \$USER (${USER})."
  return 1
}

mmi_as_root() {
  if [ "$(id -u)" -eq 0 ]; then
    "$@"
  elif command -v sudo >/dev/null 2>&1; then
    sudo "$@"
  else
    error "Need root to run: $*"
    return 1
  fi
}

mmi_os_release_value() {
  local key="$1" line file
  # MMI_OS_RELEASE overrides /etc/os-release so distro detection can be tested.
  file="${MMI_OS_RELEASE:-/etc/os-release}"
  [ -r "$file" ] || return 1
  line="$(grep -m1 "^${key}=" "$file" 2>/dev/null || true)"
  [ -n "$line" ] || return 1
  line="${line#${key}=}"
  line="${line#\"}"
  line="${line%\"}"
  line="${line#\'}"
  line="${line%\'}"
  printf '%s' "$line"
}

mmi_blob_has() {
  local blob="$1" word
  shift
  for word in "$@"; do
    case "$blob" in
      *" ${word} "*) return 0 ;;
    esac
  done
  return 1
}

mmi_prepend_path_dir() {
  local dir="$1"
  [ -d "$dir" ] || return 0
  case ":${PATH}:" in
    *":${dir}:"*) return 0 ;;
  esac
  PATH="${dir}:${PATH}"
  export PATH
}

# True when the binaries for a package-manager id are on PATH.
mmi_pkg_manager_ready() {
  case "$1" in
    apt) command -v apt-get >/dev/null 2>&1 || command -v apt >/dev/null 2>&1 ;;
    dnf) command -v dnf >/dev/null 2>&1 ;;
    yum) command -v yum >/dev/null 2>&1 ;;
    microdnf) command -v microdnf >/dev/null 2>&1 ;;
    tdnf) command -v tdnf >/dev/null 2>&1 ;;
    pacman) command -v pacman >/dev/null 2>&1 ;;
    zypper) command -v zypper >/dev/null 2>&1 ;;
    apk) command -v apk >/dev/null 2>&1 ;;
    xbps) command -v xbps-install >/dev/null 2>&1 ;;
    emerge) command -v emerge >/dev/null 2>&1 ;;
    eopkg) command -v eopkg >/dev/null 2>&1 ;;
    slackpkg) command -v slackpkg >/dev/null 2>&1 ;;
    swupd) command -v swupd >/dev/null 2>&1 ;;
    urpmi) command -v urpmi >/dev/null 2>&1 ;;
    guix) command -v guix >/dev/null 2>&1 ;;
    nixos) command -v nix-env >/dev/null 2>&1 || command -v nix >/dev/null 2>&1 ;;
    *) return 1 ;;
  esac
}

mmi_first_ready_pm() {
  local name
  for name in "$@"; do
    if mmi_pkg_manager_ready "$name"; then
      printf '%s\n' "$name"
      return 0
    fi
  done
  return 1
}

# Package manager for this distro, from /etc/os-release, then from PATH.
# Prints one id: apt, dnf, yum, pacman, zypper, apk, ...
mmi_linux_pkg_manager() {
  local id like blob picked=""
  id="$(mmi_os_release_value ID || true)"
  like="$(mmi_os_release_value ID_LIKE || true)"
  blob=" $(printf '%s %s' "$id" "$like" | tr '[:upper:]' '[:lower:]') "

  if mmi_blob_has "$blob" nixos || mmi_is_nixos; then
    printf '%s\n' nixos
    return 0
  fi

  if mmi_blob_has "$blob" \
    debian ubuntu linuxmint pop elementary zorin kali raspbian \
    devuan parrot deepin neon mx pureos trisquel linuxlite tails
  then
    picked=apt
  elif mmi_blob_has "$blob" photon; then
    picked=tdnf
  elif mmi_blob_has "$blob" \
    fedora rhel centos rocky almalinux ol amzn nobara scientific \
    eurolinux openeuler anolis openmandriva
  then
    picked="$(mmi_first_ready_pm dnf microdnf yum || true)"
  elif mmi_blob_has "$blob" mageia mandriva; then
    picked="$(mmi_first_ready_pm dnf urpmi || true)"
  elif mmi_blob_has "$blob" \
    arch manjaro endeavouros garuda artix arcolinux cachyos parabola
  then
    picked=pacman
  elif mmi_blob_has "$blob" \
    suse opensuse opensuse-leap opensuse-tumbleweed sles sled
  then
    picked=zypper
  elif mmi_blob_has "$blob" alpine postmarketos; then
    picked=apk
  elif mmi_blob_has "$blob" void; then
    picked=xbps
  elif mmi_blob_has "$blob" gentoo funtoo; then
    picked=emerge
  elif mmi_blob_has "$blob" solus; then
    picked=eopkg
  elif mmi_blob_has "$blob" slackware; then
    picked=slackpkg
  elif mmi_blob_has "$blob" clear-linux-os; then
    picked=swupd
  elif mmi_blob_has "$blob" guix; then
    picked=guix
  fi

  if [ -n "$picked" ] && mmi_pkg_manager_ready "$picked"; then
    printf '%s\n' "$picked"
    return 0
  fi

  if picked="$(mmi_first_ready_pm \
    apt dnf microdnf yum tdnf pacman zypper apk xbps emerge \
    eopkg urpmi slackpkg swupd guix nixos)"
  then
    printf '%s\n' "$picked"
    return 0
  fi
  return 1
}

mmi_install_nixos_packages() {
  local p
  local -a attrs=() flake=()
  for p in "$@"; do
    attrs+=("nixos.${p}")
    flake+=("nixpkgs#${p}")
  done
  if command -v nix-env >/dev/null 2>&1; then
    if nix-env -iA "${attrs[@]}"; then
      return 0
    fi
    warn "nix-env could not install $*. Trying nix profile."
  fi
  if command -v nix >/dev/null 2>&1; then
    nix --extra-experimental-features "nix-command flakes" profile install "${flake[@]}" \
      || return 1
    return 0
  fi
  error "This NixOS system cannot install $*."
  error "Add $* to configuration.nix, then run: sudo nixos-rebuild switch"
  return 1
}

# Install package names with a manager id from mmi_linux_pkg_manager.
mmi_install_host_packages() {
  local pm="$1"
  shift
  local p aptbin
  local -a pkgs=("$@") atoms=()
  [ ${#pkgs[@]} -gt 0 ] || return 0

  case "$pm" in
    apt)
      aptbin=apt-get
      if ! command -v apt-get >/dev/null 2>&1; then
        aptbin=apt
      fi
      mmi_as_root env DEBIAN_FRONTEND=noninteractive "$aptbin" update || return 1
      mmi_as_root env DEBIAN_FRONTEND=noninteractive "$aptbin" install -y "${pkgs[@]}" || return 1
      ;;
    dnf)
      mmi_as_root dnf install -y "${pkgs[@]}" || return 1
      ;;
    yum)
      mmi_as_root yum install -y "${pkgs[@]}" || return 1
      ;;
    microdnf)
      mmi_as_root microdnf install -y "${pkgs[@]}" || return 1
      ;;
    tdnf)
      mmi_as_root tdnf install -y "${pkgs[@]}" || return 1
      ;;
    pacman)
      mmi_as_root pacman -Sy --needed --noconfirm "${pkgs[@]}" || return 1
      ;;
    zypper)
      mmi_as_root zypper --non-interactive install "${pkgs[@]}" || return 1
      ;;
    apk)
      mmi_as_root apk add --no-cache "${pkgs[@]}" || return 1
      ;;
    xbps)
      mmi_as_root xbps-install -Sy "${pkgs[@]}" || return 1
      ;;
    emerge)
      for p in "${pkgs[@]}"; do
        case "$p" in
          git) atoms+=(dev-vcs/git) ;;
          curl) atoms+=(net-misc/curl) ;;
          xz) atoms+=(app-arch/xz-utils) ;;
          *) atoms+=("$p") ;;
        esac
      done
      mmi_as_root emerge --ask=n --noreplace "${atoms[@]}" || return 1
      ;;
    eopkg)
      mmi_as_root eopkg update-repo || return 1
      mmi_as_root eopkg install -y "${pkgs[@]}" || return 1
      ;;
    urpmi)
      mmi_as_root urpmi --auto "${pkgs[@]}" || return 1
      ;;
    slackpkg)
      mmi_as_root slackpkg -batch=on -default_answer=y update || return 1
      mmi_as_root slackpkg -batch=on -default_answer=y install "${pkgs[@]}" || return 1
      ;;
    swupd)
      mmi_as_root swupd bundle-add --assume=yes "${pkgs[@]}" || return 1
      ;;
    guix)
      guix install "${pkgs[@]}" || return 1
      ;;
    nixos)
      mmi_install_nixos_packages "${pkgs[@]}" || return 1
      ;;
    *)
      error "No install command for package manager '${pm}'."
      return 1
      ;;
  esac
}

mmi_prepend_bootstrap_path() {
  if [ -d "${MMI_BOOTSTRAP_BIN}" ]; then
    case ":${PATH}:" in
      *":${MMI_BOOTSTRAP_BIN}:"*) ;;
      *) export PATH="${MMI_BOOTSTRAP_BIN}:${PATH}" ;;
    esac
  fi
}

mmi_refresh_tool_path() {
  mmi_prepend_bootstrap_path
  mmi_prepend_path_dir /usr/local/sbin
  mmi_prepend_path_dir /usr/local/bin
  mmi_prepend_path_dir /usr/sbin
  mmi_prepend_path_dir /usr/bin
  mmi_prepend_path_dir /bin
  if [ -n "${HOME:-}" ]; then
    mmi_prepend_path_dir "${HOME}/.nix-profile/bin"
    mmi_prepend_path_dir "${HOME}/.guix-profile/bin"
    mmi_prepend_path_dir "${HOME}/.local/bin"
  fi
  mmi_prepend_path_dir /run/current-system/sw/bin
  hash -r || true
}

# Command name -> distro package. Debian's xz binary is in xz-utils.
mmi_package_name() {
  local pm="$1" tool="$2"
  case "${pm}:${tool}" in
    apt:xz) printf '%s\n' xz-utils ;;
    emerge:git) printf '%s\n' dev-vcs/git ;;
    emerge:curl) printf '%s\n' net-misc/curl ;;
    emerge:xz) printf '%s\n' app-arch/xz-utils ;;
    *) printf '%s\n' "${tool}" ;;
  esac
}

# Install whichever of the named commands is missing. Returns 1 when the
# package manager cannot do it; the caller may still fetch a static curl.
mmi_ensure_commands() {
  local tool pm pretty pkg
  local -a missing=() pkgs=() still=()
  for tool in "$@"; do
    if ! command -v "${tool}" >/dev/null 2>&1; then
      missing+=("${tool}")
    fi
  done
  if [ ${#missing[@]} -eq 0 ]; then
    return 0
  fi

  if ! pm="$(mmi_linux_pkg_manager)"; then
    warn "Need ${missing[*]} before Nix is installed."
    warn "No package manager found. Install ${missing[*]} and retry."
    return 1
  fi
  for tool in "${missing[@]}"; do
    pkg="$(mmi_package_name "${pm}" "${tool}")"
    pkgs+=("${pkg}")
  done

  pretty="$(mmi_os_release_value PRETTY_NAME || true)"
  if [ -n "$pretty" ]; then
    info "Installing missing ${missing[*]} with ${pm} (${pretty})."
  else
    info "Installing missing ${missing[*]} with ${pm}."
  fi
  case "$pm" in
    nixos|guix) ;;
    *)
      if [ "$(id -u)" -ne 0 ]; then
        info "This may ask for your sudo password."
      fi
      ;;
  esac

  if ! mmi_install_host_packages "$pm" "${pkgs[@]}"; then
    warn "Could not install ${missing[*]} with ${pm}."
    return 1
  fi

  mmi_refresh_tool_path
  for tool in "${missing[@]}"; do
    if ! command -v "$tool" >/dev/null 2>&1; then
      still+=("$tool")
    fi
  done
  if [ ${#still[@]} -ne 0 ]; then
    warn "Package install finished, but still missing: ${still[*]}"
    return 1
  fi
  info "Installed ${missing[*]}."
  return 0
}

# git (flake work tree) and curl (Nix installer) before Nix is installed.
mmi_ensure_git_and_curl() {
  mmi_ensure_commands git curl
}

# curl, else wget, else python3. Used for the Nix installer and static curl.
mmi_http_get() {
  local url="$1" dest="$2" dir
  dir="$(dirname "$dest")"
  mkdir -p "$dir"
  rm -f "$dest"
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL --proto '=https' --tlsv1.2 --retry 3 --retry-delay 2 -o "$dest" "$url" \
      || { rm -f "$dest"; return 1; }
  elif command -v wget >/dev/null 2>&1; then
    wget -qO "$dest" "$url" || { rm -f "$dest"; return 1; }
  elif command -v python3 >/dev/null 2>&1; then
    python3 - "$url" "$dest" <<'PY' || { rm -f "$dest"; return 1; }
import sys
from urllib.request import urlopen
url, dest = sys.argv[1], sys.argv[2]
with urlopen(url, timeout=180) as src, open(dest, "wb") as out:
    while True:
        chunk = src.read(1024 * 1024)
        if not chunk:
            break
        out.write(chunk)
PY
  else
    error "Cannot download ${url}: need curl, wget, or python3."
    return 1
  fi
  if [ ! -s "$dest" ]; then
    rm -f "$dest"
    error "Download was empty: ${url}"
    return 1
  fi
}

mmi_extract_tar_xz() {
  local archive="$1" dest="$2"
  mkdir -p "$dest"
  if tar -xJf "$archive" -C "$dest" 2>/dev/null; then
    return 0
  fi
  error "Cannot extract ${archive}: need tar with xz support (tar -xJf)."
  return 1
}

mmi_static_curl_asset() {
  local os arch
  os="$(uname -s)"
  arch="$(uname -m)"
  case "$os" in
    Linux)
      case "$arch" in
        x86_64|amd64) printf '%s\n' "curl-linux-x86_64-musl-${MMI_CURL_STATIC_VERSION}.tar.xz" ;;
        *)
          error "Unsupported Linux arch for static curl: ${arch}"
          return 1
          ;;
      esac
      ;;
    *)
      error "Unsupported OS for static curl: ${os}"
      return 1
      ;;
  esac
}

mmi_ensure_static_curl() {
  local asset url archive extract_dir found
  mmi_prepend_bootstrap_path
  if command -v curl >/dev/null 2>&1; then
    info "curl: $(curl --version 2>/dev/null | head -1)"
    return 0
  fi

  info "curl not found — downloading a static binary ..."
  asset="$(mmi_static_curl_asset)" || return 1
  url="https://github.com/stunnel/static-curl/releases/download/${MMI_CURL_STATIC_VERSION}/${asset}"
  mkdir -p "${MMI_BOOTSTRAP_BIN}" "${MMI_BOOTSTRAP_DIR}/tmp"
  archive="${MMI_BOOTSTRAP_DIR}/tmp/${asset}"
  extract_dir="${MMI_BOOTSTRAP_DIR}/tmp/curl-extract-$$"
  rm -rf "$extract_dir"
  mkdir -p "$extract_dir"

  if ! command -v xz >/dev/null 2>&1; then
    mmi_install_python_xz || true
  fi
  mmi_http_get "$url" "$archive" || return 1
  mmi_extract_tar_xz "$archive" "$extract_dir" || return 1

  found="$(find "$extract_dir" -type f -name curl 2>/dev/null | head -1 || true)"
  if [ -z "$found" ]; then
    error "Static curl archive had no 'curl' binary: ${asset}"
    return 1
  fi
  cp -f "$found" "${MMI_BOOTSTRAP_BIN}/curl"
  chmod +x "${MMI_BOOTSTRAP_BIN}/curl"
  rm -rf "$extract_dir" "$archive"
  mmi_prepend_bootstrap_path
  info "curl installed (static): $(curl --version 2>/dev/null | head -1)"
}

# The Nix installer refuses to unpack its .tar.xz unless xz is on PATH.
# tar -xJf is what actually extracts; this command only has to exist and
# decompress stdin when tar shells out to it.
mmi_install_python_xz() {
  command -v python3 >/dev/null 2>&1 || return 1
  python3 -c 'import lzma' >/dev/null 2>&1 || return 1
  mkdir -p "${MMI_BOOTSTRAP_BIN}"
  cat > "${MMI_BOOTSTRAP_BIN}/xz" <<'EOF'
#!/bin/sh
# tar runs "xz -d" with the archive on stdin. A filename is used when one
# is passed. Flags stay in this shell: Python treats a leading -dc as its
# own options and drops the path.
while [ $# -gt 0 ]; do
  case "$1" in
    -*) shift ;;
    *) break ;;
  esac
done
if [ $# -gt 0 ]; then
  exec python3 -c 'import lzma, sys
src = lzma.open(sys.argv[1], "rb")
while True:
    chunk = src.read(1024 * 1024)
    if not chunk:
        break
    sys.stdout.buffer.write(chunk)
' "$1"
fi
exec python3 -c 'import lzma, sys
src = lzma.open(sys.stdin.buffer, "rb")
while True:
    chunk = src.read(1024 * 1024)
    if not chunk:
        break
    sys.stdout.buffer.write(chunk)
'
EOF
  chmod 755 "${MMI_BOOTSTRAP_BIN}/xz"
  mmi_prepend_bootstrap_path
}

mmi_ensure_xz() {
  if command -v xz >/dev/null 2>&1; then
    return 0
  fi
  mmi_ensure_commands xz \
    || warn "Could not install xz with the system package manager."
  if command -v xz >/dev/null 2>&1; then
    info "xz: $(xz --version 2>/dev/null | head -1)"
    return 0
  fi
  info "xz not found — using Python's lzma so the Nix installer can unpack."
  if ! mmi_install_python_xz; then
    error "The Nix installer needs xz to unpack its tarball."
    error "Install it and re-run. On Debian/Ubuntu: sudo apt-get install -y xz-utils"
    return 1
  fi
  info "xz: python lzma helper at ${MMI_BOOTSTRAP_BIN}/xz"
}

# Distro packages first (git + curl). Static curl covers hosts whose package
# manager cannot install curl. A git checkout still needs git itself.
mmi_ensure_bootstrap_tools() {
  local had_git=0 had_curl=0
  command -v git >/dev/null 2>&1 && had_git=1
  command -v curl >/dev/null 2>&1 && had_curl=1
  if [ "$had_git" -eq 0 ] || [ "$had_curl" -eq 0 ]; then
    mmi_ensure_git_and_curl \
      || warn "Could not install missing git/curl with the system package manager."
    if ! command -v curl >/dev/null 2>&1; then
      mmi_ensure_static_curl || return 1
    elif [ "$had_curl" -eq 0 ]; then
      info "curl: $(curl --version 2>/dev/null | head -1)"
    fi
    if ! command -v git >/dev/null 2>&1; then
      if [ -e "${SCRIPT_DIR}/.git" ]; then
        error "This checkout is a Git work tree, but git is not installed."
        error "Install git and run ./run.sh again."
        return 1
      fi
      warn "git is not installed. Nix can still fetch flake inputs; local Git checks are skipped."
    elif [ "$had_git" -eq 0 ]; then
      info "git: $(git --version 2>/dev/null | head -1)"
    fi
  fi
  mmi_ensure_xz || return 1
}

mmi_find_nix() {
  local dir old_ifs
  if command -v nix >/dev/null 2>&1; then
    command -v nix
    return 0
  fi
  old_ifs="${IFS}"
  IFS=':'
  for dir in ${PATH}; do
    [ -n "${dir}" ] && [ "${dir}" != "." ] || continue
    if [ -x "${dir}/nix" ] && [ -f "${dir}/nix" ]; then
      IFS="${old_ifs}"
      printf '%s' "${dir}/nix"
      return 0
    fi
  done
  IFS="${old_ifs}"
  for dir in \
    /nix/var/nix/profiles/default/bin \
    "${HOME:-}/.nix-profile/bin" \
    "/nix/var/nix/profiles/per-user/${USER:-}/profile/bin" \
    /run/current-system/sw/bin
  do
    if [ -x "${dir}/nix" ]; then
      printf '%s' "${dir}/nix"
      return 0
    fi
  done
  return 1
}

mmi_source_nix() {
  if [ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
    # shellcheck source=/dev/null
    . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
  elif [ -f "${HOME}/.nix-profile/etc/profile.d/nix.sh" ]; then
    # shellcheck source=/dev/null
    . "${HOME}/.nix-profile/etc/profile.d/nix.sh"
  elif [ -f /etc/profile.d/nix.sh ]; then
    # shellcheck source=/dev/null
    . /etc/profile.d/nix.sh
  fi
  export NIX_CONFIG="${NIX_CONFIG:-}
experimental-features = nix-command flakes
"
  # A previous nix-channel / NIX_PATH must not replace the locked nixpkgs.
  export NIX_PATH=""
  mmi_prepend_bootstrap_path
}

mmi_systemd_running() {
  [ -d /run/systemd/system ] || return 1
  command -v systemctl >/dev/null 2>&1 || return 1
  case "$(systemctl is-system-running 2>/dev/null || true)" in
    running|degraded) return 0 ;;
    *) return 1 ;;
  esac
}

mmi_can_install_nix_daemon() {
  if [ "$(id -u)" -eq 0 ]; then
    return 0
  fi
  command -v sudo >/dev/null 2>&1
}

# Multi-user (--daemon) when systemd and sudo work. WSL stays single-user:
# the daemon installer starts units that can kill the distro.
mmi_detect_nix_install_mode() {
  if mmi_is_wsl; then
    printf '%s\n' "no-daemon"
    return 0
  fi
  if mmi_systemd_running && mmi_can_install_nix_daemon; then
    printf '%s\n' "daemon"
    return 0
  fi
  printf '%s\n' "no-daemon"
}

mmi_explain_nix_install_choice() {
  local mode="$1"
  case "$mode" in
    daemon)
      info "Nix install: multi-user (--daemon) — Linux with systemd + sudo"
      ;;
    *)
      if mmi_is_wsl; then
        info "Nix install: single-user (--no-daemon) — WSL does not use the daemon installer"
      else
        info "Nix install: single-user (--no-daemon) — no systemd or no sudo for multi-user"
      fi
      ;;
  esac
  info "Manual equivalent:"
  if [ "$mode" = "daemon" ]; then
    info "  curl --proto '=https' --tlsv1.2 -L ${MMI_NIX_INSTALL_URL} | sh -s -- --daemon"
  else
    info "  curl --proto '=https' --tlsv1.2 -L ${MMI_NIX_INSTALL_URL} | sh -s -- --no-daemon"
  fi
  info "This run uses pinned installer: ${MMI_NIX_INSTALL_URL}"
}

# Nix's installer calls tcgetattr. Without a TTY it aborts. A synthetic PTY
# can crash WSL, so WSL only runs when stdin/stdout or /dev/tty is real.
mmi_run_with_pty() {
  local wrapper st
  if mmi_is_wsl; then
    if [ -t 0 ] && [ -t 1 ]; then
      "$@"
      return $?
    fi
    if [ -r /dev/tty ] && [ -w /dev/tty ]; then
      "$@" < /dev/tty > /dev/tty 2>&1
      return $?
    fi
    error "Nix install on WSL needs an interactive terminal."
    error "Run ./run.sh from a WSL shell, not a background job."
    return 1
  fi
  if [ -t 0 ] && [ -t 1 ]; then
    "$@"
    return $?
  fi
  if command -v python3 >/dev/null 2>&1; then
    python3 -c 'import pty,sys; raise SystemExit(pty.spawn(sys.argv[1:]))' "$@"
    return $?
  fi
  if command -v script >/dev/null 2>&1; then
    mkdir -p "${MMI_BOOTSTRAP_DIR}/tmp"
    wrapper="$(mktemp "${MMI_BOOTSTRAP_DIR}/tmp/pty-XXXXXX")"
    {
      printf '#!/usr/bin/env bash\nset -- '
      printf '%q ' "$@"
      printf '\nexec "$@"\n'
    } > "$wrapper"
    chmod +x "$wrapper"
    script -q -e -c "$wrapper" /dev/null
    st=$?
    rm -f "$wrapper"
    return "$st"
  fi
  warn "No PTY helper — Nix install may fail without a real terminal"
  "$@"
}

mmi_activate_nix_bin() {
  local bin="$1" dir
  NIX_BIN="$bin"
  export NIX_BIN
  dir="$(dirname "$bin")"
  case ":${PATH}:" in
    *":${dir}:"*) ;;
    *) export PATH="${dir}:${PATH}" ;;
  esac
  hash -r || true
}

# Single-user Nix needs /nix owned by this user. Create it here, where sudo
# can prompt, instead of inside the installer.
mmi_ensure_user_nix_dir() {
  local user
  if mmi_is_nixos; then
    return 0
  fi
  if [ -d /nix ] && [ -w /nix ] && [ -O /nix ]; then
    return 0
  fi
  if [ -e /nix ]; then
    return 0
  fi
  user="$(id -un 2>/dev/null || printf '%s' "${USER:-}")"
  if [ "$(id -u)" -eq 0 ]; then
    mkdir -m 0755 /nix || return 1
    return 0
  fi
  if ! command -v sudo >/dev/null 2>&1; then
    error "Single-user Nix needs /nix owned by ${user}."
    error "As root run: mkdir -m 0755 /nix && chown ${user} /nix"
    return 1
  fi
  info "Creating /nix owned by ${user}. This asks for your sudo password."
  sudo sh -c "mkdir -m 0755 /nix && chown $(printf '%q' "$user") /nix"
}

mmi_download_nix_installer() {
  local dest
  if [ -n "${MMI_NIX_INSTALLER:-}" ]; then
    printf '%s\n' "${MMI_NIX_INSTALLER}"
    return 0
  fi
  mkdir -p "${MMI_BOOTSTRAP_DIR}/tmp"
  dest="${MMI_BOOTSTRAP_DIR}/tmp/nix-installer.sh"
  mmi_http_get "${MMI_NIX_INSTALL_URL}" "$dest" || return 1
  chmod +x "$dest"
  printf '%s\n' "$dest"
}

mmi_remove_nix() {
  local u f
  if mmi_is_nixos; then
    error "This is NixOS. Refusing to delete /nix."
    error "Set nix.package = pkgs.nixVersions.nix_2_28 and run: sudo nixos-rebuild switch"
    return 1
  fi
  info "Removing the previous Nix installation."
  if command -v systemctl >/dev/null 2>&1; then
    mmi_as_root systemctl stop nix-daemon.socket nix-daemon.service >/dev/null 2>&1 || true
    mmi_as_root systemctl disable nix-daemon.socket nix-daemon.service >/dev/null 2>&1 || true
    mmi_as_root systemctl daemon-reload >/dev/null 2>&1 || true
  fi
  for f in /etc/bashrc /etc/bash.bashrc /etc/profile /etc/zsh/zshrc /etc/zshrc; do
    if [ -f "${f}.backup-before-nix" ]; then
      mmi_as_root cp -a "${f}.backup-before-nix" "$f" || true
    fi
  done
  mmi_as_root rm -rf \
    /nix \
    /etc/nix \
    /etc/profile.d/nix.sh \
    /etc/profile.d/nix-daemon.sh \
    /etc/tmpfiles.d/nix-daemon.conf \
    /usr/lib/systemd/system/nix-daemon.service \
    /usr/lib/systemd/system/nix-daemon.socket \
    /etc/systemd/system/nix-daemon.service \
    /etc/systemd/system/nix-daemon.socket \
    /root/.nix-profile /root/.nix-defexpr /root/.nix-channels \
    /root/.local/state/nix /root/.cache/nix \
    || return 1
  rm -rf \
    "${HOME:-}/.nix-profile" "${HOME:-}/.nix-defexpr" "${HOME:-}/.nix-channels" \
    "${HOME:-}/.local/state/nix" "${HOME:-}/.cache/nix" \
    "${HOME:-}/.config/nix"
  if getent group nixbld >/dev/null 2>&1; then
    while IFS= read -r u; do
      [ -n "$u" ] || continue
      mmi_as_root userdel "$u" >/dev/null 2>&1 || true
    done < <(getent passwd | awk -F: '$1 ~ /^nixbld[0-9]+$/ { print $1 }')
    mmi_as_root groupdel nixbld >/dev/null 2>&1 || true
  fi
  if getent group nix-daemon >/dev/null 2>&1; then
    mmi_as_root groupdel nix-daemon >/dev/null 2>&1 || true
  fi
  hash -r || true
  unset NIX_BIN || true
}

# Install pinned Nix 2.28.5. A previous install is removed first when this
# is a replacement, or when /nix is left behind without a working binary.
mmi_install_nix() {
  local installer flags mode tmp old_tmp had_tmp
  if mmi_is_nixos; then
    error "Nix is not available on this NixOS system."
    error "Boot a generation that includes nix, then run ./run.sh again."
    return 1
  fi
  if ! command -v curl >/dev/null 2>&1; then
    mmi_ensure_static_curl || return 1
  fi
  mmi_ensure_xz || return 1
  if [ "${MMI_NIX_REPLACE:-}" = "1" ]; then
    mmi_remove_nix || return 1
  elif ! mmi_find_nix >/dev/null 2>&1 && { [ -e /nix ] || [ -e "${HOME:-}/.nix-profile" ]; }; then
    mmi_remove_nix || return 1
  fi

  export USER="${USER:-$(id -un 2>/dev/null || echo root)}"
  tmp="${TMPDIR:-/tmp}"
  case "$tmp" in
    */) ;;
    *) tmp="${tmp}/" ;;
  esac
  had_tmp=0
  old_tmp=""
  if [ "${TMPDIR+set}" = set ]; then
    had_tmp=1
    old_tmp="$TMPDIR"
  fi
  export TMPDIR="$tmp"
  export NIX_INSTALLER_YES=1
  export NIX_INSTALLER_NO_CHANNEL_ADD=1

  if ! installer="$(mmi_download_nix_installer)"; then
    return 1
  fi
  chmod +x "$installer" 2>/dev/null || true

  mode="$(mmi_detect_nix_install_mode)"
  case "$mode" in
    daemon) flags="--daemon --yes --no-channel-add" ;;
    *) flags="--no-daemon --yes --no-channel-add" ;;
  esac
  mmi_explain_nix_install_choice "$mode"
  info "Nix installer flags: ${flags}"
  if [ "$mode" != "daemon" ]; then
    mmi_ensure_user_nix_dir || return 1
  fi
  # shellcheck disable=SC2086
  if ! mmi_run_with_pty sh "$installer" $flags; then
    if mmi_is_wsl; then
      error "Nix installer failed. Not running it again on WSL."
      error "If /nix was left behind and you own it: rm -rf /nix ~/.nix-profile"
      return 1
    fi
    if [ "$mode" = "daemon" ]; then
      warn "Daemon install failed — retrying single-user (--no-daemon)"
      mmi_remove_nix || return 1
      mmi_ensure_user_nix_dir || return 1
      if ! mmi_run_with_pty sh "$installer" --no-daemon --yes --no-channel-add; then
        error "Nix installer failed. If /nix was left behind, remove it and re-run."
        return 1
      fi
    else
      warn "Nix installer failed. Removing the previous tree and retrying once."
      mmi_remove_nix || return 1
      mmi_ensure_user_nix_dir || return 1
      # shellcheck disable=SC2086
      if ! mmi_run_with_pty sh "$installer" $flags; then
        error "Nix installer failed. If /nix was left behind, remove it and re-run."
        return 1
      fi
    fi
  fi
  if [ "$had_tmp" -eq 1 ]; then
    export TMPDIR="$old_tmp"
  else
    unset TMPDIR
  fi
  if [ -z "${MMI_NIX_INSTALLER:-}" ]; then
    rm -f "$installer"
  fi
  hash -r || true
  mmi_source_nix
  if ! mmi_find_nix >/dev/null 2>&1 && ! mmi_select_nix_bin >/dev/null 2>&1; then
    error "Nix installed but not on PATH. Open a new terminal and re-run."
    return 1
  fi
  mmi_reload_nix_bin || return 1
  info "Nix installed: $("$NIX_BIN" --version 2>/dev/null || true)"
}

mmi_reload_nix_bin() {
  local best
  hash -r || true
  mmi_source_nix
  if mmi_prefer_pinned_bin; then
    return 0
  fi
  if ! best="$(mmi_select_nix_bin)"; then
    if ! best="$(mmi_find_nix)"; then
      error "Nix install finished, but the nix command is still missing."
      return 1
    fi
  fi
  mmi_activate_nix_bin "$best"
}

mmi_repair_nix_and_recheck() {
  if mmi_is_nixos; then
    error "This is NixOS. Refusing to delete /nix."
    error "Set nix.package = pkgs.nixVersions.nix_2_28 and run: sudo nixos-rebuild switch"
    return 1
  fi
  if [ "${MMI_NIX_REPAIR:-}" = "1" ]; then
    error "Nix is still not usable after replacing the previous install."
    return 1
  fi
  export MMI_NIX_REPAIR=1
  export MMI_NIX_REPLACE=1
  info "Replacing this Nix with pinned Nix ${MMI_NIX_PIN_VERSION}."
  mmi_install_nix || return 1
  mmi_reload_nix_bin || return 1
  mmi_check_existing_nix
}

# Start a stopped daemon, or re-enter the script with the nix-daemon group.
# Returns 0 when the caller should run the Nix check again.
mmi_revive_nix_store() {
  local msg="$1" members
  case "$msg" in
    *daemon*|*socket*|*Connection\ refused*|*disconnected*)
      if command -v systemctl >/dev/null 2>&1; then
        info "Starting the Nix daemon from the previous install."
        mmi_as_root systemctl start nix-daemon.socket nix-daemon.service >/dev/null 2>&1 || true
        return 0
      fi
      ;;
  esac
  case "$msg" in
    *Permission\ denied*|*Operation\ not\ permitted*|*not\ allowed*)
      if [ "${MMI_NIX_SG:-}" = "1" ]; then
        return 1
      fi
      if getent group nix-daemon >/dev/null 2>&1; then
        members="$(getent group nix-daemon | awk -F: '{ print $4 }')"
        case ",${members}," in
          *",${USER},"*) ;;
          *)
            info "Adding ${USER} to the nix-daemon group."
            mmi_as_root usermod -aG nix-daemon "${USER}" || return 1
            ;;
        esac
        if command -v sg >/dev/null 2>&1; then
          info "Opening the Nix store as a member of nix-daemon."
          export MMI_NIX_SG=1
          local q a
          q="./run.sh"
          if [ "${MMI_ORIG_ARGS+set}" = "set" ]; then
            for a in "${MMI_ORIG_ARGS[@]}"; do
              q="${q} $(printf '%q' "$a")"
            done
          fi
          exec sg nix-daemon -c "cd $(printf '%q' "$SCRIPT_DIR") && exec ${q}"
        fi
      fi
      ;;
  esac
  return 1
}

# NixOS 25.05 ships Nix 2.28.5 (nixpkgs nixVersions.nix_2_28).
mmi_nix_version_is_pinned() {
  [ "$1" -eq "$MMI_NIX_PIN_MAJOR" ] \
    && [ "$2" -eq "$MMI_NIX_PIN_MINOR" ] \
    && [ "$3" -eq "$MMI_NIX_PIN_PATCH" ]
}

mmi_nix_parse_version() {
  local line
  line="$("$1" --version 2>/dev/null | head -n 1 || true)"
  if [[ "$line" =~ ([0-9]+)\.([0-9]+)(\.([0-9]+))? ]]; then
    printf '%s %s %s\n' "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}" "${BASH_REMATCH[4]:-0}"
    return 0
  fi
  return 1
}

# Newest Nix binary among PATH and the usual install locations.
# Prints one path. The caller keeps it only when it is Nix 2.28.5.
mmi_select_nix_bin() {
  local cand resolved seen best best_key key maj min pat
  local -a cands
  seen="|"
  best=""
  best_key=-1
  cands=()
  if command -v nix >/dev/null 2>&1; then
    cands+=("$(command -v nix)")
  fi
  cands+=(
    /nix/var/nix/profiles/default/bin/nix
    "${HOME:-}/.nix-profile/bin/nix"
    "/nix/var/nix/profiles/per-user/${USER:-}/profile/bin/nix"
    /run/current-system/sw/bin/nix
    /usr/bin/nix
  )
  for cand in "${cands[@]}"; do
    [ -n "$cand" ] && [ -x "$cand" ] || continue
    resolved="$(readlink -f "$cand" 2>/dev/null || printf '%s' "$cand")"
    case "$seen" in
      *"|${resolved}|"*) continue ;;
    esac
    seen="${seen}${resolved}|"
    if ! read -r maj min pat < <(mmi_nix_parse_version "$cand"); then
      continue
    fi
    key=$((maj * 1000000 + min * 1000 + pat))
    if [ "$key" -gt "$best_key" ]; then
      best_key="$key"
      best="$cand"
    fi
  done
  [ -n "$best" ] || return 1
  printf '%s\n' "$best"
}

# Use an already-installed Nix 2.28.5 even when a newer binary is earlier on PATH.
mmi_prefer_pinned_bin() {
  local cand maj min pat
  for cand in \
    "${HOME:-}/.nix-profile/bin/nix" \
    "/nix/var/nix/profiles/per-user/${USER:-}/profile/bin/nix" \
    /nix/var/nix/profiles/default/bin/nix \
    /run/current-system/sw/bin/nix
  do
    [ -n "$cand" ] && [ -x "$cand" ] || continue
    if read -r maj min pat < <(mmi_nix_parse_version "$cand"); then
      if mmi_nix_version_is_pinned "$maj" "$min" "$pat"; then
        mmi_activate_nix_bin "$cand"
        return 0
      fi
    fi
  done
  return 1
}

mmi_nixpkgs_25_05_rev() {
  local lock="${SCRIPT_DIR}/flake.lock" rev
  [ -f "$lock" ] || return 1
  rev="$(awk '
    /"rev":/ { gsub(/[",]/, "", $2); rev = $2 }
    /"ref": "nixos-25.05"/ { print rev; exit }
  ' "$lock")"
  [ -n "$rev" ] || return 1
  printf '%s\n' "$rev"
}

# NixOS owns /nix. Put the pinned package manager in the user profile.
mmi_install_pinned_on_nixos() {
  local rev
  rev="$(mmi_nixpkgs_25_05_rev)" || {
    error "Could not read the nixos-25.05 revision from ${SCRIPT_DIR}/flake.lock."
    return 1
  }
  info "This is NixOS. Installing Nix ${MMI_NIX_PIN_VERSION} into the user profile."
  info "The system /nix store is left in place."
  "$NIX_BIN" --extra-experimental-features "nix-command flakes" profile install \
    --accept-flake-config \
    "github:NixOS/nixpkgs/${rev}#nixVersions.nix_2_28" || return 1
  if ! mmi_prefer_pinned_bin; then
    error "Nix ${MMI_NIX_PIN_VERSION} installed, but it is not available in the user profile."
    return 1
  fi
}

# Description of a nixpkgs channel that is not nixos-25.05. Empty when
# there is no channel, or the channel is already 25.05.
mmi_foreign_nixpkgs_channel() {
  local url="" ver="" f
  if command -v nix-channel >/dev/null 2>&1; then
    url="$(nix-channel --list 2>/dev/null | awk '$1=="nixpkgs" || $1=="nixos" { print $2; exit }' || true)"
  fi
  for f in \
    "${HOME:-}/.nix-defexpr/channels/nixpkgs/.version" \
    "/nix/var/nix/profiles/per-user/${USER:-}/channels/nixpkgs/.version" \
    "/nix/var/nix/profiles/per-user/root/channels/nixpkgs/.version"
  do
    [ -f "$f" ] || continue
    ver="$(tr -d '[:space:]' <"$f" || true)"
    [ -n "$ver" ] && break
  done
  if [ -z "$url" ] && [ -z "$ver" ]; then
    return 0
  fi
  if [[ "$url" =~ nixos-25\.05([^0-9]|$) ]]; then
    return 0
  fi
  if [ -z "$url" ] && [[ "$ver" =~ ^25\.05([^0-9]|$) ]]; then
    return 0
  fi
  if [ -n "$url" ] && [ -n "$ver" ]; then
    printf '%s (checkout %s)\n' "$url" "$ver"
  elif [ -n "$url" ]; then
    printf '%s\n' "$url"
  else
    printf 'checkout %s\n' "$ver"
  fi
}

mmi_nix_store_error() {
  local msg="$1" line
  error "Nix is installed, but the existing store cannot be used."
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    error "$line"
  done <<<"$(printf '%s\n' "$msg" | head -n 6)"
  case "$msg" in
    *experimental*feature*|*flakes*)
      error "Enable flakes, then retry. In ~/.config/nix/nix.conf or /etc/nix/nix.conf:"
      error "  experimental-features = nix-command flakes"
      ;;
    *daemon*|*socket*|*Connection\ refused*|*disconnected*)
      error "Start the Nix daemon:  sudo systemctl start nix-daemon"
      error "If this user was just added to the nix-daemon group, log out and back in."
      ;;
    *Permission\ denied*|*Operation\ not\ permitted*|*not\ allowed*)
      error "This user cannot access the store from the previous Nix install."
      error "Multi-user Nix: add the user to nix-daemon and log in again."
      error "Single-user Nix: run as the user who originally installed Nix."
      ;;
    *database*|*schema*|*not\ compatible*)
      error "The Nix database was written by a different Nix version."
      error "Re-run ./run.sh to replace it with Nix ${MMI_NIX_PIN_VERSION}."
      ;;
    *)
      error "Re-run ./run.sh to replace this Nix with ${MMI_NIX_PIN_VERSION}."
      ;;
  esac
}

# Previous Nix: any version other than 2.28.5, a store left by that version,
# or a daemon that no longer matches the client.
mmi_check_existing_nix() {
  local first best maj min pat channel err json url sver
  local smaj smin sys feats store_msg

  mmi_source_nix
  first="$(command -v nix 2>/dev/null || true)"
  if mmi_prefer_pinned_bin; then
    best="$NIX_BIN"
  elif ! best="$(mmi_select_nix_bin)"; then
    if [ "${MMI_NIX_REPAIR:-}" = "1" ]; then
      error "Nix binaries still do not run after reinstall."
      return 1
    fi
    if mmi_is_nixos; then
      error "Nix is not available on this NixOS system."
      error "Boot a generation that includes nix, then run ./run.sh again."
      return 1
    fi
    info "The Nix binary on this machine does not run. Replacing it."
    mmi_repair_nix_and_recheck || return 1
    return 0
  else
    mmi_activate_nix_bin "$best"
    if [ -n "$first" ] && [ "$first" != "$best" ]; then
      info "Using ${best} (newer Nix than ${first})."
    fi
  fi

  if ! read -r maj min pat < <(mmi_nix_parse_version "$NIX_BIN"); then
    if [ "${MMI_NIX_REPAIR:-}" = "1" ]; then
      error "Nix at ${NIX_BIN} still does not report a version."
      return 1
    fi
    info "Nix at ${NIX_BIN} did not report a version. Replacing it."
    mmi_repair_nix_and_recheck || return 1
    return 0
  fi

  channel="$(mmi_foreign_nixpkgs_channel || true)"

  if ! mmi_nix_version_is_pinned "$maj" "$min" "$pat"; then
    if [ "${MMI_NIX_REPAIR:-}" = "1" ]; then
      error "Nix ${maj}.${min}.${pat} is still not Nix ${MMI_NIX_PIN_VERSION} after reinstall."
      return 1
    fi
    if mmi_is_nixos; then
      if [ "${MMI_NIXOS_PIN_TRIED:-}" = "1" ]; then
        error "This NixOS system still provides Nix ${maj}.${min}.${pat}, not Nix ${MMI_NIX_PIN_VERSION}."
        error "Set nix.package = pkgs.nixVersions.nix_2_28 and run: sudo nixos-rebuild switch"
        return 1
      fi
      export MMI_NIXOS_PIN_TRIED=1
      mmi_install_pinned_on_nixos || return 1
      mmi_check_existing_nix || return 1
      return 0
    fi
    info "Nix ${maj}.${min}.${pat} is not pinned Nix ${MMI_NIX_PIN_VERSION} (NixOS 25.05). Replacing it."
    if [ -n "$channel" ]; then
      info "Existing nixpkgs channel: ${channel}"
    fi
    mmi_repair_nix_and_recheck || return 1
    return 0
  fi

  if [ -n "$channel" ]; then
    warn "A previous nixpkgs channel is ${channel}."
    warn "That channel is outside NixOS 25.05. This run ignores it."
    warn "Packages come from flake.lock (github:NixOS/nixpkgs/nixos-25.05)."
  fi

  err="${TMPDIR:-/tmp}/mmi-nix-check.$$"
  json="$("$NIX_BIN" store info --json 2>"$err" || true)"
  if [ -z "$json" ]; then
    json="$("$NIX_BIN" store ping --json 2>"$err" || true)"
  fi
  if [ -z "$json" ]; then
    store_msg="$(cat "$err" 2>/dev/null || true)"
    rm -f "$err"
    if [ "${MMI_NIX_STORE_RETRY:-}" != "1" ]; then
      export MMI_NIX_STORE_RETRY=1
      if mmi_revive_nix_store "$store_msg"; then
        mmi_check_existing_nix || return 1
        return 0
      fi
    fi
    if [ "${MMI_NIX_REPAIR:-}" != "1" ]; then
      info "The existing Nix store is unusable. Installing Nix ${MMI_NIX_PIN_VERSION}."
      mmi_repair_nix_and_recheck || return 1
      return 0
    fi
    mmi_nix_store_error "$store_msg"
    return 1
  fi
  rm -f "$err"

  url="$(printf '%s' "$json" | sed -n 's/.*"url"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n 1)"
  sver="$(printf '%s' "$json" | sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n 1)"
  if [[ "$sver" =~ ^([0-9]+)\.([0-9]+)\.([0-9]+) ]]; then
    smaj="${BASH_REMATCH[1]}"
    smin="${BASH_REMATCH[2]}"
    if [ "$smaj" != "$maj" ] || [ "$smin" != "$min" ]; then
      if [ "${MMI_NIX_REPAIR:-}" = "1" ]; then
        error "Nix client ${maj}.${min}.${pat} still does not match the store (${sver})."
        return 1
      fi
      info "Nix client ${maj}.${min}.${pat} does not match the store (${sver}). Replacing Nix."
      mmi_repair_nix_and_recheck || return 1
      return 0
    fi
  fi

  if [ -S /nix/var/nix/daemon-socket/socket ] && [[ "${url}" != daemon* ]]; then
    warn "A Nix daemon socket exists, but ${NIX_BIN} is using a local store."
    warn "A single-user Nix and a multi-user Nix are both installed."
  fi

  if [[ "${url}" == daemon* ]] && ! grep -q '^nixbld1:' /etc/passwd 2>/dev/null; then
    if [ "${MMI_NIX_REPAIR:-}" = "1" ]; then
      error "The Nix daemon still has no nixbld build users."
      return 1
    fi
    info "The Nix daemon has no nixbld build users. Replacing Nix."
    mmi_repair_nix_and_recheck || return 1
    return 0
  fi

  if ! "$NIX_BIN" flake --help >/dev/null 2>&1; then
    if [ "${MMI_NIX_REPAIR:-}" = "1" ]; then
      error "Nix ${maj}.${min}.${pat} still cannot run flakes."
      return 1
    fi
    info "Nix ${maj}.${min}.${pat} cannot run flakes. Replacing it."
    mmi_repair_nix_and_recheck || return 1
    return 0
  fi

  sys="$("$NIX_BIN" config show system 2>/dev/null || true)"
  if [ -n "$sys" ] && [ "$sys" != "x86_64-linux" ]; then
    error "Nix is configured for system ${sys}. CAD needs x86_64-linux."
    error "Fix the system setting in /etc/nix/nix.conf or ~/.config/nix/nix.conf."
    return 1
  fi

  if [ "$("$NIX_BIN" config show restrict-eval 2>/dev/null || true)" = "true" ]; then
    error "Nix restrict-eval is enabled, so this flake cannot fetch NixOS 25.05."
    error "Set restrict-eval = false in the Nix configuration and retry."
    return 1
  fi

  feats="$("$NIX_BIN" config show experimental-features 2>/dev/null || true)"
  if ! printf '%s' "$feats" | grep -q 'flakes' \
    || ! printf '%s' "$feats" | grep -q 'nix-command'; then
    error "This Nix install does not have flakes enabled."
    error "Add this to ~/.config/nix/nix.conf or /etc/nix/nix.conf and retry:"
    error "  experimental-features = nix-command flakes"
    return 1
  fi

  info "Nix ${maj}.${min}.${pat} (pinned for NixOS 25.05)"
  return 0
}

mmi_ensure_nix() {
  mmi_source_nix
  if mmi_find_nix >/dev/null 2>&1 || mmi_select_nix_bin >/dev/null 2>&1; then
    mmi_check_existing_nix || return 1
    return 0
  fi
  info "Nix not found — installing Nix ${MMI_NIX_PIN_VERSION} (NixOS 25.05)."
  mmi_install_nix || return 1
  mmi_check_existing_nix || return 1
}

# Process-local safe.directory so Nix's git can read a WSL checkout whose
# owner does not match this user. Does not write git config.
mmi_export_git_safe_directory() {
  local dir="$1" n
  [ "${MMI_GIT_SAFE_DIR:-}" = "$dir" ] && return 0
  command -v git >/dev/null 2>&1 || return 0
  git -c safe.directory=/ --version >/dev/null 2>&1 || return 0
  [ -n "$dir" ] || return 0
  n="${GIT_CONFIG_COUNT:-0}"
  case "$n" in
    ""|*[!0-9]*) n=0 ;;
  esac
  export GIT_CONFIG_COUNT=$((n + 1))
  export "GIT_CONFIG_KEY_${n}=safe.directory"
  export "GIT_CONFIG_VALUE_${n}=${dir}"
  export MMI_GIT_SAFE_DIR="$dir"
}

# Restore flake paths that are missing from the work tree. Do not `git add`:
# staging on every ./run.sh dirties the tree, and a dirty flake recopies
# vendor/mmi from disk (can OOM a small VM).
mmi_ensure_flake_git_files() {
  local rel f
  mmi_export_git_safe_directory "${SCRIPT_DIR}"
  if ! command -v git >/dev/null 2>&1; then
    return 0
  fi
  if ! git -C "${SCRIPT_DIR}" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    return 0
  fi

  # Older run.sh staged pdk/nix on every launch. Unstage those paths so Nix
  # can use the Git commit already in the store instead of recopying vendor/mmi.
  if ! git -C "${SCRIPT_DIR}" diff --cached --quiet -- nix pdk 2>/dev/null; then
    git -C "${SCRIPT_DIR}" reset -q HEAD -- nix pdk
  fi

  if [ ! -d "${SCRIPT_DIR}/pdk/samples" ] \
    && git -C "${SCRIPT_DIR}" ls-tree -r --name-only HEAD -- pdk/samples | grep -q .; then
    git -C "${SCRIPT_DIR}" checkout HEAD -- pdk/samples
    info "Restored pdk/samples from git"
  fi

  while IFS= read -r rel; do
    [ -n "${rel}" ] || continue
    f="${SCRIPT_DIR}/${rel}"

    if [ ! -e "${f}" ]; then
      if git -C "${SCRIPT_DIR}" cat-file -e "HEAD:${rel}" 2>/dev/null \
        || git -C "${SCRIPT_DIR}" ls-tree -r --name-only HEAD -- "${rel}" | grep -q .; then
        git -C "${SCRIPT_DIR}" checkout HEAD -- "${rel}"
        info "Restored ${rel} from git (required by flake.nix)"
      else
        error "flake.nix needs '${rel}', but it is not in this Git repository."
        error "Fix:  git add ${rel} && git commit"
        return 1
      fi
    fi

    if [ -d "${f}" ] && ! git -C "${SCRIPT_DIR}" ls-files -- "${rel}" | grep -q .; then
      error "flake.nix needs directory '${rel}', but Git has no files there."
      error "Fix:  git add ${rel} && git commit"
      return 1
    fi
  done < <(
    grep -vE '^[[:space:]]*#' "${SCRIPT_DIR}/flake.nix" \
      | grep -oE '\./(nix|pdk)[-A-Za-z0-9_./]*' \
      | sed 's|^\./||' \
      | sort -u
  )
}

mmi_warn_if_git_dirty() {
  mmi_export_git_safe_directory "${SCRIPT_DIR}"
  if ! command -v git >/dev/null 2>&1; then
    return 0
  fi
  if ! git -C "${SCRIPT_DIR}" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    return 0
  fi
  if [ -n "$(git -C "${SCRIPT_DIR}" status --porcelain --untracked-files=normal 2>/dev/null)" ]; then
    warn "Git working tree is dirty. Nix may recopy vendor/mmi and freeze a small VM."
    warn "If stuck on 'copying .../vendor/mmi', press Ctrl-C, run git status, then"
    warn "commit, stash, or restore accidental edits so the tree is clean and retry."
  fi
}
