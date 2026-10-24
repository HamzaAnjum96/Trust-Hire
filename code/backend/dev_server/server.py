#!/usr/bin/env python3
"""Trust Hire's dev server: Stripe test payments and the fare agent.

    python3 code/backend/dev_server/server.py

Standard library only, so there is nothing to install. It binds to localhost,
reads `.env` beside this file (see `.env.example`), and serves:

    GET  /health                    what is switched on, for the app's status line
    POST /payments/checkout         open a Stripe Checkout Session for a top-up
    GET  /payments/checkout/<id>    has it been paid, and for how many tokens
    POST /payments/webhook          Stripe's own confirmation, signature checked
    GET  /payments/done             where Stripe sends the browser afterwards
    POST /fares/advice              ask the fare agent

**This is not the backend.** Nothing here stores anything the app depends on;
the app stays local-first and keeps working with this server switched off. It
exists because two things cannot be done from a client: holding a Stripe
secret key, and running a language model.
"""

from __future__ import annotations

import json
import os
import re
import sys
import threading
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from typing import Dict, List, Optional
from urllib.parse import urlparse

sys.path.insert(0, str(Path(__file__).resolve().parent))

from fare_agent import AgentError, FareAgent, model_status, parse_request  # noqa: E402
from payments import PaymentError, StripeCheckout, key_problem, verify_webhook  # noqa: E402

MAX_BODY = 512 * 1024


def load_env(path: Path) -> None:
    """KEY=value lines into the environment, without overriding what is set."""
    if not path.exists():
        return
    for line in path.read_text().splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, _, value = line.partition("=")
        os.environ.setdefault(key.strip(), value.strip().strip('"').strip("'"))


class Config:
    def __init__(self, env: Dict[str, str]):
        self.port = int(env.get("DEV_SERVER_PORT", "8787"))
        self.public_url = env.get("DEV_SERVER_PUBLIC_URL", f"http://localhost:{self.port}")
        self.origins = [
            o.strip()
            for o in env.get(
                "DEV_SERVER_ORIGINS", "http://localhost:*,http://127.0.0.1:*"
            ).split(",")
            if o.strip()
        ]
        self.stripe_key = env.get("STRIPE_SECRET_KEY", "")
        self.stripe_webhook_secret = env.get("STRIPE_WEBHOOK_SECRET", "")
        self.stripe_currency = env.get("STRIPE_CURRENCY", "pkr")
        self.stripe_api_base = env.get("STRIPE_API_BASE", "https://api.stripe.com")
        self.llm_base_url = env.get("LLM_BASE_URL", "http://localhost:11434/v1")
        self.llm_model = env.get("LLM_MODEL", "qwen2.5:3b")
        self.llm_api_key = env.get("LLM_API_KEY", "")


def origin_allowed(origin: str, allowed: List[str]) -> bool:
    """Exact origins, `*`, or a trailing `:*` for any port on that host."""
    for pattern in allowed:
        if pattern == "*" or pattern == origin:
            return True
        if pattern.endswith(":*") and re.fullmatch(re.escape(pattern[:-2]) + r":\d+", origin):
            return True
    return False


class DevServer:
    """The pieces, wired from a Config. Separate from HTTP so tests can drive it."""

    def __init__(self, config: Config, *, stripe: Optional[StripeCheckout] = None, agent: Optional[FareAgent] = None):
        self.config = config
        self.payments_problem = key_problem(config.stripe_key) if stripe is None else None
        self.stripe = stripe
        if self.stripe is None and self.payments_problem is None:
            self.stripe = StripeCheckout(
                config.stripe_key,
                currency=config.stripe_currency,
                public_url=config.public_url,
                api_base=config.stripe_api_base,
            )
        self.agent = agent or FareAgent(
            config.llm_base_url, config.llm_model, api_key=config.llm_api_key
        )
        # Sessions Stripe has confirmed by webhook. In memory: this is a
        # record of what Stripe said, not the ledger — that lives in the app.
        self.confirmed: Dict[str, dict] = {}
        self._lock = threading.Lock()

    def health(self) -> dict:
        model = model_status(self.config.llm_base_url, self.config.llm_model, self.config.llm_api_key)
        return {
            "ok": True,
            "payments": {
                "enabled": self.stripe is not None,
                "mode": "test",
                "currency": self.config.stripe_currency,
                "problem": self.payments_problem,
                "webhooks": bool(self.config.stripe_webhook_secret),
            },
            "fareAgent": {
                "enabled": model["reachable"] and model["ready"],
                **model,
            },
        }

    def _need_stripe(self) -> StripeCheckout:
        if self.stripe is None:
            raise PaymentError(503, "payments_disabled", self.payments_problem or "")
        return self.stripe

    def checkout(self, body: dict) -> dict:
        return self._need_stripe().create(body.get("tokens"), body.get("account"))

    def checkout_status(self, session_id: str) -> dict:
        status = self._need_stripe().status(session_id)
        with self._lock:
            status["confirmedByWebhook"] = session_id in self.confirmed
        return status

    def webhook(self, payload: bytes, signature: str) -> dict:
        event = verify_webhook(payload, signature, self.config.stripe_webhook_secret)
        if event.get("type") == "checkout.session.completed":
            session = (event.get("data") or {}).get("object") or {}
            with self._lock:
                self.confirmed[session.get("id", "")] = session
            print(f"[stripe] confirmed {session.get('id')} — {(session.get('metadata') or {}).get('tokens')} tokens")
        return {"received": True}

    def fare_advice(self, body: object) -> dict:
        return self.agent.advise(parse_request(body))


