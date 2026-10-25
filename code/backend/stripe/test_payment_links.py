"""The Stripe Payment Links tool, checked without Stripe.

    python3 -m unittest discover code/backend/stripe

Stripe is replaced by a transport that answers like Stripe would and keeps
what it was asked to make. What is under test is the part that is ours: which
keys are accepted, what each link is made with, and that running it twice
makes nothing new.
"""

from __future__ import annotations

import json
import sys
import unittest
import urllib.parse
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from payment_links import PACKAGES, dart_map, ensure_links, redirect_for  # noqa: E402
from stripe_api import StripeApi, key_problem  # noqa: E402

TEST_KEY = "sk_test_" + "x" * 24


class KeyTests(unittest.TestCase):
    def test_only_test_keys_are_taken(self):
        self.assertIsNone(key_problem(TEST_KEY))
        self.assertIn("live", key_problem("sk_live_" + "x" * 24))
        self.assertIn("live", key_problem("rk_live_" + "x" * 24))
        self.assertIsNotNone(key_problem(""))
        self.assertIsNotNone(key_problem("pk_test_123"))
        with self.assertRaises(ValueError):
            StripeApi("sk_live_" + "x" * 24)


class FakeStripeCatalogue:
    """Answers the endpoints the Payment Links script uses, and keeps what it
    was asked to make."""

    def __init__(self, links=None, products=None):
        self.links = list(links or [])
        self.products = list(products or [])
        self.posts: list[tuple[str, dict]] = []

    def __call__(self, request, timeout):
        path = urllib.parse.urlparse(request.full_url).path
        if request.get_method() == "GET":
            data = self.links if path.endswith("/payment_links") else self.products
            return 200, json.dumps({"data": data}).encode()

        form = dict(urllib.parse.parse_qsl(request.data.decode()))
        self.posts.append((path, form))
        n = len(self.posts)
        if path.endswith("/products"):
            body = {"id": f"prod_{n}", "metadata": {"app": "trust_hire"}}
        elif path.endswith("/prices"):
            body = {"id": f"price_{n}"}
        else:
            body = {"id": f"plink_{n}", "url": f"https://buy.stripe.com/test_{n}"}
        return 200, json.dumps(body).encode()


class PaymentLinkTests(unittest.TestCase):
    site = "https://team.github.io/Trust-Hire/"

    def test_one_link_per_package_each_returning_with_its_session(self):
        stripe = FakeStripeCatalogue()
        links = ensure_links(StripeApi(TEST_KEY, transport=stripe), self.site)

        self.assertEqual(sorted(links), list(PACKAGES))
        made = [form for path, form in stripe.posts if path.endswith("/payment_links")]
        self.assertEqual(len(made), len(PACKAGES))
        for form in made:
            tokens = int(form["metadata[tokens]"])
            # Stripe's own placeholder, sent literally for Stripe to fill in.
            self.assertEqual(
                form["after_completion[redirect][url]"],
                f"{self.site}?topup={tokens}&session={{CHECKOUT_SESSION_ID}}",
            )
        prices = [form for path, form in stripe.posts if path.endswith("/prices")]
        self.assertEqual(
            sorted(int(f["unit_amount"]) for f in prices),
            [tokens * 100 for tokens in PACKAGES],
        )
        self.assertEqual({f["currency"] for f in prices}, {"pkr"})

    def test_running_it_again_makes_nothing_new(self):
        existing = [
            {
                "url": f"https://buy.stripe.com/test_old_{tokens}",
                "metadata": {"app": "trust_hire", "tokens": str(tokens)},
                "after_completion": {"redirect": {"url": redirect_for(self.site, tokens)}},
            }
            for tokens in PACKAGES
        ]
        stripe = FakeStripeCatalogue(links=existing)
        links = ensure_links(StripeApi(TEST_KEY, transport=stripe), self.site)

        self.assertEqual(stripe.posts, [])
        self.assertEqual(links[1000], "https://buy.stripe.com/test_old_1000")

    def test_a_link_for_another_site_is_not_reused(self):
        elsewhere = [
            {
                "url": "https://buy.stripe.com/test_fork",
                "metadata": {"app": "trust_hire", "tokens": "1000"},
                "after_completion": {"redirect": {"url": redirect_for("https://fork.github.io/x/", 1000)}},
            }
        ]
        stripe = FakeStripeCatalogue(links=elsewhere, products=[{"id": "prod_1", "metadata": {"app": "trust_hire"}}])
        links = ensure_links(StripeApi(TEST_KEY, transport=stripe), self.site)

        self.assertNotEqual(links[1000], "https://buy.stripe.com/test_fork")
        # The product is shared; only prices and links are per site.
        self.assertFalse(any(path.endswith("/products") for path, _ in stripe.posts))

    def test_only_test_keys(self):
        with self.assertRaises(ValueError):
            StripeApi("sk_live_" + "x" * 24)

    def test_the_dart_it_prints(self):
        dart = dart_map({1000: "https://buy.stripe.com/test_a", 500: "https://buy.stripe.com/test_b"}, self.site)
        self.assertIn(f"static const site = '{self.site}';", dart)
        self.assertLess(dart.index("500:"), dart.index("1000:"))


if __name__ == "__main__":
    unittest.main()
