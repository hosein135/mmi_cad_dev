#!/usr/bin/env bash
# Download the published Caravel harness Magic layouts plus the example
# user design, so MAX can convert .mag -> GDS -> .max.
#
# Harness:  https://github.com/efabless/caravel  mag/   (Apache-2.0)
#   top cell caravel.mag, padframe chip_io, management caravel_core, ...
# Design:   https://github.com/efabless/caravel_user_project  mag/
#   user_project_wrapper.mag places user_proj_example (the counter).
#   This wrapper replaces the harness LEF abstract of the same name.
#
# Stdcells and IO pads stay in the sky130A PDK (Magic mag2gds loads them).
# RAM128 (management SRAM) is not published as a .mag in either repo.
#
# Usage: fetch_caravel_harness_mag.sh DEST_DIR [STATUS] [CANCEL] [LOG]
set +e
export LC_ALL=C
export LANG=C

dest="${1:-}"
status_file="${2:-}"
cancel_file="${3:-}"
log_file="${4:-}"

if [ -n "$log_file" ]; then
  exec >>"$log_file" 2>&1
else
  exec 2>&1
fi

if [ -z "$dest" ]; then
  echo "usage: fetch_caravel_harness_mag.sh DEST_DIR [STATUS] [CANCEL] [LOG]"
  exit 1
fi

HARNESS="${CARAVEL_HARNESS_MAG_URL:-https://raw.githubusercontent.com/efabless/caravel/main/mag}"
DESIGN="${CARAVEL_DESIGN_MAG_URL:-https://raw.githubusercontent.com/efabless/caravel_user_project/main/mag}"

st() {
  local pct="${1:-1}"
  local msg="${2:-Downloading Caravel Magic harness...}"
  local status="${3:-running}"
  echo "$msg"
  if [ -n "$status_file" ]; then
    {
      echo "STATUS=$status"
      echo "PCT=$pct"
      echo "MSG=$msg"
      echo "DEST=$dest"
    } > "${status_file}.tmp"
    mv -f "${status_file}.tmp" "$status_file"
  fi
}

cancelled() {
  [ -n "$cancel_file" ] && [ -f "$cancel_file" ]
}

fail() {
  st 0 "${1:-fetch failed}" fail
  exit 1
}

ok() {
  st 100 "Caravel harness Magic ready" ok
  exit 0
}

if cancelled; then
  fail "Cancelled."
fi

mkdir -p "$dest/hexdigits" "$dest/primitives" || fail "cannot create $dest"

big_ok() {
  local f="$1" min="$2"
  [ -f "$f" ] || return 1
  local sz
  sz=$(wc -c < "$f" 2>/dev/null | tr -d ' ')
  [ "${sz:-0}" -ge "$min" ]
}

# Design wrapper must instance the counter, not the harness LEF abstract.
wrapper_ok() {
  big_ok "$dest/user_project_wrapper.mag" 1000000 || return 1
  grep -q 'user_proj_example' "$dest/user_project_wrapper.mag"
}

if big_ok "$dest/caravel.mag" 1000 && \
   big_ok "$dest/caravel_core.mag" 20000000 && \
   big_ok "$dest/housekeeping.mag" 5000000 && \
   big_ok "$dest/chip_io.mag" 100000 && \
   big_ok "$dest/user_proj_example.mag" 20000000 && \
   big_ok "$dest/hexdigits/alpha_0.mag" 50 && \
   big_ok "$dest/primitives/sky130_fd_pr__res_xhigh_po_0p69_S5N9F3.mag" 1000 && \
   wrapper_ok
then
  st 100 "Using existing Caravel harness Magic tree" ok
  echo "already have $dest"
  exit 0
fi

fetch_one() {
  local url="$1" out="$2" min="$3"
  if cancelled; then
    fail "Cancelled."
  fi
  if big_ok "$out" "$min"; then
    echo "have $out"
    return 0
  fi
  mkdir -p "$(dirname "$out")"
  rm -f "$out.partial"
  if command -v curl >/dev/null 2>&1; then
    curl -L --fail --retry 2 -o "$out.partial" "$url" || fail "curl failed: $url"
  elif command -v wget >/dev/null 2>&1; then
    wget -O "$out.partial" "$url" || fail "wget failed: $url"
  else
    fail "need curl or wget"
  fi
  local sz
  sz=$(wc -c < "$out.partial" 2>/dev/null | tr -d ' ')
  echo "got $url bytes=$sz"
  if [ "${sz:-0}" -lt "$min" ]; then
    rm -f "$out.partial"
    fail "download too small (${sz:-0} bytes): $url"
  fi
  mv -f "$out.partial" "$out" || fail "could not install $out"
}

# name min_bytes   (harness mag/ files, not the LEF-only user_project_wrapper)
harness_files="
caravel.mag 1000
caravel_logo.mag 1000
caravel_motto.mag 500
copyright_block.mag 1000
open_source.mag 1000
user_id_textblock.mag 200
chip_io.mag 100000
chip_io_gpio_connects.mag 500
constant_block.mag 1000
EF_fill_4_8.mag 100
caravel_clocking.mag 100000
empty_macro.mag 50
empty_macro_1.mag 50
gpio_defaults_block.mag 1000
gpio_logic_high.mag 1000
housekeeping.mag 5000000
manual_power_connections.mag 10000
mgmt_protect_hv.mag 1000
mprj2_logic_high.mag 1000
mprj_io_buffer.mag 10000
mprj_logic_high.mag 10000
simple_por.mag 1000
spare_logic_block.mag 10000
user_id_programming.mag 10000
xres_buf.mag 1000
"

