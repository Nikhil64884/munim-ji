import http.server
import os
import socketserver
import sys

DIRECTORY = os.path.join(os.path.dirname(os.path.abspath(__file__)), "build", "web")
PORT = 8080

class SPAServer(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=DIRECTORY, **kwargs)

    def end_headers(self):
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "*")
        self.send_header("Access-Control-Allow-Headers", "*")
        self.send_header("Cache-Control", "no-cache")
        super().end_headers()

    def do_GET(self):
        req_path = self.translate_path(self.path)
        if not os.path.exists(req_path):
            self.path = "/index.html"
        return super().do_GET()

if __name__ == "__main__":
    socketserver.TCPServer.allow_reuse_address = True
    print(f"Munim Ji Web App serving on http://localhost:{PORT} from {DIRECTORY}")
    with socketserver.TCPServer(("", PORT), SPAServer) as httpd:
        httpd.serve_forever()
