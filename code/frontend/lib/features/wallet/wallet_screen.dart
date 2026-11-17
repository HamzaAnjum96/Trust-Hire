import 'package:flutter/material.dart';
import '../../core/roles.dart';
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
              decoration: BoxDecoration(
                color: context.colours.feature,
                borderRadius: BrandRadius.sheetAll,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    strings.walletBalance,
                    style: BrandType.supporting.copyWith(
                      color: context.colours.onFeature.withValues(alpha: 0.8),
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
                        color: context.colours.onFeature,
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
                      color: context.colours.onFeature.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: BrandSizing.spaceMd),
                  FilledButton.icon(
                    onPressed: () => TopUpSheet.open(context),
                    style: FilledButton.styleFrom(
                      backgroundColor: context.colours.onFeature,
                      foregroundColor: context.colours.feature,
                    ),
                    icon: const Icon(Icons.add_rounded),
                    label: Text(strings.topUpTitle),
                  ),
                ],
              ),
            ),

            const SizedBox(height: BrandSizing.spaceMd),
            if (controller.isLockedOut)
              NoticePanel(
                message: strings.walletLocked,
                icon: Icons.lock_outline_rounded,
                tone: NoticeTone.warning,
              )
            else if (controller.isInDebt)
              NoticePanel(
                message: strings.walletInDebt(
                  Format.fare(strings, -wallet.balance),
                ),
                icon: Icons.error_outline_rounded,
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
                  const _LedgerHeader(),
                  // Newest first to read, oldest first to compute. The ledger
                  // is stored in the order things happened because the debt
                  // count depends on it; only the display is reversed. The
                  // balance after each line is the same replay, so a worker
                  // can see how they got to the number at the top.
                  for (final (entry, balance) in _withBalances(
                    wallet.entries,
                  ).reversed)
                    _EntryRow(entry: entry, balanceAfter: balance),
                ],
              ),

            if (rules.isLockedOut(wallet)) const SizedBox(height: 0),
          ],
        ),
      ),
    );
  }
}

/// Each entry with the balance once it had happened, oldest first.
List<(WalletEntry, int)> _withBalances(List<WalletEntry> entries) {
  var running = 0;
  return [for (final entry in entries) (entry, running += entry.tokens)];
}

/// **A data table, since 0.24.** Column headings over the ledger, and every
/// amount in one right-aligned column of tabular figures, so the digits line
/// up and a column of money can be read down. The balance sits under its
/// amount rather than beside it: two money columns do not fit at 320px
/// beside a description, and a description cut to one word is worse.
class _LedgerHeader extends StatelessWidget {
  const _LedgerHeader();

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final style = Theme.of(
      context,
    ).textTheme.labelSmall?.copyWith(color: context.colours.textMuted);

    // A visual heading for sighted readers; each row already says what its
    // numbers are when read aloud.
    return ExcludeSemantics(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          BrandSizing.spaceMd,
          BrandSizing.spaceSm,
          BrandSizing.spaceMd,
          BrandSizing.spaceXs,
        ),
        child: Row(
          children: [
            Expanded(child: Text(strings.walletColumnEntry, style: style)),
            Text(strings.walletColumnAmount, style: style),
          ],
        ),
      ),
    );
  }
}

class _EntryRow extends StatelessWidget {
  const _EntryRow({required this.entry, required this.balanceAfter});

  final WalletEntry entry;
  final int balanceAfter;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final isCredit = entry.tokens >= 0;
    final balance = balanceAfter < 0
        ? '−${Format.fare(strings, -balanceAfter)}'
        : Format.fare(strings, balanceAfter);

    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: BrandSizing.spaceMd,
          vertical: BrandSizing.spaceSm + 4,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) => _row(
            context,
            strings,
            theme,
            isCredit,
            balance,
            constraints.maxWidth,
          ),
        ),
      ),
    );
  }

  Widget _row(
    BuildContext context,
    AppStrings strings,
    ThemeData theme,
    bool isCredit,
    String balance,
    double rowWidth,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          switch (entry.kind) {
            WalletEntryKind.topUp => Icons.add_circle_outline_rounded,
            WalletEntryKind.commission => Icons.percent_rounded,
            WalletEntryKind.firstJobCredit => Icons.card_giftcard_rounded,
            WalletEntryKind.loyaltyBonus => Icons.stars_rounded,
            WalletEntryKind.cancellationPenalty =>
              Icons.remove_circle_outline_rounded,
            WalletEntryKind.adminAdjustment => Icons.build_rounded,
          },
          size: 20,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: BrandSizing.spaceMd),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(entry.kind.label(strings), style: theme.textTheme.bodyLarge),
              Text(
                Format.posted(strings, entry.createdAt, DateTime.now()),
                style: theme.textTheme.labelSmall,
              ),
            ],
          ),
        ),
        const SizedBox(width: BrandSizing.spaceSm),
        // The money column may take up to half the row, never more. A
        // figure shrinks to fit rather than wrap or push the description
        // off the screen: Rs. 1,000 over two lines is two numbers.
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: rowWidth / 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _Fitted(
                Text(
                  // The sign is spelled out rather than left to colour
                  // alone.
                  '${isCredit ? '+' : '−'} ${Format.fare(strings, entry.tokens.abs())}',
                  style: BrandType.fare.copyWith(
                    fontSize: 16,
                    color: isCredit
                        ? context.colours.good
                        : theme.colorScheme.onSurface,
                  ),
                ),
              ),
              _Fitted(
                Text(
                  strings.walletBalanceAfter(balance),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: context.colours.textMuted,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A figure that scales down, never wraps, and keeps to the end edge.
class _Fitted extends StatelessWidget {
  const _Fitted(this.child);

  final Widget child;

  @override
  Widget build(BuildContext context) => FittedBox(
    fit: BoxFit.scaleDown,
    alignment: AlignmentDirectional.centerEnd,
    child: child,
  );
}
