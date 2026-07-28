import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../app/admin_controller.dart';
import '../../app/bid_controller.dart';
import '../../app/job_controller.dart';
import '../../core/formatters.dart';
import '../../core/layout.dart';
import '../../core/tokens.dart';
import '../../l10n/app_localizations.dart';
import '../../models/admin.dart';
import '../../models/job.dart';
import '../../widgets/state_views.dart';
import 'admin_rules.dart';

/// Section 12, in four tabs: who is waiting, what has gone wrong, what is
/// happening, and what staff have done about it.
///
/// **The last tab is the point.** An admin panel is a set of powers to
/// override the rules the rest of the app enforces, and the only thing that
/// makes that acceptable is that every use of them is written down. So the log
/// is not a diagnostic afterthought — it is the feature, and everything else
/// here is the thing that writes to it.
class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  static Future<void> open(BuildContext context) => Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => const AdminScreen()),
  );

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 4, vsync: this);

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final admin = context.watch<AdminController>();

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.adminPanel),
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          tabs: [
            Tab(text: '${strings.adminTabUsers} · ${admin.queue.length}'),
            Tab(
              text:
                  '${strings.adminTabDisputes} · ${admin.openDisputes.length}',
            ),
            Tab(text: strings.adminTabJobs),
            Tab(text: '${strings.adminTabLog} · ${admin.log.length}'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: const [
          _UsersTab(),
          _DisputesTab(),
          _JobsTab(),
          _LogTab(),
        ],
      ),
    );
  }
}

/// The approval queue, and the wallet overrides that go with a person.
class _UsersTab extends StatelessWidget {
  const _UsersTab();

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final admin = context.watch<AdminController>();

    // The queue first, then everybody else — a panel that only ever showed
    // the queue would give staff no way back to somebody they have already
    // decided on, which is exactly who a complaint is about.
    final queue = admin.queue;
    final decided = admin.reviews
        .where((review) => !review.needsDecision)
        .toList(growable: false);

    if (admin.reviews.isEmpty) {
      return EmptyView(
        icon: Icons.how_to_reg_outlined,
        title: strings.adminQueueEmpty,
        message: strings.adminQueueEmptyMessage,
      );
    }

    return ReadableWidth(
      child: ListView(
        padding: const EdgeInsets.all(BrandSizing.spaceMd),
        children: [
          Text(
            strings.signalCaveat,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: BrandSizing.spaceMd),

          for (final review in [...queue, ...decided]) ...[
            _ReviewCard(review: review),
            const SizedBox(height: BrandSizing.spaceSm + 4),
          ],
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review});

  final AccountReview review;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final admin = context.watch<AdminController>();
    final jobs = context.watch<JobController>();

    final name = jobs.userById(review.userId)?.name ?? review.userId;
    final wallet = admin.walletOf(review.userId);
    final locked = admin.walletRules.isLockedOut(wallet);

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BrandRadius.mediumAll,
        side: BorderSide(
          color: review.isFlagged
              ? BrandColours.errorRed.withValues(alpha: 0.5)
              : theme.colorScheme.outlineVariant,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(BrandSizing.spaceMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(name, style: theme.textTheme.titleMedium),
                ),
                _StatusPill(status: review.status),
              ],
            ),

            const SizedBox(height: BrandSizing.spaceSm),
            Wrap(
              spacing: BrandSizing.spaceXs,
              runSpacing: BrandSizing.spaceXs,
              children: [
                _Signal(
                  ok: review.cnicOnFile,
                  label: review.cnicOnFile
                      ? strings.signalCnicOnFile
                      : strings.signalCnicMissing,
                ),
                if (review.cnicOnFile && review.cnicPlausible)
                  _Signal(ok: true, label: strings.signalCnicShape),
                _Signal(
                  ok: review.phoneVerified,
                  label: review.phoneVerified
                      ? strings.signalPhoneVerified
                      : strings.signalPhoneUnverified,
                ),
                if (review.isFlagged)
                  _Signal(ok: false, label: strings.signalSimMismatch),
              ],
            ),

