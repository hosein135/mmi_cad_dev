#!/usr/bin/env bash
# Retarget the 2004 MMI source tree from i486-linux to native x86_64-linux.
set -euo pipefail
ROOT="${1:?path to extracted mmi_pd_040526}"
cd "$ROOT"

python3 "${PATCH_INTPTR:?}" "$ROOT/src"

# MAX pool allocator (mem.c) is ILP32: free-list pointer math uses
# "(mem_free_item)storage + i" which is 8-byte strides on LP64 while
# slots are sized in 4-byte ints, and the header size uses
# sizeof(struct)-sizeof(int) which is wrong once pointers are 8 bytes.
python3 - << 'PY'
from pathlib import Path

p = Path("src/max4.3.16/m/memory/mem.c")
t = p.read_text(encoding="latin-1")
if "MEM_LP64_PATCH" in t:
    print("mem.c: LP64 allocator already patched")
else:
    t = t.replace(
        '#include "port.h"\n#include "mem.h"\n',
        '#include "port.h"\n#include "mem.h"\n'
        "#include <stddef.h>\n#include <stdint.h>\n"
        "extern int posix_memalign(void **memptr, size_t alignment, size_t size);\n",
        1,
    )
    old_macros = """#define MEM_MALLOC_OVERHEAD    8
#define MEM_MAX_ALLOC        512
#define MEM_BLOCK_BITS        11
#define MEM_BLOCK_ALIGN        ( 1 << MEM_BLOCK_BITS)
#define MEM_BLOCK_MASK         (-1 << MEM_BLOCK_BITS)
#define MEM_BLOCK_HEADER_SIZE  (sizeof (struct mem_block) - sizeof (int))
#define MEM_BLOCK_ALLOC        (MEM_BLOCK_ALIGN - MEM_MALLOC_OVERHEAD)
#define MEM_BLOCK_STORAGE_SIZE (MEM_BLOCK_ALLOC - MEM_BLOCK_HEADER_SIZE)"""
    new_macros = """#define MEM_LP64_PATCH 1
#define MEM_MALLOC_OVERHEAD    8
#define MEM_MAX_ALLOC        512
#define MEM_BLOCK_BITS        11
#define MEM_BLOCK_ALIGN        ( 1 << MEM_BLOCK_BITS)
#define MEM_BLOCK_MASK         (~((uintptr_t) MEM_BLOCK_ALIGN - 1))
#define MEM_BLOCK_HEADER_SIZE  (offsetof (struct mem_block, storage))
#define MEM_BLOCK_ALLOC        MEM_BLOCK_ALIGN
#define MEM_BLOCK_STORAGE_SIZE (MEM_BLOCK_ALLOC - MEM_BLOCK_HEADER_SIZE)"""
    if old_macros not in t:
        raise SystemExit("mem.c: MEM_* macros not found")
    t = t.replace(old_macros, new_macros, 1)

    old_reg = """static
void
mem_register_block (mem_block block, int flag)
{
  unsigned int block_index = ((ptrdiff_t) block >> MEM_BLOCK_BITS);
  unsigned int offset = block_index >> 5;
  unsigned int bit = block_index & 0x1f;
  unsigned int mask = 1 << bit;

  if ( offset >= mem_block_table_size ) {
    unsigned int i;
    unsigned int old_table_size = mem_block_table_size;

    mem_block_table_size = power_2_roundup (offset);
    mem_block_table = realloc (mem_block_table,
			       mem_block_table_size * sizeof (int));

    for ( i = old_table_size; i < mem_block_table_size; i++ ) {
      mem_block_table[i] = 0;
    }
  }

  if ( flag )
    mem_block_table[offset] |= mask;
  else
    mem_block_table[offset] &= ~mask;
}"""
    new_reg = """static mem_block *mem_reg_tab = NULL;
static unsigned int mem_reg_cap = 0;
static unsigned int mem_reg_used = 0;
#define MEM_REG_EMPTY ((mem_block) 0)
#define MEM_REG_TOMB  ((mem_block) (uintptr_t) 1)

static unsigned int
mem_reg_hash (mem_block block)
{
  uintptr_t x = (uintptr_t) block >> MEM_BLOCK_BITS;
  x ^= x >> 33;
  x *= (uintptr_t) 0xff51afd7ed558ccdULL;
  return (unsigned int) x;
}

static void
mem_reg_grow (void)
{
  unsigned int ncap = mem_reg_cap ? mem_reg_cap * 2 : 64;
  mem_block *ntab = calloc (ncap, sizeof (mem_block));
  unsigned int i;

  for ( i = 0; i < mem_reg_cap; i++ ) {
    mem_block b = mem_reg_tab[i];
    if ( b != MEM_REG_EMPTY && b != MEM_REG_TOMB ) {
      unsigned int j = mem_reg_hash (b) & (ncap - 1);
      while ( ntab[j] != MEM_REG_EMPTY )
	j = (j + 1) & (ncap - 1);
      ntab[j] = b;
    }
  }
  free (mem_reg_tab);
  mem_reg_tab = ntab;
  mem_reg_cap = ncap;
}

static int
mem_block_is_regular (mem_block block)
{
  unsigned int j;
  if ( ! mem_reg_tab || ! block )
    return 0;
  j = mem_reg_hash (block) & (mem_reg_cap - 1);
  for ( ;; ) {
    mem_block b = mem_reg_tab[j];
    if ( b == MEM_REG_EMPTY )
      return 0;
    if ( b == block )
      return 1;
    j = (j + 1) & (mem_reg_cap - 1);
  }
}

static
void
mem_register_block (mem_block block, int flag)
{
  unsigned int j;

  if ( flag ) {
    if ( mem_reg_used * 2 >= mem_reg_cap )
      mem_reg_grow ();
    j = mem_reg_hash (block) & (mem_reg_cap - 1);
    for ( ;; ) {
      mem_block b = mem_reg_tab[j];
      if ( b == MEM_REG_EMPTY || b == MEM_REG_TOMB || b == block ) {
	if ( b != block )
	  mem_reg_used++;
	mem_reg_tab[j] = block;
	return;
      }
      j = (j + 1) & (mem_reg_cap - 1);
    }
  }

  if ( ! mem_reg_tab )
    return;
  j = mem_reg_hash (block) & (mem_reg_cap - 1);
  for ( ;; ) {
    mem_block b = mem_reg_tab[j];
    if ( b == MEM_REG_EMPTY )
      return;
    if ( b == block ) {
      mem_reg_tab[j] = MEM_REG_TOMB;
      return;
    }
    j = (j + 1) & (mem_reg_cap - 1);
  }
}"""
    if old_reg not in t:
        raise SystemExit("mem.c: mem_register_block not found")
    t = t.replace(old_reg, new_reg, 1)

    old_of = """static
mem_block
mem_block_of_pointer (void *ptr)
{
  unsigned int block_index = ((ptrdiff_t) ptr) >> MEM_BLOCK_BITS;
  unsigned int offset = block_index >> 5;
  unsigned int bit = block_index & 0x1f;
  unsigned int mask = 1 << bit;
  mem_block block;

  if ( offset >= mem_block_table_size ||
       ! (mem_block_table[offset] & mask) ) {
    block = (mem_block) (((ptrdiff_t) ptr) - MEM_BLOCK_HEADER_SIZE);
  }
  else {
    block = (mem_block) (((ptrdiff_t) ptr) & MEM_BLOCK_MASK);
  }

  return block;
}"""
    new_of = """static
mem_block
mem_block_of_pointer (void *ptr)
{
  mem_block aligned = (mem_block) (((uintptr_t) ptr) & MEM_BLOCK_MASK);

  if ( mem_block_is_regular (aligned) ) {
    unsigned char *p = (unsigned char *) ptr;
    unsigned char *b = (unsigned char *) aligned;
    if ( p >= b + MEM_BLOCK_HEADER_SIZE && p < b + MEM_BLOCK_ALLOC )
      return aligned;
  }
  return (mem_block) ((unsigned char *) ptr - MEM_BLOCK_HEADER_SIZE);
}"""
    if old_of not in t:
        raise SystemExit("mem.c: mem_block_of_pointer not found")
    t = t.replace(old_of, new_of, 1)

    old_alloc = """  mem_block block = memalign (MEM_BLOCK_ALIGN, MEM_BLOCK_ALLOC);

  group->regular_blocks++;
  group->allocated += MEM_BLOCK_ALLOC + MEM_MALLOC_OVERHEAD;

  block->group = group;
  block->num_words = num_words;

  mem_dll_insert (group, block);

  mem_register_block (block, 1);

  {
    int i;
    int *storage = block->storage;
    int storage_size = MEM_BLOCK_STORAGE_SIZE / sizeof (int); 

    for ( i = 0; i + num_words < storage_size; i += num_words ) {
      mem_free_item item = (mem_free_item) storage + i;
      mem_free_item next = (mem_free_item) storage + i + num_words;

      group->free += num_words * sizeof (int);

      if ( i + 2*num_words < storage_size ) {
	item->next = next;
      }
      else {
	item->next = NULL;
      }
    }

    return (mem_free_item) storage;
  }"""
    new_alloc = """  mem_block block;
  {
    void *p = NULL;
    if ( posix_memalign (&p, MEM_BLOCK_ALIGN, MEM_BLOCK_ALLOC) != 0 )
      p = NULL;
    block = (mem_block) p;
  }

  if ( block == NULL ) {
    group->out_of_memory_fun ();
  }

  group->regular_blocks++;
  group->allocated += MEM_BLOCK_ALLOC + MEM_MALLOC_OVERHEAD;

  block->group = group;
  block->num_words = num_words;

  mem_dll_insert (group, block);

  mem_register_block (block, 1);

  {
    int i;
    int *storage = block->storage;
    int storage_size = MEM_BLOCK_STORAGE_SIZE / sizeof (int); 

    /* Slot index is in ints; do not use mem_free_item* arithmetic (8 bytes
     * on LP64 vs 4-byte slots). */
    for ( i = 0; i + num_words < storage_size; i += num_words ) {
      mem_free_item item = (mem_free_item) (storage + i);
      mem_free_item next = (mem_free_item) (storage + i + num_words);

      group->free += num_words * sizeof (int);

      if ( i + 2*num_words < storage_size ) {
	item->next = next;
      }
      else {
	item->next = NULL;
      }
    }

    return (mem_free_item) storage;
  }"""
    if old_alloc not in t:
        raise SystemExit("mem.c: mem_alloc_items body not found")
    t = t.replace(old_alloc, new_alloc, 1)

    old_align = """  int alignment = (align + 3) & 0xfffffffc;"""
    new_align = """  int alignment = (align + 3) & 0xfffffffc;
  if ( alignment < (int) sizeof (void *) )
    alignment = (int) sizeof (void *);"""
    if old_align not in t:
        raise SystemExit("mem.c: mem_group_create alignment not found")
    t = t.replace(old_align, new_align, 1)

    p.write_text(t, encoding="latin-1")
    print("mem.c: LP64 pool allocator (free-list strides, header offsetof, posix_memalign)")
