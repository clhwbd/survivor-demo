#!/usr/bin/env python3
from http.server import ThreadingHTTPServer, BaseHTTPRequestHandler
from urllib.parse import unquote
import os
import mimetypes

ROOT = os.path.dirname(os.path.abspath(__file__))


class CompressedHandler(BaseHTTPRequestHandler):
    def _serve(self, send_body: bool) -> None:
        rel = unquote(self.path.split('?', 1)[0].split('#', 1)[0])
        if rel == '/':
            rel = '/index.html'
        full = os.path.normpath(os.path.join(ROOT, rel.lstrip('/')))
        if not full.startswith(ROOT):
            self.send_error(403)
            return
        if not os.path.exists(full) or os.path.isdir(full):
            self.send_error(404)
            return

        accept = self.headers.get('Accept-Encoding', '')
        use_gzip = os.path.exists(full + '.gz') and 'gzip' in accept
        serve_path = full + '.gz' if use_gzip else full
        size = os.path.getsize(serve_path)

        ctype, _ = mimetypes.guess_type(full)
        if full.endswith('.wasm'):
            ctype = 'application/wasm'
        elif full.endswith('.pck'):
            ctype = 'application/octet-stream'
        elif ctype is None:
            ctype = 'application/octet-stream'

        self.send_response(200)
        self.send_header('Content-Type', ctype)
        self.send_header('Content-Length', str(size))
        self.send_header('Cache-Control', 'public, max-age=300')
        if use_gzip:
            self.send_header('Content-Encoding', 'gzip')
            self.send_header('Vary', 'Accept-Encoding')
        self.end_headers()

        if send_body:
            with open(serve_path, 'rb') as f:
                self.wfile.write(f.read())

    def do_GET(self):
        self._serve(send_body=True)

    def do_HEAD(self):
        self._serve(send_body=False)


if __name__ == '__main__':
    port = int(os.environ.get('PORT', '8000'))
    server = ThreadingHTTPServer(('0.0.0.0', port), CompressedHandler)
    print(f'Serving compressed web build on http://0.0.0.0:{port}')
    server.serve_forever()
