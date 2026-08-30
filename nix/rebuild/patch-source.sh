#!/usr/bin/env bash
# Retarget the 2004 MMI source tree from i486-linux to native x86_64-linux.
set -euo pipefail
ROOT="${1:?path to extracted mmi_pd_040526}"
cd "$ROOT"

python3 "${PATCH_INTPTR:?}" "$ROOT/src"

mkdir -p src/utils/pccts/h
cp -a "${PATCH_PCCTS_H:?}/." src/utils/pccts/h/

# --- platform ids ---
sed -i \
  -e 's/TARGET := i486-linux$(OS_VERSION)/TARGET := x86_64-linux/' \
  -e 's/TARGET2 := i486-linux/TARGET2 := linux/' \
  -e '/ifeq "$(TARGET)" "i486-linux2.0"/,/endif/d' \
  src/utils/config/main.config

sed -i \
  -e 's|-L/usr/X11R6/lib -lX11|-lX11 -lXext -lXt|' \
  -e 's/ $(X_LIB) -lieee -ldl/ $(X_LIB) -ldl/' \
  -e 's/-lieee //g' \
  src/utils/config/main.common

sed -i 's/BIN_LINUX := bin.i486-linux/BIN_LINUX := bin.linux/' \
  src/max4.3.16/make/Makefile.main \
  src/max4.2.11/make/Makefile.main 2>/dev/null || true

# Tcl/Tk 8.0: drop i486 config.cache and do not let uname -r (WSL) break case $system.
for d in src/utils/tcltk/tcl8.0.4/unix src/utils/tcltk/tk8.0.4/unix; do
  rm -f "$d/config.cache" "$d/config.status" "$d/config.log"
  if [ -f "$d/configure" ]; then
    chmod +x "$d/configure" "$d/config.guess" "$d/config.sub" 2>/dev/null || true
    sed -i \
      -e 's/system=`uname -s`-`uname -r`/system=Linux-4.19/' \
      -e 's|test -r /etc/.relid|test -r /etc/.relid-disabled|' \
      -e "s|/etc/.relid'|/etc/.relid|" \
      "$d/configure"
  fi
done

# Do not treat warnings as errors (gcc 14 vs 1990s C).
sed -i \
  -e 's/ -Werror//g' \
  -e 's/-Werror//g' \
  -e 's/ -Wuninitialized//g' \
  -e 's/ -Wreturn-type//g' \
  src/max4.3.16/make/config.linux*

# MAX link rule typo: ${OBJDIR} was never defined (should be ${OBJ_DIR}).
sed -i 's/\${OBJDIR}\/max/\${OBJ_DIR}\/max/' src/max4.3.16/max/Makefile

sed -i 's|GEMINI := aux/gemini/gemini|GEMINI := maxaux/gemini/gemini|' \
  src/max4.3.16/make/Makefile.main

# makemods (was :makemods csh script) — inline in Makefile.main; also write helper script.
for max_mk in src/max4.3.16/make src/max4.2.11/make; do
  [ -d "$max_mk" ] || continue
  cat > "$max_mk/makemods" << 'EOF'
#!/usr/bin/env bash
set -euo pipefail
for mod in "$@"; do
  echo "------- Doing $mod -------"
  make -e -C "m/$mod" -k
done
EOF
  chmod +x "$max_mk/makemods"
  rm -f "$max_mk/:makemods"
  if [ -f "$max_mk/Makefile.main" ]; then
    python3 - << PY
from pathlib import Path
p = Path("$max_mk/Makefile.main")
t = p.read_text(encoding="latin-1")
old = "\t./make/makemods \${MODULES}\n"
if old not in t:
    old = "\tmake/:makemods \${MODULES}\n"
new = """\t@for mod in \$(MODULES); do \\\\
\t  echo "------- Doing \$\$mod -------"; \\\\
\t  \$(MAKE) -e -C m/\$\$mod -k || exit 1; \\\\
\tdone
"""
if old in t:
    t = t.replace(old, new)
    p.write_text(t, encoding="latin-1")
    print("patch:", p, "makemods inlined")
else:
    print("warn: makemods recipe not found in", p)
PY
  fi
done

