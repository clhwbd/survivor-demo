#!/usr/bin/env sh
set -eu

ROOT="$(CDPATH= cd -- "$(dirname "$0")/../.." && pwd)"
WEB_RELEASE_DIR="$ROOT/builds/web-release"
WEB_COMPRESSED_DIR="$ROOT/builds/web"
PAGES_DIR="$ROOT/builds/pages-deploy"
SYNC_SCRIPT="$ROOT/tests/smoke/sync_pages_build.sh"
PAGES_PORT="${PAGES_PORT:-18083}"
RAW_FILES="index.html index.png"
GZIP_FILES="index.js index.wasm index.pck index.audio.worklet.js index.audio.position.worklet.js"
CORE_FILES="index.html index.js index.wasm index.pck index.png index.audio.worklet.js index.audio.position.worklet.js"
PAGES_PID=""

cleanup() {
  if [ -n "$PAGES_PID" ] && kill -0 "$PAGES_PID" 2>/dev/null; then
    kill "$PAGES_PID" 2>/dev/null || true
    wait "$PAGES_PID" 2>/dev/null || true
  fi
}
trap cleanup EXIT INT TERM

log() {
  printf '\n[%s] %s\n' "pages-release-guard" "$1"
}

require_file() {
  if [ ! -f "$1" ]; then
    echo "missing file: $1" >&2
    exit 1
  fi
}

require_text() {
  file="$1"
  needle="$2"
  if ! grep -F "$needle" "$file" >/dev/null 2>&1; then
    echo "missing text '$needle' in $file" >&2
    exit 1
  fi
}

wait_http() {
  url="$1"
  attempt=0
  while [ "$attempt" -lt 20 ]; do
    if curl -fsS "$url" >/dev/null 2>&1; then
      return 0
    fi
    attempt=$((attempt + 1))
    sleep 0.3
  done
  echo "server did not become ready: $url" >&2
  exit 1
}

is_supported_macos_for_pages_dev() {
  if [ "$(uname -s)" != "Darwin" ]; then
    return 0
  fi
  version="$(sw_vers -productVersion 2>/dev/null || printf '0.0.0')"
  major="$(printf '%s' "$version" | cut -d. -f1)"
  minor="$(printf '%s' "$version" | cut -d. -f2)"
  if [ "$major" -gt 13 ]; then
    return 0
  fi
  if [ "$major" -eq 13 ] && [ "$minor" -ge 5 ]; then
    return 0
  fi
  return 1
}

log "syncing Pages deploy directory"
chmod +x "$SYNC_SCRIPT"
"$SYNC_SCRIPT"

for file in $RAW_FILES; do
  require_file "$PAGES_DIR/$file"
  if ! cmp -s "$WEB_RELEASE_DIR/$file" "$PAGES_DIR/$file"; then
    echo "pages raw asset drifted from web-release: $file" >&2
    exit 1
  fi
done

log "verifying precompressed runtime assets"
python3 - <<'PY' "$WEB_COMPRESSED_DIR" "$PAGES_DIR" "$GZIP_FILES"
import sys
from pathlib import Path

web_dir = Path(sys.argv[1])
pages_dir = Path(sys.argv[2])
files = sys.argv[3].split()
for name in files:
    src = web_dir / f"{name}.gz"
    dst = pages_dir / name
    if src.read_bytes() != dst.read_bytes():
        raise SystemExit(f"pages asset drifted from compressed build: {name}")
    if dst.read_bytes()[:2] != b"\x1f\x8b":
        raise SystemExit(f"pages asset is not gzip encoded: {name}")
PY

log "checking Pages headers"
require_file "$PAGES_DIR/_headers"
require_text "$PAGES_DIR/_headers" '/index.wasm'
require_text "$PAGES_DIR/_headers" 'Content-Type: application/wasm'
require_text "$PAGES_DIR/_headers" 'Content-Encoding: gzip'
require_text "$PAGES_DIR/_headers" '/index.audio.worklet.js'
require_text "$PAGES_DIR/_headers" '/index.audio.position.worklet.js'
require_text "$PAGES_DIR/_headers" 'Cache-Control: no-cache, max-age=0, must-revalidate'

log "serving pages-deploy with a static server for file presence checks"
cd "$PAGES_DIR"
python3 -m http.server "$PAGES_PORT" >/tmp/survivor-pages-release-guard-http.log 2>&1 &
PAGES_PID=$!
wait_http "http://127.0.0.1:$PAGES_PORT/index.html"
for file in $CORE_FILES; do
  code=$(curl -s -o /dev/null -w '%{http_code}' -I "http://127.0.0.1:$PAGES_PORT/$file")
  if [ "$code" != "200" ]; then
    echo "unexpected status for pages asset $file: $code" >&2
    exit 1
  fi
done
kill "$PAGES_PID" >/dev/null 2>&1 || true
wait "$PAGES_PID" >/dev/null 2>&1 || true
PAGES_PID=""

if is_supported_macos_for_pages_dev; then
  log "attempting wrangler pages dev header preview"
  npx wrangler pages dev "$PAGES_DIR" --port "$PAGES_PORT" --compatibility-date=2026-03-20 >/tmp/survivor-pages-release-guard-wrangler.log 2>&1 &
  PAGES_PID=$!
  wait_http "http://127.0.0.1:$PAGES_PORT/index.html"
  HEADERS_FILE=$(mktemp)
  trap 'rm -f "$HEADERS_FILE"; cleanup' EXIT INT TERM
  curl -sS -D "$HEADERS_FILE" -o /dev/null -I -H 'Accept-Encoding: gzip' "http://127.0.0.1:$PAGES_PORT/index.wasm"
  require_text "$HEADERS_FILE" 'HTTP/1.1 200 OK'
  require_text "$HEADERS_FILE" 'Content-Encoding: gzip'
  require_text "$HEADERS_FILE" 'Content-Type: application/wasm'
  rm -f "$HEADERS_FILE"
  kill "$PAGES_PID" >/dev/null 2>&1 || true
  wait "$PAGES_PID" >/dev/null 2>&1 || true
  PAGES_PID=""
else
  log "skipping wrangler pages dev preview: local macOS is below Cloudflare workerd minimum (13.5+)"
fi

log "pages deploy checks passed"
