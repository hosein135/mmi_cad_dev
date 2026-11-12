# Plan: exact Magic to MAX conversion, `importer` app, SUE design libraries, `sue -lib`

Written 2026-11-12, before any code change. Adding this file is the only change so far
(branch `main` at `ed23d8b`, working tree was clean).

Path shorthand: `max/` = `vendor/mmi/src/max4.3.16/`, `sue/` = `vendor/mmi/src/sue4.4/`.
Statements are marked **verified** (I read the code or ran a command) or **to check**
(not confirmed yet). Nothing marked "to check" is treated as fact in the design.

## 1. What you asked for and what will exist at the end

| # | Request | Result |
|---|---------|--------|
| 1 | Handle `.5` values in `.mag` to `.max` conversion (scale change or another exact method) | No coordinate is ever rounded silently. Paint is converted corner to corner in integer arithmetic. The database unit of the PDK technologies is halved to 0.5 nm so midpoints are integers too. A check before and after every conversion proves exactness. |
| 2 | Saved `.max` reopens with many DRC errors (sample `user_proj_example.mag`) | Measured first, then fixed by cause. Target: reopening shows no DRC error that Magic's own DRC does not also report at the same place. |
| 3 | GUI application `importer` for PDKs and design libraries that work with SUE and MAX | New standalone app, started with `./run.sh importer`. |
| 4 | Remove the PDK downloader from MAX | Menu entries, dialog and download engine leave MAX. |
| 5 | A SUE design library for each PDK MAX supports | Libraries `sky130A`, `gf180mcu`, `sg13g2`, generated from the installed PDK. |
| 6 | `-lib` for SUE like `-tech` for MAX | `sue -lib sky130A` pairs with `max -tech sky130A`. |

## 2. Findings

### 2.1 How MAX stores geometry, and where half units come from (verified)

- A `.max` file is integers in database units. The header carries `max 4`, `tech <name>`,
  `resolution <DB unit in microns>` (`max/m/database/DBwrite.c` 612-625).
- Paint (section `RECTS`) is stored as **two corners**: `xbot ybot xtop ytop`
  (`DBwrite.c` 131-138). The reader uses `sscanf("%d %d %d %d")` (`DBread.c` 526-528), so a
  value such as `7569.5` cannot be stored. You are right that MAX only takes integers.
- The **midpoint** form is used for other objects, and those are where `.5` appears:

  | Object | Stored as | Half-unit risk |
  |--------|-----------|----------------|
  | Paint rectangles | two corners | none, if the corner is on the DB grid |
  | Generated via / FET cells (`#via...`, `#fet...`) | instance placed at its centre, box symmetric around 0 (`vendor/mmi/src/utils/tech/mmi18/stdcell/max/MMI_INVA.max` 70-77) | centre of an odd-sized rectangle |
  | Wire paths | centre-line points plus width | odd width puts the edges on `.5` |
  | Labels read from GDS | one point | the point is the midpoint of the Magic label box |
  | Cut arrays made by `squares` at GDS output | centred in the via paint | odd leftover |

- The DB unit comes from the technology: `units DBRes CPRes CIFRes GDSRes` in `cifoutput`
  (`max/m/cif/cifTech.c` 501-556). The technologies this repo generates use
  `units .001 .001 .001 .001`, so **1 DB unit = 1 nm** (`pdk/source_to_tech27.tcl` 650).
- On read, a `.max` file is scaled by `file resolution / DB unit` and rounded, with only a
  warning (`DBread.c` 1100, 1256-1265). GDS input is scaled and rounded the same way and can
  additionally be snapped to a grid (`max/m/gds/gdsRead.c` 425-438, 562-580, 654-675).
- Numbers for sky130A: the `.mag` files use `magscale 1 2`, one file unit is 5 nm (a `viali`
  rectangle in `user_proj_example.mag` is 34 x 34 units = 0.17 um). Corners are whole
  nanometres. The midpoint of an odd-sized rectangle is not: `rect 70 7344 6652 7795` in
  `pdk/samples/caravel_analog_por/example_por.mag` is 451 units high, midpoint y = 7569.5
  units = 37847.5 nm. At a 1 nm DB unit that is not an integer. At 0.5 nm it is.

Conclusion: converting corners needs the source grid to be a whole number of DB units.
Converting or creating anything centred needs **half** the source grid to be a whole number
of DB units. Today the first holds for the PDK grids and the second does not.

