import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/wallet_controller.dart';
import '../../core/formatters.dart';
import '../../core/layout.dart';
import '../../core/tokens.dart';
import '../../l10n/app_localizations.dart';
import '../../models/wallet.dart';
import '../../widgets/settings_group.dart';
import '../../widgets/state_views.dart';
import 'top_up_sheet.dart';
import 'wallet_rules.dart';

/// The wallet: what is in it, and everything that has moved.
///
/// The ledger is the screen, not a detail behind one. A worker being charged
/// 5% of their earnings should be able to see every charge without asking
/// anybody, and the entries are the same list the balance is computed from —
/// so what they read is what the app used.
class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  static Future<void> open(BuildContext context) {
    return Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const WalletScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final controller = context.watch<WalletController>();
    final wallet = controller.wallet;
    final rules = controller.rules;

    final toNextBonus =
        WalletRules.loyaltyStepTokens -
        (wallet.lifetimeTopUp % WalletRules.loyaltyStepTokens);

    return Scaffold(
      appBar: AppBar(title: Text(strings.navWallet)),
      body: ReadableWidth(
        child: ListView(
          padding: const EdgeInsets.all(BrandSizing.spaceMd),
          children: [
            // **The one bold surface in the app.** Everything else is white
            // on sand; the balance is the number a worker opens this screen
            // for, and it is money, so it gets the brand's deepest colour.
            Container(
              padding: const EdgeInsets.all(BrandSizing.spaceLg),
              decoration: const BoxDecoration(
                color: BrandColours.deepBurgundy,
                borderRadius: BrandRadius.sheetAll,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    strings.walletBalance,
                    style: BrandType.supporting.copyWith(
                      color: BrandColours.white.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: BrandSizing.spaceXs),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      Format.fare(strings, wallet.balance),
                      // Debt is said in the notice under the card as well:
                      // section 29 rules out colour as the only carrier of
                      // meaning, and red would not read on burgundy anyway.
                      style: BrandType.fare.copyWith(
                        fontSize: 36,
                        height: 44 / 36,
                        color: BrandColours.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: BrandSizing.spaceXs),
                  Text(
                    !wallet.hasFirstJobCredit
                        ? strings.firstJobCreditWaiting(
                            Format.fare(
                              strings,
                              WalletRules.firstJobCreditTokens,
                            ),
                          )
                        : strings.loyaltyProgress(
                            Format.fare(strings, toNextBonus),
                          ),
                    style: BrandType.caption.copyWith(
                      color: BrandColours.white.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: BrandSizing.spaceMd),
                  FilledButton.icon(
                    onPressed: () => TopUpSheet.open(context),
                    style: FilledButton.styleFrom(
                      backgroundColor: BrandColours.white,
                      foregroundColor: BrandColours.deepBurgundy,
                    ),
                    icon: const Icon(Icons.add),
                    label: Text(strings.topUpTitle),
                  ),
                ],
              ),
            ),

            const SizedBox(height: BrandSizing.spaceMd),
            if (controller.isLockedOut)
              NoticePanel(
                message: strings.walletLocked,
                icon: Icons.lock_outline,
                tone: NoticeTone.warning,
              )
            else if (controller.isInDebt)
              NoticePanel(
                message: strings.walletInDebt(
                  Format.fare(strings, -wallet.balance),
                ),
                icon: Icons.error_outline,
                tone: NoticeTone.warning,
              )
            else
              NoticePanel(message: strings.walletExplanation),

            const SizedBox(height: BrandSizing.spaceLg),
            if (wallet.entries.isEmpty)
              Text(strings.walletEmpty, style: theme.textTheme.bodyMedium)
            else
              SettingsGroup(
                title: strings.walletHistory,
                children: [
                  // Newest first to read, oldest first to compute. The ledger
                  // is stored in the order things happened because the debt
                  // count depends on it; only the display is reversed.
                  for (final entry in wallet.entries.reversed)
                    _EntryRow(entry: entry),
                ],
              ),

            if (rules.isLockedOut(wallet)) const SizedBox(height: 0),
          ],
        ),
      ),
    );
  }
}

class _EntryRow extends StatelessWidget {
  const _EntryRow({required this.entry});

  final WalletEntry entry;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final isCredit = entry.tokens >= 0;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: BrandSizing.spaceMd,
        vertical: BrandSizing.spaceSm + 4,
      ),
      child: Row(
        children: [
          Icon(
            switch (entry.kind) {
              WalletEntryKind.topUp => Icons.add_circle_outline,
              WalletEntryKind.commission => Icons.percent,
              WalletEntryKind.firstJobCredit => Icons.card_giftcard,
              WalletEntryKind.loyaltyBonus => Icons.stars_outlined,
              WalletEntryKind.cancellationPenalty =>
                Icons.remove_circle_outline,
              WalletEntryKind.adminAdjustment => Icons.build_outlined,
            },
            size: 20,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: BrandSizing.spaceMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.kind.label(strings),
                  style: theme.textTheme.bodyLarge,
                ),
                Text(
                  Format.posted(strings, entry.createdAt, DateTime.now()),
                  style: theme.textTheme.labelSmall,
                ),
              ],
            ),
          ),
          Text(
            // The sign is spelled out rather than left to colour alone.
            '${isCredit ? '+' : '−'} ${Format.fare(strings, entry.tokens.abs())}',
            style: BrandType.fare.copyWith(
              fontSize: 16,
              color: isCredit
                  ? BrandColours.successTeal
                  : theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
