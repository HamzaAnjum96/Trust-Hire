"""Stripe Checkout, in test mode, over Stripe's plain REST API.

No SDK: Stripe's API is form-encoded HTTP, and a dev server that needs
`pip install` before it runs is a dev server half the team never starts.

Three rules this file exists to keep:

- **Test keys only.** A live key is refused when the server starts, not when a
  payment is attempted. Section 13a of the POC plan excludes real money, and a
  demo that can charge a real card is one typo away from doing it.
- **The amount comes from Stripe, never from the app.** The app asks for a
  number of tokens; when it later asks whether that payment went through, the
  tokens it is told to credit are read back from the session Stripe stored —
  and cross-checked against what Stripe actually charged. A tampered request
  cannot turn a Rs. 500 payment into a Rs. 50,000 credit.
- **Webhooks are verified before they are believed.** An unsigned POST to
  `/payments/webhook` is somebody's guess at what Stripe would have said.
"""

from __future__ import annotations

import base64
import hashlib
import hmac
import json
import re
import time
import urllib.error
import urllib.parse
import urllib.request
from typing import Callable, Dict, List, Optional, Tuple

# Rupees. The app's packages are 500 to 10,000. The floor is also Stripe's:
# a charge must be worth at least about US$0.50, which Rs. 100 is not. The
# ceiling is loose, but a top-up of ten million is a bug, not a purchase.
MIN_TOKENS = 500
MAX_TOKENS = 100_000

SESSION_ID = re.compile(r"^cs_test_[A-Za-z0-9]{1,200}$")
ACCOUNT_ID = re.compile(r"^[A-Za-z0-9_-]{1,100}$")

# Stripe signs webhooks with a timestamp; older than this is a replay.
WEBHOOK_TOLERANCE_SECONDS = 300


class PaymentError(Exception):
    """Something the caller should see, with an HTTP status to send it with."""

    def __init__(self, status: int, code: str, detail: str = ""):
        super().__init__(detail or code)
        self.status = status
        self.code = code
        self.detail = detail


def key_problem(secret_key: str) -> Optional[str]:
    """Why this key cannot be used, or None when it can."""
    if not secret_key:
        return "STRIPE_SECRET_KEY is not set"
    if secret_key.startswith(("sk_live_", "rk_live_")):
        return "a live Stripe key was supplied; this server only takes test keys"
    if not secret_key.startswith(("sk_test_", "rk_test_")):
        return "STRIPE_SECRET_KEY does not look like a Stripe test key"
    return None


def _form(fields: Dict[str, object]) -> bytes:
    return urllib.parse.urlencode(
        [(k, str(v)) for k, v in fields.items()]
    ).encode()


Transport = Callable[[urllib.request.Request, float], Tuple[int, bytes]]


def _urlopen(request: urllib.request.Request, timeout: float) -> Tuple[int, bytes]:
    try:
        with urllib.request.urlopen(request, timeout=timeout) as response:
            return response.status, response.read()
    except urllib.error.HTTPError as error:
        return error.code, error.read()


class StripeApi:
    """Stripe's REST API, with a test key and nothing else.

    Shared by Checkout (`StripeCheckout`) and the Payment Links script
    (`payment_links.py`), so the test-keys-only rule is checked in one place.
    """

    def __init__(
        self,
        secret_key: str,
        *,
        api_base: str = "https://api.stripe.com",
        transport: Transport = _urlopen,
        timeout: float = 20.0,
    ):
        problem = key_problem(secret_key)
        if problem:
            raise ValueError(problem)
        self._auth = "Basic " + base64.b64encode(f"{secret_key}:".encode()).decode()
        self.api_base = api_base.rstrip("/")
        self._transport = transport
        self._timeout = timeout

    def call(self, method: str, path: str, body: Optional[bytes] = None) -> dict:
        request = urllib.request.Request(
            f"{self.api_base}{path}",
            data=body,
            method=method,
            headers={
                "Authorization": self._auth,
                "Content-Type": "application/x-www-form-urlencoded",
                "Stripe-Version": "2024-06-20",
            },
        )
        try:
            status, raw = self._transport(request, self._timeout)
        except (urllib.error.URLError, OSError) as error:
            raise PaymentError(502, "stripe_unreachable", str(error)) from error

        try:
            payload = json.loads(raw.decode() or "{}")
        except ValueError as error:
            raise PaymentError(502, "stripe_bad_response") from error

        if status >= 400:
            message = (payload.get("error") or {}).get("message", "")
            raise PaymentError(502, "stripe_refused", message)
        return payload


