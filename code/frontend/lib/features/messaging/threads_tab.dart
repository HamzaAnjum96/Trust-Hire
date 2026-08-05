import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/job_controller.dart';
import '../../app/message_controller.dart';
import '../../core/formatters.dart';
import '../../core/tokens.dart';
import '../../l10n/app_localizations.dart';
import '../../models/job.dart';
import '../../models/message.dart';
import '../../widgets/state_views.dart';
import 'messaging_rules.dart';
import 'thread_screen.dart';

/// Every conversation this account is part of.
///
/// A thread is reachable from its job's sheet as well, but only if you can
/// find the job — and the person waiting for an answer does not want to go
/// looking for the work to find the message about it.
class ThreadsTab extends StatelessWidget {
  const ThreadsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final messages = context.watch<MessageController>();
    final jobs = context.watch<JobController>();

    const rules = MessagingRules();
    final me = messages.viewerId;

    // One row per job that has a thread and belongs to this account, newest
    // message first — a conversation somebody is waiting on should not be
    // below one that ended a fortnight ago.
    final rows = <(Job, Message?, int)>[];
    for (final job in jobs.jobs) {
      if (!rules.isOpen(job) || !rules.belongsTo(job, me)) continue;

      final thread = messages.threadFor(job.id);
      if (thread.isEmpty) continue;

      rows.add((job, thread.last, messages.unreadFor(job)));
    }

    rows.sort((a, b) => b.$2!.sentAt.compareTo(a.$2!.sentAt));

    if (rows.isEmpty) {
      return EmptyView(
        icon: Icons.forum_outlined,
        title: strings.noThreads,
        message: strings.noThreadsMessage,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        BrandSizing.spaceMd,
        BrandSizing.spaceMd,
        BrandSizing.spaceMd,
        BrandSizing.spaceXl * 3,
      ),
      itemCount: rows.length,
      separatorBuilder: (_, _) => const SizedBox(height: BrandSizing.spaceSm),
      itemBuilder: (context, index) {
        final (job, latest, unread) = rows[index];
        final otherId = rules.otherParty(job, me);

        return _ThreadRow(
          job: job,
          latest: latest!,
          unread: unread,
          otherName: otherId == null ? null : jobs.userById(otherId)?.name,
          isMine: latest.senderId == me,
        );
      },
    );
  }
}

class _ThreadRow extends StatelessWidget {
  const _ThreadRow({
    required this.job,
    required this.latest,
    required this.unread,
    required this.isMine,
    this.otherName,
  });

  final Job job;
  final Message latest;
  final int unread;
  final bool isMine;
  final String? otherName;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BrandRadius.mediumAll,
        side: BorderSide(
          color: unread > 0
              ? theme.colorScheme.primary
              : theme.colorScheme.outlineVariant,
          width: unread > 0 ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BrandRadius.mediumAll,
        onTap: () => ThreadScreen.open(context, jobId: job.id),
        child: Padding(
          padding: const EdgeInsets.all(BrandSizing.spaceMd),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      otherName ?? strings.someone,
                      style: theme.textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      job.displayTitle(strings),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: BrandSizing.spaceXs),
                    Text(
                      // Prefixed when it is yours, so a row showing your own
                      // last line does not read as something they said.
                      isMine ? '${strings.you}: ${latest.body}' : latest.body,
                      style: theme.textTheme.bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: BrandSizing.spaceSm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    Format.posted(strings, latest.sentAt, DateTime.now()),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (unread > 0) ...[
                    const SizedBox(height: BrandSizing.spaceXs),
                    Badge.count(count: unread),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
