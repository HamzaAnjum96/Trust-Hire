import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/dev_services_controller.dart';
import '../../app/wallet_controller.dart';
import '../../core/formatters.dart';
import '../../core/tokens.dart';
import '../../l10n/app_localizations.dart';
import '../../services/dev_services.dart';
import '../../widgets/state_views.dart';
import 'stripe_links.dart';

/// Buying tokens.
///
/// Section 11 asks for a real-feeling flow; Section 13a excludes real payment
/// handling. Three ways to satisfy both, best first:
///
/// - **Stripe through the dev server**, when one with a test key is running
///   (`code/backend/dev_server/`): a real Checkout page opens, a test card
///   pays, and the tokens land once the server has asked Stripe and Stripe
///   says paid. No real money — the server refuses a live key outright.
/// - **Stripe through a Payment Link**, on the GitHub Pages site, where there
///   is no server: the page goes to Stripe and Stripe sends it back. Believed
///   only as far as this browser can vouch for it — see [StripeReturn].
/// - **Simulated**, everywhere else: packages, a confirm, a balance that moves.
///
/// Whichever it is, the sheet says plainly which one. A screen that looks like
/// a payment page without saying what it is, is the shape of a scam, and a
/// product about trust cannot afford to teach people that Trust Hire asks for
/// card numbers. The card is only ever typed into Stripe's own page.
class TopUpSheet extends StatefulWidget {
  const TopUpSheet({
    super.key,
    this.openUrl = _openInBrowser,
    this.pollEvery = const Duration(seconds: 3),
    this.paymentLinks,
    this.openPaymentLink = _openHere,
  });

  /// Packages a person would actually pick, in rupees. The largest is a step
  /// toward the Rs. 100,000 loyalty bonus rather than an arbitrary round
  /// number.
  static const packages = <int>[500, 1000, 2500, 5000, 10000];

  /// Opens Stripe's page. Replaced in tests.
  final Future<bool> Function(Uri) openUrl;

  /// How often to ask whether the payment has gone through. Stripe confirms
  /// within a second or two of the card being accepted; three seconds is
  /// quick enough that nobody waits, slow enough to be no load at all.
  final Duration pollEvery;

  /// Payment Links by package. Null means whatever this build has — which is
  /// none at all off the GitHub Pages site. See [StripePaymentLinks].
  final Map<int, String>? paymentLinks;

  /// Leaves for a Payment Link, in this tab. Replaced in tests.
  final Future<bool> Function(Uri) openPaymentLink;

  static Future<void> open(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const TopUpSheet(),
    );
  }

  static Future<bool> _openInBrowser(Uri url) async {
    try {
      return await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
        webOnlyWindowName: '_blank',
      );
    } catch (error) {
      if (kDebugMode) debugPrint('Could not open the payment page: $error');
      return false;
    }
  }

  /// The same tab, not a new one: Stripe sends the buyer back to the site,
  /// and a second copy of the app open beside the first would leave two
  /// wallets in memory over one storage, the older of which writes last.
  static Future<bool> _openHere(Uri url) async {
    try {
      return await launchUrl(url, webOnlyWindowName: '_self');
    } catch (error) {
      if (kDebugMode) debugPrint('Could not open the payment page: $error');
      return false;
    }
  }

  @override
  State<TopUpSheet> createState() => _TopUpSheetState();
}

class _TopUpSheetState extends State<TopUpSheet> {
  /// Set while a Stripe payment is open; the sheet is waiting on it.
  CheckoutSession? _session;

  bool _starting = false;
  bool _checking = false;
  Timer? _poll;

  /// Why the last attempt did not work, already in words.
  String? _problem;

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _buySimulated(int tokens) async {
    final strings = AppStrings.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    await context.read<WalletController>().topUp(tokens);

    navigator.pop();
    messenger.showSnackBar(
      SnackBar(content: Text(strings.topUpDone(Format.fare(strings, tokens)))),
    );
  }

  Future<void> _payWithStripe(DevServicesClient client, int tokens) async {
    final strings = AppStrings.of(context);
    final wallet = context.read<WalletController>();

    setState(() {
      _starting = true;
      _problem = null;
    });

    final CheckoutSession session;
    try {
      session = await client.startCheckout(
        tokens: tokens,
        account: wallet.workerId,
      );
    } on DevServicesException {
      if (!mounted) return;
      setState(() {
        _starting = false;
        _problem = strings.topUpStripeFailed;
      });
      return;
    }

    final opened = await widget.openUrl(session.url);
    if (!mounted) return;

    setState(() {
      _starting = false;
      _session = session;
      // Still waiting: a blocked pop-up is what "open it again" is for.
      _problem = opened ? null : strings.topUpCouldNotOpen;
    });
    _poll = Timer.periodic(widget.pollEvery, (_) => _check(client));
  }

  /// Asks whether the open payment has gone through, and credits it if so.
  ///
  /// Returns once it knows; the periodic tick and "stop waiting" both use it,
  /// so somebody who paid and then gave up a second too soon still gets their
  /// tokens.
  /// Off to Stripe, having written down what for. The page leaves, so there
  /// is nothing to wait for here — the return is handled when Stripe sends the
  /// buyer back (see `AppShell`).
  Future<void> _payWithLink(String link, int tokens) async {
    final strings = AppStrings.of(context);
    final wallet = context.read<WalletController>();

    setState(() {
      _starting = true;
      _problem = null;
    });

    await wallet.notePendingTopUp(tokens);
    final opened = await widget.openPaymentLink(
      StripePaymentLinks.withAccount(link, wallet.workerId),
    );
    if (!mounted) return;
    setState(() {
      _starting = false;
      if (!opened) _problem = strings.topUpCouldNotOpen;
    });
  }

