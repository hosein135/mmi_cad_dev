#!/usr/bin/env bash
# Download the published Caravel harness die (sky130A GDS).
#
# This is chipfoundry/caravel gds/caravel.gds.gz: padframe, management core,
# and the empty user-project wrapper. It is not example_por and it does not
# include a filled user project.
#
# Usage: fetch_caravel_die.sh DEST_DIR [STATUS_FILE] [CANCEL_FILE] [LOG_FILE]
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
  echo "usage: fetch_caravel_die.sh DEST_DIR [STATUS] [CANCEL] [LOG]"
  exit 1
fi

URL="${CARAVEL_DIE_URL:-https://github.com/chipfoundry/caravel/raw/main/gds/caravel.gds.gz}"
# Compressed object on GitHub is about 55 MB. Reject HTML error pages and
# truncated downloads. Uncompressed GDS is larger still.
MIN_GZ=40000000
MIN_GDS=20000000

st() {
  local pct="${1:-1}"
  local msg="${2:-Downloading Caravel die...}"
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
  st 100 "Caravel die ready" ok
  exit 0
}

if cancelled; then
  fail "Cancelled."
fi

mkdir -p "$dest" || fail "cannot create $dest"

gds="$dest/caravel.gds"
if [ -f "$gds" ]; then
  sz=$(wc -c < "$gds" 2>/dev/null | tr -d ' ')
  if [ "${sz:-0}" -ge "$MIN_GDS" ]; then
    st 100 "Using existing Caravel die ($sz bytes)" ok
    echo "already have $gds ($sz bytes)"
    exit 0
  fi
  echo "existing $gds is only ${sz:-0} bytes; downloading again"
fi

stage=$(mktemp -d /tmp/caravel_die_XXXXXX) || fail "mktemp failed"
trap 'rm -rf "$stage"' EXIT

st 5 "Downloading Caravel die from GitHub (about 55 MB)..."
echo "URL=$URL"
echo "dest=$dest"

archive="$stage/caravel.gds.gz"
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
if [ "${sz:-0}" -lt "$MIN_GZ" ]; then
  fail "download too small (${sz:-0} bytes); expected caravel.gds.gz"
fi

if ! gzip -t "$archive" 2>/dev/null; then
  fail "download is not a gzip file"
fi

st 60 "Uncompressing caravel.gds..."
tmp="$dest/caravel.gds.partial"
rm -f "$tmp"
gzip -dc "$archive" > "$tmp" || fail "gzip decompress failed"
sz=$(wc -c < "$tmp" 2>/dev/null | tr -d ' ')
echo "gds bytes=${sz:-0}"
if [ "${sz:-0}" -lt "$MIN_GDS" ]; then
  rm -f "$tmp"
  fail "uncompressed GDS too small (${sz:-0} bytes)"
fi
mv -f "$tmp" "$gds" || fail "could not install $gds"

cat > "$dest/SOURCE.txt" << EOF
Caravel harness die (downloaded)

Upstream:
  $URL
  https://github.com/chipfoundry/caravel
  path: gds/caravel.gds.gz
  license: Apache-2.0

Top cell: caravel
This is the padframe + management core + empty user_project_wrapper.
It is not example_por and not a filled user project.
Downloaded: $(date -u +%Y-%m-%dT%H:%M:%SZ)
EOF

echo "installed $gds"
ok