# Drop hardcoded Juniper paths so MMI_CAD / MMI_UTILS come from the environment.
sed -i \
  -e '/^MMI_CAD :=/d' \
  -e '/^MMI_UTILS :=/d' \
  src/nst2.4/Makefile \
  src/sue4.4/build/Makefile \
  src/utils/tclmods/Makefile \
  src/edif2sue1.2.12/Makefile \
  src/utils/speedy4.0/Makefile

# SUE: no nl_shell (gr.c / mem.h). NST BLT lives in the i486-named source tree.
python3 - << 'PY'
from pathlib import Path
import re

p = Path("src/sue4.4/build/Makefile")
t = p.read_text(encoding="latin-1")
t = re.sub(
    r"(?m)^(\s*SRCS\s+=\s+sueAppInit\.c mmiInterrupt\.c steiner\.c)\s+gr\.c\s*$",
    r"\1",
    t,
)
t = re.sub(
    r"(?m)^(\s*OBJS\s+=\s+sueAppInit\.o mmiInterrupt\.o steiner\.o)\s+gr\.o\s*$",
    r"\1",
    t,
)
t = re.sub(r"(?m)^\s*NL_LIB\s*=.*", "NL_LIB =", t)
t = re.sub(r"(?m)^\s*NL_INCLUDES\s*=.*", "NL_INCLUDES =", t)
p.write_text(t, encoding="latin-1")
print("sue Makefile: dropped gr.c and nl_shell")

app = Path("src/sue4.4/build/sueAppInit.c")
t = app.read_text(encoding="latin-1")
t = t.replace("  static int nlsh_app_init ();\n", "")
t = t.replace("  nlsh_app_init(interp);", "#ifndef SHARED_OBJECT\n  nlsh_app_init(interp);\n#endif")
app.write_text(t, encoding="latin-1")
print("sueAppInit: optional nlsh")

# Flat install: binaries live in $MMI_TOOLS/bin; SUE assets in $MMI_TOOLS/sue.
sue_init = Path("src/sue4.4/build/sueInit.tcl")
t = sue_init.read_text(encoding="latin-1")
if "file join $env(MMI_TOOLS) sue" not in t:
    t = t.replace(
        'if {$SUE_DIR == "."} {\n  set SUE_DIR [pwd]\n}\n',
        'if {$SUE_DIR == "."} {\n  set SUE_DIR [pwd]\n}\n'
        'if {[info exists env(MMI_TOOLS)] && $env(MMI_TOOLS) ne ""} {\n'
        '  set SUE_DIR [file join $env(MMI_TOOLS) sue]\n'
        '}\n',
    )
    t = t.replace("set SUE_BIN bin.i486-linux", "set SUE_BIN bin.linux")
    sue_init.write_text(t, encoding="latin-1")
    print("sueInit.tcl: MMI_TOOLS/sue, bin.linux")

max0 = Path("src/max4.3.16/maxtcl/max0.tcl")
t = max0.read_text(encoding="latin-1")
if 'set MN_BIN_DIR "bin.i486-linux"' in t:
    t = t.replace(
        '"Linux" { set MN_BIN_DIR "bin.i486-linux" }',
        '"Linux" { set MN_BIN_DIR "bin.linux" }',
    )
    max0.write_text(t, encoding="latin-1")
    print("max0.tcl: bin.linux")

# GCC 14: block-scope "static int foo(args);" is invalid. Hoist to file scope.
nested_proto = re.compile(
    r"^[ \t]+static[ \t]+((?:int|void|bool|char|long|short|unsigned)(?:[ \t]+\*)?[ \t]+\w+[ \t]*\([^;]*\))[ \t]*;[ \t]*$",
    re.M,
)
for pth in Path("src/max4.3.16").rglob("*.c"):
    if not pth.is_file():
        continue
    try:
        t = pth.read_text(encoding="latin-1")
    except OSError:
        continue
    found = nested_proto.findall(t)
    if not found:
        continue
    t2 = nested_proto.sub("", t)
    protos = "\n".join(f"static {sig};" for sig in dict.fromkeys(found))
    # Insert after the last #include
    lines = t2.splitlines(keepends=True)
    last_inc = 0
    for i, ln in enumerate(lines):
        if ln.lstrip().startswith("#include"):
            last_inc = i
    lines.insert(last_inc + 1, "\n" + protos + "\n")
    pth.write_text("".join(lines), encoding="latin-1")
    print("hoisted nested static", pth.name, len(found))