### 2.2 The current converter (verified)

- Flow: `pdk/mag_import.tcl` runs `pdk/mag2gds.sh` (Magic `gds write`), then MAX `gds_read`,
  then `cell_save_tree 0` (`mag_import.tcl` 2337-2368).
- For normal imports `mag2gds.sh` 104-112 emits `cif *hier write disable` and
  `cif *array write disable`. Only the full-chip path enables them.
- When no Magic rc is found the dialog switches by itself to the "Tcl paint dump"
  (`mag_import.tcl` 1520-1523). That path copies Magic paint with approximations (contact
  areas written as cut layers, implants grown by a fixed amount per rectangle,
  `mag_import.tcl` 116-121). It cannot be DRC clean.
- The Tcl dump uses floating point: `round(double(x) * scale)` and label midpoints
  `(x1 + x2) / 2.0` (`mag_import.tcl` 1045-1049, 1442-1445).
- The generated MAX DRC deck is only minimum width and spacing per layer, plus `no_overlap`
  for FETs and `exact_overlap` for vias (`source_to_tech27.tcl` 897-948). Values come from
  hand-written tables in `pdk/pdk_import.tcl` 85-274. At least one is wrong: `polyres` has
  width and spacing 0.69, which flags every 0.35 um poly resistor.
- Implant, diffusion and tap rules are checked on layers MAX regenerates (`grow 0.125`),
  not on the implant that was actually read from the GDS.

### 2.3 PDK downloader inside MAX (verified)

- `pdk/pdk_import.tcl`: dialog, menu entries, download and convert engine, layer tables.
  `pdk/fetch_pdk.sh` downloads pinned ciel releases with resume. `pdk/compile_tech.sh` and
  `pdk/source_to_tech27.tcl` build the MAX technology. `pdk/maxrc` loads it into MAX.
- `pdk/mag_import.tcl` uses a few helpers from it (`pdk_root`, `pdk_which`,
  `pdk_tech27_ok`, `pdk_find_tech27`, clipboard copy) and already works without them.
- MAX finds a technology as `tech/<tech>/<tech>-<var>.tech27`, then
  `tech/<tech>/<tech>.tech27` (`max/m/main/mnTech.c` 786-799). `-tech` is parsed in
  `max/maxtcl/max0.tcl` 180-243.

### 2.4 SUE (verified)

- SUE's Tcl is compiled into `sue.exe` (`sue/build/Makefile`, target `sueInit`).
- The command line is parsed without case: `call_keyword -nocase -append $argv {... {LIB ""}
  {AUTOLIB ""} ...}` (`sue/build/sueInit.tcl` 82-85). So `-lib <dir>` already equals
  `-LIB <dir>` and adds a **directory** to the icon search path. A library **name** is not
  understood.
- Start-up files are read in this order: system, site (`$MMI_LOCAL/sue/.suerc`), user,
  private, current directory (`sue/build/sueInitA.tcl` 36-40, 67-93). `LIB` and `AUTOLIB`
  are consumed afterwards (`sue/build/sueInitB.tcl` 70-89). A site file can therefore turn
  names into directories with no rebuild of SUE.
- `nix/launch.sh` 116-120 creates `mmi_local/max` before testing for it, so
  `mmi_local.sample` is never copied and there is no site `.suerc` today.
- A library is a directory of `.sue` files plus `tclIndex`. Icon format: see
  `vendor/mmi/sue/schematics/mspice/nmos.sue` (terminals, lines, user properties, a `spice`
  netlist template, a `sim` template used for LVS against MAX).

### 2.5 What I take from revolution-eda (verified from its source)

- A JSON registry lists PDKs and libraries: name, process, version, license, type,
  description, URL (`pdks.json`, `libraries.json`).
- The window has an install-location field with Browse, a table with an "Installed" column,
  a description pane, a progress bar, and Download/Install, Uninstall, Refresh buttons
  (`revedaEditor/gui/pdkRegistry.py`, `libraryRegistry.py`).
- Installed means the target directory exists with its metadata file. Versions are compared
  to offer updates. Zip extraction is guarded against path escape.
- The active PDK is chosen per run (`REVEDA_PDK_PATH`), libraries per project. Here the
  matching choices are `max -tech` and `sue -lib`.

### 2.6 This workstation (verified)

