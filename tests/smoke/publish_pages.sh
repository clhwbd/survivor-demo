#!/usr/bin/env sh
set -eu

ROOT="$(CDPATH= cd -- "$(dirname "$0")/../.." && pwd)"
PROJECT_NAME="${CF_PAGES_PROJECT:-survivor-demo}"
WRANGLER_BIN="${WRANGLER_BIN:-npx wrangler}"
COMMIT_DIRTY_FLAG="${CF_PAGES_COMMIT_DIRTY:-true}"

log() {
  printf '\n[%s] %s\n' "publish-pages" "$1"
}

cd "$ROOT"

log "syncing Pages deploy directory"
chmod +x tests/smoke/sync_pages_build.sh tests/smoke/pages_release_guard.sh
./tests/smoke/sync_pages_build.sh

log "running Pages release guard"
./tests/smoke/pages_release_guard.sh

log "deploying builds/pages-deploy to Cloudflare Pages project: $PROJECT_NAME"
$WRANGLER_BIN pages deploy builds/pages-deploy --project-name "$PROJECT_NAME" --commit-dirty="$COMMIT_DIRTY_FLAG"

log "done"
log "stable URL: https://$PROJECT_NAME.pages.dev"
