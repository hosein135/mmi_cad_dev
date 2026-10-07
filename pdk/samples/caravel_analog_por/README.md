# Caravel analog design converted to MAX

The **Download full Caravel die** choice fetches the published harness [`caravel.gds.gz`](https://github.com/chipfoundry/caravel/blob/main/gds/caravel.gds.gz) and opens it in MAX. That path is GDS, not Magic.

**Download Caravel harness + example design** is the Magic conversion. It fetches [`efabless/caravel` `mag/`](https://github.com/efabless/caravel/tree/main/mag) (top cell `caravel`, padframe, management core) and the example counter [`user_proj_example.mag`](https://github.com/efabless/caravel_user_project/blob/main/mag/user_proj_example.mag) from `caravel_user_project`, then runs Magic → GDS → MAX and opens the original layout in Magic.

This folder is the separate small sample: the analog power-on-reset cell **example_por**. Choose **Local Caravel sample** to convert it.

`fetch_caravel_mag.sh` can still download that analog `mag/` folder (Apache-2.0) if you want the POR files on disk. Converted `.max` files for a Magic folder are written to `<design>/max_import`. The full die stays as GDS under `samples/caravel_die` and is not flattened into one `.max` per cell.

## URLs

| What | URL |
| --- | --- |
| Top cell (`example_por.mag`) | https://github.com/efabless/caravel_user_project_analog/blob/main/mag/example_por.mag |
| Magic layouts (`mag/`) | https://github.com/efabless/caravel_user_project_analog/tree/main/mag |
| Upstream repository | https://github.com/efabless/caravel_user_project_analog |
| Download archive used by `fetch_caravel_mag.sh` | https://github.com/efabless/caravel_user_project_analog/archive/refs/heads/main.tar.gz |
| ChipFoundry Caravel harness | https://github.com/chipfoundry/caravel |
| Full die downloaded by the menu (`gds/caravel.gds.gz`) | https://github.com/chipfoundry/caravel/raw/main/gds/caravel.gds.gz |
| Harness Magic (`caravel.mag` and the management/padframe cells) | https://github.com/efabless/caravel/tree/main/mag |
| Example design Magic (`user_proj_example.mag`) | https://github.com/efabless/caravel_user_project/blob/main/mag/user_proj_example.mag |

## What is included

This sample is the power-on-reset (`example_por`) used as the analog user-space example on Efabless/ChipFoundry Caravel (sky130A), plus the leaf `sky130_fd_pr` device cells that `example_por` instantiates.

- Top cell for conversion: `example_por`
- Also present: `user_analog_proj_example` (two POR instances)
- License: Apache-2.0 (upstream)

## What is not included

These need the full Caravel padframe / PDK standard-cell Magic views:

- `user_analog_project_wrapper.mag`
- `sky130_fd_sc_hvl__*` (schmittbuf / buf_8 / inv_8 / fill_4)

Those HVL standard-cell instances become empty placeholders in GDS unless the importer is pointed at a folder that also contains their `.mag` files from open_pdks.