- Windows Server 2019 with WSL **1** (kernel `4.4.0-17763-Microsoft`), 3 GB RAM, 2 CPUs.
  The product needs Linux with user namespaces, so `./run.sh` cannot run here.
- In WSL: Nix 2.28.5. The store holds magic-vlsi 8.3.623, Tcl/Tk 8.6.16 and gcc 14.3.
  `~/.ciel` holds sky130A, gf180mcuD and ihp-sg13g2 trees. MAX is not built in the store.
- The sample `user_proj_example.mag` is reachable (88.6 MB, `tech sky130A`, `magscale 1 2`).

## 3. Part A: conversion (resolution and DRC)

### 3.1 The cause of the DRC errors is not proven yet

I have not run MAX on the sample, so I do not know which rules fire. These are the
candidates from the code, ordered by how many errors each could produce, not by confidence.

| ID | Candidate | How I confirm it | Fix if confirmed |
|----|-----------|------------------|------------------|
| H1 | GDS input is snapped to the user design grid instead of the DB unit, moving 5 nm coordinates | Read the Tcl `gds_read` wrapper and `GeoScalePointGrid`; compare coordinates before and after | Force the snap to one DB unit during import |
| H2 | DRC on regenerated implant/diffusion layers and automatic "overlap" errors between cells on the shared active plane | Count errors per rule on one row of abutting standard cells | Check the drawn layers; adjust what `source_to_tech27.tcl` emits |
| H3 | The Tcl paint dump was used (automatic when no Magic rc) | `method=` line in `/tmp/mag_import_*/convert.log` | Never fall back silently; label the dump "preview only" |
| H4 | `cif *hier write disable` / `*array write disable` drop geometry Magic generates where subcells touch or overlap | XOR of Magic GDS written with and without the two switches | Enable both by default; disable only for the full-chip view |
| H5 | Rule values stricter than the foundry deck (`polyres` 0.69 is one) | Compare each generated rule with the PDK's Magic `drc` section | Correct the tables; add the comparison as a test |
| H6 | GDS cell names over 32 characters cut short, merging different device cells | Read `gdsInt.h` / `gdsReadIO.c`; test two long names with a common prefix | Raise the limit or fail loudly |
| H7 | Manhattan polygons that MAX cannot split into rectangles are dropped | Count "Couldn't convert manhattan polygon" in the log | Fix the split or pre-split in the converter |
| H8 | Diffusion typed wrongly when the implant sits in another cell (typing is per cell) | Look for wrong-type devices in hierarchical analog cells | Type from the flattened context where needed |
| H9 | On reopen, child cells resolve to another directory or an older conversion | Print the file each cell was loaded from | Write and reopen through one explicit cell path |

If you can tell me which "GDS conversion method" was selected and paste a few DRC messages,
I can skip part of this triage.

### 3.2 Step A0: reproduce and measure (test scripts only, no product change)

New `pdk/tests/convert_check.sh <mag dir> <top cell> <pdk>`:

1. Magic writes the GDS (current settings, and again with hierarchy processing on).
2. MAX reads the GDS, saves the tree, exits. A second MAX loads the saved top cell, runs
   DRC to completion and writes the error count per rule with the first coordinates.
3. Magic runs its own DRC on the same cell as the reference.
4. Geometry comparison per layer between Magic's GDS and the GDS written by MAX from the
   reopened cell (XOR area).

Test designs: `user_proj_example.mag`, the bundled `example_por`, one standard-cell row,
and small synthetic cells with odd-sized rectangles, contacts and labels.

### 3.3 Step A1: exactness rules built into the converter

1. **Integer arithmetic only.** Coordinates stay integers in source units. The scale is kept
   as a fraction (`lambda_nm * n / d`). No `double`, no `round()` on coordinates.
2. **Paint is converted corner to corner.** No midpoint is computed for paint, ever.
3. **Check before converting.** Read the grid of the source (`.mag` `magscale` and the PDK
   scale factor, then the UNITS record and coordinates of the GDS Magic wrote), the DB unit
   of the destination (parsed from its `.tech27`, not assumed) and the GDS snap grid. If any
   coordinate would not be a whole number of DB units, the conversion stops with the exact
   numbers, or switches to a finer technology. It does not round.
4. **MAX reads exactly.** The GDS snap is set to one DB unit for the import and restored
   afterwards. A round-off warning from MAX is treated as a failed conversion.
