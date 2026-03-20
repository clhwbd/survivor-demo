#!/usr/bin/env sh
set -eu

ROOT="$(CDPATH= cd -- "$(dirname "$0")/../.." && pwd)"
WEB_RELEASE_DIR="$ROOT/builds/web-release"
WEB_COMPRESSED_DIR="$ROOT/builds/web"
SYNC_FILES="index.html index.js index.wasm index.pck index.png index.audio.worklet.js index.audio.position.worklet.js"
GZIP_FILES="index.html index.js index.wasm index.pck index.audio.worklet.js index.audio.position.worklet.js"

log() {
  printf '\n[%s] %s\n' "sync-compressed-build" "$1"
}

require_file() {
  if [ ! -f "$1" ]; then
    echo "missing file: $1" >&2
    exit 1
  fi
}

log "checking release artifacts"
require_file "$WEB_COMPRESSED_DIR/serve_compressed.py"
for file in $SYNC_FILES; do
  require_file "$WEB_RELEASE_DIR/$file"
done

log "syncing shared files from builds/web-release/ to builds/web/"
for file in $SYNC_FILES; do
  cp "$WEB_RELEASE_DIR/$file" "$WEB_COMPRESSED_DIR/$file"
done

log "regenerating deterministic gzip assets"
WEB_COMPRESSED_DIR="$WEB_COMPRESSED_DIR" GZIP_FILES="$GZIP_FILES" python3 - <<'PY'
import gzip
import os
from pathlib import Path

root = Path(os.environ["WEB_COMPRESSED_DIR"])
for name in os.environ["GZIP_FILES"].split():
    src = root / name
    dst = root / f"{name}.gz"
    with src.open("rb") as rf, dst.open("wb") as raw, gzip.GzipFile(filename="", mode="wb", fileobj=raw, mtime=0) as wf:
        while True:
            chunk = rf.read(1024 * 1024)
            if not chunk:
                break
            wf.write(chunk)
PY

log "compressed delivery build is now aligned with builds/web-release/"