import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/bid_controller.dart';
import '../../app/job_controller.dart';
import '../../app/rating_controller.dart';
import '../../features/jobs/saved_jobs_controller.dart';
import '../../app/profile_controller.dart';
import '../../app/wallet_controller.dart';
import '../../core/formatters.dart';
import '../../app/settings_controller.dart';
import '../../core/app_version.dart';
import '../../core/layout.dart';
import '../../core/tokens.dart';
import '../../models/worker_profile.dart';
import '../../services/backend/mock_backend.dart';
import '../../services/backend/remote_api.dart';
import '../../widgets/settings_group.dart';
import '../../widgets/state_views.dart';
import '../../widgets/status_pill.dart';
import '../../l10n/app_localizations.dart';
import '../wallet/wallet_screen.dart';
import 'my_trades_screen.dart';
import '../../app/admin_controller.dart';
import '../../app/message_controller.dart';
import '../../app/sync_controller.dart';
import '../../app/verification_controller.dart';
import '../../app/premium_controller.dart';
import '../admin/admin_screen.dart';
import '../verification/verification_screen.dart';
import '../account/account_switcher.dart';
import '../directory/my_listing_screen.dart';
import '../ratings/worker_standing_view.dart';
import '../../app/account_controller.dart';

/// Who you are here, and how the app behaves for you.
///
/// Role and trades are not settings — they decide which jobs the rest of the
/// app shows you at all — so they lead, above the appearance and language
/// controls. Giving them a destination of their own also gives P1-5 somewhere
/// to put a rating, a completed-jobs count and a fare average, rather than
/// bolting a marketplace identity onto a preferences screen.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final settings = context.watch<SettingsController>();
    final theme = Theme.of(context);
    final isAdmin = context.watch<AccountController>().active.isAdmin;

    return Scaffold(
      appBar: AppBar(title: Text(strings.navProfile)),
      body: ReadableWidth(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            BrandSizing.spaceMd,
            BrandSizing.spaceSm,
            BrandSizing.spaceMd,
            BrandSizing.spaceXl,
          ),
          children: [
            // Who you are, first. Above the role picker, because switching
            // account can change the role underneath it — and a control that
            // silently reorders the one below should sit above it.
            Padding(
              padding: const EdgeInsetsDirectional.only(
                start: BrandSizing.spaceXs,
                bottom: BrandSizing.spaceSm,
              ),
              child: Text(
                strings.demoAccounts,
                style: theme.textTheme.titleMedium,
              ),
            ),
            const AccountCard(),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                BrandSizing.spaceXs,
                BrandSizing.spaceSm,
                BrandSizing.spaceXs,
                0,
              ),
              child: Text(
                strings.demoAccountsExplain,
                style: theme.textTheme.bodyMedium,
              ),
            ),

            // Straight after the account, because for the one account that
            // has it this is the whole reason to be here — and burying it
            // under the appearance controls would put the platform's own
            // tools three screens below a light/dark switch.
            const _AdminSection(),

            // Then, because it changes what the rest of the app shows: a
            // worker gets a feed filtered to their trades, a hirer gets the
            // jobs they posted.
            //
            // Not for staff. Trust Hire's own account is not looking for work
            // and is not hiring, and offering it a wallet and a trade list
            // would be four controls that mean nothing on the one account
            // that has a different job entirely.
            if (!isAdmin) ...[
              const SizedBox(height: BrandSizing.spaceLg),
              const _RolePicker(),
            ],

            const SizedBox(height: BrandSizing.spaceLg),
            SettingsGroup(
              title: strings.navSettings,
              children: [
                GroupPadding(
                  child: _Labelled(
                    label: strings.appearance,
                    child: SegmentedButton<ThemeMode>(
                      segments: [
                        ButtonSegment(
                          value: ThemeMode.system,
                          label: Text(strings.themeSystem),
                          icon: const Icon(Icons.brightness_auto_outlined),
                        ),
                        ButtonSegment(
                          value: ThemeMode.light,
                          label: Text(strings.themeLight),
                          icon: const Icon(Icons.light_mode_outlined),
                        ),
                        ButtonSegment(
                          value: ThemeMode.dark,
                          label: Text(strings.themeDark),
                          icon: const Icon(Icons.dark_mode_outlined),
                        ),
                      ],
                      selected: {settings.themeMode},
                      onSelectionChanged: (selection) =>
                          settings.setThemeMode(selection.first),
                    ),
                  ),
                ),
                GroupPadding(
                  child: _Labelled(
                    label: strings.language,
                    child: SegmentedButton<String>(
                      segments: [
                        ButtonSegment(
                          value: '',
                          label: Text(strings.themeSystem),
                          icon: const Icon(Icons.translate),
                        ),
                        for (final locale in SettingsController.supportedLocales)
                          ButtonSegment(
                            value: locale.languageCode,
                            // Each language names itself, so someone who
                            // cannot read the current one can still find
                            // their own.
                            label: Text(
                              strings.localeName == locale.languageCode
                                  ? strings.languageName
                                  : _languageName(locale.languageCode),
                            ),
                          ),
                      ],
                      selected: {settings.locale?.languageCode ?? ''},
                      onSelectionChanged: (selection) => settings.setLocale(
                        selection.first.isEmpty
                            ? null
                            : Locale(selection.first),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // The proof-of-concept small print, at the foot rather than the
            // head. It used to be the first thing on this screen, which put
            // a disclaimer above the person's own name.
            const SizedBox(height: BrandSizing.spaceLg),
            SettingsGroup(
              title: strings.profileThisDemo,
              caption: strings.settingsStorageNotice,
              children: [
                ListTile(
                  leading: const Icon(Icons.slideshow_outlined),
                  title: Text(strings.showIntroAgain),
                  onTap: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    await settings.resetIntro();
                    messenger.showSnackBar(
                      SnackBar(content: Text(strings.introReset)),
                    );
                  },
                ),
                ListTile(
                  // The colour is on the icon only: Error Red is too dark to
                  // read as text on the dark theme's surfaces. The words say
                  // what it does, and a confirmation says it again.
                  leading: const Icon(
                    Icons.restart_alt,
                    color: BrandColours.errorRed,
                  ),
                  // Section 21 — explicit label, never "Confirm".
                  title: Text(strings.restoreSeedData),
                  subtitle: Text(strings.restoreSeedExplanation),
                  onTap: () => _confirmReset(context),
                ),
              ],
            ),

            const SizedBox(height: BrandSizing.spaceLg),
            const _BackendSection(),

            const _VersionLine(),
          ],
        ),
      ),
    );
  }

  /// A language's own name, so it is legible to whoever speaks it regardless
  /// of the interface language currently in force.
  static String _languageName(String code) => switch (code) {
    'ur' => 'اردو',
    _ => 'English',
  };

  Future<void> _confirmReset(BuildContext context) async {
    final strings = AppStrings.of(context);
    final controller = context.read<JobController>();
    final messenger = ScaffoldMessenger.of(context);

    // Everything the reset rewrites. Read before the dialogue, because after
    // an await the context may be gone.
    final bids = context.read<BidController>();
    final ratings = context.read<RatingController>();
    final wallet = context.read<WalletController>();
    final profile = context.read<ProfileController>();
    final saved = context.read<SavedJobsController>();
    final premium = context.read<PremiumController>();
    final admin = context.read<AdminController>();
    final verification = context.read<VerificationController>();
    final messages = context.read<MessageController>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: const RoundedRectangleBorder(borderRadius: BrandRadius.largeAll),
        title: Text(strings.restoreSeedTitle),
        content: Text(strings.restoreSeedWarning),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(strings.keepMyJobs),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: BrandColours.errorRed),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(strings.restoreSeedData),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await controller.resetToSeed();

    // **Everything the seed writes has to be re-read here.** The reset
    // replaces the offers, ratings, wallets, trades, directory listings and
    // the admin panel's data as well as the jobs, and every one of those is
    // already in memory somewhere. Without this the screen would show a
    // restored map beside a wallet balance that no longer exists in storage —
    // and the next write would put the stale one back.
    //
    // This list has to grow whenever `DemoSeed` learns to write something
    // new; `demo_history_test.dart` fails if it does not.
    await bids.load();
    ratings.load();
    wallet.load();
    profile.load();
    saved.load();
    premium.load();
    admin.load();
    verification.load();
    await messages.load();

    messenger.showSnackBar(SnackBar(content: Text(strings.seedRestored)));
  }
}

