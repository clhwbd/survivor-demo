#!/usr/bin/env sh
set -eu

ROOT="$(CDPATH= cd -- "$(dirname "$0")/../.." && pwd)"
WEB_RELEASE_DIR="$ROOT/builds/web-release"
WEB_COMPRESSED_DIR="$ROOT/builds/web"
PAGES_DIR="$ROOT/builds/pages-deploy"
RAW_FILES="index.html index.png"
GZIP_FILES="index.js index.wasm index.pck index.audio.worklet.js index.audio.position.worklet.js"

log() {
  printf '\n[%s] %s\n' "sync-pages-build" "$1"
}

require_file() {
  if [ ! -f "$1" ]; then
    echo "missing file: $1" >&2
    exit 1
  fi
}

mkdir -p "$PAGES_DIR"

log "checking source artifacts"
for file in $RAW_FILES; do
  require_file "$WEB_RELEASE_DIR/$file"
done
for file in $GZIP_FILES; do
  require_file "$WEB_COMPRESSED_DIR/$file.gz"
done

log "syncing raw page shell assets"
for file in $RAW_FILES; do
  cp "$WEB_RELEASE_DIR/$file" "$PAGES_DIR/$file"
done

log "syncing precompressed runtime assets for Cloudflare Pages"
for file in $GZIP_FILES; do
  cp "$WEB_COMPRESSED_DIR/$file.gz" "$PAGES_DIR/$file"
done

log "writing Pages headers"
cat > "$PAGES_DIR/_headers" <<'EOF'
/index.wasm
  Content-Type: application/wasm
  Content-Encoding: gzip
  Cache-Control: public, max-age=600, must-revalidate

/index.js
  Content-Type: application/javascript; charset=utf-8
  Content-Encoding: gzip
  Cache-Control: public, max-age=600, must-revalidate

/index.pck
  Content-Type: application/octet-stream
  Content-Encoding: gzip
  Cache-Control: public, max-age=600, must-revalidate

/index.audio.worklet.js
  Content-Type: application/javascript; charset=utf-8
  Content-Encoding: gzip
  Cache-Control: public, max-age=600, must-revalidate

/index.audio.position.worklet.js
  Content-Type: application/javascript; charset=utf-8
  Content-Encoding: gzip
  Cache-Control: public, max-age=600, must-revalidate

/index.html
  Cache-Control: no-cache, max-age=0, must-revalidate
EOF

log "Pages deploy directory is now aligned with the current compressed delivery build"
