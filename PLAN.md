# Plan: exact Magic to MAX conversion, `importer` app, SUE design libraries, `sue -lib`

Written 2026-11-12, before any product code change. This revision adds the
mechanisms, numbers, and file-level constraints from reading the MAX and SUE
sources and from probing the PDK trees. Adding and editing this file is still
the only change (branch `main` at `ed23d8b`).

Path shorthand: `max/` = `vendor/mmi/src/max4.3.16/`, `sue/` = `vendor/mmi/src/sue4.4/`.
Statements are marked **verified** (read in the source, or measured with a command)
or **to check** (not confirmed yet). Nothing marked "to check" is treated as fact.

## 1. What you asked for and what will exist at the end

| # | Request | Result |
|---|---------|--------|
| 1 | Handle `.5` values when a `.mag` rectangle is turned into a `.max` record | No coordinate is ever rounded silently. Paint is converted corner to corner, in integer arithmetic. The database unit of the three PDK technologies is halved to 0.5 nm, so a midpoint of an odd-sized rectangle is an integer too. A check before the conversion and a check of the written file prove exactness. |
| 2 | A finished conversion, after Save and Open, shows a lot of DRC errors (sample `user_proj_example.mag`) | The import currently marks every GDS cell DRC-clean, so the errors stay hidden until the `.max` is opened again. That hiding is removed. The rules and the geometry are then fixed until a reopened cell has no DRC error that Magic's own DRC does not also report at the same place. |
| 3 | A GUI application named `importer` that downloads the PDKs and the design libraries that work with SUE and MAX | New standalone app. `./run.sh importer`. |
| 4 | Remove the PDK downloader from MAX | The menu entries, the dialog, and the download engine leave MAX. Repair of an already installed technology stays. |
| 5 | A SUE design library for each PDK that MAX supports | Libraries `sky130A`, `gf180mcu`, `sg13g2`, generated from the PDK the user installed. |
| 6 | `-lib` for SUE, the way `-tech` works for MAX | `sue -lib sky130A` next to `max -tech sky130A`. A directory is still accepted. |

## 2. Findings

### 2.1 Two formats, and where a `.5` can appear (verified)

A Magic `.mag` stores paint as two corners in integer file units:

```
magic
tech sky130A          (or "tech $PDK", which Magic expands from the environment)
magscale 1 2
<< viali >>
rect 557273 341853 557307 341887
```

`magscale n d` means one file unit is `(n/d)` of a Magic lambda. For the open_pdks
sky130 deck the lambda is 10 nm (`scalefactor 10 nanometers`, the default also
hard-coded in `pdk/mag_import.tcl` `mag_scalefactor_nm`). With `magscale 1 2`
one file unit is 5 nm. gf180mcu's lambda is 50 nm, IHP sg13g2's is 10 nm
(same defaults in `mag_scalefactor_nm`; the installed `.tech` overrides them).

A `.max` file is also integers, but in database units, and the header says how
big one database unit is (`max/m/database/DBwrite.c` 612-625):

```
max 4
tech sky130A
resolution 0.001
```

`resolution` is the database unit in microns. The technologies this repo
generates write `units .001 .001 .001 .001` (`pdk/source_to_tech27.tcl` 650),
so today 1 database unit = 1 nm. On open, every coordinate is multiplied by
`file resolution / database unit` and rounded (`DBread.c` 1081-1100, 1253-1265).
A coordinate that is not a whole number of database units is not stored: the
rectangles reader is `sscanf` with `%d` (`DBread.c` 526-528). The same rounding
applies to labels, polygons, wire paths, and instance boxes.

Paint itself is stored as two corners, the same shape as Magic, in the `RECTS`
section (`DBwrite.c` 131-138):

```
layer met1
0 6900 1480 7900
```

So a Magic rectangle whose corners land on whole database units converts with
no `.5` and no rounding. The `.5` appears only when something is stored by its
middle, or when a later step recenters a shape.

| Object | How MAX stores it | Where a half unit comes from |
|--------|-------------------|-------------------------------|
| Paint in `RECTS` | two corners, integers | nowhere, if each corner is a whole number of database units |
| A label (`lab type x1 y1 x2 y2 pos kind text`, `DBread.c` 321) | two corners; the shipped cells use a zero-size box (`370 0 370 0`) | the converter picks the point. Today the Tcl dump uses the midpoint (`mag_import.tcl` 1442-1445) |
| A generated via or FET (`#via!-type!...`, `#fet!-width!...`) | an instance whose box is symmetric about 0, placed at the center (`vendor/mmi/src/utils/tech/mmi18/stdcell/max/MMI_INVA.max` 70-93) | the center of a rectangle with an odd width or height |
| A wire path | centerline points plus a width (`DBwrite.c` 385-390) | an odd width puts both edges on a half unit |
| Contact cuts written by `squares ... align` | centered in the via paint when MAX writes GDS (`source_to_tech27.tcl` 713-716, `max/m/cif/cifTech.c` 960-1017) | an odd gap around the cut |

Worked example, from `pdk/samples/caravel_analog_por/example_por.mag` line 6,
`magscale 1 2`, lambda 10 nm, so 1 file unit = 5 nm:

```
rect 70 7344 6652 7795
```

| Quantity | File units | nm |
|----------|------------|----|
| x corners | 70 and 6652 | 350 and 33260 |
| y corners | 7344 and 7795 | 36720 and 38975 |
| width, height | 6582, 451 | 32910, 2255 |
| midpoint x | 3361 exactly | 16805 exactly |
| midpoint y | 7569.5 | 37847.5 |

At a 1 nm database unit the y midpoint cannot be stored. At 0.5 nm it is
75695 database units. Both corners are whole nanometres, so they are exact at
either unit.

The contacts at the start of `user_proj_example.mag` are 34 by 34 file units,
which is 170 nm by 170 nm (the sky130 `licon` size). 34 is even, so their
midpoint is an integer file unit and an integer nanometre. The half-unit
problem is the odd sizes (451 above, and any odd file-unit span), not the
170 nm contacts.

Conclusion, used everywhere below. Converting corners needs the source grid to
be a whole number of database units. Placing anything by its center needs half
the source grid to be a whole number of database units. For these PDKs the
source grid is 5 nm (sky130, IHP with `magscale 1 2`) or 50 nm (gf180). Half
of that is 2.5 nm or 25 nm. 1 nm divides the corners and does not divide
2.5 nm. 0.5 nm divides the corners, the GDS 1 nm lattice, and both midpoints.

Anything that is an integer number of nanometres is an even count of 0.5 nm
units. That matters for GDS path import: `gdsReadPaint.c` 950 treats an odd
width as non-Manhattan and builds a wire path instead of rectangles. A 170 nm
cut is 340 units at 0.5 nm, so it stays a rectangle.

### 2.2 What the converter does today (verified)

`pdk/mag_import.tcl` (revision 12) is the File / Local command
"Import Magic Design Folder...". The preferred path:

1. `pdk/mag2gds.sh` starts nixpkgs `magic-vlsi` with the PDK `.magicrc`.
2. The script it writes turns DRC off, forces the PDK tech, sets
   `gds rescale false`, and for a normal cell sets
   `cif *hier write disable` and `cif *array write disable`
   (`mag2gds.sh` 104-112). The full-chip Caravel path sets
   `MAG2GDS_KEEP_HIER=1` and does the opposite.
3. `load <top> -force -dereference`, then `expand` (unless hierarchical),
   then `gds write`.
