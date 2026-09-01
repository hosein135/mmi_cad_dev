#!/usr/bin/env bash
# x86_64 Linux preflight: bare metal, VM, or WSL2 (not WSL1, not Windows-native).
# Sourced from run.sh. Expects info/warn/error.

mmi_is_wsl() {
  grep -qi microsoft /proc/version 2>/dev/null
}

mmi_is_wsl2() {
  uname -r | grep -qiE 'microsoft-standard|WSL2'
}

mmi_is_wsl1() {
  mmi_is_wsl && ! mmi_is_wsl2
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

  if mmi_is_wsl1; then
    error "WSL1 detected (kernel $(uname -r)). Nix FHS/bubblewrap needs a real Linux kernel."
    error "Switch this distro to WSL2:  wsl --set-version <distro> 2"
    error "Or run on bare-metal Linux / a Linux VM."
    return 1
  fi

  if mmi_is_wsl2; then
    info "Host: WSL2 x86_64"
  elif [ -f /sys/class/dmi/id/product_name ] || [ -d /sys/hypervisor ]; then
    info "Host: x86_64 Linux (bare metal or VM)"
  else
    info "Host: x86_64 Linux"
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
}

# Nix flakes copy only Git-tracked files. Git does not track directories, so a
# dirty eval of ./nix/rebuild/pccts-h fails with:
#   Path 'nix/rebuild/pccts-h' is not tracked by Git — run: git add -N ...
mmi_ensure_flake_git_files() {
  local rel f
  if ! command -v git >/dev/null 2>&1; then
    return 0
  fi
  if ! git -C "${SCRIPT_DIR}" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    return 0
  fi

  # Git has no directory objects. Nix dirty eval of ./nix/rebuild/pccts-h
  # needs an index entry: `git add -N <dir>` then `git add <dir>`.
  local d
  for d in nix/rebuild/pccts-h pdk nix/rebuild nix/x11; do
    if [ -d "${SCRIPT_DIR}/${d}" ]; then
      git -C "${SCRIPT_DIR}" add -N -- "${d}" 2>/dev/null || true
      git -C "${SCRIPT_DIR}" add -- "${d}"
    fi
  done

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
        error "Fix:  git add -N ${rel} && git add ${rel}"
        return 1
      fi
    fi

    # Intent-to-add first: Nix dirty eval looks up the path in the index.
    # Directories only appear after `git add -N` (files after `git add`).
    git -C "${SCRIPT_DIR}" add -N -- "${rel}" 2>/dev/null || true
    git -C "${SCRIPT_DIR}" add -- "${rel}"
    if [ -d "${f}" ] && ! git -C "${SCRIPT_DIR}" ls-files -- "${rel}" | grep -q .; then
      error "flake.nix needs directory '${rel}', but Git has no files there."
      error "Fix:  git add ${rel}"
      return 1
    fi
  done < <(
    grep -oE '\./(nix|pdk)[^"[:space:];)}]*' "${SCRIPT_DIR}/flake.nix" \
      | sed 's|^\./||' \
      | sort -u
  )
}