            if (review.isFlagged) ...[
              const SizedBox(height: BrandSizing.spaceXs),
              // Section 2 is explicit that false positives are expected. A
              // flag that read as guilt would get people rejected for lending
              // their brother a phone.
              Text(
                strings.simMismatchCaveat,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],

            const SizedBox(height: BrandSizing.spaceSm),
            Text(
              locked
                  ? strings.adminWalletLocked(
                      Format.fare(strings, -wallet.balance),
                    )
                  : strings.adminWalletBalance(
                      Format.fare(strings, wallet.balance),
                    ),
              style: theme.textTheme.labelMedium?.copyWith(
                color: locked ? BrandColours.errorRed : null,
              ),
            ),

            const SizedBox(height: BrandSizing.spaceSm),
            Wrap(
              spacing: BrandSizing.spaceSm,
              runSpacing: BrandSizing.spaceXs,
              children: [
                if (review.status != ReviewStatus.approved)
                  FilledButton.tonal(
                    onPressed: () => admin.approve(review.userId),
                    child: Text(
                      admin.rules.mayReinstate(review)
                          ? strings.adminReinstate
                          : strings.adminApprove,
                    ),
                  ),
                if (review.status != ReviewStatus.suspended)
                  OutlinedButton(
                    onPressed: () => _OverrideSheet.open(
                      context,
                      title: strings.adminSuspend,
                      onConfirm: (note, _) =>
                          admin.suspend(review.userId, note: note),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: BrandColours.errorRed,
                    ),
                    child: Text(strings.adminSuspend),
                  ),
                if (locked)
                  OutlinedButton(
                    onPressed: () => _OverrideSheet.open(
                      context,
                      title: strings.adminUnlockWallet,
                      onConfirm: (note, _) =>
                          admin.unlockWallet(review.userId, note: note),
                    ),
                    child: Text(strings.adminUnlockWallet),
                  ),
                OutlinedButton(
                  onPressed: () => _OverrideSheet.open(
                    context,
                    title: strings.adminAdjustWallet,
                    withAmount: true,
                    onConfirm: (note, tokens) => admin.adjustWallet(
                      review.userId,
                      tokens: tokens ?? 0,
                      note: note,
                    ),
                  ),
                  child: Text(strings.adminAdjustWallet),
                ),
                _CnicButton(userId: review.userId),
              ],
            ),

            if (review.note != null) ...[
              const SizedBox(height: BrandSizing.spaceXs),
              Text(review.note!, style: theme.textTheme.labelSmall),
            ],
          ],
        ),
      ),
    );
  }
}

/// The one control in the app that refuses before it is pressed.
///
/// Disabled and explained rather than hidden: staff need to know the document
/// exists and why they cannot see it, or the rule looks like a bug and
/// somebody goes looking for a way round it.
class _CnicButton extends StatelessWidget {
  const _CnicButton({required this.userId});

  final String userId;

  Future<void> _open(BuildContext context) async {
    final strings = AppStrings.of(context);
    final admin = context.read<AdminController>();
    final messenger = ScaffoldMessenger.of(context);

    final record = await admin.openCnic(
      userId,
      note: strings.actionViewCnic,
    );
    if (record == null || !context.mounted) return;

    messenger.showSnackBar(SnackBar(content: Text(strings.adminCnicOpened)));

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: const RoundedRectangleBorder(borderRadius: BrandRadius.largeAll),
        title: Text(strings.adminOpenCnic),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${strings.cnicNameLabel}: ${record.nameOnCard}'),
            const SizedBox(height: BrandSizing.spaceXs),
            Text('${strings.cnicNumberLabel}: ${record.maskedNumber}'),
            const SizedBox(height: BrandSizing.spaceSm),
            Text(
              strings.cnicNoPhoto,
              style: Theme.of(dialogContext).textTheme.labelSmall,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(strings.close),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final allowed = context.watch<AdminController>().mayOpenCnic(userId);

    return Tooltip(
      message: allowed ? strings.adminOpenCnic : strings.adminCnicLocked,
      child: OutlinedButton.icon(
        onPressed: allowed ? () => _open(context) : null,
        icon: Icon(allowed ? Icons.badge_outlined : Icons.lock_outline),
        label: Text(strings.adminOpenCnic),
      ),
    );
  }
}

class _DisputesTab extends StatelessWidget {
  const _DisputesTab();

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final admin = context.watch<AdminController>();
    final jobs = context.watch<JobController>();

    if (admin.disputes.isEmpty) {
      return EmptyView(
        icon: Icons.gavel_outlined,
        title: strings.adminNoDisputes,
        message: strings.adminNoDisputesMessage,
      );
    }

    String name(String id) => jobs.userById(id)?.name ?? id;