4. MAX runs `gds_read` on that GDS and `cell_save_tree 0`
   (`mag_import.tcl` 2337-2368 and `mag_max_after_gds_script`).

`mag2gds.sh` also deletes every `use font_...` line before Magic starts
(lines 71-78). Those are the `sky130_ml_xx_hd` logo fonts; a large magscale
on them segfaults Magic before the GDS is written. The chip geometry does
not use them. The same deletion is in `pdk/open_mag.sh`.

There is a second path, the "Tcl paint dump". The dialog selects it by itself
when no PDK `.magicrc` is installed (`mag_import.tcl` 1520-1523). It parses
`.mag` rectangles and writes its own GDS. One Magic paint name becomes several
GDS layers (`ndiffc` becomes diffusion + contact + metal + implant,
`mag_import.tcl` 116-121), and the implant is a copy of the rectangle grown
by a fixed amount, not the foundry boolean. Coordinates go through
`round(double(x) * scale)` (`mag_import.tcl` 1045-1048). This path cannot be
DRC-clean against the foundry deck. It stays available, labeled as a preview,
and it gets the same integer checks as the Magic path.

### 2.3 Why Save, then Open, is where the DRC errors show up (verified)

This matches the report: the conversion finishes, the layout is saved, and
the errors appear when that `.max` is opened.

MAX's own Tcl sets this before any user code runs (`max/maxtcl/misc.tcl` 75-76):

```
# already set to be global.  Make default true.
set GDS_READ_NO_DRC 1
```

The GDS import dialog describes that flag as (`misc.tcl` 508-511):

> imported cells are considered DRC clean and not checked for errors.
> Subsequent changes to them will be checked for DRC errors.

The C side honors it. `gdsReadNoDRC` defaults to false (`gdsRead.c` 212) and
the Tcl assignment overrides it. With the flag set, `gdsReadCell.c` 408-410
and 695-702 stamp the cell and its children with a fixed DRC version, and
`gdsReadCell.c` 786-797 paints with `DBCF_NODRC`. At the end of the file read,
`gdsRead.c` 684-717 runs `DRCClean` on every cell the GDS created.

Opening a `.max` does not take that path. `DBread.c` `dbReadChangeNotify`
(714-737) calls `DBChangedArea` with `DBCF_DEFREAD` and no `DBCF_NODRC`, so
DRC runs on the geometry that was saved.

So a conversion can look clean and still be full of errors. The errors are in
the saved geometry and in the rule deck. They are revealed by the reopen,
they are not created by the reopen, unless the save/load scale is not 1
(section 2.1). Step A0 measures which of those two it is before any rule is
changed.

`mag_import.tcl` already forces `GDS_READ_PARTIAL` to 0 around `gds_read`
(2344-2356) and restores it. It never touches `GDS_READ_NO_DRC`.

A second, smaller trap in the same dialog (`misc.tcl` 513-519): if the user
opens GDS Import Setup while `GDS_READ_SNAP_TO` is 0, the dialog stores the
mask grid (5 nm for these techs) into that variable. `gds_read` itself does
not do this. The C default of `gdsReadSnapTo` is 0, which means no extra snap
(`gdsRead.c` 202-203, 561-580). The converter will set the snap to 0 for the
duration of the import and restore it, so a previous visit to that dialog
cannot move a 1 nm edge onto the 5 nm grid.

### 2.4 The rule deck the errors are checked against (verified)

`pdk/source_to_tech27.tcl` (generator revision 6) emits, for every layer that
has a number, a minimum width and a minimum spacing, `touching_ok`
(lines 897-948). It also emits `no_overlap` between the FET types and
`exact_overlap` across every via type. It does not emit the enclosure,
extension, or area rules that the shipped `mmi18.tech27` has.

The numbers come from the hand-written tables in `pdk/pdk_import.tcl`
(`pdk_layers_sky130A` 85-129, `pdk_rules_sky130A` 131-177, and the gf180 and
sg13g2 pairs). One value is already stricter than the device it is named for:

```
{polyres 66:13 - - 0.69 0.69 ...}     # pdk_import.tcl line 100
```

sky130 has both a 0.69 um and a 0.35 um xhigh poly resistor. The 0.35 um
device is a normal cell in the Caravel layouts (`res_xhigh_po_0p35` is listed
in the resistor `.mag` properties). A 0.69 um minimum width flags every one
of those. The Magic layer `res0p69` in
`pdk/samples/.../sky130_fd_pr__res_xhigh_po_0p69_S5N9F3.mag` is the resistor
marker around a 0.69 um body; the same marker around a 0.35 um body is still
layer 66 datatype 13, so it lands on `polyres`.

Implant rules are checked on a layer MAX rebuilds, not on the implant Magic
wrote. `pdk_rules_sky130A` says:

```
derive nsdm from ndiff,ntap grow 0.125 or nsdm
derive psdm from pdiff,ptap grow 0.125 or psdm
derive ndiff from diff and-not psdm
derive pdiff from diff and psdm
```

`cifwidth` / `cifspacing` on `GDS_nsdm` then re-grow that implant during DRC
(`source_to_tech27.tcl` 911-924). A fringe that the boolean leaves behind
(diffusion not covered by the implant, or an implant sliver) is checked
against the diffusion minimum width. Whether the foundry GDS actually
produces that fringe is measured in A0, not assumed.

`exact_overlap` is defined as a ban on two cells overlapping in that via type
unless the overlap is the same geometry (`DRCtech.c` 80-85). It fires on
hierarchical overlap. A flat cell does not exercise it. `user_proj_example.mag`
has no `use` line in its first 300 KB (9,502 `rect` lines, 0 `use` lines, file
size 88,603,511 bytes). The rest of the 88 MB was not scanned, so the file is
not claimed to be flat.

Scale of a false error from rounding. A minimum-width check fails when a
legal shape shrinks by one database unit. A 170 nm contact read with a scale
that is not an integer becomes 169 nm or 171 nm. 169 fails a 0.17 um width
rule; 171 passes it. Spacing between two shapes can shrink the same way.
This is why "exact, or stop" is the rule, and why a post-conversion XOR
against Magic's GDS is the acceptance test.

### 2.5 Database-unit change, what has to stay true (verified)

`units DBRes CPRes CIFRes GDSRes` is parsed in `max/m/cif/cifTech.c` 501-556.
`CIFSetStyle` copies those four numbers to `CIFDBRes`, `CIFPlaneRes`,
`CIFRes`, `CIFGDSRes` (`cifMain.c` 175-207). DRC microns are divided by
`cs_DBRes` (`DRCtech.c` `drcDimension`, 129-187). CIF grow, shrink, and
`squares` distances are divided by `cs_CIFPlaneRes` (`cifTech.c`
`cifDimension`, 91-147). Both round to the nearest integer and print a tech
error when the remainder is larger than `UNIT_TOLERANCE` (`1e-5` microns,
`max/m/main/magic.h` 166).

Every width, spacing, and grow in the three tables is a multiple of 0.001 um,
hence of 0.0005 um. Moving the database unit from 0.001 to 0.0005 does not
make any current rule off-grid. The tech file will fail to load if a future
rule is not a multiple of the database unit; that failure is the behavior
we want.

GDS output scale is `CIFDBRes / CIFGDSRes` (`gdsWrite.c` 1164). With
`units .0005 .0005 .0005 .0005` the ratio stays 1, so a database rectangle
is written to GDS with the same integer coordinates. With
`units .0005 .0005 .0005 .001` the ratio is 0.5 and every odd database
coordinate would land between GDS units. The four numbers stay equal.