for pth in Path("src").rglob("*"):
    if pth.suffix not in {".c", ".h"}:
        continue
    if not pth.is_file():
        continue
    try:
        t = pth.read_text(encoding="latin-1")
    except OSError:
        continue
    orig = t
    t = t.replace(
        "while (gdsRdBufLoc<=last)  *(((unsigned char *) buf)++) = *(gdsRdBufLoc++);",
        "{ unsigned char *_gds_bp = (unsigned char *) buf; "
        "while (gdsRdBufLoc<=last) *_gds_bp++ = *(gdsRdBufLoc++); "
        "buf = _gds_bp; }",
    )
    t = t.replace(
        "*(((unsigned char *) buf)++) = *(gdsRdBufLoc++);",
        "{ unsigned char *_gds_bp = (unsigned char *) buf; *_gds_bp++ = *(gdsRdBufLoc++); buf = _gds_bp; }",
    )
    if t != orig:
        pth.write_text(t, encoding="latin-1")
        print("gds lvalue", pth)
PY

ln -sfn blt2.4g.i486-linux2.2 src/utils/blt2.4g.x86_64-linux
if [ -f src/utils/blt2.4g.i486-linux2.2/configure ]; then
  blt=src/utils/blt2.4g.i486-linux2.2
  chmod +x "$blt/configure" "$blt/cf/config.guess" "$blt/cf/config.sub" "$blt/cf/install-sh" 2>/dev/null || true
fi

# Pre-generated DEF parser is in the tarball; do not require 32-bit PCCTS/antlr.
python3 - << 'PY'
from pathlib import Path
p = Path("src/max4.3.16/m/def/Makefile")
t = p.read_text(encoding="latin-1")
t = t.replace("\t$(ANTLR) -gl -fl def_lex.dlg -fe def_parse_err.c -fh def_parse.h def_parse.g", "\t@true")
t = t.replace("\t$(DLG) $(DFLAGS) $< > $@", "\t@true")
p.write_text(t, encoding="latin-1")
print("def Makefile: skip antlr/dlg")

# GCC 14: K&R "extern void foo(), bar();" conflicts with prototyped headers.
import re
from pathlib import Path
rx_kandr = re.compile(r"^extern void \w+\(\)(, \w+\(\))+;\s*$", re.M)
for p in Path("src/max4.3.16").rglob("*.c"):
    if not p.is_file():
        continue
    try:
        t = p.read_text(encoding="latin-1")
    except OSError:
        continue
    t2 = rx_kandr.sub("", t)
    if t2 != t:
        p.write_text(t2, encoding="latin-1")
        print("dropped K&R extern", p)

gds = Path("src/max4.3.16/m/gds/gdsWrite.c")
t = gds.read_text(encoding="latin-1")
old = "{\n  static int calmaProcessDef(CellDef *def);     /* forward ref */\n  return (calmaProcessDef(use->cu_def));\n}"
new = "{\n  return (calmaProcessDef(use->cu_def));\n}"
if old in t:
    t = t.replace(old, new, 1)
    needle = "static int calmaProcessUse(CellUse *use,"
    t = t.replace(needle, "static int calmaProcessDef(CellDef *def);\n\n" + needle, 1)
    gds.write_text(t, encoding="latin-1")
    print("hoisted calmaProcessDef")
else:
    print("gdsWrite hoist skipped")
PY

# Explicit 64-bit tile-flag macros (lvalue-int-cast is illegal on GCC 14).
python3 - << 'PY'
from pathlib import Path
import re

