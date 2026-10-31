import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/job_controller.dart';
import '../../app/message_controller.dart';
import '../../core/formatters.dart';
import '../../core/tokens.dart';
import '../../l10n/app_localizations.dart';
import '../../models/job.dart';
import '../../models/message.dart';
import '../../widgets/inbox_row.dart';
import '../../widgets/initials_avatar.dart';
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

    // One surface with hairlines between conversations, like Updates. See
    // [InboxRow].
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        BrandSizing.spaceMd,
        BrandSizing.spaceMd,
        BrandSizing.spaceMd,
        BrandSizing.spaceXl * 3,
      ),
      itemCount: rows.length,
      itemBuilder: (context, index) {
        final (job, latest, unread) = rows[index];
        final otherId = rules.otherParty(job, me);

        return InboxRow(
          index: index,
          count: rows.length,
          highlighted: unread > 0,
          child: _ThreadRow(
            job: job,
            latest: latest!,
            unread: unread,
            otherName: otherId == null ? null : jobs.userById(otherId)?.name,
            isMine: latest.senderId == me,
          ),
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

    final name = otherName ?? strings.someone;

    return InkWell(
      onTap: () => ThreadScreen.open(context, jobId: job.id),
      child: Padding(
        padding: const EdgeInsets.all(BrandSizing.spaceMd),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InitialsAvatar(name: name),
            const SizedBox(width: BrandSizing.spaceSm + 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: theme.textTheme.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: BrandSizing.spaceSm),
                      Text(
                        Format.posted(strings, latest.sentAt, DateTime.now()),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
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
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          // Prefixed when it is yours, so a row showing your
                          // own last line does not read as something they
                          // said.
                          isMine
                              ? '${strings.you}: ${latest.body}'
                              : latest.body,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            // Unread is said by the edge and the count; the
                            // line itself reads stronger as well.
                            color: unread > 0
                                ? theme.colorScheme.onSurface
                                : null,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (unread > 0) ...[
                        const SizedBox(width: BrandSizing.spaceSm),
                        // Burgundy, not Material's error red: an unread message
                        // is news, not a fault.
                        Badge.count(
                          count: unread,
                          backgroundColor: theme.colorScheme.primary,
                          textColor: theme.colorScheme.onPrimary,
                        ),
                      ],
                    ],
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