Existing `.max` files with `resolution 0.001` reload on a 0.0005 tech by
multiplying every coordinate by 2 (`DBread.c` 1100). That is exact.

Coordinate headroom. `user_proj_example.mag` coordinates near 558,411 file
units are 2.792 mm. At 0.5 nm that is about 5.6 million database units.
`UnitsS2I` clips only near `0.45 * INFINITY` (`mnUnits.c` 232-265). The die
is far inside that.

Code that assumes the database unit is 0.001 is listed in section 3.4 and is
read before the default is switched. The image importer
(`pdk/image_layout.tcl`) paints in database units; it is on that list.

### 2.6 Cell names in GDS (verified, corrects an earlier guess)

The MAX GDS reader keeps 512 characters of a cell name.
`GDS_STRING_LENGTH` is 512 and `CALMANAMELENGTH` is defined as that
(`max/m/gds/gdsInt.h` 177-181). The historical 32 is commented out on the
line above. A 32-character limit does still exist in
`max/maxaux/ext/include/calmaInt.h` 127; that header belongs to the extract
tools, and `gds_read` does not use it. sky130 cell names longer than 32
characters are not merged by this converter. The 32-character limit is not
a candidate for these DRC errors.

### 2.7 PDK downloader inside MAX, and what has to survive it (verified)

`pdk/maxrc` sources three files into every MAX: `pdk_import.tcl`,
`mag_import.tcl`, `image_layout.tcl`.

`pdk_import.tcl` (revision 15) is the downloader and the technology builder
together. The menu installer is `_pdk_import_install_menus` (2072-2086):
"Import PDK..." on the Local menu and on the File menu. The download is
`pdk_import_fetch`, which runs `pdk/fetch_pdk.sh`. The convert is
`pdk_import_convert` plus `pdk/compile_tech.sh` plus
`pdk/source_to_tech27.tcl`. On startup, `after idle pdk_autofix_tech27`
rebuilds a technology whose `MMI_PDK_GEN` is older than
`PDK_GEN_REQUIRED` (6). `nix/launch.sh` `mmi_repair_tech27` (226-276) does
the same rebuild from the shell before MAX starts.

`mag_import.tcl` calls these names from `pdk_import.tcl`, and already
continues when they are absent: `pdk_root`, `pdk_which`, `pdk_tech27_ok`,
`pdk_find_tech27`, `pdk_import_copy_text`. Those five move to a small file
that MAX still sources. The dialog, the download poll, the layer tables, and
the convert engine move to the importer. The layer tables are data, not a
MAX feature; the importer and `source_to_tech27.tcl` are their only readers.

`fetch_pdk.sh` pins three ciel tags (lines 24-26) and a fixed asset list:

| Family | Directory under `PDK_ROOT` | Tag suffix | Assets |
|--------|----------------------------|------------|--------|
| sky130A | `sky130A` | `e8daeda73ca8f5814dbc0b11d1d05802251a3750` | `common`, `sky130_fd_pr`, `sky130_fd_io`, `sky130_fd_sc_hd`, `sky130_fd_sc_hvl` |
| gf180mcu | `gf180mcuD` | `0fe599b2afb6708d281543108caf8310912f54af` | `common`, `gf180mcu_fd_pr`, `gf180mcu_fd_io`, `gf180mcu_fd_sc_mcu7t5v0` |
| sg13g2 | `ihp-sg13g2` | `ddb601a4a4473163e1ed6df416b885df18b4ac03` | `common`, `sg13g2_pr`, `sg13g2_io`, `sg13g2_stdcell`, `sg13g2_sram` |

Extra archives can be added with `MMI_PDK_LIBS` (the comment names
`sky130_sram_macros`). A finished tree is `libs.tech/magic/*.magicrc` plus
at least one directory in `libs.ref`. An unfinished tree is deleted on the
next run; the `.fetch-<family>/dl/*.tar.zst` cache is kept so the download
resumes. `PDK_ROOT/max` is never deleted.

MAX finds a technology by name through `mnTechLoad` (`max/m/main/mnTech.c`
780-799): `tech/<tech>/<tech>-<var>.tech27` if `-tech` carried a variation,
otherwise `tech/<tech>/<tech>.tech27`, searched on `MnPathSysLib`. The
search list is built in `mnMain.c` `mnInitLibPaths` and is exposed as the
Tcl variable `MMI_PATH_SYSLIB`. The importer writes the technology into
`$PDK_ROOT/max/tech/<tech>/`, which is already on that path
(`pdk_max_tech_dirs`, `pdk_import.tcl` 732-744). `-tech` itself is parsed
in `max/maxtcl/max0.tcl` `_max0_parse_tech` (180-243): command line, then
`MAX_TECHNOLOGY`, then the last file, then `MAX_DEFAULT_TECH`, then
`mmi25`. The variation syntax is `<tech>-<var>`, which selects
`<tech>-<var>.tech27`. That is the fallback if 0.5 nm cannot be the
default: ship `sky130A-half.tech27` and pass `-tech sky130A-half`.

`compile_tech.sh` refuses a technology that would crash MAX. The importer
keeps every one of these checks:

- no `labels *` (MAX wants `labels space`)
- no `width` or `spacing` whose distance is `-`
- no `calma` line with a `*` datatype (sky130 reuses layer numbers)
- `cifstyle` occurs inside `drc`, not as its own section
- `${tech}.palette` and `${tech}.tcl` exist and are non-empty
- `set MMI_PDK_GEN <n>` is present and matches `GEN_REV`
- no `set DRC_DATA(...)` whose value is an unbraced list of two words
- at most 10 `pal_layer ... solid` lines (an 11th makes MAX abort in
  `pal_build`; `source_to_tech27.tcl` 1058-1081 enforces this)

`pdk_tech27_ok` (`pdk_import.tcl` 746-831) repeats those checks inside MAX
and treats a low `MMI_PDK_GEN` as "not ok", which is what triggers the
rebuild. Bumping `GEN_REV` is how a rule fix reaches a technology the user
already installed.

### 2.8 SUE, and why `-lib` can be a name without recompiling SUE (verified)

SUE's Tcl is compiled into `sue.exe`. `sue/build/mkcsue` concatenates the
Tcl, `prepare` turns it into a C string, and `sueAppInit.c` evals that
string. Changing `sueInit.tcl` changes the binary, which means a
`mmi-vendor` rebuild. The plan does not do that for `-lib`.

The wrapper the user actually runs is `vendor/mmi/sue/sue` (csh). It
recognizes `-help`, `-private`, and `-log`, and forwards every other
argument to `sue.exe`. Its help text documents `-LIB <dir>` and
`-AUTOLIB <dir>` (lines 79-80). It does not interpret them.

Inside `sue.exe` the order is fixed:

1. `sue/build/sueInit.tcl` 79-90 parses the command line with
   `call_keyword -nocase -append`. The option table includes `{LIB ""}` and
   `{AUTOLIB ""}`. `-nocase` is why `-lib` already sets the same variable
   as `-LIB`. The value is stored as given. A second `-lib` appends.
2. `sue/build/sueInitA.tcl` 36-107 sources, in order, the system `.suerc`
   (`$SUE_DIR/.suerc`), the site file (`$MMI_LOCAL/sue/.suerc` or
   `sue.rc`), the user file, the private file, and `./.suerc`.
   `LIB` already holds the command-line value while the site file runs,
   and the site file is allowed to replace it.
