#!/usr/bin/env bash
# Build MMI tools as native ELF 64-bit from the patched source tree.
set -euo pipefail

ROOT="${PWD}"
SRC="${ROOT}/src"
UTILS="${SRC}/utils"
export MMI_CAD="${SRC}"
export MMI_UTILS="${UTILS}"
export PATH="${PATH}"

: "${CC:=gcc}"
export CC
export CFLAGS="${CFLAGS:--std=gnu89 -fcommon -fno-strict-aliasing -O2 -U_FORTIFY_SOURCE -D_FORTIFY_SOURCE=0} -Wno-error -Wno-implicit-function-declaration -Wno-implicit-int -Wno-int-conversion -Wno-incompatible-pointer-types -Wno-pointer-to-int-cast -Wno-int-to-pointer-cast -Wno-return-type -Wno-unused -Wno-old-style-definition -Wno-declaration-after-statement -include float.h -DCLK_TCK=100"
export NIX_CFLAGS_COMPILE="${NIX_CFLAGS_COMPILE:-} ${CFLAGS}"
HOST_TCLSH="$(command -v tclsh || true)"

LIBDIR="${UTILS}/lib.x86_64-linux"
mkdir -p "${LIBDIR}"

log() { printf '%s\n' "[mmi-rebuild] $*"; }

build_tcl() {
  log "Tcl 8.0.4 (x86_64 static)"
  local d="${UTILS}/tcltk/tcl8.0.4/unix"
  cd "$d"
  printf '%s\n' '#!/bin/sh' 'echo x86_64-unknown-linux-gnu' > config.guess
  chmod +x config.guess configure 2>/dev/null || true
  rm -f config.cache config.status
  bash ./configure --disable-shared --disable-load --enable-gcc \
    --cache-file=/dev/null --prefix="${UTILS}/tcltk/install-x64"
  make -e -j1 CFLAGS="${CFLAGS}" || make -e -j1
  cp -f libtcl8.0.a "${LIBDIR}/" || cp -f *.a "${LIBDIR}/libtcl8.0.a"
  if [ -x tclsh ]; then
    mkdir -p "${UTILS}/bin.x86_64-linux"
    cp -f tclsh "${UTILS}/bin.x86_64-linux/tclsh"
  fi
  cd "${ROOT}"
}

build_tk() {
  log "Tk 8.0.4 (x86_64 static)"
  local d="${UTILS}/tcltk/tk8.0.4/unix"
  cd "$d"
  printf '%s\n' '#!/bin/sh' 'echo x86_64-unknown-linux-gnu' > config.guess
  chmod +x config.guess configure 2>/dev/null || true
  rm -f config.cache config.status
  bash ./configure --disable-shared --disable-load --enable-gcc \
    --cache-file=/dev/null \
    --with-tcl="${UTILS}/tcltk/tcl8.0.4/unix" \
    --prefix="${UTILS}/tcltk/install-x64"
  make -e -j1 CFLAGS="${CFLAGS}" || make -e -j1
  cp -f libtk8.0.a "${LIBDIR}/" || true
  if [ -x wish ]; then
    mkdir -p "${UTILS}/bin.x86_64-linux"
    cp -f wish "${UTILS}/bin.x86_64-linux/wish"
    ln -sfn wish "${UTILS}/bin.x86_64-linux/mmi_wish"
  fi
  cd "${ROOT}"
}

install_utils_bin() {
  log "utils bindir (remove_comments.tcl)"
  local b="${UTILS}/bin.x86_64-linux"
  mkdir -p "$b"
  export PATH="${b}:${PATH}"
  local runner="${HOST_TCLSH:-${b}/tclsh}"
  {
    printf '%s\n' '#!/bin/sh' '# \' "exec \"${runner}\" \"\$0\" \"\$@\""
    cat "${UTILS}/build/remove_comments.tcl"
  } > "$b/remove_comments.tcl"
  chmod +x "$b/remove_comments.tcl"
  log "remove_comments via ${runner}"
}

build_prepare() {
  log "prepare (host tool)"
  mkdir -p "${UTILS}/bin.x86_64-linux"
  gcc ${CFLAGS} "${UTILS}/prepare/prepare.c" -o "${UTILS}/bin.x86_64-linux/prepare"
  chmod +x "${UTILS}/bin.x86_64-linux/prepare"
}

