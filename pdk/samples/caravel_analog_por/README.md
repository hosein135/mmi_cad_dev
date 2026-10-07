# Caravel analog design converted to MAX

The Magic design this project converts to MAX is the Caravel analog power-on-reset cell **example_por** (sky130A), from the Efabless analog user project.

The importer downloads the whole `mag/` folder (Apache-2.0) and converts `example_por` to MAX under sky130A. Converted `.max` files are written to `<design>/max_import`.

## URLs

| What | URL |
| --- | --- |
| Top cell (`example_por.mag`) | https://github.com/efabless/caravel_user_project_analog/blob/main/mag/example_por.mag |
| Magic layouts (`mag/`) | https://github.com/efabless/caravel_user_project_analog/tree/main/mag |
| Upstream repository | https://github.com/efabless/caravel_user_project_analog |
| Download archive used by `fetch_caravel_mag.sh` | https://github.com/efabless/caravel_user_project_analog/archive/refs/heads/main.tar.gz |
| ChipFoundry Caravel | https://github.com/chipfoundry/caravel |

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
