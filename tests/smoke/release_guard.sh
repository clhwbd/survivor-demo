#!/usr/bin/env sh
set -eu

ROOT="$(CDPATH= cd -- "$(dirname "$0")/../.." && pwd)"
GAME_DIR="$ROOT/game"
WEB_RELEASE_DIR="$ROOT/builds/web-release"
WEB_COMPRESSED_DIR="$ROOT/builds/web"
GODOT_BIN="${GODOT_BIN:-/Applications/Godot.app/Contents/MacOS/Godot}"
RELEASE_PORT="${RELEASE_PORT:-18081}"
COMPRESSED_PORT="${COMPRESSED_PORT:-18082}"
CORE_FILES="index.html index.js index.wasm index.pck"
README_FILES="$ROOT/README.md $ROOT/docs/status.md $ROOT/docs/release-acceptance.md $ROOT/docs/deployment-plan.md"
SMOKE_README="$ROOT/tests/smoke/README.md"
NGINX_TEMPLATE="$ROOT/docs/deployment/nginx-web-release.conf"
RELEASE_PID=""
COMPRESSED_PID=""

cleanup() {
  if [ -n "$RELEASE_PID" ] && kill -0 "$RELEASE_PID" 2>/dev/null; then
    kill "$RELEASE_PID" 2>/dev/null || true
    wait "$RELEASE_PID" 2>/dev/null || true
  fi
  if [ -n "$COMPRESSED_PID" ] && kill -0 "$COMPRESSED_PID" 2>/dev/null; then
    kill "$COMPRESSED_PID" 2>/dev/null || true
    wait "$COMPRESSED_PID" 2>/dev/null || true
  fi
}
trap cleanup EXIT INT TERM

log() {
  printf '\n[%s] %s\n' "release-guard" "$1"
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

log "checking required files"
require_file "$GODOT_BIN"
require_file "$GAME_DIR/project.godot"
require_file "$WEB_COMPRESSED_DIR/serve_compressed.py"
require_file "$ROOT/docs/release-minimum-checklist.md"
require_file "$NGINX_TEMPLATE"
require_file "$SMOKE_README"

for file in $README_FILES; do
  require_file "$file"
  require_text "$file" "builds/web-release/"
done
require_text "$ROOT/docs/release-minimum-checklist.md" 'tests/smoke/release_guard.sh'
require_text "$ROOT/docs/deployment-plan.md" 'docs/deployment/nginx-web-release.conf'
require_text "$SMOKE_README" 'release_guard.sh'
require_text "$SMOKE_README" 'builds/web-release/'
require_text "$SMOKE_README" 'builds/web/'
require_text "$NGINX_TEMPLATE" 'root /srv/survivor-demo/builds/web-release;'
require_text "$NGINX_TEMPLATE" 'location = /index.html'
require_text "$NGINX_TEMPLATE" 'default_type application/wasm;'
require_text "$NGINX_TEMPLATE" 'Cache-Control "no-cache, max-age=0, must-revalidate"'

log "headless load main scene"
"$GODOT_BIN" --headless --path "$GAME_DIR" --scene res://scenes/main.tscn --quit-after 3 >/tmp/survivor-release-guard-scene.log 2>&1

log "exporting web release"
EXPORT_STARTED_AT=$(date +%s)
"$GODOT_BIN" --headless --path "$GAME_DIR" --export-release Web "$WEB_RELEASE_DIR/index.html" >/tmp/survivor-release-guard-export.log 2>&1

for file in $CORE_FILES; do
  require_file "$WEB_RELEASE_DIR/$file"
  FILE_MTIME=$(stat -f %m "$WEB_RELEASE_DIR/$file")
  if [ "$FILE_MTIME" -lt "$EXPORT_STARTED_AT" ]; then
    echo "stale export artifact: $WEB_RELEASE_DIR/$file" >&2
    exit 1
  fi
done

log "serving web-release and checking core files"
cd "$WEB_RELEASE_DIR"
python3 -m http.server "$RELEASE_PORT" >/tmp/survivor-release-guard-http.log 2>&1 &
RELEASE_PID=$!
wait_http "http://127.0.0.1:$RELEASE_PORT/index.html"
for file in $CORE_FILES; do
  code=$(curl -s -o /dev/null -w '%{http_code}' -I "http://127.0.0.1:$RELEASE_PORT/$file")
  if [ "$code" != "200" ]; then
    echo "unexpected status for $file: $code" >&2
    exit 1
  fi
done

log "serving compressed web build and checking gzip + HEAD"
cd "$WEB_COMPRESSED_DIR"
PORT="$COMPRESSED_PORT" python3 serve_compressed.py >/tmp/survivor-release-guard-compressed.log 2>&1 &
COMPRESSED_PID=$!
wait_http "http://127.0.0.1:$COMPRESSED_PORT/index.html"

HEADERS_FILE=$(mktemp)
BODY_HEADERS_FILE=$(mktemp)
trap 'rm -f "$HEADERS_FILE" "$BODY_HEADERS_FILE"; cleanup' EXIT INT TERM

curl -sS -D "$HEADERS_FILE" -o /dev/null -I -H 'Accept-Encoding: gzip' "http://127.0.0.1:$COMPRESSED_PORT/index.wasm"
require_text "$HEADERS_FILE" 'HTTP/1.0 200 OK'
require_text "$HEADERS_FILE" 'Content-Encoding: gzip'
require_text "$HEADERS_FILE" 'Vary: Accept-Encoding'
require_text "$HEADERS_FILE" 'Content-Type: application/wasm'

curl -sS -D "$BODY_HEADERS_FILE" -o /dev/null -H 'Accept-Encoding: gzip' "http://127.0.0.1:$COMPRESSED_PORT/index.wasm"
require_text "$BODY_HEADERS_FILE" 'HTTP/1.0 200 OK'
require_text "$BODY_HEADERS_FILE" 'Content-Encoding: gzip'
require_text "$BODY_HEADERS_FILE" 'Vary: Accept-Encoding'
require_text "$BODY_HEADERS_FILE" 'Content-Type: application/wasm'

log "all release checks passed"
