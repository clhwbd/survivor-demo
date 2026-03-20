#!/usr/bin/env sh
set -eu

ROOT="$(CDPATH= cd -- "$(dirname "$0")/../.." && pwd)"
PORT="${CONTROLLED_PORT:-18084}"
SERVER_SCRIPT="$ROOT/scripts/serve_controlled_web.py"
NGINX_TEMPLATE="$ROOT/docs/deployment/nginx-web-controlled.conf"
PID=""

cleanup() {
  if [ -n "$PID" ] && kill -0 "$PID" 2>/dev/null; then
    kill "$PID" 2>/dev/null || true
    wait "$PID" 2>/dev/null || true
  fi
}
trap cleanup EXIT INT TERM

log() {
  printf '\n[%s] %s\n' "controlled-web-guard" "$1"
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

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"; cleanup' EXIT INT TERM

log "running base release guard first"
chmod +x "$ROOT/tests/smoke/release_guard.sh"
"$ROOT/tests/smoke/release_guard.sh"

log "checking controlled-hosting assets"
require_file "$SERVER_SCRIPT"
require_file "$NGINX_TEMPLATE"
require_text "$NGINX_TEMPLATE" 'root /srv/survivor-demo/builds/web;'
require_text "$NGINX_TEMPLATE" 'gzip_static on;'
require_text "$NGINX_TEMPLATE" 'application/wasm'
require_text "$NGINX_TEMPLATE" 'Access-Control-Allow-Origin "*" always;'
require_text "$NGINX_TEMPLATE" 'Cache-Control "no-cache, max-age=0, must-revalidate" always;'
require_text "$NGINX_TEMPLATE" 'Cache-Control "public, max-age=600, must-revalidate" always;'
require_text "$NGINX_TEMPLATE" 'location = /healthz'

log "serving controlled web release locally"
python3 "$SERVER_SCRIPT" --port "$PORT" >/tmp/survivor-controlled-web-guard.log 2>&1 &
PID=$!
wait_http "http://127.0.0.1:$PORT/healthz"

HTML_HEADERS="$TMP_DIR/html.headers"
WASM_HEADERS="$TMP_DIR/wasm.headers"
PCK_HEADERS="$TMP_DIR/pck.headers"
JS_HEADERS="$TMP_DIR/js.headers"
OPTIONS_HEADERS="$TMP_DIR/options.headers"

curl -sS -D "$HTML_HEADERS" -o /dev/null -I "http://127.0.0.1:$PORT/index.html"
require_text "$HTML_HEADERS" 'HTTP/1.0 200 OK'
require_text "$HTML_HEADERS" 'Cache-Control: no-cache, max-age=0, must-revalidate'
require_text "$HTML_HEADERS" 'Access-Control-Allow-Origin: *'

curl -sS -D "$WASM_HEADERS" -o /dev/null -I -H 'Accept-Encoding: gzip' "http://127.0.0.1:$PORT/index.wasm"
require_text "$WASM_HEADERS" 'HTTP/1.0 200 OK'
require_text "$WASM_HEADERS" 'Content-Type: application/wasm'
require_text "$WASM_HEADERS" 'Content-Encoding: gzip'
require_text "$WASM_HEADERS" 'Vary: Accept-Encoding'
require_text "$WASM_HEADERS" 'Cache-Control: public, max-age=600, must-revalidate'
require_text "$WASM_HEADERS" 'Access-Control-Allow-Origin: *'

curl -sS -D "$PCK_HEADERS" -o /dev/null -I -H 'Accept-Encoding: gzip' "http://127.0.0.1:$PORT/index.pck"
require_text "$PCK_HEADERS" 'HTTP/1.0 200 OK'
require_text "$PCK_HEADERS" 'Content-Type: application/octet-stream'
require_text "$PCK_HEADERS" 'Content-Encoding: gzip'
require_text "$PCK_HEADERS" 'Cache-Control: public, max-age=600, must-revalidate'

curl -sS -D "$JS_HEADERS" -o /dev/null -I -H 'Accept-Encoding: gzip' "http://127.0.0.1:$PORT/index.js"
require_text "$JS_HEADERS" 'HTTP/1.0 200 OK'
require_text "$JS_HEADERS" 'Content-Encoding: gzip'
require_text "$JS_HEADERS" 'Cache-Control: public, max-age=600, must-revalidate'

curl -sS -D "$OPTIONS_HEADERS" -o /dev/null -X OPTIONS "http://127.0.0.1:$PORT/index.wasm"
require_text "$OPTIONS_HEADERS" 'HTTP/1.0 204 No Content'
require_text "$OPTIONS_HEADERS" 'Access-Control-Allow-Origin: *'
require_text "$OPTIONS_HEADERS" 'Access-Control-Allow-Methods: GET, HEAD, OPTIONS'
require_text "$OPTIONS_HEADERS" 'Access-Control-Allow-Headers: Content-Type, Range'

curl -fsS "http://127.0.0.1:$PORT/healthz" | grep -F 'ok' >/dev/null

log "controlled hosting checks passed"
