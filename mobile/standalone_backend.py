import json
import re
import socket
import sys
from http.server import HTTPServer, BaseHTTPRequestHandler

PORT = 8000

def get_lan_ip():
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
        s.close()
        return ip
    except Exception:
        try:
            return socket.gethostbyname(socket.gethostname())
        except Exception:
            return "127.0.0.1"

customers = [
    {"id": 1, "name": "Suresh Sharma", "phone": "98765 43210", "balance": 1450, "balance_paise": 145000, "type": "udhaar"},
    {"id": 2, "name": "Ramesh Kumar", "phone": "88877 66554", "balance": 3600, "balance_paise": 360000, "type": "udhaar"},
    {"id": 3, "name": "Pooja Verma", "phone": "91234 56789", "balance": -890, "balance_paise": -89000, "type": "jama"},
    {"id": 4, "name": "Vikram Singh", "phone": "99887 76655", "balance": 5200, "balance_paise": 520000, "type": "udhaar"},
    {"id": 5, "name": "Aisha Khan", "phone": "87654 32109", "balance": 0, "balance_paise": 0, "type": "settled"},
]

recent_activity = [
    {"id": 1, "name": "Ramesh Kumar", "type": "udhaar", "amount": 1450, "time": "10:30 AM"},
    {"id": 2, "name": "Suresh Sharma", "type": "jama", "amount": 800, "time": "11:15 AM"},
    {"id": 3, "name": "Cash Sale", "type": "cash", "amount": 250, "time": "12:00 PM"},
]

next_cust_id = 6

class MunimApiHandler(BaseHTTPRequestHandler):
    def end_headers(self):
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, PATCH, DELETE, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type, Authorization")
        self.send_header("Cache-Control", "no-cache")
        super().end_headers()

    def do_OPTIONS(self):
        self.send_response(200)
        self.end_headers()

    def _send_json(self, data, status=200):
        body = json.dumps(data, ensure_ascii=False).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def _read_body(self):
        length = int(self.headers.get("Content-Length", 0))
        if length > 0:
            raw = self.rfile.read(length).decode("utf-8", errors="ignore")
            try:
                return json.loads(raw)
            except Exception:
                return {}
        return {}

    def do_GET(self):
        global customers
        path = self.path.split("?")[0]

        if path == "/api/summary":
            self._send_json({
                "todaySales": 14250,
                "totalJama": 8500,
                "totalUdhaar": 5750,
                "customerCount": len(customers),
                "udhaar_display": "₹5,750",
                "jama_display": "₹8,500",
                "cash_sale_display": "₹14,250",
                "jama_count": 14,
                "udhaar_count": 8,
                "cash_count": 32,
                "jama_paise": 850000,
                "udhaar_paise": 575000,
                "cash_sale_paise": 1425000,
                "recent_activity": recent_activity
            })
        elif path == "/api/customers":
            self._send_json({"customers": customers, "total": len(customers)})
        elif re.match(r"^/api/customers/\d+/ledger$", path):
            self._send_json({
                "balance_paise": 145000,
                "entries": [
                    {"id": 101, "transaction_type": "Debit",  "amount_paise": 50000,  "item_desc": "Aata 10kg & Chini 2kg",   "date": "2026-10-18T10:30:00Z"},
                    {"id": 102, "transaction_type": "Debit",  "amount_paise": 95000,  "item_desc": "Refined Oil 5L",          "date": "2026-10-15T16:15:00Z"},
                    {"id": 103, "transaction_type": "Credit", "amount_paise": 100000, "item_desc": "UPI Payment received",    "date": "2026-10-10T14:00:00Z"}
                ]
            })
        elif path == "/api/audit":
            self._send_json({"entries": []})
        elif path.startswith("/api/export"):
            self._send_json({"detail": "Export file not available in mock backend"}, status=404)
        elif path.startswith("/api/"):
            self._send_json({"detail": f"Endpoint {path} not found"}, status=404)
        else:
            self._send_json({"status": "online", "service": "Munim Ji AI Backend API", "version": "1.0"})

    def do_POST(self):
        global next_cust_id, customers
        path = self.path.split("?")[0]
        body = self._read_body()

        if path == "/api/auth/send-otp":
            self._send_json({"message": "OTP 123456 bhej diya gaya", "otp": "123456", "test_otp": "123456"})
        elif path == "/api/auth/verify-otp":
            self._send_json({
                "token": "jwt_token_munim_ji_active_session",
                "user": {"phone": "9876543210", "name": "Sharma Kirana Store"}
            })
        elif path == "/api/auth/google-login":
            email = body.get("email") or "user@gmail.com"
            name = body.get("name") or email.split("@")[0].capitalize()
            self._send_json({
                "token": f"jwt_google_{re.sub(r'[^a-zA-Z0-9]', '', email)}_active",
                "user": {"email": email, "name": name, "auth_provider": "google"}
            })
        elif path == "/api/chat":
            text = (body.get("message") or body.get("prompt") or "").lower()
            reply = "Namaste Ji! Main aapka Munim Ji AI. Main aapka hisaab-kitaab maintain rakhne me madad karunga."
            if "sale" in text or "aaj" in text:
                reply = "Aaj ki Total Sale: \u20b914,250 (Jama: \u20b98,500 | Udhaar: \u20b95,750)."
            elif "udhaar" in text or "baaki" in text:
                reply = "Ramesh Kumar par \u20b91,450 baki hai. Kul 4 grahakon par \u20b99,360 baki hai."
            elif "jama" in text:
                reply = "Jama darj kar liya gaya hai."
            elif "cash" in text:
                reply = "Cash Sale safalta se add ho gayi hai."
            self._send_json({"reply": reply})
        elif path == "/api/voice":
            self._send_json({"transcript": "Ramesh 500 udhaar", "reply": "Ramesh Kumar par ₹500 udhaar darj ho gaya."})
        elif path == "/api/customers":
            name = body.get("name") or "Naya Grahak"
            phone = body.get("phone") or ""
            new_c = {"id": next_cust_id, "name": name, "phone": phone, "balance_paise": 0}
            next_cust_id += 1
            customers.append(new_c)
            self._send_json(new_c, status=201)
        elif path == "/api/transactions":
            self._send_json({"message": "Transaction darj ho gaya"})
        elif path == "/api/customers/merge":
            self._send_json({"message": "Customers merged successfully"})
        elif path.startswith("/api/"):
            self._send_json({"detail": f"Endpoint {path} not found"}, status=404)
        else:
            self._send_json({"status": "online"})

    def do_PATCH(self):
        self._send_json({"message": "Updated successfully"})

    def do_DELETE(self):
        self._send_json({"message": "Deleted successfully"})

if __name__ == "__main__":
    server_address = ("0.0.0.0", PORT)
    httpd = HTTPServer(server_address, MunimApiHandler)
    lan_ip = get_lan_ip()
    print(f"==================================================")
    print(f" Munim Ji Backend API running on port {PORT}")
    print(f" Listening on all network interfaces (0.0.0.0:{PORT})")
    print(f" Local URL : http://localhost:{PORT}")
    print(f" Network URL: http://{lan_ip}:{PORT}")
    print(f"==================================================")
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\nStopping backend server...")
        httpd.server_close()