5. **Midpoints.** After step A2 they are exact. Where one point must be chosen (GDS text),
   it is a grid point inside the label box, chosen by a fixed rule.
6. **Check after converting.** Every coordinate in the written `.max` files is on the mask
   grid, and bounding boxes match the Magic source exactly.
7. The Tcl dump follows the same rules. A grow that is not a multiple of the grid is rounded
   outward on purpose and logged.

### 3.4 Step A2: change the scale (DB unit 0.5 nm for the PDK technologies)

- `source_to_tech27.tcl` writes `units .0005 ...`, generator revision goes up, and installed
  technologies are rebuilt by the existing repair path.
- Why 0.5 nm: GDS data sits on a 1 nm lattice, the mask grid is 5 nm, midpoints fall on
  0.5 nm and 2.5 nm. 0.5 nm divides all of them.
- Existing `.max` files (`resolution 0.001`) load exactly, every value times 2
  (`DBread.c` 1100). Coordinate range stays above 20 cm.
- **To check before I switch the default:** that MAX's CIF, GDS-output and DRC code is
  correct when the DB unit differs from the GDS unit (`gdsWrite.c` 1164-1173, `cifGen.c`
  745 and 1100, `cifHier.c` 494 and 939, `cifRdCl.c` 172, `DRCcif.c`), and that nothing in
  the MAX Tcl code or `pdk/image_layout.tcl` assumes 0.001.
- If that check fails, 1 nm stays the default and the 0.5 nm technology ships as a
  selectable variant through MAX's own `<tech>-<var>.tech27` lookup.
- I will **not** turn Magic contacts into MAX via cells. That would replace foundry
  geometry with generated geometry.

### 3.5 Step A3: fix what the measurement shows

One fix per confirmed row of 3.1, each with a test that fails before and passes after.
Changes to MAX's C code only if a row needs one (H6, H7); that rebuilds `mmi-vendor`.

### 3.6 Step A4: rule audit

Every width and spacing in the three PDK tables is compared with the PDK's Magic DRC deck.
A generated rule may never be stricter than the deck. The comparison becomes a test that
runs against an installed PDK.

### 3.7 Done when

- XOR area is 0 on every mapped mask layer between Magic's GDS and the GDS MAX writes from
  the reopened `.max`. Layers MAX derives or does not map are listed explicitly.
- Reopening the saved top cell shows no DRC error without a matching Magic DRC error.
- No rounding warning appears anywhere in the log.
- The synthetic odd-size cells convert with every coordinate equal to source times scale.

## 4. Part B: the `importer` application

- **Toolkit:** Tcl/Tk 8.6 (`wish`), already in the CAD environment. No new dependency, and
  the proven download, resume and convert logic moves over instead of being rewritten.
- **Start:** `./run.sh importer`, or `importer` inside the CAD shell.
- **Window** (modelled on the revolution-eda registry windows):

```
+-- importer -------------------------------------------------------------+
| Install into: [/mmi-pdks  (host: data/pdks)              ] [Browse...]  |
| [ PDKs ] [ Design libraries ]                                           |
| +-----------+-----------+----------------+---------+-----+-----+ +-----+|
| | Installed | Name      | Process        | Version | MAX | SUE | |Desc.||
| | yes       | sky130A   | SkyWater 130nm | e8daeda | yes | yes | |     ||
| | partial   | gf180mcuD | GF 180nm MCU   | 0fe599b | yes | no  | |     ||
| | no        | sg13g2    | IHP 130nm SiGe | ddb601a |     |     | |     ||
| +-----------+-----------+----------------+---------+-----+-----+ +-----+|
| With the PDK: [x] MAX technology  [x] SUE library  [ ] extra cell libs  |
| [Download / Install] [Uninstall] [Repair] [Refresh]           [Cancel]  |
| [==========================>            ] 62%  Unpacking sky130_fd_sc_hd|
| Log ...                                              [Copy] [Open dir]  |
+-------------------------------------------------------------------------+
```

- **Catalogue:** `pdk/importer/registry.json` lists PDKs (the three pinned ciel releases
  already in `fetch_pdk.sh`, unchanged) and libraries (MAX technology and SUE library per
  PDK, each naming the PDK it needs). A registry URL can replace it later.
- **States per item:** missing, downloading (resumable), downloaded but not converted,
  installed, outdated (older generator revision), broken. The buttons follow the state.
  This is the state logic that exists today in `pdk_import_state`.
