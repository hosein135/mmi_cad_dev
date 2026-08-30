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
: "${CXX:=g++}"
export CC CXX
: "${SOURCE_DATE_EPOCH:=315532800}"
export SOURCE_DATE_EPOCH
# Do not add -D__DATE__ / -D__TIME__. The date string contains spaces
# ("Jan  1 1980"); Nix's cc-wrapper word-splits NIX_CFLAGS_COMPILE and
# GCC 14 then reports: error: duplicate 'unsigned'. GCC already stamps
# those builtins from SOURCE_DATE_EPOCH.
export CFLAGS="${CFLAGS:--std=gnu89 -fcommon -fno-strict-aliasing -O2 -frandom-seed=mmi-cad-040526 -U_FORTIFY_SOURCE -D_FORTIFY_SOURCE=0} -Wno-error -Wno-implicit-function-declaration -Wno-implicit-int -Wno-int-conversion -Wno-incompatible-pointer-types -Wno-pointer-to-int-cast -Wno-int-to-pointer-cast -Wno-return-type -Wno-unused -Wno-old-style-definition -Wno-declaration-after-statement -include float.h -DCLK_TCK=100 -DUSE_SYSTEM_MALLOC"

export LC_ALL=C
export LANG=C
export TZ=UTC

# Deterministic GNU ar (zero uid/gid/mtime in archive members).
mmi_ar_rcs() { ar -D rcs "$@"; }
export AR="ar -D rc"
export RANLIB="${RANLIB:-ranlib}"
HOST_TCLSH="$(command -v tclsh)"

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
  make -e -j1 CFLAGS="${CFLAGS}"
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
  make -e -j1 CFLAGS="${CFLAGS}"
  cp -f libtk8.0.a "${LIBDIR}/"
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
    make AR="${AR}" RANLIB="${RANLIB}" EXTRA_CFLAGS= \
      CFLAGS="${CFLAGS} ${inc}" \
      INCLUDES="-I. -I.. ${inc}" \
      -j1 all
    mapfile -t blt_objs < <(LC_ALL=C find . -maxdepth 1 -name '*.o' | LC_ALL=C sort)
    rm -f libBLT.a
    mmi_ar_rcs libBLT.a "${blt_objs[@]}"
    "${RANLIB}" libBLT.a
  )
  if [ ! -f src/libBLT.a ]; then
    log "ERROR: libBLT.a not built (NST requires BLT)"
    exit 1
  fi
  file src/libBLT.a
  cd "${ROOT}"
}

build_tclmods() {
  log "tclmods"
  cd "${UTILS}/tclmods"
  rm -f "${LIBDIR}/libtclmods8.0.a"
  mkdir -p o/x86_64-linux
  # Do not use find(1) — vendor tree ships 32-bit libtclmods8.0.a under o/i486-linux*.
  make -j1 MMI_UTILS="${UTILS}" TARGET=x86_64-linux \
    CC="${CC:-gcc}" CFLAGS="${CFLAGS}" AR="${AR}" RANLIB="${RANLIB}"
  local built="o/x86_64-linux/libtclmods8.0.a"
  if [ ! -f "$built" ]; then
    mapfile -t objs < <(LC_ALL=C find o/x86_64-linux -maxdepth 1 -name '*.o' | LC_ALL=C sort)
    if [ "${#objs[@]}" -gt 0 ]; then
      mmi_ar_rcs "$built" "${objs[@]}"
      "${RANLIB}" "$built"
    fi
  fi
  if [ ! -f "$built" ]; then
    log "ERROR: libtclmods8.0.a not built in o/x86_64-linux"
    exit 1
  fi
  sample=$(LC_ALL=C find o/x86_64-linux -maxdepth 1 -name '*.o' | LC_ALL=C sort | head -1)
  if [ -n "$sample" ] && ! file "$sample" | grep -q 'ELF 64-bit'; then
    log "ERROR: tclmods objects are not ELF 64-bit ($sample)"
    file "$sample" >&2
    exit 1
  fi
  cp -f "$built" "${LIBDIR}/libtclmods8.0.a"
  file "${LIBDIR}/libtclmods8.0.a"
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
  mkdir -p "${max}/o/linux/maxaux/ext/utils" \
    "${max}/o/linux/maxaux/ext/extflat" \
    "${max}/o/linux/maxaux/ext/ext2sim" \
    "${max}/o/linux/maxaux/ext/ext2spice" \
    "${max}/o/linux/maxaux/gemini" \
    "${max}/o/linux/maxaux/irsim/irsim" \
    "${max}/o/linux/maxaux/irsim/anXhelper" \
    "${max}/o/linux/maxaux/irsim/ana11" \
    "${max}/o/linux/aux/ext/utils" \
    "${max}/o/linux/aux/ext/extflat" \
    "${max}/o/linux/aux/ext/ext2sim" \
    "${max}/o/linux/aux/ext/ext2spice" \
    "${max}/o/linux/aux/gemini" \
    "${max}/o/linux/aux/irsim/irsim" \
    "${max}/o/linux/aux/irsim/anXhelper" \
    "${max}/o/linux/aux/irsim/ana11"
  find "${max}/o/linux/maxaux" "${max}/o/linux/aux" -type d -exec touch {}/depend \;
  make -C "${max}/maxaux" -e -j1
  local aux found
  for aux in ext2spice ext2sim gemini irsim anXhelper; do
    found="$(LC_ALL=C find "${max}/o" -type f -name "$aux" | LC_ALL=C sort | head -1)"
    if [ -z "$found" ] || [ ! -x "$found" ]; then
      log "ERROR: maxaux did not produce $aux"
      exit 1
    fi
    if ! file -L "$found" | grep -q 'ELF 64-bit'; then
      log "ERROR: $aux is not ELF 64-bit"
      file -L "$found" >&2
      exit 1
    fi
  done
  cd "${ROOT}"
}