PAGE = """<!doctype html><meta charset="utf-8"><meta name="viewport" content="width=device-width">
<title>Trust Hire</title><body style="font-family:system-ui;max-width:28rem;margin:4rem auto;padding:0 1rem;color:#2b1d1a">
<h1 style="color:#7a1f2b">{title}</h1><p>{body}</p></body>"""


def make_handler(server: DevServer):
    class Handler(BaseHTTPRequestHandler):
        server_version = "TrustHireDev/1"

        def log_message(self, format: str, *args: object) -> None:  # noqa: A002
            # Method and path only: a request body here can hold job text.
            sys.stderr.write(f"[dev] {self.command} {urlparse(self.path).path} -> {args[1] if len(args) > 1 else ''}\n")

        def _cors(self) -> None:
            origin = self.headers.get("Origin")
            if origin and origin_allowed(origin, server.config.origins):
                self.send_header("Access-Control-Allow-Origin", origin)
                self.send_header("Vary", "Origin")
                self.send_header("Access-Control-Allow-Headers", "Content-Type")
                self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
                # Chrome asks before a public page (GitHub Pages) may reach a
                # server on this machine.
                if self.headers.get("Access-Control-Request-Private-Network") == "true":
                    self.send_header("Access-Control-Allow-Private-Network", "true")

        def _send(self, status: int, payload: object) -> None:
            body = json.dumps(payload, ensure_ascii=False).encode()
            self.send_response(status)
            self._cors()
            self.send_header("Content-Type", "application/json; charset=utf-8")
            self.send_header("Content-Length", str(len(body)))
            self.send_header("Cache-Control", "no-store")
            self.end_headers()
            self.wfile.write(body)

        def _page(self, title: str, body: str) -> None:
            html = PAGE.format(title=title, body=body).encode()
            self.send_response(200)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.send_header("Content-Length", str(len(html)))
            self.end_headers()
            self.wfile.write(html)

        def _body(self) -> bytes:
            length = int(self.headers.get("Content-Length") or 0)
            if length > MAX_BODY:
                raise PaymentError(413, "body_too_large")
            return self.rfile.read(length) if length else b""

        def _json(self) -> dict:
            try:
                data = json.loads(self._body().decode() or "{}")
            except ValueError as error:
                raise PaymentError(400, "body_not_json") from error
            if not isinstance(data, dict):
                raise PaymentError(400, "body_not_an_object")
            return data

        def _handle(self, action) -> None:
            try:
                self._send(200, action())
            except (PaymentError, AgentError) as error:
                self._send(error.status, {"error": error.code, "detail": error.detail})
            except Exception as error:  # noqa: BLE001 — a dev server should say what broke
                self._send(500, {"error": "internal", "detail": str(error)})

        def do_OPTIONS(self) -> None:  # noqa: N802
            self.send_response(204)
            self._cors()
            self.send_header("Content-Length", "0")
            self.end_headers()

        def do_GET(self) -> None:  # noqa: N802
            path = urlparse(self.path).path
            if path == "/health":
                self._handle(server.health)
            elif path.startswith("/payments/checkout/"):
                self._handle(lambda: server.checkout_status(path.rsplit("/", 1)[-1]))
            elif path == "/payments/done":
                self._page("Payment received", "Go back to Trust Hire — your tokens appear there in a few seconds. You can close this tab.")
            elif path == "/payments/cancelled":
                self._page("Payment cancelled", "Nothing was charged. Go back to Trust Hire to try again.")
            else:
                self._send(404, {"error": "not_found"})

        def do_POST(self) -> None:  # noqa: N802
            path = urlparse(self.path).path
            if path == "/payments/checkout":
                self._handle(lambda: server.checkout(self._json()))
            elif path == "/payments/webhook":
                self._handle(lambda: server.webhook(self._body(), self.headers.get("Stripe-Signature", "")))
            elif path == "/fares/advice":
                self._handle(lambda: server.fare_advice(self._json()))
            else:
                self._send(404, {"error": "not_found"})

    return Handler


def main() -> None:
    load_env(Path(__file__).resolve().parent / ".env")
    config = Config(dict(os.environ))
    server = DevServer(config)

    httpd = ThreadingHTTPServer(("127.0.0.1", config.port), make_handler(server))
    print(f"Trust Hire dev server on http://localhost:{config.port}")
    print(
        "  payments: "
        + ("Stripe test mode" if server.stripe else f"off — {server.payments_problem}")
    )
    status = model_status(config.llm_base_url, config.llm_model, config.llm_api_key)
    print(
        f"  fare agent: {config.llm_model} at {config.llm_base_url} — "
        + (
            "ready"
            if status["ready"]
            else ("model not found; pull it first" if status["reachable"] else "model server not reachable")
        )
    )
    print(f"  origins: {', '.join(config.origins)}")
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        pass


if __name__ == "__main__":
    main()
