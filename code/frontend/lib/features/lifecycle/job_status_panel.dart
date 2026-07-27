import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/account_controller.dart';
import '../../app/job_controller.dart';
import '../../app/wallet_controller.dart';
import '../../core/tokens.dart';
import '../../l10n/app_localizations.dart';
import '../../models/job.dart';
import '../../models/job_status.dart';
import '../../app/rating_controller.dart';
import '../../widgets/state_views.dart';
import '../ratings/rating_sheet.dart';
import 'job_lifecycle.dart';

/// Where a job stands, and what the person looking at it can do next.
///
/// One panel for both sides. The actions differ — Section 7 gives arrival and
/// completion to the hirer, because the hirer is the one who can see whether
/// anybody turned up — but the *state* is the same fact for everybody, and
/// showing it in two different places would let the two drift.
class JobStatusPanel extends StatelessWidget {
  const JobStatusPanel({
    super.key,
    required this.job,
    this.lifecycle = const JobLifecycle(),
  });

  final Job job;
  final JobLifecycle lifecycle;

  Future<void> _run(BuildContext context, JobAction action) async {
    final strings = AppStrings.of(context);
    final jobs = context.read<JobController>();
    final wallet = context.read<WalletController>();
    final me = context.read<AccountController>().activeId;
    final role = lifecycle.roleFor(job, viewerId: me);

    if (action == JobAction.cancel) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          shape: const RoundedRectangleBorder(
            borderRadius: BrandRadius.largeAll,
          ),
          title: Text(strings.cancelJob),
          content: Text(strings.cancelJobExplanation),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(strings.keepJob),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: BrandColours.errorRed,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(strings.cancelJob),
            ),
          ],
        ),
      );

      if (confirmed != true) return;
    }

    // Null when the job moved on while the sheet was open — a race, not an
    // error, so nothing is said and nothing is written.
    final next = lifecycle.resultOf(action, job: job, role: role);
    if (next == null) return;

    await jobs.saveJob(job.withStatus(next));

    // The money follows the status, and only after it is saved. If the write
    // above fails, nobody has been charged for a job that did not finish.
    // Both wallet calls are idempotent by job id, so a retry cannot charge
    // twice — see WalletController.
    final fare = job.agreedFare;
    if (next == JobStatus.completed && fare != null) {
      await wallet.recordCompletion(jobId: job.id, agreedFare: fare);
    } else if (next == JobStatus.cancelled && role == JobRole.worker) {
      // Only the worker is penalised. Section 11 charges the person who
      // accepted a job and then walked away from it.
      await wallet.recordWorkerCancellation(jobId: job.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final me = context.watch<AccountController>().activeId;
    final role = lifecycle.roleFor(job, viewerId: me);
    final actions = lifecycle.actionsFor(job, role: role);

    final ending = switch (job.status) {
      JobStatus.completed => strings.jobFinished,
      JobStatus.cancelled => strings.jobCalledOff,
      JobStatus.expired => strings.jobExpired,
      _ => null,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            _StatusChip(status: job.status),
            const SizedBox(width: BrandSizing.spaceSm),
            if (job.status == JobStatus.inProgress)
              Expanded(
                child: Text(
                  strings.statusInProgress,
                  style: theme.textTheme.labelSmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),

        if (ending != null) ...[
          const SizedBox(height: BrandSizing.spaceSm),
          NoticePanel(message: ending, icon: Icons.info_outline),
        ],

        // Only on a finished job, and only for the two people who were in it.
        // A cancelled job is deliberately not ratable — nobody did any work,
        // and a one-star for a job that never happened is a weapon rather
        // than a signal.
        if (job.status == JobStatus.completed && role != JobRole.bystander)
          _RatingPrompt(job: job, role: role),

        for (final action in actions) ...[
          const SizedBox(height: BrandSizing.spaceSm),
          if (action == JobAction.cancel)
            OutlinedButton(
              onPressed: () => _run(context, action),
              style: OutlinedButton.styleFrom(
                foregroundColor: BrandColours.errorRed,
              ),
              child: Text(strings.cancelJob),
            )
          else
            FilledButton(
              onPressed: () => _run(context, action),
              child: Text(switch (action) {
                JobAction.confirmArrival => strings.confirmArrival,
                JobAction.markComplete => strings.markComplete,
                JobAction.cancel => strings.cancelJob,
              }),
            ),
        ],
      ],
    );
  }
}

/// The way in to rating the other person, once there is one.
///
/// It replaces itself with a note when the rating is already given, rather
/// than disappearing: a button that vanishes reads as a failed tap, and a
/// person who cannot remember whether they rated somebody will tap it again.
class _RatingPrompt extends StatelessWidget {
  const _RatingPrompt({required this.job, required this.role});

  final Job job;
  final JobRole role;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final ratings = context.watch<RatingController>();

    if (!ratings.canRate(job, role: role)) {
      return Padding(
        padding: const EdgeInsets.only(top: BrandSizing.spaceSm),
        child: Text(strings.alreadyRated, style: theme.textTheme.labelSmall),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: BrandSizing.spaceSm),
      child: FilledButton.tonalIcon(
        onPressed: () => RatingSheet.open(context, job: job, role: role),
        icon: const Icon(Icons.star_border),
        label: Text(strings.rateThisJob),
      ),
    );
  }
}

/// The state, as a word rather than a colour.
///
/// Section 29 of the brand guidelines: colour is never the only carrier of
/// meaning, so the chip is labelled and the tint only reinforces it.
class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final JobStatus status;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);

    final (background, foreground) = switch (status) {
      JobStatus.open => (
        theme.colorScheme.surfaceContainerHighest,
        theme.colorScheme.onSurfaceVariant,
      ),
      JobStatus.accepted || JobStatus.inProgress => (
        theme.colorScheme.primary,
        theme.colorScheme.onPrimary,
      ),
      JobStatus.completed => (BrandColours.successTeal, BrandColours.white),
      JobStatus.cancelled || JobStatus.expired => (
        theme.colorScheme.surfaceContainerHighest,
        theme.colorScheme.onSurfaceVariant,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: BrandSizing.spaceSm + 2,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BrandRadius.smallAll,
      ),
      child: Text(
        status.label(strings),
        style: theme.textTheme.labelSmall?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