    return ReadableWidth(
      child: ListView(
        padding: const EdgeInsets.all(BrandSizing.spaceMd),
        children: [
          for (final dispute in admin.disputes) ...[
            Card(
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BrandRadius.mediumAll,
                side: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
              child: Padding(
                padding: const EdgeInsets.all(BrandSizing.spaceMd),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            strings.disputeAbout(name(dispute.aboutUserId)),
                            style: theme.textTheme.titleMedium,
                          ),
                        ),
                        Text(
                          dispute.isOpen
                              ? strings.disputeOpen
                              : strings.disputeClosed,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: dispute.isOpen
                                ? BrandColours.errorRed
                                : theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: BrandSizing.spaceXs),
                    Text(
                      strings.disputeRaisedBy(name(dispute.raisedByUserId)),
                      style: theme.textTheme.labelSmall,
                    ),
                    const SizedBox(height: BrandSizing.spaceSm),
                    Text(dispute.reason, style: theme.textTheme.bodyMedium),

                    if (dispute.resolution != null) ...[
                      const SizedBox(height: BrandSizing.spaceSm),
                      Text(
                        dispute.resolution!,
                        style: theme.textTheme.labelMedium,
                      ),
                    ],

                    if (dispute.isOpen) ...[
                      const SizedBox(height: BrandSizing.spaceSm),
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: OutlinedButton(
                          onPressed: () => _OverrideSheet.open(
                            context,
                            title: strings.adminCloseDispute,
                            onConfirm: (note, _) =>
                                admin.closeDispute(dispute.id, note: note),
                          ),
                          child: Text(strings.adminCloseDispute),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: BrandSizing.spaceSm + 4),
          ],
        ],
      ),
    );
  }
}

/// Every job on the platform, with its bid history. Read-only.
///
/// Section 12 asks for "visibility into all jobs and bid history
/// platform-wide", and visibility is the whole ask — an admin who could edit
/// somebody's job would be able to change an agreed fare after the fact, which
/// is the one number the commission depends on.
class _JobsTab extends StatelessWidget {
  const _JobsTab();

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final jobs = context.watch<JobController>();
    final bids = context.watch<BidController>();

    final all = [...jobs.jobs]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return ReadableWidth(
      child: ListView.builder(
        padding: const EdgeInsets.all(BrandSizing.spaceMd),
        itemCount: all.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: BrandSizing.spaceSm),
              child: Text(
                strings.adminJobsIntro,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            );
          }

          final job = all[index - 1];
          return _JobRow(job: job, offers: bids.forJob(job.id).length);
        },
      ),
    );
  }
}

class _JobRow extends StatelessWidget {
  const _JobRow({required this.job, required this.offers});

  final Job job;
  final int offers;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      title: Text(job.displayTitle(strings)),
      subtitle: Text(
        [
          job.status.label(strings),
          strings.adminOffersOn(offers),
          if (job.agreedFare != null) Format.fare(strings, job.agreedFare!),
        ].join(' · '),
        style: theme.textTheme.labelSmall,
      ),
    );
  }
}

/// The record.
class _LogTab extends StatelessWidget {
  const _LogTab();

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final admin = context.watch<AdminController>();
    final jobs = context.watch<JobController>();

    if (admin.log.isEmpty) {
      return EmptyView(
        icon: Icons.receipt_long_outlined,
        title: strings.adminLogEmpty,
        message: strings.adminLogEmptyMessage,
      );
    }

    final now = DateTime.now();

    return ReadableWidth(
      child: ListView.separated(
        padding: const EdgeInsets.all(BrandSizing.spaceMd),
        itemCount: admin.log.length + 1,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: BrandSizing.spaceSm),
              child: Text(
                strings.adminLogIntro,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            );
          }