build_edif2sue() {
  log "edif2sue"
  local d="${SRC}/edif2sue1.2.12"
  [ -d "$d" ] || { log "ERROR: edif2sue sources missing"; exit 1; }
  cd "$d"
  # Do not leak C-only -std=gnu89 / -Wno-implicit-int into g++.
  local cxxflags="-fcommon -O2 -U_FORTIFY_SOURCE -D_FORTIFY_SOURCE=0 -fpermissive -Wno-write-strings -Wno-error -std=gnu++98"
  if ! NIX_CFLAGS_COMPILE="" NIX_CXXFLAGS_COMPILE="${cxxflags}" \
      make MMI_UTILS="${UTILS}" MMI_CAD="${SRC}" TARGET2=linux \
      CC="${CXX:-g++}" CXX="${CXX:-g++}" \
      CFLAGS="${cxxflags}" CXXFLAGS="${cxxflags}" \
      -j1; then
    log "edif2sue make failed, compiling with g++"
    shopt -s nullglob
    local srcs=(./*.cc)
    shopt -u nullglob
    if [ "${#srcs[@]}" -eq 0 ]; then
      log "ERROR: edif2sue sources missing"
      exit 1
    fi
    NIX_CFLAGS_COMPILE="" NIX_CXXFLAGS_COMPILE="${cxxflags}" \
      ${CXX:-g++} ${cxxflags} -I. -DE2S_VERSION='"1.2.12"' -c "${srcs[@]}"
    NIX_CFLAGS_COMPILE="" ${CXX:-g++} -o edif2sue.linux ./*.o -lm
  fi
  if [ ! -x edif2sue.linux ] && [ ! -x edif2sue ]; then
    log "ERROR: edif2sue binary not produced"
    exit 1
  fi
  cd "${ROOT}"
}

build_sue_tee() {
  log "sue_tee"
  mkdir -p "${SRC}/sue4.4/bin.linux"
  # sue_tee.c uses // comments (not valid gnu89).
  gcc -O2 -fcommon -U_FORTIFY_SOURCE -D_FORTIFY_SOURCE=0 \
    "${SRC}/sue4.4/build/sue_tee.c" -o "${SRC}/sue4.4/bin.linux/sue_tee"
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
    "${SRC}/nst2.4/bin.linux/nst" \
    "${SRC}/sue4.4/bin.linux/sue_tee"; do
    if [ ! -x "$f" ]; then
      log "ERROR: missing $f"
      ok=1
    elif ! file -L "$f" | grep -q 'ELF 64-bit'; then
      log "ERROR: not ELF 64-bit: $f"
      file -L "$f" >&2
      ok=1
    fi
  done
  return "$ok"
}

verify_tools || exit 1
log "Build finished (max, sue.exe, nst are ELF 64-bit)"
