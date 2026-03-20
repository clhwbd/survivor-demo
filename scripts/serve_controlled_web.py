#!/usr/bin/env python3
from __future__ import annotations

from http.server import ThreadingHTTPServer, BaseHTTPRequestHandler
from pathlib import Path
from urllib.parse import unquote
import argparse
import hashlib
import mimetypes
import os

DEFAULT_ROOT = Path(__file__).resolve().parent.parent / "builds" / "web"
IMMUTABLE_EXTENSIONS = {
    ".js",
    ".wasm",
    ".pck",
    ".png",
}
WORKLET_NAMES = {
    "index.audio.worklet.js",
    "index.audio.position.worklet.js",
}


def build_etag(path: Path, size: int, mtime: int) -> str:
    token = f"{path.name}:{size}:{mtime}".encode("utf-8")
    return '"' + hashlib.sha1(token).hexdigest()[:16] + '"'


class ControlledStaticHandler(BaseHTTPRequestHandler):
    server_version = "SurvivorControlledWeb/1.0"

    def do_GET(self) -> None:
        self._serve(send_body=True)

    def do_HEAD(self) -> None:
        self._serve(send_body=False)

    def do_OPTIONS(self) -> None:
        self.send_response(204)
        self._send_common_headers()
        self.send_header("Content-Length", "0")
        self.send_header("Content-Type", "text/plain; charset=utf-8")
        self.end_headers()

    def _serve(self, send_body: bool) -> None:
        root = Path(self.server.root)
        rel = unquote(self.path.split("?", 1)[0].split("#", 1)[0])
        if rel in {"", "/"}:
            rel = "/index.html"
        if rel == "/healthz":
            payload = b"ok\n"
            self.send_response(200)
            self._send_common_headers()
            self.send_header("Content-Type", "text/plain; charset=utf-8")
            self.send_header("Cache-Control", "no-cache, max-age=0, must-revalidate")
            self.send_header("Content-Length", str(len(payload)))
            self.end_headers()
            if send_body:
                self.wfile.write(payload)
            return

        requested = (root / rel.lstrip("/")).resolve()
        try:
            requested.relative_to(root)
        except ValueError:
            self.send_error(403)
            return
        if not requested.exists() or requested.is_dir():
            self.send_error(404)
            return

        accept_encoding = self.headers.get("Accept-Encoding", "")
        gzip_path = requested.with_name(requested.name + ".gz")
        use_gzip = gzip_path.exists() and "gzip" in accept_encoding.lower()
        served_path = gzip_path if use_gzip else requested
        stat = served_path.stat()

        content_type, _ = mimetypes.guess_type(str(requested))
        if requested.name.endswith(".wasm"):
            content_type = "application/wasm"
        elif requested.name.endswith(".pck"):
            content_type = "application/octet-stream"
        elif content_type is None:
            content_type = "application/octet-stream"

        etag = build_etag(served_path, stat.st_size, int(stat.st_mtime))
        if self.headers.get("If-None-Match") == etag:
            self.send_response(304)
            self._send_common_headers()
            self.send_header("ETag", etag)
            self.end_headers()
            return

        self.send_response(200)
        self._send_common_headers()
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(stat.st_size))
        self.send_header("ETag", etag)
        self.send_header("Cache-Control", self._cache_control_for(requested))
        if use_gzip:
            self.send_header("Content-Encoding", "gzip")
            self.send_header("Vary", "Accept-Encoding")
        self.end_headers()

        if send_body:
            with served_path.open("rb") as handle:
                while True:
                    chunk = handle.read(1024 * 1024)
                    if not chunk:
                        break
                    self.wfile.write(chunk)

    def _send_common_headers(self) -> None:
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, HEAD, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type, Range")
        self.send_header("Cross-Origin-Resource-Policy", "cross-origin")

    def _cache_control_for(self, requested: Path) -> str:
        if requested.name == "index.html":
            return "no-cache, max-age=0, must-revalidate"
        if requested.name in WORKLET_NAMES or requested.suffix in IMMUTABLE_EXTENSIONS:
            return "public, max-age=600, must-revalidate"
        return "public, max-age=300, must-revalidate"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Serve survivor-demo controlled web release with explicit gzip/MIME/cache/CORS headers.")
    parser.add_argument("--root", default=str(DEFAULT_ROOT), help="Directory to serve (default: builds/web)")
    parser.add_argument("--port", type=int, default=int(os.environ.get("PORT", "18084")), help="Port to listen on")
    parser.add_argument("--host", default=os.environ.get("HOST", "0.0.0.0"), help="Host to bind")
    return parser.parse_args()


if __name__ == "__main__":
    args = parse_args()
    root = Path(args.root).resolve()
    if not root.exists():
        raise SystemExit(f"missing root directory: {root}")
    server = ThreadingHTTPServer((args.host, args.port), ControlledStaticHandler)
    server.root = str(root)
    print(f"Serving controlled web release from {root} on http://{args.host}:{args.port}")
    server.serve_forever()
