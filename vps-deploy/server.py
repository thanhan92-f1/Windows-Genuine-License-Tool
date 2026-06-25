#!/usr/bin/env python3
"""
VPS Script Server - Pho Tue SoftWare Solutions JSC
Serve PowerShell script cho clients Windows
Khong can Nginx, chi can Python 3.6+
"""

import os
import sys
import signal
from http.server import HTTPServer, BaseHTTPRequestHandler
from datetime import datetime

# ============================================================
#  CAU HINH
# ============================================================
PORT = int(os.environ.get("PORT", 8888))
SCRIPT_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "scripts")
DEFAULT_SCRIPT = "Windows_License_Cleanup.ps1"
DOMAIN = "irm-genuine-license-windows.hitechcloud.vn"

# ============================================================
#  REQUEST HANDLER
# ============================================================
class ScriptHandler(BaseHTTPRequestHandler):
    def log_message(self, format, *args):
        timestamp = datetime.now().strftime("%H:%M:%S")
        sys.stdout.write(f"  [{timestamp}] {self.address_string()} - {format % args}\n")
        sys.stdout.flush()

    def do_GET(self):
        path = self.path.lstrip("/").split("?")[0]

        # Root URL -> serve script chinh
        if path == "" or path == "index":
            script_path = os.path.join(SCRIPT_DIR, DEFAULT_SCRIPT)
            if os.path.exists(script_path):
                self._serve_file(script_path, DEFAULT_SCRIPT)
            else:
                self._serve_error(404, f"# Khong tim thay {DEFAULT_SCRIPT}")
            return

        # Tim file trong thu muc scripts
        file_path = os.path.join(SCRIPT_DIR, os.path.basename(path))

        if os.path.isfile(file_path):
            self._serve_file(file_path, os.path.basename(path))
        else:
            self._serve_error(404, f"# 404 Not Found: {path}")

    def _serve_file(self, filepath, filename):
        try:
            with open(filepath, "r", encoding="utf-8") as f:
                content = f.read()

            encoded = content.encode("utf-8")
            self.send_response(200)
            self.send_header("Content-Type", "text/plain; charset=utf-8")
            self.send_header("Content-Length", str(len(encoded)))
            self.send_header("Cache-Control", "no-cache, no-store, must-revalidate")
            self.end_headers()
            self.wfile.write(encoded)

            size_kb = len(encoded) / 1024
            print(f"  -> Phuc vu: {filename} ({size_kb:.1f} KB)")
        except Exception as e:
            self._serve_error(500, f"# Server Error: {e}")

    def _serve_error(self, code, message):
        encoded = message.encode("utf-8")
        self.send_response(code)
        self.send_header("Content-Type", "text/plain; charset=utf-8")
        self.send_header("Content-Length", str(len(encoded)))
        self.end_headers()
        self.wfile.write(encoded)

# ============================================================
#  MAIN
# ============================================================
def main():
    # Kiem tra thu muc scripts
    if not os.path.exists(SCRIPT_DIR):
        os.makedirs(SCRIPT_DIR, exist_ok=True)
        print(f"  [+] Da tao thu muc: {SCRIPT_DIR}")

    # Kiem tra script chinh
    main_script = os.path.join(SCRIPT_DIR, DEFAULT_SCRIPT)
    if not os.path.exists(main_script):
        print(f"  [!] CANH BAO: Khong tim thay {DEFAULT_SCRIPT}")
        print(f"      Hay copy file .ps1 vao: {SCRIPT_DIR}")

    # Lay so luong scripts
    scripts = [f for f in os.listdir(SCRIPT_DIR) if f.endswith(".ps1")]

    # Lay IP public
    public_ip = "YOUR-VPS-IP"
    try:
        import urllib.request
        public_ip = urllib.request.urlopen("https://api.ipify.org", timeout=5).read().decode()
    except:
        try:
            import socket
            public_ip = socket.gethostbyname(socket.gethostname())
        except:
            pass

    # Khoi dong server
    server = HTTPServer(("0.0.0.0", PORT), ScriptHandler)

    # Xu ly Ctrl+C
    def shutdown(sig, frame):
        print("\n  [!] Dang tat server...")
        server.shutdown()
        sys.exit(0)

    signal.signal(signal.SIGINT, shutdown)
    signal.signal(signal.SIGTERM, shutdown)

    # Hien thi thong tin
    print("")
    print(f"  {'=' * 60}")
    print(f"  VPS SCRIPT SERVER - Pho Tue SoftWare Solutions JSC")
    print(f"  {'=' * 60}")
    print(f"")
    print(f"  Port:       {PORT}")
    print(f"  Scripts:    {SCRIPT_DIR} ({len(scripts)} file)")
    print(f"  Default:    {DEFAULT_SCRIPT}")
    print(f"")
    print(f"  Client su dung lenh:")
    print(f"")
    print(f"  \033[1;32m  irm https://{DOMAIN} | iex\033[0m")
    print(f"")
    print(f"  (hoac: irm http://{public_ip}:{PORT} | iex)")
    print(f"")
    print(f"  Nhan Ctrl+C de tat server")
    print(f"  {'=' * 60}")
    print(f"")

    server.serve_forever()

if __name__ == "__main__":
    main()