PY

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

# Magic's page allocator stores pointers in 32-bit INT (OBJECTTOPAGE).
# That is wrong on LP64 and GCC 14 errors on the casts. Use libc malloc.
python3 - << 'PY'
from pathlib import Path

old_int = """#ifdef	ALPHA
#define	INT		long
#define ALIGN		long
#define	BYPERWD		(sizeof (INT))
#define	LOGBYPERWD	3				    /* LOG2(BYPERWD) */
#else
#define	INT		int
#define ALIGN		int
#define	BYPERWD		(sizeof (INT))
#define	LOGBYPERWD	2				    /* LOG2(BYPERWD) */
#endif"""

new_int = """#define	INT		intptr_t
#define ALIGN		intptr_t
#define	BYPERWD		(sizeof (INT))
#if defined(__LP64__) || defined(_LP64) || defined(ALPHA)
#define	LOGBYPERWD	3				    /* LOG2(BYPERWD) */
#else
#define	LOGBYPERWD	2				    /* LOG2(BYPERWD) */
#endif"""

# NOMACROS (which makes FREE() skip mallocFreePage) is decided BEFORE the
# INT macros. Define USE_SYSTEM_MALLOC at the top of the header.
sys_off = """/* The USE_SYSTEM_MALLOC flag disables Magic's allocator, allowing
 * the system malloc to be used instead.
 */
"""
sys_on = """/* The USE_SYSTEM_MALLOC flag disables Magic's allocator, allowing
 * the system malloc to be used instead.
 */
#ifndef USE_SYSTEM_MALLOC
#define USE_SYSTEM_MALLOC 1
#endif
"""