3. `sue/build/sueInitB.tcl` 57-89 calls `add_auto_path` on each `LIB` entry
   and `auto_load_directory` on each `AUTOLIB` entry. Only then is the
   value consumed.

`add_auto_path` (`sue/src/cell.tcl` 2042-2130) treats its argument as a
directory of `.sue` files and builds `tclIndex` for it. Given the name
`sky130A`, the directory test fails and the name is handed to
`file dirname`, which yields `.`. The current directory would be added to
the search path and the library would not load. The site file exists to
rewrite the name into a directory before step 3.

`nix/launch.sh` 116-126 creates `$CAD/mmi_local/max` before the test
`[ ! -d mmi_local/max ]`, so the copy of `mmi_local.sample` never runs and
there is no site `.suerc` today. The sample's `sue/.suerc` only sets a
spice header path and comments out `lappend AUTOLIB` of the generic
stdcell icons. The launcher will create the site file itself, the same way
it appends `source /mmi-bundle/maxrc` to `.maxrc` (`launch.sh` 187-205).

A library is a directory of `.sue` files plus `tclIndex`. The index format
SUE reads is the block in `vendor/mmi/sue/schematics/mspice/tclIndex`:
one `set auto_index(ICON_<name>)` per proc, and a `mtimes` list. SUE
rebuilds a stale index when the directory is writable (`cell.tcl`
2076-2117), so a generated library can ship the index or let the first
launch write it. The generator writes it, so a read-only library still
loads.

The icon that the generator copies from, `mspice/nmos.sue`:

- `icon_term` pins `d`, `s` (inout) and `g` (input). The bulk is not a pin.
  The spice line ties it to `gnd` (pmos ties it to `vdd`).
- User properties `name`, `M`, `W` default `1`, `L` default `ln_min`,
  `model` default `n`.
- A fixed `spice` property is the netlist line:
  `[unique_name M $name] $d $g $s gnd $model W='$W*1u' L=$L` plus area and
  perimeter parms.
- A fixed `sim` property is the line MAX's LVS compares against:
  `n $g $s $d [sim_size $L] [sim_size $W 1.0e-6]`.
- A fixed `verilog` property. PDK libraries are analog; verilog is left
  empty unless the symbol has one.
- Drawing commands (`icon_line`, `icon_arc`) are in SUE's own grid
  (`GRID_SPACING` is 8 in the system `.suerc`). They are not microns and
  they are not the layout `.5` problem.

`ln_min`, `lp_min`, `arean`, `areap`, `perin`, `perip` are `.param` lines
in the spice header (`mspice/default_spice_header.h` 23-37). A PDK library
ships its own header that includes the PDK's ngspice files and sets those
params to that process. The system header's 0.35 um and 3.0 V stay the
default only when no `-lib` is given.

`SCHEM_DIR(spice)` still loads the generic `mspice` icons in spice mode
(`sueInitB.tcl` 100-103). A PDK icon with the same proc name
(`ICON_nmos`) would be shadowed or would shadow the generic one depending
on `auto_path` order. PDK icons therefore keep the PDK cell name
(`ICON_sky130_fd_pr__nfet_01v8`) and the library is loaded as an
`AUTOLIB`, which fills the icon list. Generic `nmos` / `pmos` stay
available for drawings that are not on a foundry deck.

### 2.9 What is taken from revolution-eda (verified from its source)

The useful part is the shape of the two registry windows, not the PDKs
they download. Revolution EDA's own registry
(`revolutionEDA_pdks/pdks.json`) publishes a Python module `ihp_pdk` for
that program. `revolutionEDA_libraries/libraries.json` publishes
`analogLib` and `ihp_designs`, which are Revolution schematic libraries.
Neither is a MAX technology or a SUE library. The importer does not
download them.

What is copied as behavior:

- A JSON catalogue: name, process, version, license, type, description,
  download URL (`revedaEditor/gui/pdkRegistry.py`, `libraryRegistry.py`).
- One window, an install-location field with Browse, a table whose first
  column is "Installed", a description pane, a progress bar, Download /
  Install, Uninstall, Refresh.
- Installed means the target directory exists and its metadata file
  parses. The remote version is compared with the installed version so
  an update can be offered.
- A zip is extracted with a path-escape check (`safeExtractZip`). Our
  archives are `.tar.zst`, and `fetch_pdk.sh` already unpacks them with
  `tar` into a private stage directory and moves only the variant
  directory into `PDK_ROOT`. That stays the unpack path.
- The active PDK is chosen per run (`REVEDA_PDK_PATH` there,
  `max -tech` here). Libraries are chosen per run (`sue -lib` here).

### 2.10 This workstation, and what it can and cannot prove (verified)

Windows Server 2019, 3 GB RAM, 2 vCPUs, about 32 GB free on `C:`. WSL is
version 1 (kernel `4.4.0-17763-Microsoft`), Ubuntu 20.04, user `os`,
`sudo` asks for a password. `./run.sh` needs user namespaces and bubblewrap,
so the full CAD session cannot be started here. Building `mmi-vendor`
(gcc 14 compiling the whole MAX tree) will not be attempted on 3 GB.

Inside that WSL, Nix 2.28.5 is installed and the store already contains
`magic-vlsi` 8.3.623, Tcl/Tk 8.6.16, and a gcc 14 wrapper.
`~/.ciel` holds three PDK trees (6.6 GB):

| Link | Commit actually on disk |
|------|-------------------------|
| `~/.ciel/sky130A` | `8afc8346a57fe1ab7934ba5a6056ea8b43078e71` |
| `~/.ciel/gf180mcuD` | `54435919abffb937387ec956209f9cf5fd2dfbee` |
| `~/.ciel/ihp-sg13g2` | `c4b8b4e5e7a05f375cca3815d51b3a37721fbf5c` |

These are not the commits `fetch_pdk.sh` pins (section 2.7). They are the
right shape for writing and checking the SUE library generator, and the
wrong bytes for a bit-exact test of the downloader. Each tree has
`libs.ref` (primitives, IO, stdcells) and `libs.tech` with at least
`magic`, `klayout`, `netgen`, `ngspice`, `xschem`. sky130A also has
`sky130_sram_macros` and `sky130_ml_xx_hd`, which the pinned asset list
does not download unless `MMI_PDK_LIBS` is set.

`user_proj_example.mag` was fetched far enough to read the header
(88,603,511 bytes, `tech sky130A`, `magscale 1 2`, first layer `viali`,
34 by 34 file-unit contacts). The whole file is not kept in the repo.

## 3. Part A — conversion

### 3.1 Causes, in the order they will be tested

