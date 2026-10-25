import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/wallet_controller.dart';
import '../../core/formatters.dart';
import '../../core/tokens.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/state_views.dart';
import 'stripe_links.dart';

/// Buying tokens.
///
/// Section 11 asks for a real-feeling flow; Section 13a excludes real payment
/// handling. Two ways to satisfy both:
///
/// - **Stripe through a Payment Link**, on the GitHub Pages site: the page
///   goes to Stripe's own checkout in test mode and Stripe sends it back.
///   Believed only as far as this browser can vouch for it — see
///   [StripeReturn].
/// - **Simulated**, everywhere else: packages, a confirm, a balance that moves.
///
/// Whichever it is, the sheet says plainly which one. A screen that looks like
/// a payment page without saying what it is, is the shape of a scam, and a
/// product about trust cannot afford to teach people that Trust Hire asks for
/// card numbers. The card is only ever typed into Stripe's own page.
class TopUpSheet extends StatefulWidget {
  const TopUpSheet({
    super.key,
    this.paymentLinks,
    this.openPaymentLink = _openHere,
  });

  /// Packages a person would actually pick, in rupees. The largest is a step
  /// toward the Rs. 100,000 loyalty bonus rather than an arbitrary round
  /// number.
  static const packages = <int>[500, 1000, 2500, 5000, 10000];

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
  bool _starting = false;

  /// Why the last attempt did not work, already in words.
  String? _problem;

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

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final links = widget.paymentLinks ?? StripePaymentLinks.forThisBuild();

    return Padding(
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
          Text(strings.topUpTitle, style: theme.textTheme.headlineMedium),
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
                  links != null
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
          for (final tokens in TopUpSheet.packages)
            if (links == null || links.containsKey(tokens)) ...[
              OutlinedButton(
                onPressed: _starting
                    ? null
                    : links != null
                    ? () => _payWithLink(links[tokens]!, tokens)
                    : () => _buySimulated(tokens),
                child: Text(
                  links == null
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
    );
  }
}