for p in Path("src").glob("max*/maxaux/ext/include/malloc.h"):
    t = p.read_text(encoding="latin-1")
    if old_int not in t and "intptr_t" not in t:
        raise SystemExit(f"malloc.h INT macros not found in {p}")
    if old_int in t:
        t = t.replace(old_int, new_int, 1)
    if sys_off in t and "#define USE_SYSTEM_MALLOC 1" not in t:
        t = t.replace(sys_off, sys_on, 1)
    if "#include <stdint.h>" not in t:
        t = "#include <stdint.h>\n" + t
    p.write_text(t, encoding="latin-1")
    print("malloc.h LP64 + USE_SYSTEM_MALLOC", p)

old_ext = """/* These were defined to be error strings in malloc.h */
#undef	malloc
#undef	free

/* Imports */
extern void TxError();
extern char *TxGetLine();
extern char *sbrk();
extern char *malloc();
"""
new_ext = """/* These were defined to be error strings in malloc.h */
#undef	malloc
#undef	free
#undef	calloc

#include <stdlib.h>
#include <string.h>
#include <unistd.h>

/* Imports */
extern void TxError();
extern char *TxGetLine();
"""
for p in Path("src").glob("max*/maxaux/ext/utils/malloc.c"):
    t = p.read_text(encoding="latin-1")
    if old_ext not in t:
        if "include <stdlib.h>" in t:
            print("malloc.c already patched", p)
            continue
        raise SystemExit(f"malloc.c extern block not found in {p}")
    t = t.replace(old_ext, new_ext, 1)
    t = t.replace("bzero(cp, (int) nbytes);", "memset(cp, 0, (size_t) nbytes);")
    p.write_text(t, encoding="latin-1")
    print("malloc.c stdlib after undef", p)