- **Install of a PDK:** download and unpack, build the MAX technology, generate the SUE
  library, write `registry/installed.json`.
- **Uninstall:** removes only paths under the install location, after confirmation.
- **Custom URL or folder** import stays available as an advanced entry (it exists in MAX
  today, so dropping it would lose a feature).
- **No-window mode** for scripts and tests: `importer --list`, `--status`,
  `--install <name>`, `--uninstall <name>`, `--repair`. `nix/launch.sh` calls `--repair`
  before MAX starts, so table and generator fixes reach installed technologies at once.
- After an install the app offers "Start MAX with this PDK" and "Start SUE with this
  library".

Layout on disk (one shared `PDK_ROOT`, as today):

```
$PDK_ROOT/
  sky130A/  gf180mcuD/  ihp-sg13g2/   open_pdks trees (Magic, models, cell libraries)
  max/tech/<tech>/                    MAX technology (exists today)
  sue/lib/<name>/                     SUE design library (new)
  registry/installed.json             what the importer installed (new)
```

## 5. Part C: remove the PDK downloader from MAX

- `pdk/maxrc` stops loading the downloader. "Import PDK..." disappears from the File and
  Local menus.
- `pdk/pdk_import.tcl` is split: the small helpers MAX add-ons need go to
  `pdk/pdk_common.tcl` (Tcl 8.0 safe); dialog, engine and layer tables move to the importer.
- Messages that say "File -> Import PDK" (`mag_import.tcl`, `mag2gds.sh`, `fetch_pdk.sh`,
  `launch.sh` banner, README) point to `./run.sh importer`.
- Stale copies of `pdk_import.tcl` in `data/home/cad/mmi_local/max/pdk/` are removed at
  launch.
- No menu entry is added to MAX in its place.

## 6. Part D: SUE design libraries and `sue -lib`

### 6.1 Library content, one per PDK

```
$PDK_ROOT/sue/lib/sky130A/
  LIBRARY            name, PDK, generator revision, PDK release
  lib.suerc          read by SUE when the library is selected
  spice_header.h     includes the PDK's ngspice models
  devices/*.sue      one icon per PDK primitive, plus tclIndex
  examples/*.sue     inverter and test bench built from those icons
```

- **Device icons are generated from the installed PDK**, from its own xschem symbols
  (`libs.tech/xschem`, present in all three PDK trees): pins, drawing, parameters with
  defaults, and the SPICE line. The library therefore matches the PDK release that was
  downloaded. A small built-in table (core MOS, resistor, capacitor) is the fallback when a
  tree has no symbols.
- MOS icons also carry the `sim` template with the device names of the generated MAX
  technology (`nfet`, `pfet`), so SUE netlists line up with MAX extraction.
- `lib.suerc` sets the SPICE header, the minimum lengths and `MAX_EXEC` to
  `max -tech <same name>`.
- Each generated netlist template is checked against the PDK: the model or subcircuit it
  names must exist in the PDK's ngspice files.
- Optional later: standard-cell icons from the PDK's SPICE library.

### 6.2 `sue -lib`

- `sue -lib sky130A` loads the library of that name. `sue -lib /some/dir` keeps today's
  meaning (plain directory). Several `-lib` are allowed. `SUE_DEFAULT_LIB` is used when no
  `-lib` is given, like `MAX_DEFAULT_TECH`.
- Search order for a name: `$SUE_LIB_PATH`, `$PDK_ROOT/sue/lib`, `~/mmi_private/sue/lib`,
  `$MMI_LOCAL/sue/lib`, `$MMI_TOOLS/sue/lib`.
- A name that is not installed gives a clear message with the installed libraries and the
  importer command, instead of silently adding the current directory.
- Implementation: `nix/launch.sh` creates the site file `mmi_local/sue/.suerc` (same marker
  pattern as `.maxrc`), which loads `pdk/sue/sue_lib.tcl` (Tcl 8.0 safe). It rewrites `LIB`
  before SUE consumes it. SUE itself is not rebuilt for this.
- `-lib` is added to the SUE help text the next time `mmi-vendor` is rebuilt for another
  reason.

## 7. Part E: wiring and documentation

- `flake.nix`: install the new files into the bundle, drop `pdk_import.tcl`, put the
  `importer` launcher on PATH. `mmi-vendor` is not touched by this.
