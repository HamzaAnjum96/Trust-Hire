"""Stripe's REST API, with a test key and nothing else.

No SDK: Stripe's API is form-encoded HTTP, and a tool that needs `pip install`
before it runs is a tool half the team never runs. Used by
`payment_links.py`, which makes the Payment Links the GitHub Pages site sells
tokens with.

**Test keys only, refused up front.** Section 13a of the POC plan excludes
real money, and a script that can create live prices is one pasted key away
from doing it.
"""

from __future__ import annotations

import base64
import json
import urllib.error
import urllib.parse
import urllib.request
from typing import Callable, Dict, Optional, Tuple


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
        return "a live Stripe key was supplied; only test keys are accepted"
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

    Everything that talks to Stripe goes through here, so the
    test-keys-only rule is checked in one place.
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
