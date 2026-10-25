import 'stripe_links.dart';

/// What happened to a return from Stripe.
enum StripeReturnOutcome {
  /// Tokens added.
  credited,

  /// This session had already been turned into tokens. Nothing changed.
  alreadyCredited,

  /// This browser did not start a top-up — a bookmarked or shared return
  /// address, or one typed by hand. Ignored without a word.
  notStartedHere,

  /// A top-up was started, but not this one: another amount, or another
  /// account. Nothing added, and the screen says so.
  notMatched,
}

/// A top-up this browser has sent somebody to Stripe for.
///
/// Written just before the page leaves for a Payment Link, because the page
/// does leave — the whole app is gone until Stripe sends the buyer back — and
/// what comes back is only an amount and a session id. This is what the
/// return is checked against.
class PendingTopUp {
  const PendingTopUp({
    required this.account,
    required this.tokens,
    required this.startedAt,
  });

  /// Long enough to find a card and come back; short enough that a return
  /// address found in the history next week does nothing.
  static const maxAge = Duration(hours: 24);

  final String account;
  final int tokens;
  final DateTime startedAt;

  factory PendingTopUp.fromJson(Map<String, dynamic> json) => PendingTopUp(
    account: json['account'] as String,
    tokens: (json['tokens'] as num).round(),
    startedAt: DateTime.parse(json['startedAt'] as String),
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'account': account,
    'tokens': tokens,
    'startedAt': startedAt.toIso8601String(),
  };
}

/// Coming back from a Stripe Payment Link: `?topup=1000&session=cs_test_…`.
///
/// **What this can and cannot establish.** On GitHub Pages nothing can ask
/// Stripe whether the session it was sent back with was paid — that takes the
/// secret key, which a public site cannot hold. So a return is believed only
/// as far as the browser it lands in can vouch for it: this browser started a
/// top-up of exactly this amount, for this account, in the last day, and this
/// session has not been credited before. That is no weaker than the simulated
/// top-up it replaces — the wallet lives in this browser either way. A real
/// deployment checks the session with Stripe, on its own server, first.
class StripeReturn {
  const StripeReturn({required this.sessionId, required this.tokens});

  final String sessionId;
  final int tokens;

  /// Test sessions only. A live one would mean real money, and nothing on
  /// this site may claim to have taken any.
  static final _testSession = RegExp(r'^cs_test_[A-Za-z0-9]{1,250}$');

  static const _amountParam = 'topup';
  static const _sessionParam = 'session';

  /// The return [location] carries, or null when it carries none — or one
  /// for an amount this build does not sell.
  static StripeReturn? from(Uri location, {Iterable<int>? sold}) {
    final session = location.queryParameters[_sessionParam];
    final tokens = int.tryParse(location.queryParameters[_amountParam] ?? '');
    if (session == null || tokens == null) return null;
    if (!_testSession.hasMatch(session)) return null;
    if (!(sold ?? StripePaymentLinks.byTokens.keys).contains(tokens)) {
      return null;
    }
    return StripeReturn(sessionId: session, tokens: tokens);
  }

  /// [location] without the return, so a reload or a bookmark does not carry
  /// it — and so the address bar reads like the app again.
  static Uri cleaned(Uri location) {
    final rest = {...location.queryParameters}
      ..remove(_amountParam)
      ..remove(_sessionParam);
    return Uri(
      scheme: location.scheme,
      userInfo: location.userInfo,
      host: location.host,
      port: location.hasPort ? location.port : null,
      path: location.path,
      queryParameters: rest.isEmpty ? null : rest,
      fragment: location.hasFragment ? location.fragment : null,
    );
  }

  /// Whether this return may be credited to [account].
  ///
  /// Returns [StripeReturnOutcome.credited] to mean "go ahead"; whether it
  /// then turns out to have been credited already is the ledger's to say.
  StripeReturnOutcome check(
    PendingTopUp? pending, {
    required String account,
    required DateTime now,
  }) {
    if (pending == null ||
        now.difference(pending.startedAt) > PendingTopUp.maxAge) {
      return StripeReturnOutcome.notStartedHere;
    }
    if (pending.tokens != tokens || pending.account != account) {
      return StripeReturnOutcome.notMatched;
    }
    return StripeReturnOutcome.credited;
  }
}