- `nix/launch.sh`: `importer` command, site `.suerc`, repair call, updated banner.
- `run.sh`: help text. `README.md`, `pdk/PDK_SHARED.txt`, sample README: new commands.
- All new text files use LF line endings; scripts get the executable bit in git.

## 8. Files

| File | Change |
|------|--------|
| `PLAN.md` | this plan |
| `pdk/mag_import.tcl`, `pdk/mag2gds.sh` | exactness rules, checks, fixes from 3.5 |
| `pdk/source_to_tech27.tcl` | DB unit, corrected DRC emission, generator revision |
| `pdk/pdk_common.tcl` (new) | helpers kept for MAX add-ons |
| `pdk/pdk_import.tcl` | removed; content moved to the two places above and below |
| `pdk/importer/importer.tcl`, `engine.tcl`, `pdk_tables.tcl`, `registry.json`, `importer` (new) | the app |
| `pdk/sue/sue_lib.tcl`, `suerc`, `gen_sue_lib.tcl`, fallback device tables, templates (new) | SUE libraries and `-lib` |
| `pdk/tests/*` (new) | resolution tests, conversion check, rule audit, importer and SUE tests |
| `pdk/maxrc`, `pdk/fetch_pdk.sh`, `pdk/compile_tech.sh` | no downloader in MAX, messages |
| `flake.nix`, `nix/launch.sh`, `run.sh`, `README.md`, `pdk/PDK_SHARED.txt` | wiring, docs |
| `vendor/mmi/src/...` | only if 3.5 needs a C fix |

## 9. Order of work

1. A0 measurement scripts; run them as far as this workstation allows.
2. A1 exactness rules and their tests (pure Tcl, testable here).
3. B and C: importer, downloader out of MAX.
4. D: SUE library generator and `-lib`.
5. A2 scale change, A3 fixes, A4 rule audit, driven by the measurement.
6. E wiring and docs, then the full check and a report of what passed and what did not.

What I can test where:

| Level | Where | Covers |
|-------|-------|--------|
| 1 | here, always | Tcl 8.6 logic and unit tests, importer no-window mode, SUE library generation against the PDK trees in WSL, importer window layout |
| 2 | here, if it works under WSL 1 | Magic writing GDS for the samples; building MAX with Nix and running it under a virtual display for the DRC counts |
| 3 | your Linux machine | `./run.sh importer`, `./run.sh max`, `./run.sh sue -lib ...`, anything level 2 could not do |

If level 2 fails, I continue with everything level 1 covers and give you one command
(`pdk/tests/convert_check.sh`) whose output decides the fixes in 3.5. Code that runs inside
MAX or SUE must be Tcl 8.0 safe; that is checked with the repo's own Tcl 8.0 once it is
built, and by review until then.

## 10. Choices I made (tell me if you want something else)

1. The importer is Tcl/Tk, not Python or Qt.
2. A SUE library has the same name as the MAX technology (`sky130A`, `gf180mcu`, `sg13g2`).
3. `-lib` takes a name or a directory.
4. MAX gets no downloader and no replacement menu entry.
5. SUE libraries are generated locally from the downloaded PDK. Nothing new is hosted
   online; the registry can point to URLs later.
6. PDK releases stay pinned to the versions in `fetch_pdk.sh`.
7. No commits or pushes unless you ask.

## 11. Not in this work

- Simulator integration (ngspice is not in the CAD environment); only netlists and headers.
- Converting Magic contacts or transistors into MAX generated cells.
- Pre-converted `.max` copies of whole PDK cell libraries.
- New dependencies in the Nix environment.

## 12. Code I still have to read before the matching step

- MAX Tcl `gds_read`, the grid code, `GeoScalePointGrid` (H1).
- `squares ... align` in `max/m/cif/cifGen.c` (cut placement, half units at output).
- `gdsInt.h`, `gdsReadIO.c` (H6); `cifRdPoly.c` (H7).
- The scale-factor code listed in 3.4.
- MAX DRC commands for the per-rule report (`mmi_local.sample/max/api_examples/drc_info.tcl`,
  `DRCtcl.c`) and how to run MAX without interaction.
- SUE netlister (`sue/src/net_spice.tcl`, `unique_name`, the `M` property) and icon calls
  for four-terminal devices.
- xschem symbol directories and format details in each PDK tree.
