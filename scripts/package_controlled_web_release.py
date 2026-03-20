#!/usr/bin/env python3
from __future__ import annotations

import argparse
import hashlib
import io
import tarfile
from datetime import datetime
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
WEB_DIR = ROOT / 'builds' / 'web'
VERIFY_SCRIPT = ROOT / 'tests' / 'smoke' / 'verify_controlled_web_remote.sh'
NGINX_TEMPLATE = ROOT / 'docs' / 'deployment' / 'nginx-web-controlled.conf'
OUTPUT_DIR = ROOT / 'artifacts' / 'controlled-web-delivery'

INCLUDE_FILES = [
    Path('builds/web'),
    Path('docs/deployment/nginx-web-controlled.conf'),
    Path('tests/smoke/verify_controlled_web_remote.sh'),
]


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open('rb') as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b''):
            digest.update(chunk)
    return digest.hexdigest()


def build_manifest() -> str:
    files = [
        WEB_DIR / 'index.html',
        WEB_DIR / 'index.js',
        WEB_DIR / 'index.js.gz',
        WEB_DIR / 'index.wasm',
        WEB_DIR / 'index.wasm.gz',
        WEB_DIR / 'index.pck',
        WEB_DIR / 'index.pck.gz',
        WEB_DIR / 'index.audio.worklet.js',
        WEB_DIR / 'index.audio.worklet.js.gz',
        WEB_DIR / 'index.audio.position.worklet.js',
        WEB_DIR / 'index.audio.position.worklet.js.gz',
        WEB_DIR / 'index.png',
        VERIFY_SCRIPT,
        NGINX_TEMPLATE,
    ]
    lines = ['# survivor-demo controlled web delivery manifest', '']
    for path in files:
        if not path.exists():
            raise SystemExit(f'missing required file for package: {path}')
        size = path.stat().st_size
        lines.append(f'{path.relative_to(ROOT)}\t{size}\tsha256={sha256(path)}')
    lines.append('')
    return '\n'.join(lines)


def build_readme(package_name: str) -> str:
    return f'''# survivor-demo controlled web delivery bundle

## Bundle
- package: `{package_name}`
- created_at: `{datetime.now().astimezone().isoformat(timespec="seconds")}`

## What to upload
1. Upload `builds/web/` to the target machine, for example `/srv/survivor-demo/builds/web/`
2. Copy `docs/deployment/nginx-web-controlled.conf` to `/etc/nginx/conf.d/survivor-demo.conf`
3. Adjust `server_name` in that nginx config
4. Run `sudo nginx -t && sudo systemctl reload nginx`

## Live verification
After the site is reachable, run:

```bash
./tests/smoke/verify_controlled_web_remote.sh https://your-domain
```

That script checks:
- `/healthz`
- `index.html` no-cache policy
- `index.wasm` gzip + `application/wasm`
- `index.js` / `index.pck` gzip headers
- CORS / OPTIONS

## Shortest stable delivery path
- Preferred primary path: self-hosted Nginx static site serving `builds/web/`
- If you only need a handoff bundle, this tarball is the shortest reproducible package
- If you must troubleshoot a live external link, verify headers first instead of only checking `200 OK`
'''


def create_package(output: Path) -> None:
    output.parent.mkdir(parents=True, exist_ok=True)
    manifest = build_manifest()
    package_name = output.name
    staging_files = {
        Path('DELIVERY_README.md'): build_readme(package_name).encode('utf-8'),
        Path('manifest-sha256.txt'): manifest.encode('utf-8'),
    }
    with tarfile.open(output, 'w:gz') as archive:
        for rel_path in INCLUDE_FILES:
            src = ROOT / rel_path
            if src.is_dir():
                for file in sorted(src.rglob('*')):
                    if file.is_file():
                        archive.add(file, arcname=str(file.relative_to(ROOT)))
            else:
                archive.add(src, arcname=str(rel_path))
        for rel_path, payload in staging_files.items():
            info = tarfile.TarInfo(str(rel_path))
            info.size = len(payload)
            info.mtime = int(datetime.now().timestamp())
            archive.addfile(info, fileobj=io.BytesIO(payload))


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description='Package the controlled web delivery bundle for handoff.')
    parser.add_argument('--output', help='Output tar.gz path. Defaults to artifacts/controlled-web-delivery/survivor-demo-controlled-web-<timestamp>.tar.gz')
    return parser.parse_args()


if __name__ == '__main__':
    args = parse_args()
    if args.output:
        output = Path(args.output).expanduser().resolve()
    else:
        stamp = datetime.now().strftime('%Y%m%d-%H%M%S')
        output = (OUTPUT_DIR / f'survivor-demo-controlled-web-{stamp}.tar.gz').resolve()
    create_package(output)
    print(output)