class StripeCheckout(StripeApi):
    """Creates and reads Checkout Sessions for token top-ups."""

    def __init__(
        self,
        secret_key: str,
        *,
        currency: str = "pkr",
        public_url: str = "http://localhost:8787",
        api_base: str = "https://api.stripe.com",
        transport: Transport = _urlopen,
        timeout: float = 20.0,
    ):
        super().__init__(secret_key, api_base=api_base, transport=transport, timeout=timeout)
        self.currency = currency.lower()
        self.public_url = public_url.rstrip("/")

    # Stripe takes PKR in paisa — it is a two-decimal currency there, even
    # though nobody prices labour in paisa. 1 token is Rs. 1 (Section 11).
    def _minor_units(self, tokens: int) -> int:
        return tokens * 100

    def create(self, tokens: object, account: object) -> dict:
        """Opens a Checkout Session for [tokens] rupees of tokens."""
        if not isinstance(tokens, int) or isinstance(tokens, bool):
            raise PaymentError(400, "tokens_not_a_whole_number")
        if not MIN_TOKENS <= tokens <= MAX_TOKENS:
            raise PaymentError(400, "tokens_out_of_range")
        if not isinstance(account, str) or not ACCOUNT_ID.match(account):
            raise PaymentError(400, "account_missing")

        session = self.call(
            "POST",
            "/v1/checkout/sessions",
            _form(
                {
                    "mode": "payment",
                    "client_reference_id": account,
                    "line_items[0][quantity]": 1,
                    "line_items[0][price_data][currency]": self.currency,
                    "line_items[0][price_data][unit_amount]": self._minor_units(tokens),
                    "line_items[0][price_data][product_data][name]": "Trust Hire tokens",
                    "line_items[0][price_data][product_data][description]": (
                        f"{tokens:,} tokens · 1 token = Rs. 1 · test mode"
                    ),
                    "metadata[tokens]": tokens,
                    "metadata[account]": account,
                    # The app polls for the result; these pages only have to
                    # tell somebody to go back to it.
                    "success_url": f"{self.public_url}/payments/done",
                    "cancel_url": f"{self.public_url}/payments/cancelled",
                }
            ),
        )
        return {"id": session.get("id"), "url": session.get("url")}

    def status(self, session_id: str) -> dict:
        """Whether a session has been paid, and what it pays for."""
        if not SESSION_ID.match(session_id or ""):
            raise PaymentError(400, "not_a_test_session")

        session = self.call(
            "GET", f"/v1/checkout/sessions/{urllib.parse.quote(session_id)}"
        )
        return describe_session(session, currency=self.currency)


def describe_session(session: dict, *, currency: str) -> dict:
    """What the app needs to know about a session, with the amount checked.

    `paid` is true only when Stripe says it was paid *and* what it charged is
    exactly the tokens recorded on the session, in the currency this server
    charges in. Anything else is reported as unpaid with the reason — crediting
    a wallet on a mismatch would be trusting the half of the record that can
    be wrong.
    """
    metadata = session.get("metadata") or {}
    try:
        tokens = int(metadata.get("tokens", ""))
    except ValueError:
        tokens = 0

    paid = session.get("payment_status") == "paid"
    problem = None
    if paid:
        if (session.get("currency") or "").lower() != currency:
            problem = "currency_mismatch"
        elif session.get("amount_total") != tokens * 100 or tokens <= 0:
            problem = "amount_mismatch"

    return {
        "id": session.get("id"),
        "status": session.get("status"),
        "paid": paid and problem is None,
        "tokens": tokens,
        "account": session.get("client_reference_id") or metadata.get("account"),
        "problem": problem,
    }


def verify_webhook(
    payload: bytes,
    signature_header: str,
    secret: str,
    *,
    now: Optional[float] = None,
) -> dict:
    """The event Stripe sent, or a PaymentError if Stripe did not send it."""
    if not secret:
        raise PaymentError(503, "webhook_secret_not_set")

    timestamp = None
    signatures: List[str] = []
    for part in (signature_header or "").split(","):
        key, _, value = part.strip().partition("=")
        if key == "t":
            timestamp = value
        elif key == "v1":
            signatures.append(value)

    if not timestamp or not signatures:
        raise PaymentError(400, "signature_missing")

    expected = hmac.new(
        secret.encode(), f"{timestamp}.".encode() + payload, hashlib.sha256
    ).hexdigest()
    if not any(hmac.compare_digest(expected, s) for s in signatures):
        raise PaymentError(400, "signature_invalid")

    try:
        age = abs((now if now is not None else time.time()) - int(timestamp))
    except ValueError as error:
        raise PaymentError(400, "signature_invalid") from error
    if age > WEBHOOK_TOLERANCE_SECONDS:
        raise PaymentError(400, "signature_too_old")

    try:
        return json.loads(payload.decode())
    except ValueError as error:
        raise PaymentError(400, "event_not_json") from error