/// Section 2, from the profile.
///
/// Above the trades rather than below the wallet: what a worker does is a
/// setting, whether a hirer can see they have been through verification is
/// closer to who they are. It is never a gate — the subtitle counts steps
/// rather than saying "incomplete", because there is nothing here that has to
/// be completed to use the app.
class _VerificationTile extends StatelessWidget {
  const _VerificationTile();

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final verification = context.watch<VerificationController>();
    final mine = verification.mine;

    return ListTile(
      leading: Icon(
        mine.isComplete ? Icons.verified_user : Icons.badge_outlined,
        color: mine.isFlagged
            ? BrandColours.warningAmber
            : (mine.isComplete ? BrandColours.successTeal : null),
      ),
      title: Text(strings.verificationTile),
      subtitle: Text(strings.verificationSubtitle(mine.stepsDone)),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => VerificationScreen.open(context),
    );
  }
}

/// The backend seam, made visible.
///
/// There is no server, and a seam nobody can see is a claim rather than a
/// demonstration — so this shows the queue, lets somebody switch the stand-in
/// off, and lists anything the server would not take. **The refusals are the
/// part worth showing:** an offline app that quietly discards a change the
/// server rejects is the failure mode this whole layer exists to avoid.
class _BackendSection extends StatelessWidget {
  const _BackendSection();

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final sync = context.watch<SyncController>();
    final backend = context.read<MockBackend>();

