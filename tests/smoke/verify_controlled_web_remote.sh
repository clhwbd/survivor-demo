#!/usr/bin/env sh
set -eu

if [ "$#" -ne 1 ]; then
  echo "usage: $0 <base-url>" >&2
  exit 1
fi

BASE_URL="$1"
BASE_URL="${BASE_URL%/}"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT INT TERM

log() {
  printf '\n[%s] %s\n' "verify-controlled-web-remote" "$1"
}

require_text() {
  file="$1"
  needle="$2"
  if ! grep -F "$needle" "$file" >/dev/null 2>&1; then
    echo "missing text '$needle' in $file" >&2
    exit 1
  fi
}

fetch_headers() {
  out="$1"
  shift
  curl -fsS -D "$out" -o /dev/null "$@"
}

HTML_HEADERS="$TMP_DIR/index-html.headers"
WASM_HEADERS="$TMP_DIR/index-wasm.headers"
JS_HEADERS="$TMP_DIR/index-js.headers"
PCK_HEADERS="$TMP_DIR/index-pck.headers"
OPTIONS_HEADERS="$TMP_DIR/options.headers"

log "checking health endpoint"
curl -fsS "$BASE_URL/healthz" | grep -F 'ok' >/dev/null

log "checking index.html headers"
fetch_headers "$HTML_HEADERS" -I "$BASE_URL/index.html"
require_text "$HTML_HEADERS" '200'
require_text "$HTML_HEADERS" 'Cache-Control: no-cache, max-age=0, must-revalidate'

log "checking runtime asset headers"
fetch_headers "$WASM_HEADERS" -I -H 'Accept-Encoding: gzip' "$BASE_URL/index.wasm"
require_text "$WASM_HEADERS" '200'
require_text "$WASM_HEADERS" 'Content-Type: application/wasm'
require_text "$WASM_HEADERS" 'Content-Encoding: gzip'
require_text "$WASM_HEADERS" 'Vary: Accept-Encoding'
require_text "$WASM_HEADERS" 'Cache-Control: public, max-age=600, must-revalidate'

fetch_headers "$JS_HEADERS" -I -H 'Accept-Encoding: gzip' "$BASE_URL/index.js"
require_text "$JS_HEADERS" '200'
require_text "$JS_HEADERS" 'Content-Encoding: gzip'
require_text "$JS_HEADERS" 'Cache-Control: public, max-age=600, must-revalidate'

fetch_headers "$PCK_HEADERS" -I -H 'Accept-Encoding: gzip' "$BASE_URL/index.pck"
require_text "$PCK_HEADERS" '200'
require_text "$PCK_HEADERS" 'Content-Encoding: gzip'
require_text "$PCK_HEADERS" 'Cache-Control: public, max-age=600, must-revalidate'

log "checking CORS preflight"
fetch_headers "$OPTIONS_HEADERS" -X OPTIONS "$BASE_URL/index.wasm"
require_text "$OPTIONS_HEADERS" '204'
require_text "$OPTIONS_HEADERS" 'Access-Control-Allow-Origin: *'
require_text "$OPTIONS_HEADERS" 'Access-Control-Allow-Methods: GET, HEAD, OPTIONS'
require_text "$OPTIONS_HEADERS" 'Access-Control-Allow-Headers: Content-Type, Range'

log "remote controlled-web checks passed"