          final entry = admin.log[index - 1];
          final about = entry.targetUserId == null
              ? null
              : (jobs.userById(entry.targetUserId!)?.name ??
                    entry.targetUserId!);

          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              entry.action.isOverride
                  ? Icons.priority_high
                  : Icons.check_circle_outline,
              color: entry.action.isOverride ? BrandColours.copper : null,
            ),
            title: Text(_label(strings, entry.action)),
            subtitle: Text(
              [
                ?about,
                if (entry.tokens != null)
                  Format.fare(strings, entry.tokens!.abs()),
                Format.posted(strings, entry.at, now),
                if (entry.note != null) entry.note!,
              ].join(' · '),
            ),
          );
        },
      ),
    );
  }

  String _label(AppStrings strings, AdminAction action) => switch (action) {
    AdminAction.approveUser => strings.actionApproveUser,
    AdminAction.suspendUser => strings.actionSuspendUser,
    AdminAction.reinstateUser => strings.actionReinstateUser,
    AdminAction.viewCnic => strings.actionViewCnic,
    AdminAction.adjustWallet => strings.actionAdjustWallet,
    AdminAction.unlockWallet => strings.actionUnlockWallet,
    AdminAction.cancelJob => strings.actionCancelJob,
    AdminAction.closeDispute => strings.actionCloseDispute,
  };
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final ReviewStatus status;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);

    final (label, background, foreground) = switch (status) {
      ReviewStatus.pending => (
        strings.statusPending,
        theme.colorScheme.surfaceContainerHighest,
        theme.colorScheme.onSurfaceVariant,
      ),
      ReviewStatus.approved => (
        strings.statusApproved,
        BrandColours.successTeal,
        BrandColours.white,
      ),
      ReviewStatus.suspended => (
        strings.statusSuspended,
        BrandColours.errorRed,
        BrandColours.white,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: BrandSizing.spaceSm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BrandRadius.smallAll,
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _Signal extends StatelessWidget {
  const _Signal({required this.ok, required this.label});

  final bool ok;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          ok ? Icons.check : Icons.close,
          size: 16,
          color: ok ? BrandColours.successTeal : BrandColours.errorRed,
        ),
        const SizedBox(width: 4),
        Text(label, style: theme.textTheme.labelSmall),
      ],
    );
  }
}

/// Asking for the reason, before the override happens.
///
/// The note is required by [AdminRules.needsNote] and the controller refuses
/// without one, so this sheet is the polite half of a rule that holds whether
/// or not anybody builds a screen for it.
class _OverrideSheet extends StatefulWidget {
  const _OverrideSheet({
    required this.title,
    required this.onConfirm,
    this.withAmount = false,
  });

  final String title;
  final bool withAmount;
  final Future<void> Function(String note, int? tokens) onConfirm;

  static Future<void> open(
    BuildContext context, {
    required String title,
    required Future<void> Function(String note, int? tokens) onConfirm,
    bool withAmount = false,
  }) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _OverrideSheet(
      title: title,
      onConfirm: onConfirm,
      withAmount: withAmount,
    ),
  );

  @override
  State<_OverrideSheet> createState() => _OverrideSheetState();
}

class _OverrideSheetState extends State<_OverrideSheet> {
  final _note = TextEditingController();
  final _amount = TextEditingController();
  static const _rules = AdminRules();

  @override
  void dispose() {
    _note.dispose();
    _amount.dispose();
    super.dispose();
  }

  bool get _isReady {
    if (!_rules.isUsableNote(_note.text)) return false;
    if (!widget.withAmount) return true;
    return (int.tryParse(_amount.text.replaceAll('+', '')) ?? 0) != 0;
  }

  Future<void> _confirm() async {
    final navigator = Navigator.of(context);
    await widget.onConfirm(
      _note.text,
      int.tryParse(_amount.text.replaceAll('+', '')),
    );
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          BrandSizing.spaceMd,
          0,
          BrandSizing.spaceMd,
          BrandSizing.spaceMd + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.title, style: theme.textTheme.titleLarge),
            const SizedBox(height: BrandSizing.spaceSm),
            Text(
              strings.adminNoteRequired,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: BrandSizing.spaceMd),

            if (widget.withAmount) ...[
              TextField(
                controller: _amount,
                keyboardType: const TextInputType.numberWithOptions(
                  signed: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[-+0-9]')),
                ],
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: strings.adminAmountLabel,
                  border: const OutlineInputBorder(
                    borderRadius: BrandRadius.mediumAll,
                  ),
                ),
              ),
              const SizedBox(height: BrandSizing.spaceSm),
            ],

            TextField(
              controller: _note,
              maxLines: 3,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: strings.adminNoteLabel,
                border: const OutlineInputBorder(
                  borderRadius: BrandRadius.mediumAll,
                ),
              ),
            ),

            const SizedBox(height: BrandSizing.spaceMd),
            FilledButton(
              onPressed: _isReady ? _confirm : null,
              child: Text(strings.adminApply),
            ),
          ],
        ),
      ),
    );
  }
}