new = """#define DBisSetTileFlag(tp,f)      (((intptr_t) (tp)->ti_body) & (f))
#define DBsetTileFlag(tp,f)\t((tp)->ti_body = (ClientData)(((intptr_t)(tp)->ti_body) | (intptr_t)(f)))
#define DBresetTileFlag(tp,f)   ((tp)->ti_body = (ClientData)(((intptr_t)(tp)->ti_body) & ~(intptr_t)(f)))"""
rx = re.compile(
    r"#define DBisSetTileFlag\(tp,f\)\s+\(\(\(int\) \(tp\)->ti_body\) & \(f\)\)\s*\n"
    r"#define DBsetTileFlag\(tp,f\)\s+\(\(\(int\) \(tp\)->ti_body\) \|= \(f\)\)\s*\n"
    r"#define DBresetTileFlag\(tp,f\)\s+\(\(\(int\) \(tp\)->ti_body\) &= ~\(f\)\)",
)
rx2 = re.compile(
    r"#define\s+DBgetTileType\(tp\)\s+\(\(\(TileType\) \(tp\)->ti_body\) & 0xff\)"
)
for p in Path("src").rglob("database.h"):
    t = p.read_text(encoding="latin-1")
    t2 = rx.sub(new, t)
    t2 = rx2.sub("#define\tDBgetTileType(tp)       (((intptr_t) (tp)->ti_body) & 0xff)", t2)
    t2 = t2.replace(
        "(ClientData) (((TileType) (tp)->ti_body) & ~0xff | ((TileType) (b)))",
        "(ClientData) ((((intptr_t) (tp)->ti_body) & ~0xff) | ((intptr_t) (b)))",
    )
    if t2 != t:
        p.write_text(t2, encoding="latin-1")
        print("macros", p)
PY

# Rewrite mkcsue / mknst as bash (csh not required at build time).
cat > src/sue4.4/build/mkcsue << 'EOF'
#!/usr/bin/env bash
set -euo pipefail
: "${MMI_CAD:?MMI_CAD not set}"
: "${MMI_UTILS:?MMI_UTILS not set}"
export MMI_CAD MMI_UTILS CC="${CC:-gcc}" CFLAGS="${CFLAGS:-}"
SUEDIR=../..
CSUEDIR=..
rm -rf tmp
mkdir tmp
cd tmp
cp "$SUEDIR"/src/*.tcl .
cp "$CSUEDIR"/sueInit.tcl "$CSUEDIR"/sueInitA.tcl "$CSUEDIR"/sueInitB.tcl .
cp "$CSUEDIR"/Makefile "$CSUEDIR"/sueAppInit.c "$CSUEDIR"/mmiInterrupt.c .
cp "$CSUEDIR"/steiner.c "$CSUEDIR"/nl_include.h .
make -e sueInit
make -e sue
mkdir -p "$CSUEDIR/../bin.linux"
mv -f sue "$CSUEDIR/../bin.linux/sue.exe"
EOF
chmod +x src/sue4.4/build/mkcsue

cat > src/nst2.4/mknst << 'EOF'
#!/usr/bin/env bash
set -euo pipefail
: "${MMI_CAD:?MMI_CAD not set}"
: "${MMI_UTILS:?MMI_UTILS not set}"
export MMI_CAD MMI_UTILS CC="${CC:-gcc}" CFLAGS="${CFLAGS:-}"
NSTDIR=..
rm -rf tmp
mkdir tmp
cd tmp
cp "$NSTDIR"/*.tcl "$NSTDIR"/nstinit.a "$NSTDIR"/nstinit.b .
cp "$NSTDIR"/Makefile "$NSTDIR"/nst.c "$NSTDIR"/nstAppInit.c .
make -e nst
mkdir -p "$NSTDIR/bin.linux"
mv -f nst "$NSTDIR/bin.linux/nst"
EOF
chmod +x src/nst2.4/mknst

# Windows NTFS reserves AUX; rename MAX helper sources so git works on C:.
for max in src/max4.2.11 src/max4.3.16; do
  if [ -d "$max/aux" ]; then
    rm -rf "$max/maxaux"
    mv "$max/aux" "$max/maxaux"
    echo "patch: $max/aux -> maxaux"
  fi
  mm="$max/make/Makefile.main"
  if [ -f "$mm" ]; then
    sed -i \
      -e 's|aux/ext/|maxaux/ext/|g' \
      -e 's|aux/irsim/|maxaux/irsim/|g' \
      -e 's/all: max aux/all: max maxaux/' \
      -e 's/^aux:/maxaux:/' \
      -e 's/^\.PHONY: aux$/.PHONY: maxaux/' \
      -e 's/cd aux;/cd maxaux;/' \
      "$mm"
    echo "patch: $mm aux paths -> maxaux"
  fi
done

echo "x86_64 source patches applied under $ROOT"