PY

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
# Remove broken Tcl-8.0-incompatible patch from an earlier attempt.
t = t.replace(
    'if {[info exists env(MMI_TOOLS)] && $env(MMI_TOOLS) ne ""} {\n'
    '  set SUE_DIR [file join $env(MMI_TOOLS) sue]\n'
    '}\n',
    "",
)
old_sue_dir = """set SUE_DIR [file nativename [file dirname [file dirname $argv0]]]

if {$SUE_DIR == "."} {
  set SUE_DIR [pwd]
}
"""
new_sue_dir = """if [info exists env(MMI_TOOLS)] {
  set SUE_DIR [file join $env(MMI_TOOLS) sue]
} else {
  set SUE_DIR [file nativename [file dirname [file dirname $argv0]]]
  if {$SUE_DIR == "."} {
    set SUE_DIR [pwd]
  }
}
"""
if old_sue_dir in t:
    t = t.replace(old_sue_dir, new_sue_dir)
elif "file join $env(MMI_TOOLS) sue" not in t:
    t = t.replace(
        'set SUE_DIR [file nativename [file dirname [file dirname $argv0]]]',
        new_sue_dir.strip() + "\n\n# (SUE_DIR set above)",
        1,
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

# MAX: font path must be readable by the X server (not only the client).  Never
# abort on X_SetFontPath failure (BadValue when the path is sandbox-only).
python3 - << 'PY'
from pathlib import Path

p = Path("src/max4.3.16/m/graphics/graphics1.c")
t = p.read_text(encoding="latin-1")

if 'getenv("MMI_MAX_FONTS_DIR")' in t and "Max fonts not on X server font path" in t:
    print("graphics1.c: grAugmentFontPath already patched")
else:
    sig = "static void grAugmentFontPath()"
    start = t.find(sig)
    if start < 0:
        raise SystemExit("graphics1.c: grAugmentFontPath anchor missing")

    brace = t.find("{", start)
    if brace < 0:
        raise SystemExit("graphics1.c: grAugmentFontPath body missing")
    depth = 0
    end = None
    for i in range(brace, len(t)):
        c = t[i]
        if c == "{":
            depth += 1
        elif c == "}":
            depth -= 1
            if depth == 0:
                end = i + 1
                break
    if end is None:
        raise SystemExit("graphics1.c: grAugmentFontPath end not found")

    new_fn = """static void grAugmentFontPath()
{
  char fontDirBuf[BUFSIZ];
  char **dirs;
  int nDirs, i;
  char *fontDir = NULL;
  char *envDir;
  FILE *fp;
  char *opened;

  /* The X server must read font dirs from its own filesystem.  launch.sh
   * registers MMI_MAX_FONTS_DIR via xset; do not call XSetFontPath here.
   */
  envDir = getenv("MMI_MAX_FONTS_DIR");
  if (envDir && envDir[0]) {
    strncpy(fontDirBuf, envDir, sizeof fontDirBuf - 1);
    fontDirBuf[sizeof fontDirBuf - 1] = '\\0';
    fontDir = fontDirBuf;
  } else {
    fp = PaOpen("fonts/fonts.dir", "r", NULL, MnPathSysLib, &opened);
    if (!fp) {
      fp = PaOpen("fonts", "r", NULL, MnPathSysLib, &opened);
    }
    if (!fp) {
      fprintf(stderr, "WARNING:  Could not find Max fonts directory!\\n");
      return;
    }
    fclose(fp);
    strncpy(fontDirBuf, opened, sizeof fontDirBuf - 1);
    fontDirBuf[sizeof fontDirBuf - 1] = '\\0';
    if (strstr(fontDirBuf, "fonts.dir")) {
      char *slash = strrchr(fontDirBuf, '/');
      if (slash) *slash = '\\0';
    }
    fontDir = fontDirBuf;
  }

  dirs = XGetFontPath(grXdpy, &nDirs);
  if (dirs) {
    for (i = 0; i < nDirs; i++) {
      if (dirs[i] && strcmp(fontDir, dirs[i]) == 0) {
        XFreeFontPath(dirs);
        return;
      }
    }
    XFreeFontPath(dirs);
  }

  fprintf(stderr,
          "WARNING:  Max fonts not on X server font path (%s).\\n"
          "          Set MMI_MAX_FONTS_DIR and run: xset +fp <dir>\\n",
          fontDir);
}"""
    t = t[:start] + new_fn + t[end:]
    p.write_text(t, encoding="latin-1")
    print("graphics1.c: grAugmentFontPath (xset only, no XSetFontPath)")

t = p.read_text(encoding="latin-1")
if "#include <unistd.h>" not in t and "access(fontDir" in t:
    t = t.replace("#include <stdio.h>", "#include <stdio.h>\n#include <unistd.h>", 1)
    p.write_text(t, encoding="latin-1")
    print("graphics1.c: include unistd.h for access()")

t = p.read_text(encoding="latin-1")
old = """    for(i=GrMaxFontSize; i>=0; i--)
    {
      XFontStruct *xfs = grXFonts[i];
      int wi = xfs->max_bounds.rbearing - xfs->min_bounds.lbearing;
      int hi = xfs->max_bounds.ascent + xfs->max_bounds.descent;"""
new = """    for(i=GrMaxFontSize; i>=0; i--)
    {
      XFontStruct *xfs = grXFonts[i];
      int wi, hi;

      if (!xfs) continue;
      wi = xfs->max_bounds.rbearing - xfs->min_bounds.lbearing;
      hi = xfs->max_bounds.ascent + xfs->max_bounds.descent;"""
if old in t:
    p.write_text(t.replace(old, new), encoding="latin-1")
    print("graphics1.c: skip null fonts in grInitText")
elif "if (!xfs) continue" in t:
    print("graphics1.c: grInitText null guard already patched")
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

def ensure_stdint(text: str) -> str:
    if "#include <stdint.h>" in text:
        return text
    m = re.search(r"(^/\*.*?\*/\s*\n)", text, re.S)
    if m:
        return text[: m.end()] + "#include <stdint.h>\n\n" + text[m.end() :]
    return "#include <stdint.h>\n\n" + text

def patch_database_h(path: Path) -> None:
    t = path.read_text(encoding="latin-1")
    orig = t
    t = ensure_stdint(t)
    t = re.sub(
        r"#define\s+DBgetTileType\(tp\)\s+\(\(\(TileType\)\s+\(tp\)->ti_body\)\s+&\s+0xff\)\s*",
        "#define\tDBgetTileType(tp)       (((intptr_t) (tp)->ti_body) & 0xff)  ",
        t,
    )
    t = re.sub(
        r"\(ClientData\)\s+\(\(\(TileType\)\s+\(tp\)->ti_body\)\s+&\s+~0xff\s+\|\s+\(\(TileType\)\s+\(b\)\)\)",
        "(ClientData) ((((intptr_t) (tp)->ti_body) & ~0xff) | ((intptr_t) (b)))",
        t,
    )
    t = re.sub(
        r"#define\s+DBisSetTileFlag\(tp,f\)\s+\(\(\(int\)\s+\(tp\)->ti_body\)\s+&\s+\(f\)\)\s*",
        "#define DBisSetTileFlag(tp,f)      (((intptr_t) (tp)->ti_body) & (f))  ",
        t,
    )
    t = re.sub(
        r"#define\s+DBsetTileFlag\(tp,f\)\s+\(\(\(int\)\s+\(tp\)->ti_body\)\s+\|=\s+\(f\)\)",
        "#define DBsetTileFlag(tp,f)\t((tp)->ti_body = (ClientData)(((intptr_t)(tp)->ti_body) | (intptr_t)(f)))",
        t,
    )
    t = re.sub(
        r"#define\s+DBresetTileFlag\(tp,f\)\s+\(\(\(int\)\s+\(tp\)->ti_body\)\s+&=\s+~\(f\)\)",
        "#define DBresetTileFlag(tp,f)   ((tp)->ti_body = (ClientData)(((intptr_t)(tp)->ti_body) & ~(intptr_t)(f)))",
        t,
    )
    if "(((int) (tp)->ti_body)" in t:
        raise SystemExit(f"database.h: failed LP64 tile macros in {path}")
    if t != orig:
        path.write_text(t, encoding="latin-1")
        print("macros", path)

for p in Path("src").rglob("database.h"):
    patch_database_h(p)

for p in [
    Path("src/max4.3.16/maxaux/ext/include/rtrDcmpose.h"),
    Path("src/max4.3.16/maxaux/ext/include/plowInt.h"),
]:
    if not p.is_file():
        continue
    t = p.read_text(encoding="latin-1")
    t2 = t.replace("((int) (t)->ti_client)", "((intptr_t) (t)->ti_client)")
    t2 = t2.replace("((int) (tp)->ti_client)", "((intptr_t) (tp)->ti_client)")
    if "intptr_t" in t2 and "#include <stdint.h>" not in t2:
        t2 = ensure_stdint(t2)
    if t2 != t:
        p.write_text(t2, encoding="latin-1")
        print("ti_client macros", p)

gds = Path("src/max4.3.16/m/gds/gdsWrite.c")
if gds.is_file():
    t = gds.read_text(encoding="latin-1")
    t2 = t.replace(
        "def->cd_client = (ClientData) (- (int) def->cd_client);",
        "def->cd_client = (ClientData) (- (intptr_t) def->cd_client);",
    )
    if t2 != t:
        gds.write_text(t2, encoding="latin-1")
        print("gdsWrite cd_client intptr")
PY

# GCC 14 removed <varargs.h> (va_dcl / va_start(ap)). Convert maxaux
# K&R varargs to stdarg.h before compiling ext2spice / irsim / etc.
python3 - << 'PY'
from pathlib import Path

def subst(path, old, new, label):
    p = Path(path)
    if not p.is_file():
        return
    t = p.read_text(encoding="latin-1")
    if old not in t:
        if "va_dcl" not in t:
            print("skip", label, path)
            return
        raise SystemExit(f"{label}: pattern not found in {path}")
    p.write_text(t.replace(old, new, 1), encoding="latin-1")
    print(label, path)

for maxv in ("max4.3.16", "max4.2.11"):
    root = Path(f"src/{maxv}/maxaux")
    if not root.is_dir():
        continue
    for p in root.rglob("*.c"):
        if "RCS" in p.parts:
            continue
        t = p.read_text(encoding="latin-1")
        t2 = t.replace("#include <varargs.h>", "#include <stdarg.h>")
        if t2 != t:
            p.write_text(t2, encoding="latin-1")
            print("stdarg include", p)

    subst(
        f"src/{maxv}/maxaux/ext/utils/LIBtextio.c",
        """    /*VARARGS*/
TxError(fmt, va_alist)
    char *fmt;
    va_dcl
{
    va_list ap;
 
    (void) fflush(stdout);
    (void) fflush(stderr);
    va_start(ap);
""",
        """    /*VARARGS*/
void
TxError(char *fmt, ...)
{
    va_list ap;
 
    (void) fflush(stdout);
    (void) fflush(stderr);
    va_start(ap, fmt);
""",
        "TxError stdarg",
    )
    subst(
        f"src/{maxv}/maxaux/ext/utils/LIBtextio.c",
        """    /*VARARGS*/
TxPrintf(fmt, va_alist)
    char *fmt;
    va_dcl
{
    va_list ap;
 
    (void) fflush(stderr);
    (void) fflush(stdout);
    va_start(ap);
""",
        """    /*VARARGS*/
void
TxPrintf(char *fmt, ...)
{
    va_list ap;
 
    (void) fflush(stderr);
    (void) fflush(stdout);
    va_start(ap, fmt);
""",
        "TxPrintf stdarg",
    )
    subst(
        f"src/{maxv}/maxaux/ext/extflat/EFread.c",
        """    /*VARARGS1*/
efReadError(fmt, va_alist)
    char *fmt;
    va_dcl
{
    va_list args;

    (void) printf("%s, line %d: ", efReadFileName, efReadLineNum);
    va_start(args);
""",
        """    /*VARARGS1*/
void
efReadError(char *fmt, ...)
{
    va_list args;

    (void) printf("%s, line %d: ", efReadFileName, efReadLineNum);
    va_start(args, fmt);
""",
        "efReadError stdarg",
    )
    subst(
        f"src/{maxv}/maxaux/irsim/src/ana11/textwind.c",
        """public void PRINTF( va_alist )
  va_dcl
  {
    va_list  args;
    char     *format;
    char     *s;
    int      len;

    va_start( args );
    format = va_arg( args, char * );
""",
        """public void PRINTF( char *format, ... )
  {
    va_list  args;
    char     *s;
    int      len;

    va_start( args, format );
""",
        "PRINTF stdarg",
    )
    subst(
        f"src/{maxv}/maxaux/irsim/src/irsim/prints.c",
        """public void lprintf( va_alist )
  va_dcl
  {
    va_list  args;
    char     *fmt;
    FILE     *fp;
    char     buff[ 300 ];

    va_start( args );
    fp = va_arg( args, FILE * );
    fmt = va_arg( args, char * );
""",
        """public void lprintf( FILE *fp, char *fmt, ... )
  {
    va_list  args;
    char     buff[ 300 ];

    va_start( args, fmt );
""",
        "lprintf stdarg",
    )
    subst(
        f"src/{maxv}/maxaux/irsim/src/irsim/prints.c",
        """public void error( va_alist )
  va_dcl
  {
    va_list  args;
    char     *filename;
    int      lineno;
    char     *fmt;
    char     buf1[ 100 ], buf2[ 200 ];

    va_start( args );
    filename = va_arg( args, char * );
    lineno = va_arg( args, int );
    fmt = va_arg( args, char * );
""",
        """public void error( char *filename, int lineno, char *fmt, ... )
  {
    va_list  args;
    char     buf1[ 100 ], buf2[ 200 ];

    va_start( args, fmt );
""",
        "error stdarg",
    )
    subst(
        f"src/{maxv}/maxaux/irsim/src/irsim/netupdate.c",
        """private void nu_error( va_alist )
  va_dcl
  {
    va_list  args;
    char     *fmt, *errstr = "| error";
    FILE     *fp;

    if( nu_logf != NULL )	fp = nu_logf;
    else if( logfile != NULL )	fp = logfile;
    else			fp = stderr, errstr ++;

    va_start( args );
    fmt = va_arg( args, char * );
""",
        """private void nu_error( char *fmt, ... )
  {
    va_list  args;
    char     *errstr = "| error";
    FILE     *fp;

    if( nu_logf != NULL )	fp = nu_logf;
    else if( logfile != NULL )	fp = logfile;
    else			fp = stderr, errstr ++;

    va_start( args, fmt );
""",
        "nu_error stdarg",
    )

left = []
for p in Path("src").glob("max*/maxaux/**/*.c"):
    if "RCS" in p.parts:
        continue
    t = p.read_text(encoding="latin-1", errors="replace")
    if "va_dcl" in t or "#include <varargs.h>" in t:
        left.append(str(p).replace("\\", "/"))
if left:
    raise SystemExit("still using varargs.h / va_dcl:\n  " + "\n  ".join(left))
print("maxaux: K&R varargs converted to stdarg.h")
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

# Reproducible DATE in packaging rules (not used for the CAD binaries).
sed -i \
  -e 's/^DATE[[:space:]]*=.*/DATE = epoch/' \
  -e 's/^DATETAG[[:space:]]*=.*/DATETAG = 0101/' \
  src/max4.3.16/make/Makefile.main \
  src/max4.2.11/make/Makefile.main 2>/dev/null || true

# maxaux: Windows-safe dir name + optional depend include + X11 libs for anXhelper.
find src/max4.3.16/maxaux src/max4.2.11/maxaux -type f -name Makefile 2>/dev/null \
  | while IFS= read -r mk; do
      sed -i \
        -e 's|/o/${CONFIG}/aux/|/o/${CONFIG}/maxaux/|g' \
        -e 's|/o/$(CONFIG)/aux/|/o/$(CONFIG)/maxaux/|g' \
        -e 's|^include \$(OBJ_DIR)/depend|-include $(OBJ_DIR)/depend|' \
        -e 's/COMPILE_FLAGS=	$(CONFIG_CFLAGS)/COMPILE_FLAGS=	$(CFLAGS) $(CONFIG_CFLAGS)/' \
        "$mk"
    done
if [ -f src/max4.3.16/maxaux/irsim/src/anXhelper/Makefile ]; then
  if ! grep -q '^LIBS' src/max4.3.16/maxaux/irsim/src/anXhelper/Makefile; then
    sed -i '/^MODULE :=/i LIBS = ${CONFIG_LIBS}' \
      src/max4.3.16/maxaux/irsim/src/anXhelper/Makefile
  fi
fi

echo "x86_64 source patches applied under $ROOT"
