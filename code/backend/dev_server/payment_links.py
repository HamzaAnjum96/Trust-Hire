#!/usr/bin/env python3
"""The Stripe Payment Links the GitHub Pages build sells tokens with.

    python3 code/backend/dev_server/payment_links.py \\
        --site https://hamzaanjum96.github.io/Trust-Hire/

Run once per Stripe account. It reads STRIPE_SECRET_KEY from the environment
or from `.env` beside this file — the key is used here, on your machine, and
goes nowhere else. What it prints is the part that *can* be public: a Dart map
of Payment Link URLs, for `lib/features/wallet/stripe_links.dart`.

**Why links, and not Checkout from the page.** GitHub Pages is a static host:
anything in the site is readable by anyone, so it can never hold a secret key,
and creating a Checkout Session needs one. A Payment Link is created once, here,
and after that it is just a public URL — Stripe designed them to be shared.
Each one is fixed to one package and sends the buyer back to the site with the
session id: `<site>?topup=1000&session=cs_test_…`.

**What that costs.** Nothing on the site can ask Stripe whether the session it
was sent back with was really paid — that also needs the secret key. The app
credits a return only for a top-up that browser itself started, once per
session; see `StripeReturn` in the app. For a demo whose wallet lives in the
browser anyway, that is no weaker than the simulated top-up it replaces. A real
deployment checks the session on a server, as the dev server already does.

Running it again reuses links it already made for the same site, so it is safe
to re-run; it only creates what is missing.
"""

from __future__ import annotations

import argparse
import os
import sys
import urllib.parse
from pathlib import Path
from typing import Dict, List, Optional

sys.path.insert(0, str(Path(__file__).resolve().parent))

from payments import StripeApi, _form  # noqa: E402

# Mirrors TopUpSheet.packages in the app.
PACKAGES = (500, 1000, 2500, 5000, 10000)

APP = "trust_hire"


def redirect_for(site: str, tokens: int) -> str:
    """Where Stripe sends the buyer afterwards. `{CHECKOUT_SESSION_ID}` is
    Stripe's own placeholder, filled in with the session it just completed."""
    return f"{site}?topup={tokens}&session={{CHECKOUT_SESSION_ID}}"


def _redirect_of(link: dict) -> Optional[str]:
    after = link.get("after_completion") or {}
    return (after.get("redirect") or {}).get("url")


def _ours(item: dict) -> bool:
    return (item.get("metadata") or {}).get("app") == APP


def ensure_links(api: StripeApi, site: str, currency: str = "pkr") -> Dict[int, str]:
    """A Payment Link per package for [site], making only what is missing."""
    if not site.endswith("/"):
        site += "/"

    existing = [
        link
        for link in api.call("GET", "/v1/payment_links?active=true&limit=100").get("data", [])
        if _ours(link)
    ]

    links: Dict[int, str] = {}
    product_id: Optional[str] = None

    for tokens in PACKAGES:
        redirect = redirect_for(site, tokens)
        reuse = next(
            (
                link
                for link in existing
                if (link.get("metadata") or {}).get("tokens") == str(tokens)
                and _redirect_of(link) == redirect
            ),
            None,
        )
        if reuse is not None:
            links[tokens] = reuse["url"]
            continue

        if product_id is None:
            product_id = _product(api)

        price = api.call(
            "POST",
            "/v1/prices",
            _form(
                {
                    "product": product_id,
                    "currency": currency,
                    # PKR is a two-decimal currency at Stripe: paisa.
                    "unit_amount": tokens * 100,
                    "nickname": f"Rs. {tokens:,} of tokens",
                    "metadata[app]": APP,
                    "metadata[tokens]": tokens,
                }
            ),
        )
        link = api.call(
            "POST",
            "/v1/payment_links",
            _form(
                {
                    "line_items[0][price]": price["id"],
                    "line_items[0][quantity]": 1,
                    "after_completion[type]": "redirect",
                    "after_completion[redirect][url]": redirect,
                    "metadata[app]": APP,
                    "metadata[tokens]": tokens,
                }
            ),
        )
        links[tokens] = link["url"]

    return links


def _product(api: StripeApi) -> str:
    products = api.call("GET", "/v1/products?active=true&limit=100").get("data", [])
    for product in products:
        if _ours(product):
            return product["id"]
    created = api.call(
        "POST",
        "/v1/products",
        _form(
            {
                "name": "Trust Hire tokens",
                "description": "1 token = Rs. 1 · test mode",
                "metadata[app]": APP,
            }
        ),
    )
    return created["id"]


def dart_map(links: Dict[int, str], site: str) -> str:
    lines: List[str] = [
        f"  static const site = '{site}';",
        "",
        "  static const byTokens = <int, String>{",
    ]
    lines += [f"    {tokens}: '{links[tokens]}'," for tokens in sorted(links)]
    lines.append("  };")
    return "\n".join(lines)


def main(argv: Optional[List[str]] = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    parser.add_argument("--site", required=True, help="the deployed app, e.g. https://you.github.io/Trust-Hire/")
    args = parser.parse_args(argv)

    from server import load_env  # noqa: E402 — only needed when run by hand

    load_env(Path(__file__).resolve().parent / ".env")
    site = args.site if args.site.endswith("/") else args.site + "/"
    if urllib.parse.urlparse(site).scheme != "https":
        parser.error("--site must be the https address the app is deployed at")

    try:
        api = StripeApi(os.environ.get("STRIPE_SECRET_KEY", ""))
    except ValueError as problem:
        parser.error(str(problem))
    links = ensure_links(api, site, os.environ.get("STRIPE_CURRENCY", "pkr"))
    print(dart_map(links, site))
    return 0


if __name__ == "__main__":
    sys.exit(main())