nfiles=46
i=0
tick() {
  i=$((i + 1))
  pct=$((5 + (i * 70 / nfiles)))
  if [ "$pct" -gt 80 ]; then
    pct=80
  fi
  st "$pct" "$1"
}

while read -r name min; do
  [ -n "$name" ] || continue
  tick "Downloading harness $name..."
  fetch_one "$HARNESS/$name" "$dest/$name" "$min"
done << EOF
$harness_files
EOF

tick "Downloading caravel_core.mag.gz..."
if ! big_ok "$dest/caravel_core.mag" 20000000; then
  fetch_one "$HARNESS/caravel_core.mag.gz" "$dest/caravel_core.mag.gz" 40000000
  if ! gzip -t "$dest/caravel_core.mag.gz" 2>/dev/null; then
    fail "caravel_core.mag.gz is not gzip"
  fi
  st 82 "Uncompressing caravel_core.mag..."
  tmp="$dest/caravel_core.mag.partial"
  rm -f "$tmp"
  gzip -dc "$dest/caravel_core.mag.gz" > "$tmp" || fail "could not decompress caravel_core.mag.gz"
  if ! big_ok "$tmp" 20000000; then
    rm -f "$tmp"
    fail "caravel_core.mag uncompressed too small"
  fi
  mv -f "$tmp" "$dest/caravel_core.mag"
  rm -f "$dest/caravel_core.mag.gz"
else
  echo "have $dest/caravel_core.mag"
fi

# simple_por instances these with a relative path "primitives/".
prims="
sky130_fd_pr__cap_mim_m3_1_WRT4AW.mag 100
sky130_fd_pr__cap_mim_m3_2_W5U4AW.mag 100
sky130_fd_pr__nfet_g5v0d10v5_PKVMTM.mag 500
sky130_fd_pr__nfet_g5v0d10v5_TGFUGS.mag 1000
sky130_fd_pr__nfet_g5v0d10v5_ZK8HQC.mag 500
sky130_fd_pr__pfet_g5v0d10v5_3YBPVB.mag 500
sky130_fd_pr__pfet_g5v0d10v5_YEUEBV.mag 1000
sky130_fd_pr__pfet_g5v0d10v5_YUHPBG.mag 500
sky130_fd_pr__pfet_g5v0d10v5_YUHPXE.mag 500
sky130_fd_pr__pfet_g5v0d10v5_ZEUEFZ.mag 1000
sky130_fd_pr__res_xhigh_po_0p69_S5N9F3.mag 1000
"
while read -r name min; do
  [ -n "$name" ] || continue
  tick "Downloading primitives/${name}..."
  fetch_one "$HARNESS/primitives/$name" "$dest/primitives/$name" "$min"
done << EOF
$prims
EOF

hex="alpha_0 alpha_1 alpha_2 alpha_3 alpha_4 alpha_5 alpha_6 alpha_7 alpha_8 alpha_9 alpha_A alpha_B alpha_C alpha_D alpha_E alpha_F"
for name in $hex; do
  tick "Downloading hexdigits/${name}.mag..."
  fetch_one "$HARNESS/hexdigits/${name}.mag" "$dest/hexdigits/${name}.mag" 50
done
tick "Downloading hexdigits/open_source.mag..."
fetch_one "$HARNESS/hexdigits/open_source.mag" "$dest/hexdigits/open_source.mag" 1000

st 90 "Downloading example design user_project_wrapper.mag..."
fetch_one "$DESIGN/user_project_wrapper.mag" "$dest/user_project_wrapper.mag" 1000000
if ! wrapper_ok; then
  fail "user_project_wrapper.mag does not instance user_proj_example"
fi

st 94 "Downloading example design user_proj_example.mag (about 85 MB)..."
fetch_one "$DESIGN/user_proj_example.mag" "$dest/user_proj_example.mag" 20000000

cat > "$dest/SOURCE.txt" << EOF
Caravel harness + example design (Magic)

Harness (top cell caravel):
  $HARNESS/
  https://github.com/efabless/caravel
  license: Apache-2.0

Example user design, copied over the harness wrapper:
  $DESIGN/user_project_wrapper.mag
  $DESIGN/user_proj_example.mag
  https://github.com/efabless/caravel_user_project
  license: Apache-2.0

user_project_wrapper instances user_proj_example (the Caravel counter).
caravel_core instances that wrapper, chip_io is the padframe.
simple_por instances device cells from primitives/ (resistor, FETs, MIM caps).

Not in these repositories as .mag:
  RAM128 (management SRAM, three instances in caravel_core)

Stdcells (sky130_fd_sc_hd) and IO pads (sky130_fd_io, sky130_ef_io)
come from the imported sky130A PDK when Magic writes GDS.
Downloaded: $(date -u +%Y-%m-%dT%H:%M:%SZ)
EOF

echo "installed harness Magic tree in $dest"
ok