  Future<void> _check(DevServicesClient client) async {
    final session = _session;
    if (_checking || session == null) return;
    _checking = true;

    final strings = AppStrings.of(context);
    final wallet = context.read<WalletController>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      final status = await client.checkoutStatus(session.id);
      if (!mounted || !identical(session, _session)) return;

      if (status.expired) {
        _giveUp(strings.topUpExpired);
        return;
      }
      if (!status.paid) {
        // Paid but not creditable — the amount or currency disagree. Waiting
        // longer will not change what Stripe recorded.
        if (status.problem != null) _giveUp(strings.topUpNotMatched);
        return;
      }
      // The session names the wallet it was opened for. Crediting another one
      // would be paying one person's money into somebody else's balance.
      if (status.account != wallet.workerId) {
        _giveUp(strings.topUpNotMatched);
        return;
      }

      _poll?.cancel();
      await wallet.creditPayment(paymentId: session.id, tokens: status.tokens);
      if (!mounted) return;

      navigator.pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(strings.topUpDone(Format.fare(strings, status.tokens))),
        ),
      );
    } on DevServicesException {
      // A dropped connection while somebody is typing a card number is not a
      // failed payment. Keep waiting; the next tick asks again.
    } finally {
      _checking = false;
    }
  }

  /// One last look before letting go — the payment may have landed between
  /// ticks — then back to the packages.
  Future<void> _stopWaiting(DevServicesClient client) async {
    await _check(client);
    if (mounted && _session != null) _giveUp(null);
  }

  void _giveUp(String? problem) {
    _poll?.cancel();
    _poll = null;
    setState(() {
      _session = null;
      _problem = problem;
    });
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final devServices = context.watch<DevServicesController>();
    final stripe = devServices.paymentsReady ? devServices.client : null;
    // A dev server that can check with Stripe beats a link that cannot.
    final links = stripe == null
        ? widget.paymentLinks ?? StripePaymentLinks.forThisBuild()
        : null;
    final session = _session;

    // While a payment is open the sheet cannot be swiped or tapped away: its
    // poll is the only thing that turns Stripe's confirmation into tokens, and
    // closing it would leave somebody who paid with nothing to show for it.
    // "Stop waiting" is the way out, and it checks one last time first.
    return PopScope(
      canPop: session == null,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          BrandSizing.spaceMd,
          BrandSizing.spaceMd,
          BrandSizing.spaceMd,
          BrandSizing.spaceXl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              session == null ? strings.topUpTitle : strings.topUpWaiting,
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: BrandSizing.spaceSm),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 18,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: BrandSizing.spaceSm),
                Expanded(
                  child: Text(
                    stripe != null
                        ? strings.topUpStripeNotice
                        : links != null
                        ? strings.topUpStripeLinkNotice
                        : strings.topUpNotReal,
                    style: theme.textTheme.labelSmall,
                  ),
                ),
              ],
            ),

            // What a link cannot establish, said where the choice is made.
            if (links != null) ...[
              const SizedBox(height: BrandSizing.spaceSm),
              Text(
                strings.topUpStripeLinkCaveat,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],

            if (_problem != null) ...[
              const SizedBox(height: BrandSizing.spaceMd),
              NoticePanel(
                message: _problem!,
                icon: Icons.error_outline,
                tone: NoticeTone.warning,
              ),
            ],

            const SizedBox(height: BrandSizing.spaceLg),
            if (session != null) ...[
              Row(
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                  const SizedBox(width: BrandSizing.spaceMd),
                  Expanded(
                    child: Text(
                      strings.topUpWaitingExplain,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: BrandSizing.spaceLg),
              OutlinedButton.icon(
                onPressed: () => widget.openUrl(session.url),
                icon: const Icon(Icons.open_in_new),
                label: Text(strings.topUpOpenAgain),
              ),
              const SizedBox(height: BrandSizing.spaceSm),
              TextButton(
                onPressed: stripe == null
                    ? () => _giveUp(null)
                    : () => _stopWaiting(stripe),
                child: Text(strings.topUpStopWaiting),
              ),
            ] else
              for (final tokens in TopUpSheet.packages)
                if (links == null || links.containsKey(tokens)) ...[
                  OutlinedButton(
                    onPressed: _starting
                        ? null
                        : stripe != null
                        ? () => _payWithStripe(stripe, tokens)
                        : links != null
                        ? () => _payWithLink(links[tokens]!, tokens)
                        : () => _buySimulated(tokens),
                    child: Text(
                      stripe == null && links == null
                          ? strings.topUpConfirm(Format.fare(strings, tokens))
                          : strings.topUpPayWithStripe(
                              Format.fare(strings, tokens),
                            ),
                    ),
                  ),
                  const SizedBox(height: BrandSizing.spaceSm),
                ],
          ],
        ),
      ),
    );
  }
}
