#!/usr/bin/env python3
# Small user directory service used in the tutorial.
# APP_VERSION=v1 uses the column "name", APP_VERSION=v2 uses "full_name".
# Both versions have the same API: GET /users, POST /users, GET /health

import json
import os
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

import psycopg

VERSION = os.environ.get("APP_VERSION", "v1")
PORT = int(os.environ.get("APP_PORT", "8001"))
DB_URL = os.environ.get("DATABASE_URL", "postgresql://app:app@localhost:5432/shop")

# this is the only thing that changes between v1 and v2
COLUMN = "name" if VERSION == "v1" else "full_name"


def run_sql(sql, params=()):
    # 2s timeout so a request fails instead of hanging when the table is locked
    with psycopg.connect(DB_URL, autocommit=True, options="-c statement_timeout=2000") as conn:
        with conn.cursor() as cur:
            cur.execute(sql, params)
            if cur.description:
                return cur.fetchall()
            return []


class Handler(BaseHTTPRequestHandler):
    def send_json(self, status, data):
        body = json.dumps(data).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("X-App-Version", VERSION)
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        if self.path == "/health":
            self.send_json(200, {"status": "ok", "version": VERSION})
        elif self.path == "/users":
            try:
                rows = run_sql(f"SELECT id, {COLUMN} FROM users ORDER BY id DESC LIMIT 5")
                self.send_json(200, [{"id": r[0], "name": r[1]} for r in rows])
            except Exception as e:
                self.send_json(500, {"error": str(e).splitlines()[0], "version": VERSION})
        else:
            self.send_json(404, {"error": "not found"})

    def do_POST(self):
        if self.path != "/users":
            self.send_json(404, {"error": "not found"})
            return
        length = int(self.headers.get("Content-Length", 0))
        name = json.loads(self.rfile.read(length) or b"{}").get("name", "anonymous")
        try:
            rows = run_sql(f"INSERT INTO users ({COLUMN}) VALUES (%s) RETURNING id", (name,))
            self.send_json(201, {"id": rows[0][0], "version": VERSION})
        except Exception as e:
            self.send_json(500, {"error": str(e).splitlines()[0], "version": VERSION})

    def log_message(self, *args):
        # no access log, traffic.sh keeps its own log
        pass


if __name__ == "__main__":
    print(f"app {VERSION} on port {PORT} (column: {COLUMN})", flush=True)
    ThreadingHTTPServer(("0.0.0.0", PORT), Handler).serve_forever()