build_blt() {
  log "BLT 2.4g (x86_64 static, for NST)"
  local d="${UTILS}/blt2.4g.i486-linux2.2"
  cd "$d"
  find . -type f \( -name Makefile -o -name Makefile.in \) -print0 \
    | xargs -0 sed -i 's/-fwritable-strings//g; s/-Wtraditional//g'
  rm -f src/libBLT.a src/libBLT.so
  find src -maxdepth 1 -name '*.a' -delete 2>/dev/null || true
  printf '%s\n' '#!/bin/sh' 'echo x86_64-unknown-linux-gnu' > cf/config.guess
  cat > cf/config.sub << 'EOF'
#!/bin/sh
case "$1" in
"") echo x86_64-unknown-linux-gnu ;;
sun4) echo sparc-sun-sunos4.1.3 ;;
*) echo x86_64-unknown-linux-gnu ;;
esac
EOF
  chmod +x cf/config.guess cf/config.sub configure cf/install-sh 2>/dev/null || true
  rm -f config.cache config.status
  local inc="-I${UTILS}/tcltk/tk8.0.4/generic -I${UTILS}/tcltk/tk8.0.4/unix -I${UTILS}/tcltk/tcl8.0.4/generic -I${UTILS}/tcltk/tcl8.0.4/unix"
  [ -d "${UTILS}/tcltk/tk8.0/generic" ] && inc="${inc} -I${UTILS}/tcltk/tk8.0/generic -I${UTILS}/tcltk/tcl8.0/generic"
  CFLAGS="${CFLAGS} ${inc}" bash ./configure --disable-shared --enable-gcc --cache-file=/dev/null \
    --with-tcl="${UTILS}/tcltk/tcl8.0.4/unix" \
    --with-tk="${UTILS}/tcltk/tk8.0.4/unix" \
    --prefix="${UTILS}/tcltk/install-x64"
  find . -type f \( -name Makefile -o -name Makefile.in \) -print0 \
    | xargs -0 sed -i \
      's/-fwritable-strings//g; s/-Wtraditional//g; s/-Wwrite-strings//g; s/-Wshadow//g; s/-Wall//g'
  # Build static lib only (NST needs libBLT.a, not bltwish). Do not use make -e:
  # Nix sets AR=ar which breaks BLT's "AR = ar rc" + "$(AR) $@ $(OBJS)" recipe.
  (
    cd src
    make AR="ar rc" RANLIB=ranlib EXTRA_CFLAGS= \
      CFLAGS="${CFLAGS} ${inc}" \
      INCLUDES="-I. -I.. ${inc}" \
      -j1 all
  ) || {
    log "BLT src make failed; assembling libBLT.a from objects if any"
  }
  mkdir -p src
  if ls src/*.o >/dev/null 2>&1; then
    ( cd src && rm -f libBLT.a && ar rcs libBLT.a ./*.o && ranlib libBLT.a )
  fi
  if [ ! -f src/libBLT.a ]; then
    log "ERROR: libBLT.a not built (NST requires BLT)"
    exit 1
  fi
  file src/libBLT.a || true
  cd "${ROOT}"
}

build_tclmods() {
  log "tclmods"
  cd "${UTILS}/tclmods"
  rm -f "${LIBDIR}/libtclmods8.0.a"
  mkdir -p o/x86_64-linux
  # Do not use find(1) — vendor tree ships 32-bit libtclmods8.0.a under o/i486-linux*.
  make -j1 MMI_UTILS="${UTILS}" TARGET=x86_64-linux \
    CC="${CC:-gcc}" CFLAGS="${CFLAGS}" AR="ar rc" RANLIB=ranlib
  local built="o/x86_64-linux/libtclmods8.0.a"
  if [ ! -f "$built" ]; then
    objs=$(find o/x86_64-linux -maxdepth 1 -name '*.o' | tr '\n' ' ')
    if [ -n "${objs}" ]; then
      ar rcs "$built" ${objs}
      ranlib "$built"
    fi
  fi
  if [ ! -f "$built" ]; then
    log "ERROR: libtclmods8.0.a not built in o/x86_64-linux"
    exit 1
  fi
  sample=$(find o/x86_64-linux -maxdepth 1 -name '*.o' | head -1)
  if [ -n "$sample" ] && ! file "$sample" | grep -q 'ELF 64-bit'; then
    log "ERROR: tclmods objects are not ELF 64-bit ($sample)"
    file "$sample" >&2 || true
    exit 1
  fi
  cp -f "$built" "${LIBDIR}/libtclmods8.0.a"
  file "${LIBDIR}/libtclmods8.0.a" || true
  cd "${ROOT}"
}

build_max() {
  log "MAX 4.3.16"
  local max="${SRC}/max4.3.16"
  if ! grep -q 'intptr_t.*ti_body' "${max}/m/database/database.h"; then
    log "ERROR: database.h LP64 tile macros were not patched (see patch-source.sh)"
    exit 1
  fi
  if ! grep -q 'MEM_LP64_PATCH' "${max}/m/memory/mem.c"; then
    log "ERROR: mem.c LP64 allocator was not patched (see patch-source.sh)"
    exit 1
  fi
  cd "$max"
  mkdir -p i
  (cd i && rm -f ./*.h && ln -sf ../m/*/*.h .)
  mkdir -p o/linux
  for m in m/*; do
    [ -d "$m" ] || continue
    name=$(basename "$m")
    mkdir -p "o/linux/$name"
    touch "o/linux/$name/depend"
  done
  make -s -e -j1 max
  if [ -x o/linux/max ]; then
    file o/linux/max
  else
    log "ERROR: max binary not produced"
    exit 1
  fi
  cd "${ROOT}"
}

build_aux() {
  log "MAX maxaux (ext2spice, ext2sim, gemini, irsim, anXhelper)"
  local max="${SRC}/max4.3.16"
  mkdir -p "${max}/o/linux/aux"
  make -C "${max}/maxaux" -e -k -j1 || true
  cd "${ROOT}"
}

build_edif2sue() {
  log "edif2sue (optional)"
  local d="${SRC}/edif2sue1.2.12"
  [ -d "$d" ] || return 0
  cd "$d"
  if make MMI_UTILS="${UTILS}" MMI_CAD="${SRC}" TARGET2=linux -j1; then
    cd "${ROOT}"
    return 0
  fi
  log "edif2sue make failed, trying g++"
  shopt -s nullglob
  local srcs=(./*.cc)
  shopt -u nullglob
  if [ "${#srcs[@]}" -eq 0 ]; then
    log "WARN: edif2sue sources missing; skipping"
    cd "${ROOT}"
    return 0
  fi
  if ! ${CXX:-g++} -fcommon -O2 -U_FORTIFY_SOURCE -D_FORTIFY_SOURCE=0 \
      -Wno-write-strings -I. -DE2S_VERSION='"1.2.12"' -c "${srcs[@]}"; then
    log "WARN: edif2sue compile failed; skipping"
    cd "${ROOT}"
    return 0
  fi
  if ! ${CXX:-g++} -o edif2sue.linux ./*.o -lm; then
    log "WARN: edif2sue link failed; skipping"
  fi
  cd "${ROOT}"
}

build_sue_tee() {
  log "sue_tee"
  mkdir -p "${SRC}/sue4.4/bin.linux"
  # sue_tee.c uses // comments (not valid gnu89).
  gcc -O2 -fcommon -U_FORTIFY_SOURCE -D_FORTIFY_SOURCE=0 \
    "${SRC}/sue4.4/build/sue_tee.c" -o "${SRC}/sue4.4/bin.linux/sue_tee" || true
  cd "${ROOT}"
}

build_sue() {
  log "SUE"
  cd "${SRC}/sue4.4/build"
  chmod +x mkcsue
  CFLAGS="${CFLAGS} -DSHARED_OBJECT=1" bash ./mkcsue
  if [ ! -x "${SRC}/sue4.4/bin.linux/sue.exe" ]; then
    log "ERROR: sue.exe not produced"
    exit 1
  fi
  cd "${ROOT}"
}

build_nst() {
  log "NST"
  cd "${SRC}/nst2.4"
  chmod +x mknst
  bash ./mknst
  if [ ! -x "${SRC}/nst2.4/bin.linux/nst" ]; then
    log "ERROR: nst not produced"
    exit 1
  fi
  cd "${ROOT}"
}

build_tcl
build_tk
install_utils_bin
build_prepare
build_blt
build_tclmods
build_sue
build_nst
build_max
build_aux
build_edif2sue
build_sue_tee

verify_tools() {
  local ok=0 f
  for f in \
    "${SRC}/max4.3.16/o/linux/max" \
    "${SRC}/sue4.4/bin.linux/sue.exe" \
    "${SRC}/nst2.4/bin.linux/nst"; do
    if [ ! -x "$f" ]; then
      log "ERROR: missing $f"
      ok=1
    elif ! file -L "$f" | grep -q 'ELF 64-bit'; then
      log "ERROR: not ELF 64-bit: $f"
      file -L "$f" >&2 || true
      ok=1
    fi
  done
  return "$ok"
}

verify_tools || exit 1
log "Build finished (max, sue.exe, nst are ELF 64-bit)"
