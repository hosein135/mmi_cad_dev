#!/usr/bin/env bash
# Download Efabless caravel_user_project_analog Mag layouts (sky130A sample).
#
# Usage: fetch_caravel_mag.sh DEST_DIR [STATUS_FILE] [CANCEL_FILE] [LOG_FILE]
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
  echo "usage: fetch_caravel_mag.sh DEST_DIR [STATUS] [CANCEL] [LOG]"
  exit 1
fi

URL="${CARAVEL_MAG_URL:-https://github.com/efabless/caravel_user_project_analog/archive/refs/heads/main.tar.gz}"

st() {
  local pct="${1:-1}"
  local msg="${2:-Downloading Caravel Mag sample...}"
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
  st 100 "Caravel Mag sample ready" ok
  exit 0
}

if cancelled; then
  fail "Cancelled."
fi

# Already present?
if [ -f "$dest/example_por.mag" ] || [ -f "$dest/simple_por.mag" ]; then
  n=$(find "$dest" -maxdepth 1 -name '*.mag' 2>/dev/null | wc -l | tr -d ' ')
  if [ "${n:-0}" -ge 3 ]; then
    st 100 "Using existing Caravel Mag sample ($n files)" ok
    echo "already have $dest ($n mag files)"
    exit 0
  fi
fi

mkdir -p "$dest" || fail "cannot create $dest"

# Prefer copying the bundled sample (no network) when present.
seed=""
for d in \
  /mmi-pdk-live/samples/caravel_analog_por \
  /mmi-bundle/samples/caravel_analog_por \
  /mmi-home/cad/mmi_local/max/pdk/samples/caravel_analog_por
do
  if [ -f "$d/example_por.mag" ] || [ -f "$d/simple_por.mag" ]; then
    seed="$d"
    break
  fi
done

if [ -n "$seed" ] && [ "$seed" != "$dest" ]; then
  st 30 "Installing bundled Caravel Mag sample..."
  echo "seeding from $seed"
  cp -f "$seed"/*.mag "$dest/" 2>/dev/null || true
  if [ -f "$seed/SOURCE.txt" ]; then
    cp -f "$seed/SOURCE.txt" "$dest/" 2>/dev/null || true
  fi
  if [ ! -f "$dest/example_por.mag" ] && [ -f "$dest/simple_por.mag" ]; then
    cp -f "$dest/simple_por.mag" "$dest/example_por.mag"
  fi
  n=$(find "$dest" -maxdepth 1 -name '*.mag' 2>/dev/null | wc -l | tr -d ' ')
  echo "seeded $n mag files"
  if [ -f "$dest/example_por.mag" ] || [ -f "$dest/simple_por.mag" ]; then
    if [ "${n:-0}" -ge 1 ]; then
      ok
    fi
  fi
fi

stage=$(mktemp -d /tmp/caravel_mag_XXXXXX) || fail "mktemp failed"
trap 'rm -rf "$stage"' EXIT

st 5 "Downloading Caravel Mag sample from GitHub..."
echo "URL=$URL"
echo "dest=$dest"

archive="$stage/caravel_analog.tar.gz"
if command -v curl >/dev/null 2>&1; then
  curl -L --fail --retry 2 -o "$archive" "$URL" || fail "curl download failed"
elif command -v wget >/dev/null 2>&1; then
  wget -O "$archive" "$URL" || fail "wget download failed"
else
  fail "need curl or wget"
fi

if cancelled; then
  fail "Cancelled."
fi

sz=$(wc -c < "$archive" 2>/dev/null | tr -d ' ')
echo "archive bytes=${sz:-0}"
if [ "${sz:-0}" -lt 1000 ]; then
  fail "download too small (${sz:-0} bytes)"
fi

st 40 "Unpacking Mag layouts..."
mkdir -p "$stage/unpack"
tar -xzf "$archive" -C "$stage/unpack" || fail "tar extract failed"

magdir=""
for d in "$stage/unpack"/*/mag "$stage/unpack"/mag; do
  if [ -d "$d" ]; then
    magdir="$d"
    break
  fi
done
if [ -z "$magdir" ]; then
  # fallback: any directory with example_por.mag / simple_por.mag
  magdir=$(find "$stage/unpack" -type f \( -name 'example_por.mag' -o -name 'simple_por.mag' \) 2>/dev/null | head -1)
  if [ -n "$magdir" ]; then
    magdir=$(dirname "$magdir")
  fi
fi
if [ -z "$magdir" ] || [ ! -d "$magdir" ]; then
  fail "no mag/ folder in archive"
fi
echo "magdir=$magdir"
ls -la "$magdir" | head -40

st 70 "Installing Mag files into $dest..."
# Copy every .mag under magdir (not only top-level glob — safer if layout differs).
find "$magdir" -maxdepth 1 -type f -name '*.mag' -exec cp -f {} "$dest/" \;
# Prefer the POR + leaf devices; also keep user_analog_proj_example.
n=$(find "$dest" -maxdepth 1 -name '*.mag' 2>/dev/null | wc -l | tr -d ' ')
if [ "${n:-0}" -lt 1 ]; then
  fail "copy .mag failed (0 files from $magdir)"
fi
# Upstream historically used simple_por; our importer expects example_por.
if [ ! -f "$dest/example_por.mag" ] && [ -f "$dest/simple_por.mag" ]; then
  cp -f "$dest/simple_por.mag" "$dest/example_por.mag"
  echo "aliased simple_por.mag -> example_por.mag"
fi

cat > "$dest/SOURCE.txt" << EOF
Caravel analog Mag sample (downloaded)

Upstream:
  $URL
  https://github.com/efabless/caravel_user_project_analog
  path: mag/
  license: Apache-2.0

Top cell: example_por
Downloaded: $(date -u +%Y-%m-%dT%H:%M:%SZ)
EOF

n=$(find "$dest" -maxdepth 1 -name '*.mag' 2>/dev/null | wc -l | tr -d ' ')
echo "installed $n mag files in $dest"
ls -la "$dest" | head -40

if [ ! -f "$dest/example_por.mag" ] && [ ! -f "$dest/simple_por.mag" ]; then
  fail "example_por.mag / simple_por.mag missing after install"
fi
if [ "${n:-0}" -lt 1 ]; then
  fail "no .mag files installed"
fi

ok