| ID | What would produce the errors | Status | How it is confirmed | Change if confirmed |
|----|-------------------------------|--------|---------------------|---------------------|
| H1 | Import marks the cell DRC-clean, so the first session hides every violation. Reopen runs DRC. | **verified** as the reason they appear on reopen (section 2.3). It does not by itself invent a violation. | A0 step 2: DRC the in-memory cell before save, with the flag forced off | The converter sets `GDS_READ_NO_DRC` to 0 for the import and restores the previous value. The final dialog prints the error count. |
| H2 | A hand-written rule is stricter than the foundry rule. `polyres` 0.69 um against the 0.35 um resistor is the known case. | **verified** for that one rule. The rest of the table is not compared yet. | A4, one diff against the PDK `drc` section | Lower the number to the deck, or drop the rule when the deck has none. A generated rule is never stricter than the deck. |
| H3 | DRC re-derives implants (`grow 0.125`) and flags the fringe the boolean leaves around diffusion. | to check | A0: count errors whose layer is `nsdm`, `psdm`, `ndiff`, or `pdiff`, and whether the same coordinate fails in Magic | Check DRC on the drawn GDS layers. Stop re-growing an implant that was read from GDS. |
| H4 | The Tcl paint dump ran, because no `.magicrc` was installed, and its grown rectangles are not the foundry masks. | to check for the run that produced the report | `method=` in the convert log | The dialog no longer changes the method on its own. The dump is offered as "preview, not for DRC" and its result is stamped so a later open can say so. |
| H5 | `cif *hier write disable` and `cif *array write disable` drop the geometry Magic builds where subcells touch, so the GDS is already wrong before MAX sees it. | to check | A0 step 1: XOR the two GDS files Magic writes, one with the switches and one without | Default the two switches to the foundry-correct setting. Keep the hierarchical write only for the full-chip view, which is a display choice. |
| H6 | GDS snap or scale rounding moves an edge by 1 nm and a minimum-width shape becomes illegal (section 2.4). | to check | A0: the rounding warning, then a coordinate diff of Magic GDS against the GDS MAX writes back | Integer scale check (A1). Snap forced to 0 during import. Database unit 0.5 nm (A2) so a later midpoint is representable. |
| H7 | A Manhattan polygon MAX cannot split is dropped (`gdsReadPaint.c` 410-441, "Couldn't convert manhattan polygon"). The hole becomes a DRC error next to it. | to check | Count that warning in the import log | Fix the split, or have the converter cut the polygon into rectangles before MAX reads it. |
| H8 | Diffusion is typed per cell. An implant that lives in the parent and diffusion that lives in the child types the diffusion as n-type. | to check, and only for a hierarchical GDS | Look for `pfet` devices that Magic extracts as p and MAX extracts as n | Flatten the implant and the diffusion into the same cell before the boolean, for the cells that fail this. |
| H9 | On reopen, a child cell is loaded from a different directory than the one just written. | to check | Print the path of every cell the second session opens | Write the tree into one directory and pass that directory as the only cell path. |

H6 from the previous draft of this plan (GDS names truncated at 32
characters) is withdrawn. Section 2.6 is the measurement.

### 3.2 A0 — measure, before changing a rule

New `pdk/tests/convert_check.sh <mag-dir> <top-cell> <pdk>`. It is the
command that decides A3. It does not change the product.

1. Magic writes `${top}.foundry.gds` with the current `mag2gds.sh` script,
   and `${top}.hier.gds` with `cif *hier write enable` and
   `cif *array write enable`. Record both byte sizes and the Magic log.
2. MAX, under a virtual display, with `GDS_READ_NO_DRC` forced to 0 and
   `GDS_READ_SNAP_TO` forced to 0: `gds_read` the foundry GDS, run DRC to
   completion, write `drc_before.txt` (rule text, layer, count, first box).
   Then `cell_save_tree`, quit.
3. A second MAX opens the saved top cell with `-tech` equal to the tech
   that saved it, runs DRC, writes `drc_after.txt`.
4. Magic runs its own DRC on the same top cell and writes `drc_magic.txt`.
5. MAX writes GDS back out. Per GDS layer number, XOR that file against
   Magic's foundry GDS and record the differing area.

The designs, in increasing size:

| Design | Why it is in the set |
|--------|----------------------|
| Three synthetic `.mag` files, checked in under `pdk/tests/mag/` | One odd-height rectangle (the 451-unit case), one 170 nm contact, one label. Expected integers are in the test, so it passes or fails with no PDK and no MAX. |
| `pdk/samples/caravel_analog_por` top `example_por` | Small real sky130 cell with subcells, a 0.69 um resistor, FETs, MIM caps. Runs in Magic on this machine. |
| One sky130 hd standard-cell row, taken from the installed PDK `libs.ref` | Abutting cells: the case `exact_overlap` and implant merging care about. |
| `user_proj_example` | The reported cell. 88 MB. Run last, and only where there is memory for it. |

On this workstation step 1 can be tried for `example_por` with the Magic
binary and the `~/.ciel/sky130A` tree. Steps 2 and 3 need a MAX binary,
which is not in the Nix store here. If they cannot be run, the script is
still delivered and A1, B, C, and D proceed. A3 waits for `drc_after.txt`.

### 3.3 A1 — exactness rules in the converter

These land in `pdk/mag_import.tcl` and `pdk/mag2gds.sh` and are covered by
`pdk/tests/mag_exact.tcl`, which is plain Tcl and runs here.

1. Coordinates stay integers in source units for the whole conversion.
   The scale is a fraction: `lambda_nm * magscale_n / magscale_d` for a
   `.mag`, and the GDS `UNITS` record (metres per database unit) for a
   GDS. The fraction is reduced by the greatest common divisor. No
   coordinate is multiplied by a `double` and no coordinate passes through
   `round()`.
2. Paint is copied corner to corner. The converter never computes a
   midpoint for paint.
3. Before writing anything, the converter reads the destination database
   unit out of the generated `.tech27` `units` line. It rejects the
   conversion, with the fraction printed, when any source coordinate is
   not a whole number of destination units. It does not round and then
   continue. The alternative it offers is the finer technology from A2,
   when that file is installed.
4. For the duration of `gds_read` the converter sets `GDS_READ_SNAP_TO`
   to 0 and `GDS_READ_REPORT_ROUNDING_ERRORS` to 1, and restores both.
   Any rounding warning in the MAX log fails the conversion.
5. Where a single point is required (a GDS text has one anchor), the
   point is the corner of the label box with the smaller x, then the
   smaller y. It is a grid point by construction. The label text and
   the layer are unchanged.
6. After `cell_save_tree`, a scan of the written `.max` files checks
   every integer against the mask grid (5 nm for sky130 and IHP, 50 nm
   for gf180, unless the `.tech` said otherwise) and checks the top-cell
   bounding box against Magic's `<< properties >>` `FIXED_BBOX` when the
   `.mag` has one. `example_por` and the resistor `.mag` both have
   `FIXED_BBOX`.
7. The Tcl dump uses the same fraction and the same rejection. A grow
   that is not a multiple of the grid is expanded to the next multiple
   outward, and the log names the layer and the amount. The dump's
   `.max` gets a property `mmi_convert preview` so an open can say the
   file is not for DRC.

Magic's GDS `UNITS` and the `.tech27` `units` line are the two inputs of
check 3. The converter does not assume 1 nm on either side.

### 3.4 A2 — database unit 0.5 nm

`source_to_tech27.tcl` writes

```
units .0005 .0005 .0005 .0005
```

`GEN_REV` becomes 7. `PDK_GEN_REQUIRED` becomes 7. The existing repair
(`pdk_autofix_tech27` and `mmi_repair_tech27`) rebuilds an installed
technology from its `.source` on the next launch, so a user who already
imported a PDK gets the new unit without downloading again.

0.5 nm is the coarsest unit that divides 1 nm (the GDS lattice), 5 nm
(the sky130 and IHP mask grid), 50 nm (gf180), and 2.5 nm (half of the
5 nm grid, which is the y midpoint in section 2.1).

Before this becomes the default, these call sites are read, because they
divide by the database unit or by the GDS unit:

