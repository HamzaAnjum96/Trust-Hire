import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/wallet_controller.dart';
import '../../core/formatters.dart';
import '../../core/tokens.dart';
import '../../l10n/app_localizations.dart';

/// Buying tokens.
///
/// Section 11 asks for a real-feeling flow; Section 13a excludes real payment
/// handling. So: packages, a confirm, a balance that moves — and a notice
/// saying plainly that no money is taken and no card details are wanted.
///
/// The notice is not fine print. A screen that looks like a payment page
/// without being one is the shape of a scam, and a product about trust cannot
/// afford to teach people that Trust Hire asks for card numbers.
class TopUpSheet extends StatelessWidget {
  const TopUpSheet({super.key});

  /// Packages a person would actually pick, in rupees. The largest is a step
  /// toward the Rs. 100,000 loyalty bonus rather than an arbitrary round
  /// number.
  static const packages = <int>[500, 1000, 2500, 5000, 10000];

  static Future<void> open(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const TopUpSheet(),
    );
  }

  Future<void> _buy(BuildContext context, int tokens) async {
    final strings = AppStrings.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    await context.read<WalletController>().topUp(tokens);

    navigator.pop();
    messenger.showSnackBar(
      SnackBar(content: Text(strings.topUpDone(Format.fare(strings, tokens)))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);

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
                  strings.topUpNotReal,
                  style: theme.textTheme.labelSmall,
                ),
              ),
            ],
          ),

          const SizedBox(height: BrandSizing.spaceLg),
          for (final tokens in packages) ...[
            OutlinedButton(
              onPressed: () => _buy(context, tokens),
              child: Text(strings.topUpConfirm(Format.fare(strings, tokens))),
            ),
            const SizedBox(height: BrandSizing.spaceSm),
          ],
        ],
      ),
    );
  }
}
