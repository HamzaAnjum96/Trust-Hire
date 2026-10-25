import 'package:flutter/foundation.dart';

/// Stripe Payment Links — how the GitHub Pages build takes a test payment
/// with no server behind it.
///
/// GitHub Pages is a static host: everything in the site is readable by
/// anybody, so it can never hold a Stripe secret key, and creating a Checkout
/// Session needs one. A Payment Link is made once, ahead of time, by
/// `code/backend/stripe/payment_links.py` running on a developer's machine
/// with the key — and after that it is just a public URL. Stripe designed them
/// to be shared, so **nothing below is a secret**: these are the addresses of
/// five test-mode checkout pages, one per package.
///
/// Each link sends the buyer back to [site] with the session it completed —
/// `?topup=1000&session=cs_test_…` — and [StripeReturn] takes it from there.
///
/// Regenerate with the script after moving the site or switching Stripe
/// account; it prints this block.
class StripePaymentLinks {
  const StripePaymentLinks._();

  static const site = 'https://hamzaanjum96.github.io/Trust-Hire/';

  static const byTokens = <int, String>{
    500: 'https://buy.stripe.com/test_00w00ibnefHa7Qk2AldfG00',
    1000: 'https://buy.stripe.com/test_8x29AS9f6eD66MgcaVdfG01',
    2500: 'https://buy.stripe.com/test_cNi9ASezq7aE4E85MxdfG02',
    5000: 'https://buy.stripe.com/test_aFaeVc76Y52w9Ys3EpdfG03',
    10000: 'https://buy.stripe.com/test_14A14mdvmdz22w01whdfG04',
  };

  /// The links, when this build is running where they send people back to.
  ///
  /// Only on the web, and only on [site]'s own origin: a link returns to one
  /// address, and a payment started anywhere else — a phone, `localhost` —
  /// would come back to a browser that never started it, and be credited
  /// nowhere. Those builds keep the simulated top-up.
  static Map<int, String>? forThisBuild() =>
      kIsWeb && returnsTo(Uri.base) ? byTokens : null;

  /// Whether a payment started at [location] comes back to the same browser
  /// storage — which is per origin, so the path does not matter.
  static bool returnsTo(Uri location) =>
      (location.scheme == 'https' || location.scheme == 'http') &&
      location.origin == Uri.parse(site).origin;

  /// The link, carrying which demo account is paying. Stripe records it on
  /// the session as `client_reference_id`, so the dashboard shows who it was.
  static Uri withAccount(String link, String account) {
    final uri = Uri.parse(link);
    return uri.replace(
      queryParameters: {...uri.queryParameters, 'client_reference_id': account},
    );
  }
}
