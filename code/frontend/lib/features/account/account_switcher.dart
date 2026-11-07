import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/account_controller.dart';
import '../../app/job_controller.dart';
import '../../core/theme.dart';
import '../../core/tokens.dart';
import '../../l10n/app_localizations.dart';
import '../../models/account.dart';

/// The name to show for an account, in the reader's language.
///
/// The device account has no name in the data — it is whoever is holding the
/// phone — so it is named here rather than carrying an English "You" through
/// the model layer into an Urdu interface.
String accountName(DemoAccount account, AppStrings strings) =>
    account.name ?? strings.accountYou;

/// A round avatar with somebody's initials.
///
/// Initials rather than a photograph: the POC has no uploads, and a grey
/// silhouette repeated six times would make the accounts look identical at
/// exactly the moment the reader is trying to tell them apart.
class AccountAvatar extends StatelessWidget {
  const AccountAvatar({super.key, required this.account, this.radius = 20});

  final DemoAccount account;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);

    return CircleAvatar(
      radius: radius,
      backgroundColor: account.isDevice
          ? theme.colorScheme.primary
          : BrandColours.copper,
      foregroundColor: account.isDevice
          ? theme.colorScheme.onPrimary
          : Colors.white,
      child: Text(
        account.initialsOf(strings.accountYou),
        style: theme.textTheme.labelLarge?.copyWith(
          color: account.isDevice
              ? theme.colorScheme.onPrimary
              : Colors.white,
          fontSize: radius * 0.7,
        ),
      ),
    );
  }
}

/// The app-bar control that says who you are and opens the switcher.
///
/// On every destination rather than only on the profile screen: which account
/// is active changes what the map, the feed and the activity list show, so it
/// belongs where those are, not two taps away in settings.
class AccountButton extends StatelessWidget {
  const AccountButton({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final account = context.watch<AccountController>().active;

    return IconButton(
      tooltip: '${strings.switchAccount} · ${accountName(account, strings)}',
      onPressed: () => AccountSheet.open(context),
      icon: AccountAvatar(account: account, radius: 16),
    );
  }
}

/// The list of people you can be.
class AccountSheet extends StatelessWidget {
  const AccountSheet({super.key});

  static Future<void> open(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const AccountSheet(),
  );

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final accounts = context.watch<AccountController>();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          BrandSizing.spaceMd,
          0,
          BrandSizing.spaceMd,
          BrandSizing.spaceMd,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(strings.demoAccounts, style: theme.textTheme.titleLarge),
            const SizedBox(height: BrandSizing.spaceXs),
            Text(
              strings.demoAccountsExplain,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: BrandSizing.spaceMd),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final account in accounts.roster)
                    _AccountTile(
                      account: account,
                      isActive: account.id == accounts.activeId,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountTile extends StatelessWidget {
  const _AccountTile({required this.account, required this.isActive});

  final DemoAccount account;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final jobs = context.watch<JobController>();

    // Counted from the data rather than written into the roster, so it stays
    // true after somebody posts or deletes a job while being this person.
    final posted = jobs.jobs.where((job) => job.isPostedBy(account.id)).length;

    final subtitle = [
      if (account.isDevice) strings.accountYouHelp,
      if (account.isAdmin) strings.accountStaffHelp,
      if (account.area != null) account.area!,
      // Staff post nothing and are not meant to. A count of zero next to the
      // platform's own account reads as a person who has never got round to
      // using it.
      if (!account.isAdmin) strings.accountPostings(posted),
    ].join(' · ');

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: AccountAvatar(account: account),
      title: Text(accountName(account, strings)),
      subtitle: Text(subtitle),
      trailing: isActive
          ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary)
          : null,
      selected: isActive,
      onTap: isActive
          ? null
          : () async {
              final messenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(context);
              await context.read<AccountController>().switchTo(account);

              navigator.pop();
              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                    strings.nowActingAs(accountName(account, strings)),
                  ),
                ),
              );
            },
    );
  }
}

/// Who you are, at the head of the profile — and the way to be someone else.
///
/// **A header, not a card** since 0.23: a large avatar, the name at page
/// size, where they are, and "Switch account" said in words under it, the
/// way a profile with more than one account usually says it. The whole row
/// opens the switcher. It used to be a bordered list tile under a "Demo
/// accounts" heading, which put the demo's mechanics above the person.
class AccountCard extends StatelessWidget {
  const AccountCard({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final account = context.watch<AccountController>().active;

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: () => AccountSheet.open(context),
        borderRadius: BrandRadius.largeAll,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: BrandSizing.spaceXs,
            vertical: BrandSizing.spaceSm,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AccountAvatar(account: account, radius: 30),
              const SizedBox(width: BrandSizing.spaceMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section size, bold: under the page's own "Profile" a
                    // second 24px heading would compete with it.
                    Text(
                      accountName(account, strings),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      account.area ??
                          (account.isAdmin
                              ? strings.accountStaffHelp
                              : strings.accountYouHelp),
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: BrandSizing.spaceSm),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.swap_horiz,
                          size: 18,
                          color: theme.accentText,
                        ),
                        const SizedBox(width: BrandSizing.spaceXs + 2),
                        Flexible(
                          child: Text(
                            strings.switchAccount,
                            style: BrandType.supporting.copyWith(
                              color: theme.accentText,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