| File | What it divides |
|------|-----------------|
| `max/m/gds/gdsWrite.c` 1164 and 1173 | `CIFDBRes / CIFGDSRes`, `CIFDBRes / CIFPlaneRes` |
| `max/m/cif/cifGen.c` 745 and 1100 | same, while generating CIF |
| `max/m/cif/cifHier.c` 494 and 939 | same, hierarchical CIF |
| `max/m/cif/cifRdCl.c` 172 | `CIFPlaneRes / CIFDBRes` while reading CIF |
| `max/m/drc/DRCcif.c` | CIF-plane DRC distances |
| `pdk/image_layout.tcl` | the pixel pitch it paints with |
| `max/maxtcl/*.tcl` | any literal `0.001` used as a length |

If one of those cannot tolerate a database unit different from the GDS
unit, the default stays 0.001 and the 0.5 nm deck is installed beside it
as `sky130A-half.tech27`, selected with `-tech sky130A-half`
(section 2.7, variation syntax). The converter's check 3 then offers that
technology when a midpoint is not representable at 1 nm.

The converter will not turn Magic contacts or transistors into MAX
`#via` and `#fet` cells. Those cells are regenerated from a width and a
center; they replace the foundry geometry instead of copying it.

### 3.5 A3 — one change per confirmed row of 3.1

Each change is a separate edit with the test that fails before it and
passes after it. A C change (only H7 needs one, and only if the polygon
split is actually dropping geometry) is isolated so the `mmi-vendor`
rebuild is one commit's worth of source. H1 is not a C change: it is a
Tcl assignment around `gds_read`.

### 3.6 A4 — the rule audit

`pdk/tests/rule_audit.tcl` reads the three `pdk_rules_*` / `pdk_layers_*`
tables and the `drc` section of the installed Magic `.tech`
(`libs.tech/magic/*.tech`). For each width and spacing the generator
emits, the test finds the deck's rule for that layer. A generated number
larger than the deck's number fails the test. A layer with no deck rule
is reported and is not given a number by us. The test runs against
whichever of `~/.ciel` or `$PDK_ROOT` is present, and it is skipped with
a message when neither is.

### 3.7 Done when

- For every mask layer the tech maps, the XOR area between Magic's GDS
  and the GDS MAX writes from the reopened `.max` is 0. Layers the tech
  derives, and layers it deliberately does not map, are listed in the
  convert log rather than failing the XOR.
- `drc_after.txt` contains no error that `drc_magic.txt` does not also
  contain at the same box.
- The MAX log for the import contains no rounding warning.
- The synthetic cells match the integers in the test exactly, including
  the 37847.5 nm midpoint stored as 75695 database units at 0.5 nm.

## 4. Part B — the `importer` application

### 4.1 How it runs

Tcl/Tk 8.6 `wish`, which the CAD environment already has (`tk` is in
`targetPkgs` in `flake.nix`). No new package. The download, the resume,
and the technology compile stay in `fetch_pdk.sh` and `compile_tech.sh`;
the app drives them. It does not source those scripts into MAX, and MAX
does not source the app. The app may use Tcl 8.6. Everything MAX or SUE
still sources stays Tcl 8.0, which means: no `dict`, no `{*}`, no
`lset`, no `string repeat`, no `file normalize`, no `glob -directory`,
and no regexp class that contains a tab. `pdk/tests/tcl80_check.sh`
scans the files that MAX and SUE source and rejects those constructs.

`./run.sh importer` and `importer` from the CAD shell both work.
`nix/launch.sh` grows one branch for the command name `importer`, next
to `max`, `sue`, and `nst`.

Without a display, and in tests:

```
importer --list
importer --status
importer --install sky130A
importer --uninstall sky130A
importer --repair
```

`launch.sh` calls `importer --repair` before `max` or `sue` starts, in
place of the current in-process `pdk_autofix_tech27`. Repair rebuilds a
technology whose generator revision is old and regenerates a SUE library
whose revision is old. It does not download.

### 4.2 The window

Same information as the revolution-eda registry windows, one window for
both catalogues because a library is not useful without its PDK:

```
+-- importer -------------------------------------------------------------+
| Install into: [/mmi-pdks  (on the host: data/pdks)       ] [Browse...]  |
| [ PDKs ] [ Design libraries ]                                           |
| +-----------+-----------+----------------+---------+-----+-----+ +-----+|
| | Installed | Name      | Process        | Version | MAX | SUE | |Desc.||
| | yes       | sky130A   | SkyWater 130nm | e8daeda | yes | yes | |     ||
| | partial   | gf180mcuD | GF 180nm MCU   | 0fe599b | yes | no  | |     ||
| | no        | sg13g2    | IHP 130nm SiGe | ddb601a |     |     | |     ||
| +-----------+-----------+----------------+---------+-----+-----+ +-----+|
| With this PDK: [x] MAX technology   [x] SUE design library              |
|                [ ] extra ciel libraries (MMI_PDK_LIBS)                  |
| [Download / Install] [Uninstall] [Repair] [Refresh]           [Cancel]  |
| [==========================>            ] 62%  Unpacking sky130_fd_sc_hd|
| Log ...                                              [Copy] [Open dir]  |
+-------------------------------------------------------------------------+
```

The "Installed" column is the five states `pdk_import_state` already
computes (`pdk_import.tcl` 945-964), plus one new state for the library:

| State | Meaning | Button that is enabled |
|-------|---------|------------------------|
| `missing` | nothing on disk | Download / Install |
| `resume` | `.fetch-<family>/dl/*.tar.zst` exists, tree does not | Download / Install (continues) |
| `convert` | open_pdks tree is complete, `.tech27` or the SUE library is not | Download / Install (skips the download) |
| `outdated` | both exist, `MMI_PDK_GEN` or the library revision is older than this importer | Repair |
| `installed` | tree, tech, and library match this revision | Uninstall |
| `broken` | a tech file exists but `pdk_tech27_ok` rejects it | Repair |

Uninstall asks, then deletes only the paths recorded in
`installed.json` for that name. It refuses a path that is not under the
install location (`pdk_path_under_root` is the check today).

"Start MAX with this PDK" and "Start SUE with this library" are offered
after a successful install. They run `max -tech <name>` and
`sue -lib <name>`.

The custom URL / local directory import that the MAX dialog has today
moves here as an "Advanced..." entry, so that path is not lost.

### 4.3 Catalogue

`pdk/importer/registry.json`, shipped in the repo, one object per PDK
and one per library. The PDK entries are exactly the three rows of
section 2.7; the tag and the asset list are read from this file by
`fetch_pdk.sh` so the pin lives in one place. A `registry_url` key, empty
by default, is consulted first when it is set, and the shipped file is
the fallback. That is the hook revolution-eda uses, without depending on
a remote service now.

```json
{
  "pdks": [
    {
      "name": "sky130A",
      "process": "SkyWater 130nm",
      "dir": "sky130A",
      "family": "sky130A",
      "tag": "sky130-e8daeda73ca8f5814dbc0b11d1d05802251a3750",
      "assets": ["common", "sky130_fd_pr", "sky130_fd_io",
                 "sky130_fd_sc_hd", "sky130_fd_sc_hvl"],
      "max_tech": "sky130A",
      "sue_lib": "sky130A",
      "license": "Apache-2.0",
      "description": "open_pdks sky130A, Magic tech and the hd/hvl standard cells."
    }
  ],
  "libraries": [
    {
      "name": "sky130A",
      "pdk": "sky130A",
      "kind": "sue",
      "description": "SUE icons for the sky130A primitives, generated at install."
    }
  ]
}
```

