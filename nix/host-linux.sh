#!/usr/bin/env bash
# x86_64 Linux preflight: bare metal, VM, or WSL2 (not WSL1, not Windows-native).
# Sourced from run.sh. Expects info/warn/error.

# Completed `nix run .#mmi-cad` runtime closure (nixos-25.05), measured:
# 934120792 bytes ≈ 891 MiB across 258 store paths. About 1 GiB remains
# on disk after install. First run also unpacks NARs, copies vendor
# sources (~313 MiB), and compiles CAD — keep several extra GiB free.
MMI_STORE_AFTER_INSTALL_BYTES=$((1024 * 1024 * 1024))
MMI_FIRST_INSTALL_FREE_BYTES=$((6 * 1024 * 1024 * 1024))
MMI_RUNTIME_FREE_BYTES=$((1024 * 1024 * 1024))

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

  if [ -f /proc/sys/kernel/apparmor_restrict_unprivileged_userns ]; then
    if [ "$(cat /proc/sys/kernel/apparmor_restrict_unprivileged_userns 2>/dev/null || echo 0)" = "1" ]; then
      warn "Ubuntu/Debian AppArmor may block bubblewrap (apparmor_restrict_unprivileged_userns=1)."
      warn "If nix run fails: sudo sysctl -w kernel.apparmor_restrict_unprivileged_userns=0"
    fi
  fi

  if [ ! -w /tmp ]; then
    error "/tmp is not writable. The X11 socket and Nix builds need it."
    return 1
  fi

  return 0
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
    "${HOME}/.nix-profile/bin" \
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
}

# NixOS 25.05 ships Nix 2.28 (nixpkgs nixVersions.stable = nix_2_28).
# flake.lock version 7 needs Nix >= 2.18; 25.05 itself is evaluated with 2.28.
MMI_NIX_MIN_MAJOR=2
MMI_NIX_MIN_MINOR=28
MMI_NIX_MIN_PATCH=0

mmi_nix_parse_version() {
  local line
  line="$("$1" --version 2>/dev/null | head -n 1 || true)"
  if [[ "$line" =~ ([0-9]+)\.([0-9]+)(\.([0-9]+))? ]]; then
    printf '%s %s %s\n' "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}" "${BASH_REMATCH[4]:-0}"
    return 0
  fi
  return 1
}

mmi_nix_ver_ge() {
  local maj="$1" min="$2" pat="$3"
  local need_maj="$4" need_min="$5" need_pat="$6"
  if [ "$maj" -gt "$need_maj" ]; then return 0; fi
  if [ "$maj" -lt "$need_maj" ]; then return 1; fi
  if [ "$min" -gt "$need_min" ]; then return 0; fi
  if [ "$min" -lt "$need_min" ]; then return 1; fi
  [ "$pat" -ge "$need_pat" ]
}

# Newest Nix binary among PATH and the usual install locations.
# Prints one path. Returns 1 when none of them run.
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
      error "Upgrade or reinstall Nix so it matches that database: https://nixos.org/download.html"
      ;;
    *)
      error "Reinstall Nix from https://nixos.org/download.html if this install is broken."
      ;;
  esac
}

# Previous Nix install: too old for NixOS 25.05, wrong channel, or a
# broken daemon/store left behind by an earlier install.
mmi_check_existing_nix() {
  local best maj min pat channel err json url sver
  local smaj smin sys feats

  if ! best="$(mmi_select_nix_bin)"; then
    error "Nix was found, but every Nix binary failed to run."
    error "Reinstall from https://nixos.org/download.html"
    return 1
  fi
  if [ "$best" != "$NIX_BIN" ]; then
    info "Using ${best} (newer Nix than ${NIX_BIN})."
    NIX_BIN="$best"
  fi

  if ! read -r maj min pat < <(mmi_nix_parse_version "$NIX_BIN"); then
    error "Nix at ${NIX_BIN} did not report a version."
    error "Reinstall from https://nixos.org/download.html"
    return 1
  fi

  channel="$(mmi_foreign_nixpkgs_channel || true)"

  if ! mmi_nix_ver_ge "$maj" "$min" "$pat" \
      "$MMI_NIX_MIN_MAJOR" "$MMI_NIX_MIN_MINOR" "$MMI_NIX_MIN_PATCH"; then
    error "Nix is already installed, but its release is older than NixOS 25.05."
    error "  ${NIX_BIN}: Nix ${maj}.${min}.${pat}"
    error "NixOS 25.05 uses Nix 2.28 or newer. This repository's nixpkgs is locked to that release."
    if [ -n "$channel" ]; then
      error "Existing nixpkgs channel: ${channel}"
    fi
    error "Upgrade the installed Nix, then open a new shell and retry:"
    error "  nix --extra-experimental-features \"nix-command flakes\" upgrade-nix"
    error "Multi-user Nix:  sudo nix --extra-experimental-features \"nix-command flakes\" upgrade-nix"
    error "If the upgrade fails, reinstall from https://nixos.org/download.html"
    return 1
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
    mmi_nix_store_error "$(cat "$err" 2>/dev/null || true)"
    rm -f "$err"
    return 1
  fi
  rm -f "$err"

  url="$(printf '%s' "$json" | sed -n 's/.*"url"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n 1)"
  sver="$(printf '%s' "$json" | sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n 1)"
  if [[ "$sver" =~ ^([0-9]+)\.([0-9]+)\.([0-9]+) ]]; then
    smaj="${BASH_REMATCH[1]}"
    smin="${BASH_REMATCH[2]}"
    if [ "$smaj" != "$maj" ] || [ "$smin" != "$min" ]; then
      error "Nix client ${maj}.${min}.${pat} does not match the Nix store (${sver})."
      error "A previous upgrade left two Nix versions installed."
      error "Upgrade so the client and the daemon are the same release, then open a new shell:"
      error "  sudo nix --extra-experimental-features \"nix-command flakes\" upgrade-nix"
      return 1
    fi
  fi

  if [ -S /nix/var/nix/daemon-socket/socket ] && [[ "${url}" != daemon* ]]; then
    warn "A Nix daemon socket exists, but ${NIX_BIN} is using a local store."
    warn "A single-user Nix and a multi-user Nix are both installed."
  fi

  if [[ "${url}" == daemon* ]] && ! grep -q '^nixbld1:' /etc/passwd 2>/dev/null; then
    error "The Nix daemon is installed, but the nixbld build users are missing."
    error "Re-run the multi-user installer from https://nixos.org/download.html"
    return 1
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

  info "Nix ${maj}.${min}.${pat}"
  return 0
}

# Restore flake paths that are missing from the work tree. Do not `git add`:
# staging on every ./run.sh dirties the tree, and a dirty flake recopies
# vendor/mmi from disk (can OOM a small VM).
mmi_ensure_flake_git_files() {
  local rel f
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