    final state = sync.state();
    final label = switch (state) {
      SyncState.settled => strings.syncSettled,
      SyncState.sending => strings.syncSending,
      SyncState.offline => strings.syncOffline,
      SyncState.needsAttention => strings.syncNeedsAttention,
    };

    return SettingsGroup(
      title: strings.backendSection,
      caption: strings.backendExplain,
      children: [
        GroupPadding(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  switch (state) {
                    SyncState.settled => StatusPill.good(label),
                    SyncState.needsAttention => StatusPill.bad(label),
                    _ => StatusPill.muted(context, label),
                  },
                  const SizedBox(width: BrandSizing.spaceSm),
                  Expanded(
                    child: Text(
                      strings.syncWaiting(sync.outbox.length),
                      style: theme.textTheme.labelMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: BrandSizing.spaceXs),
              Text(
                sync.lastPulledAt == null
                    ? strings.syncNeverPulled
                    : strings.syncLastPulled(
                        Format.day(strings, sync.lastPulledAt!),
                      ),
                style: theme.textTheme.labelSmall,
              ),
            ],
          ),
        ),
        SwitchListTile(
          title: Text(strings.syncPretendOffline),
          value: backend.offline,
          onChanged: (value) {
            backend.offline = value;
            // The switch belongs to the mock, which is not a listenable — so
            // ask the controller to re-evaluate rather than leaving the pill
            // describing a connection that has just changed.
            sync.load();
          },
        ),
        ListTile(
          leading: const Icon(Icons.sync),
          title: Text(strings.syncNow),
          onTap: () async {
            await sync.push();
            await sync.pull();
          },
        ),
        if (sync.needAttention.isNotEmpty)
          GroupPadding(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(strings.syncRefusals, style: theme.textTheme.titleMedium),
                const SizedBox(height: BrandSizing.spaceSm),
                for (final refusal in sync.needAttention)
                  Padding(
                    padding: const EdgeInsets.only(bottom: BrandSizing.spaceSm),
                    child: NoticePanel(
                      message: _wordFor(strings, refusal.code),
                      icon: Icons.error_outline,
                      tone: NoticeTone.warning,
                    ),
                  ),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton(
                    onPressed: sync.acknowledge,
                    child: Text(strings.syncAcknowledge),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// The wording for a refusal.
  ///
  /// Here rather than on the wire: a server that sends prose decides what
  /// language the app speaks, and this one speaks two.
  static String _wordFor(AppStrings strings, RefusalCode code) =>
      switch (code) {
        RefusalCode.fareIsLocked => strings.refusalFareIsLocked,
        RefusalCode.workerCannotBeSwapped => strings.refusalWorkerSwapped,
        RefusalCode.nobodyWorksForThemselves => strings.refusalOwnJob,
        RefusalCode.anotherOfferWasAccepted => strings.refusalAnotherOfferWon,
        RefusalCode.offerDoesNotMatchTheJob => strings.refusalOfferMismatch,
        RefusalCode.recordIsAppendOnly => strings.refusalAppendOnly,
        RefusalCode.commissionAlreadyCharged =>
          strings.refusalCommissionCharged,
        RefusalCode.paymentAlreadyCredited => strings.refusalPaymentCredited,
        RefusalCode.jobIsNotFinished => strings.refusalJobNotFinished,
        RefusalCode.alreadyRatedFromThatSide => strings.refusalAlreadyRated,
        RefusalCode.messageCannotBeEdited => strings.refusalMessageEdited,
        RefusalCode.changedElsewhere => strings.refusalChangedElsewhere,
        RefusalCode.unreachable => strings.refusalUnreachable,
      };
}

/// The wallet, from the profile.
///
/// Only for a worker: the commission is charged to the person doing the work,
/// so a hirer has no balance to look at.
class _WalletTile extends StatelessWidget {
  const _WalletTile();

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final wallet = context.watch<WalletController>();

    return ListTile(
      leading: Icon(
        wallet.isLockedOut
            ? Icons.lock_outline
            : Icons.account_balance_wallet_outlined,
        color: wallet.isInDebt ? BrandColours.errorRed : null,
      ),
      title: Text(strings.navWallet),
      subtitle: Text(Format.fare(strings, wallet.balance)),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => WalletScreen.open(context),
    );
  }
}

/// The admin panel, for the one account that has it.
///
/// Shown rather than hidden behind a gesture: this is a demonstration, and a
/// feature nobody can find is a feature nobody can assess. It appears only
/// while the active demo account is staff, which is a property of the account
/// rather than a switch anybody can flip.
class _AdminSection extends StatelessWidget {
  const _AdminSection();

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final account = context.watch<AccountController>().active;

    if (!account.isAdmin) return const SizedBox.shrink();

    final admin = context.watch<AdminController>();
    final waiting = admin.queue.length + admin.openDisputes.length;

    return Padding(
      padding: const EdgeInsets.only(top: BrandSizing.spaceLg),
      child: SettingsGroup(
        title: strings.adminPanel,
        children: [
          ListTile(
            leading: const Icon(Icons.shield_outlined),
            title: Text(strings.adminPanelTile),
            subtitle: Text(strings.adminSubtitle(waiting)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => AdminScreen.open(context),
          ),
        ],
      ),
    );
  }
}

/// The way into Mode B, from the worker's side.
///
/// Under the wallet, because that is the order the money runs in: a worker
/// pays commission out of the wallet whatever they do, and pays for a listing
/// only if they choose to be found rather than to go looking.
class _ListingTile extends StatelessWidget {
  const _ListingTile();

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final premium = context.watch<PremiumController>();

    return ListTile(
      leading: Icon(
        premium.isPremium ? Icons.badge : Icons.badge_outlined,
        color: premium.isPremium ? BrandColours.copper : null,
      ),
      title: Text(strings.myListing),
      subtitle: Text(
        premium.hasLapsed
            ? strings.premiumLapsed
            : strings.myListingSubtitle(premium.mine.services.length),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => MyListingScreen.open(context),
    );
  }
}

/// The build, at the foot of settings — where people look for it.
class _VersionLine extends StatelessWidget {
  const _VersionLine();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: BrandSizing.spaceXl),
      child: Text(
        AppVersion.label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

/// Worker or hirer, and — for a worker — the way through to their trades.
///
/// Switching role never touches the tag list. Someone who hires a painter
/// today and looks for work tomorrow should not have to pick their trades
/// again, and quietly clearing them would empty their feed with no explanation.
class _RolePicker extends StatelessWidget {
  const _RolePicker();

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final profile = context.watch<ProfileController>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.only(
            start: BrandSizing.spaceXs,
            bottom: BrandSizing.spaceSm,
          ),
          child: Text(
            strings.whatBringsYouHere,
            style: theme.textTheme.titleMedium,
          ),
        ),
        // Two cards rather than a segmented control: the two labels are
        // whole phrases, and in Urdu at a large text size a segmented control
        // wrapped them a word a line.
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _RoleCard(
                  icon: Icons.handyman_outlined,
                  label: strings.roleWorker,
                  selected: profile.isWorker,
                  onTap: () => profile.setRole(UserRole.worker),
                ),
              ),
              const SizedBox(width: BrandSizing.spaceSm + 4),
              Expanded(
                child: _RoleCard(
                  icon: Icons.post_add_outlined,
                  label: strings.roleHirer,
                  selected: !profile.isWorker,
                  onTap: () => profile.setRole(UserRole.hirer),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            BrandSizing.spaceXs,
            BrandSizing.spaceSm,
            BrandSizing.spaceXs,
            0,
          ),
          child: Text(
            profile.isWorker ? strings.roleWorkerHelp : strings.roleHirerHelp,
            style: theme.textTheme.bodyMedium,
          ),
        ),
        if (profile.isWorker) ...[
          const SizedBox(height: BrandSizing.spaceLg),
          SettingsGroup(
            title: strings.profileYourWork,
            children: [
              // Your own record, the way a hirer reviewing your offer sees
              // it. Shown to you unprompted because Section 10 makes it the
              // thing that decides what you are offered next — a number that
              // governs your income should not be something you have to go
              // looking for.
              GroupPadding(
                child: WorkerStandingView(
                  workerId: context.watch<AccountController>().activeId,
                  heading: strings.yourStanding,
                ),
              ),
              const _VerificationTile(),
              ListTile(
                leading: const Icon(Icons.construction_outlined),
                title: Text(strings.myTrades),
                subtitle: Text(strings.tradeCount(profile.specialities.length)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => MyTradesScreen.open(context),
              ),
              const _WalletTile(),
              const _ListingTile(),
            ],
          ),
        ],
      ],
    );
  }
}

/// One side of the marketplace, as something to choose.
///
/// Selection is said three ways — the border, the tint and a tick — and to a
/// screen reader as a selected button in a group of two, so colour is never
/// the only sign of which one is on.
class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isLight = theme.brightness == Brightness.light;

    return Semantics(
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: Material(
        color: selected
            ? (isLight ? BrandColours.warmSand : BrandColours.darkElevated)
            : scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BrandRadius.largeAll,
          side: BorderSide(
            color: selected ? scheme.primary : scheme.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(BrandSizing.spaceMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      icon,
                      color: selected ? scheme.primary : scheme.onSurfaceVariant,
                    ),
                    const Spacer(),
                    if (selected)
                      Icon(Icons.check_circle, size: 20, color: scheme.primary),
                  ],
                ),
                const SizedBox(height: BrandSizing.spaceSm + 4),
                Text(
                  label,
                  style: BrandType.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A control with its name above it, inside a group.
class _Labelled extends StatelessWidget {
  const _Labelled({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: BrandType.supporting.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: BrandSizing.spaceSm),
        child,
      ],
    );
  }
}