`installed.json`, written under `$PDK_ROOT/registry/`, records what this
app put there: name, kind (`pdk`, `max_tech`, `sue_lib`), version, the
generator revision, the absolute path, and the time. Uninstall and
`--status` read it. A tree that `fetch_pdk.sh` already laid down before
this app existed is detected by the same `tree_ready` test the script
uses, and is adopted into `installed.json` on Refresh rather than
downloaded again.

### 4.4 What an install does

1. `fetch_pdk.sh <family>` — unchanged behavior: resume, stage, unpack,
   install into `$PDK_ROOT/<dir>`, write `MMI_PDK_SOURCE`.
2. Write `$PDK_ROOT/max/tech/<tech>/<tech>.source` from the layer tables
   and run `compile_tech.sh`. The `.source` revision and `GEN_REV` are
   the ones from section 3.4 once A2 has landed; until then they stay at
   the current revision so an install during steps B and C still produces
   a loadable tech.
3. Run `pdk/sue/gen_sue_lib.tcl` (section 6) into `$PDK_ROOT/sue/lib/<name>/`.
4. Append the three records to `installed.json`.
5. Offer the two start buttons.

The install location defaults to `PDK_ROOT` (`/mmi-pdks` inside the
session, `data/pdks` on the host). Browse changes it for this run and
remembers it in `installed.json`.

### 4.5 Files of the app

| File | Role |
|------|------|
| `pdk/importer/importer` | executable: finds `wish`, runs `importer.tcl`, maps `--install` and the rest |
| `pdk/importer/importer.tcl` | the window and the command-line modes |
| `pdk/importer/engine.tcl` | state machine, drives the shell scripts, parses their `STATUS`/`PCT`/`MSG` files (the format `fetch_pdk.sh` `write_status` already writes) |
| `pdk/importer/registry.json` | the catalogue |
| `pdk/importer/pdk_tables.tcl` | the layer and rule tables, moved out of `pdk_import.tcl` unchanged apart from the A4 edits |

## 5. Part C — remove the downloader from MAX

- `pdk/maxrc` sources `pdk_common.tcl`, `mag_import.tcl`, and
  `image_layout.tcl`. It stops sourcing `pdk_import.tcl`.
- `pdk/pdk_common.tcl` keeps `pdk_root`, `pdk_which`, `pdk_tech27_ok`,
  `pdk_find_tech27`, `pdk_import_copy_text`, `pdk_max_tech_dirs`, and
  `pdk_source_rev`. Magic import and the image importer use those.
  The file stays Tcl 8.0.
- `pdk_import.tcl` is deleted. Its dialog, pollers, and menus live in
  `pdk/importer/` after the move.
- Strings that tell the user to use File → Import PDK are rewritten to
  `./run.sh importer` in `mag_import.tcl`, `mag2gds.sh`, `open_mag.sh`,
  `fetch_pdk.sh`, `nix/launch.sh` (the banner around line 313),
  `README.md`, `pdk/PDK_SHARED.txt`, and
  `pdk/samples/caravel_analog_por/README.md`.
- `launch.sh` deletes a leftover `data/home/cad/mmi_local/max/pdk/pdk_import.tcl`
  on startup, because the home directory is writable and an old copy
  there is sourced in preference to the bundle (`maxrc` candidate order).
- MAX gains no replacement menu. The Magic import menu and the image
  import menu stay.

## 6. Part D — SUE design libraries and `sue -lib`

### 6.1 The library on disk

```
$PDK_ROOT/sue/lib/sky130A/
  LIBRARY                 name, pdk, generator revision, pdk tag, time
  lib.suerc               sourced when this library is selected
  spice_header.h          .param lines plus .lib/.include of the PDK models
  devices/<cell>.sue      one icon per primitive
  devices/tclIndex
  examples/inverter.sue   built from the PDK nfet and pfet icons
  examples/tclIndex
```

`gen_sue_lib.tcl` walks `$PDK/libs.tech/xschem` for symbol files. The
exact suffix and the pin syntax are read from the installed tree before
the parser is written (the directory is present for all three PDKs;
a sample file has not been opened yet). From each symbol it takes the
cell name, the pin names and directions, the parameters and their
defaults, and the spice netlist line when the symbol has one. The icon
body is `ICON_<cell>` with `icon_term`, `icon_property`, the `spice`
property, and a `sim` property whose device type is `n` or `p` for the
MOS symbols, so a SUE netlist and a MAX extraction of the same device
use the same terminal order (`g s d` on the `sim` line, matching
`nmos.sue`).

Symbols that do not parse are counted and named in `LIBRARY` under
`skipped`. A PDK with no symbol directory falls back to a built-in table
of three devices (nmos, pmos, a poly resistor) keyed by family, with the
model names taken from that family's ngspice deck. The fallback is there
so a partial tree still produces a library; the xschem walk is the
normal path.

`spice_header.h` is generated, not copied from `mspice`. It sets
`ln_min` and `lp_min` from the smallest channel length the symbols
declare, sets the area and perimeter params the generic spice line
uses, and includes the PDK's ngspice library. The include path is the
one `libs.tech/ngspice` actually contains; the generator searches for
the model file rather than assuming a name. A netlist line that names a
model or a subcircuit absent from that directory is a generation error
for that one icon, which is skipped and listed.

`lib.suerc` sets:

- `DEFAULT_SPICE_HEADER` to this library's `spice_header.h`
- `MAX_EXEC` to `max -tech <the same name>`, so "open in MAX" from SUE
  uses the matching deck
- nothing else, so the user's `~/.suerc` still wins for colors, keys,
  and grid

`examples/inverter.sue` is a schematic that instances the library's nfet
and pfet, copied in structure from `mspice/inverter.sue` (the `make nmos`
/ `make pmos` lines become `make <pdk-nfet-cell>` / `make <pdk-pfet-cell>`).
It is the smoke test for the library: SUE can load it and netlist it.

Standard-cell icons from `libs.ref/*/spice` or from the LEF are not in
this change. The `LIBRARY` file has a key for them so they can be added
later without a new directory layout.

### 6.2 `sue -lib`

Resolution, applied by `pdk/sue/sue_lib.tcl`, which the site `.suerc`
sources:

```
for each token that -lib / -LIB / -AUTOLIB put in LIB or AUTOLIB:
    if the token contains a "/" or it is an existing directory:
        keep it            # today's behavior
    else:
        look, in order, in:
            each directory of SUE_LIB_PATH
            $PDK_ROOT/sue/lib/<token>
            ~/mmi_private/sue/lib/<token>
            $MMI_LOCAL/sue/lib/<token>
            $MMI_TOOLS/sue/lib/<token>
        if a directory with a LIBRARY file is found:
            replace the token with that directory
        else:
            remove the token and print the names that do exist,
            plus the command:  ./run.sh importer
if no -lib was given and SUE_DEFAULT_LIB is set:
    treat SUE_DEFAULT_LIB as one -lib token
a library that resolved is also appended to AUTOLIB,
so its icons appear in the list without a second flag
```

`SUE_DEFAULT_LIB` is the counterpart of `MAX_DEFAULT_TECH`. The site
file is created by `launch.sh` with the marker `# mmi-sue-lib`, the same
pattern as `# mmi-pdk-nix` in `.maxrc`, so a second launch does not
append it twice. The site file is under `data/home`, which is writable;
`sue_lib.tcl` itself is read from `/mmi-bundle` or `/mmi-pdk-live`.

Several `-lib` flags are kept, in the order given, because
`call_keyword -append` already collects them that way.

The help text inside `sue/sue` and `sueInit.tcl` gains a `-lib` line the
next time `mmi-vendor` is rebuilt for some other reason. Until then the
importer's window and `sue -help` from the wrapper document it. The
wrapper's `-help` is a csh string, not compiled Tcl, so that one line
can be updated without a rebuild; the layout step installs the wrapper
from the vendor tree, so the edit is in `vendor/mmi/sue/sue`.

### 6.3 What the generator does not do

- It does not scale icon coordinates. SUE's grid is its own (section 2.8).
- It does not emit a bulk pin. The shipped nmos/pmos icons have no bulk
  pin; the spice line binds the bulk to `gnd` or `vdd`. A symbol that
  has an explicit bulk pin keeps it, because the pin list comes from the
  symbol.
- It does not overwrite a `devices/*.sue` that the user has edited. A
  file whose first line is `# mmi-sue-lib generated` is regenerated.
  A file without that line is left alone and named in the log.

## 7. Part E — wiring and docs

- `flake.nix` `mmiPdk`: install `pdk/importer/**`, `pdk/sue/**`,
  `pdk/pdk_common.tcl`, and the tests. Stop installing `pdk_import.tcl`.
  Put `importer` on `PATH` inside the FHS env. `mmi-vendor` is not
  rebuilt for this.
- `nix/launch.sh`: the `importer` command, creation of the site
  `.suerc`, `importer --repair` before MAX, deletion of a stale
  `pdk_import.tcl` under the home overlay, banner text.
- `run.sh` usage text: `./run.sh importer`.
- `README.md` and `pdk/PDK_SHARED.txt`: the install location, the two
  commands `max -tech` and `sue -lib`, and the statement that PDKs are
  fetched by `importer` rather than by a menu inside MAX.
- New text files are LF. `importer` and the shell tests are marked
  executable in git.

## 8. Files

| File | Change |
|------|--------|
| `PLAN.md` | this plan |
| `pdk/mag_import.tcl`, `pdk/mag2gds.sh` | A1 checks, H1 flag, H4 labeling, H5 switch default if A0 confirms it |
| `pdk/source_to_tech27.tcl` | database unit, `GEN_REV` 7, rule-audit fixes |
| `pdk/pdk_common.tcl` | new, the helpers MAX still needs |
| `pdk/pdk_import.tcl` | removed after the move |
| `pdk/importer/importer`, `importer.tcl`, `engine.tcl`, `pdk_tables.tcl`, `registry.json` | the app |
| `pdk/fetch_pdk.sh` | read the pin and the asset list from `registry.json`; messages |
| `pdk/sue/sue_lib.tcl`, `gen_sue_lib.tcl`, fallback device tables | libraries and `-lib` |
| `pdk/tests/mag_exact.tcl`, `convert_check.sh`, `rule_audit.tcl`, `tcl80_check.sh`, `importer_cli.sh`, `sue_lib.tcl` test, `pdk/tests/mag/*.mag` | the checks in sections 3, 4, 6 |
| `pdk/maxrc`, `pdk/compile_tech.sh`, `pdk/open_mag.sh` | what MAX sources; messages |
| `vendor/mmi/sue/sue` | one help line for `-lib` |
| `flake.nix`, `nix/launch.sh`, `run.sh`, `README.md`, `pdk/PDK_SHARED.txt`, sample README | wiring and docs |
| `vendor/mmi/src/max4.3.16/**` | only if A0 confirms H7 and the polygon split needs a C change |

## 9. Order

1. A1 and its Tcl test. The fraction and the rejection can be tested
   with no MAX and no PDK.
2. B and C. The importer installs a PDK and MAX no longer has the menu.
   The technology revision stays at 6 until step 5, so an install in
   this step still loads in today's MAX.
3. D. Generate a library from `~/.ciel/sky130A` and check the icons,
   the spice header, and the name resolution with `tclsh`.
4. A0 for `example_por` as far as Magic on this machine will go. The
   MAX half of A0 runs where a MAX binary exists.
5. A2, A3, A4, using `drc_after.txt` and the rule audit. `GEN_REV`
   moves to 7 here, and `--repair` rebuilds technologies installed in
   step 2.
6. E, then one pass of every test in section 10, and a report of what
   ran and what did not.

## 10. Where each test runs

| Test | Here | Needs |
|------|------|-------|
| `mag_exact.tcl`, `tcl80_check.sh` | yes | a `tclsh` (Nix store has 8.6; the 8.0 scan is textual) |
| `importer --list`, `--status`, and a dry install against a copied tree | yes, the Tcl, if `wish` can open | no display for `--list` and `--status` |
| `gen_sue_lib.tcl` on `~/.ciel/sky130A` | yes | the ciel tree, which is present |
| Magic GDS of `example_por` | attempted | `magic-vlsi` from the Nix store, `~/.ciel/sky130A`, enough RAM |
| MAX `gds_read`, DRC, save, reopen | no, until a MAX binary exists | `mmi-vendor` built, a display, more RAM than this VM has |
| `./run.sh importer` end to end | your Linux machine | user namespaces |

`user_proj_example` is in `convert_check.sh` and is not required to pass
on this VM. The acceptance numbers in section 3.7 are the same either
way.

## 11. Choices already made

1. The importer is Tcl/Tk 8.6, using the `wish` already in the CAD
   environment.
2. A SUE library has the same name as the MAX technology: `sky130A`,
   `gf180mcu`, `sg13g2`.
3. `-lib` takes a library name or a directory. A directory keeps the
   meaning `-LIB` has today.
4. MAX loses the downloader and gains no menu in its place. Repair of
   an installed technology stays, and it moves to `importer --repair`.
5. SUE libraries are generated on the machine that installed the PDK,
   from that PDK's symbols. The catalogue ships in the repo. Nothing
   new is published to a server. `registry_url` can point at one later.
6. The ciel tags and the asset lists stay the ones in `fetch_pdk.sh`
   today. They move into `registry.json` and the script reads them, so
   there is still one pin.
7. The database unit becomes 0.5 nm only after the files in section 3.4
   are read. If one of them cannot tolerate it, the 0.5 nm deck ships
   as `sky130A-half` and `-tech sky130A-half` selects it.
8. No commit and no push unless you ask.

## 12. Not in this work

- Running ngspice or any other simulator from SUE. The library ships a
  header and netlist lines; the simulator binary is not added to the
  CAD environment.
- Replacing foundry geometry with MAX `#via` and `#fet` generator cells.
- Pre-building `.max` copies of the standard-cell libraries.
- SUE icons for the standard cells.
- A new package in `flake.nix` `targetPkgs`.
- Downloading the Revolution EDA Python PDK or its schematic libraries.

## 13. Read before the step that needs it

| Before | Read |
|--------|------|
| A2, switching the default unit | the eight files in the table in section 3.4 |
| A3, H7 | `max/m/cif/cifRdPoly.c` `CIFPolyToRects`, and one polygon that logged "Couldn't convert manhattan polygon" |
| A4 | the `drc` section of `sky130A.tech`, `gf180mcuD.tech`, `ihp-sg13g2.tech` in the installed tree, side by side with `pdk_layers_*` |
| D, the symbol parser | one `.sym` from each of the three `libs.tech/xschem` trees, plus the ngspice file the generator would include |
| D, the smoke schematic | `sue/src/net_spice.tcl` (`unique_name`, the `M` property, pin order) |
| A0, the DRC report format | `max/m/drc/DRCtcl.c` and `vendor/mmi/mmi_local.sample/max/api_examples/drc_info.tcl` |
