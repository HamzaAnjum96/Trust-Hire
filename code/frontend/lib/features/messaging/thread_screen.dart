import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/job_controller.dart';
import '../../app/message_controller.dart';
import '../../core/formatters.dart';
import '../../core/layout.dart';
import '../../core/tokens.dart';
import '../../l10n/app_localizations.dart';
import '../../models/job.dart';
import '../../models/message.dart';
import '../../widgets/state_views.dart';
import 'messaging_rules.dart';

/// The conversation attached to one job.
///
/// Opens at the same moment the exact location does — see
/// [MessagingRules.isOpen]. The two people who agreed to meet are the two who
/// get each other's details, and a thread is that promise in another form.
class ThreadScreen extends StatefulWidget {
  const ThreadScreen({super.key, required this.jobId});

  final String jobId;

  static Future<void> open(BuildContext context, {required String jobId}) =>
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => ThreadScreen(jobId: jobId)),
      );

  @override
  State<ThreadScreen> createState() => _ThreadScreenState();
}

class _ThreadScreenState extends State<ThreadScreen> {
  final TextEditingController _draft = TextEditingController();
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    // Opening the thread is reading it. After the frame, because this notifies
    // listeners and would otherwise run during the first build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final job = context.read<JobController>().jobById(widget.jobId);
      if (job != null) context.read<MessageController>().markRead(job);
    });
  }

  @override
  void dispose() {
    _draft.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send(Job job) async {
    final body = _draft.text;
    final messages = context.read<MessageController>();
    final refusal = await messages.send(job, body);

    if (!mounted) return;

    if (refusal != null) {
      final strings = AppStrings.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_wordFor(strings, refusal))),
      );
      return;
    }

    _draft.clear();
    setState(() {});

    // The newest message is at the bottom; a conversation you have to scroll
    // to see the end of is one you cannot use.
    await WidgetsBinding.instance.endOfFrame;
    if (mounted && _scroll.hasClients) {
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    }
  }

  /// The wording for a refusal, on the screen rather than in the rules — the
  /// same split every other refusal in this app uses, and the one
  /// `localisation_test.dart` enforces.
  static String _wordFor(AppStrings strings, MessageRefusal refusal) =>
      switch (refusal) {
        MessageRefusal.notYetOpen => strings.messagesNotYetOpen,
        MessageRefusal.threadClosed => strings.messagesClosed,
        MessageRefusal.notYours => strings.messagesNotYours,
        MessageRefusal.tooLong => strings.messageTooLong,
        // An empty box is the ordinary state of a message field, not an error
        // worth a red bar. The send button is disabled instead.
        MessageRefusal.empty => '',
      };

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final messages = context.watch<MessageController>();
    final jobs = context.watch<JobController>();

    final job = jobs.jobById(widget.jobId);
    if (job == null) {
      return Scaffold(
        appBar: AppBar(title: Text(strings.messagesTitle)),
        body: EmptyView(
          icon: Icons.forum_outlined,
          title: strings.savedJobGone,
          message: strings.messagesEmptyMessage,
        ),
      );
    }

    const rules = MessagingRules();
    final me = messages.viewerId;
    final thread = messages.threadFor(job.id);
    final otherId = rules.otherParty(job, me);
    final otherName = otherId == null
        ? null
        : jobs.userById(otherId)?.name;
    final canWrite = rules.acceptsMessages(job) && rules.belongsTo(job, me);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(otherName ?? strings.messagesTitle),
            // What the conversation is about. Two people can hire each other
            // twice, and a thread with only a name at the top is a thread you
            // have to read to identify.
            Text(
              job.displayTitle(strings),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      body: ReadableWidth(
        child: Column(
          children: [
            Expanded(
              child: thread.isEmpty
                  ? EmptyView(
                      icon: Icons.forum_outlined,
                      title: strings.messagesEmpty,
                      message: strings.messagesEmptyMessage,
                    )
                  : ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.all(BrandSizing.spaceMd),
                      itemCount: thread.length,
                      itemBuilder: (context, index) => _Bubble(
                        message: thread[index],
                        isMine: thread[index].senderId == me,
                        // Only on the last of your own messages. A receipt
                        // under every bubble is noise; under the newest one it
                        // answers "did they see it?".
                        showsReceipt:
                            thread[index].senderId == me &&
                            index == thread.length - 1,
                      ),
                    ),
            ),

            if (!canWrite)
              Padding(
                padding: const EdgeInsets.all(BrandSizing.spaceMd),
                child: Text(
                  rules.isOpen(job)
                      ? strings.messagesClosed
                      : strings.messagesNotYetOpen,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              )
            else
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    BrandSizing.spaceMd,
                    BrandSizing.spaceSm,
                    BrandSizing.spaceMd,
                    BrandSizing.spaceMd,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _draft,
                          onChanged: (_) => setState(() {}),
                          // Grows with what is typed rather than scrolling a
                          // single line, up to a point.
                          minLines: 1,
                          maxLines: 4,
                          maxLength: MessagingRules.maxLength,
                          textInputAction: TextInputAction.newline,
                          keyboardType: TextInputType.multiline,
                          decoration: InputDecoration(
                            hintText: strings.messageHint,
                            counterText: '',
                            border: const OutlineInputBorder(
                              borderRadius: BrandRadius.mediumAll,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: BrandSizing.spaceSm),
                      IconButton.filled(
                        // Disabled rather than refusing: an empty box is the
                        // ordinary state of a message field.
                        onPressed: _draft.text.trim().isEmpty
                            ? null
                            : () => _send(job),
                        icon: const Icon(Icons.send),
                        tooltip: strings.sendMessage,
                        constraints: const BoxConstraints(
                          minWidth: BrandSizing.touchTargetPreferred,
                          minHeight: BrandSizing.touchTargetPreferred,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.message,
    required this.isMine,
    required this.showsReceipt,
  });

  final Message message;
  final bool isMine;
  final bool showsReceipt;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: BrandSizing.spaceSm),
      child: Column(
        crossAxisAlignment: isMine
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          // Capped, so a long message on a wide window does not become one
          // line of text a metre across.
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width * 0.78,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: BrandSizing.spaceMd,
                vertical: BrandSizing.spaceSm + 2,
              ),
              decoration: BoxDecoration(
                color: isMine
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BrandRadius.mediumAll,
              ),
              child: Text(
                message.body,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: isMine
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurface,
                ),
              ),
            ),
          ),
          const SizedBox(height: BrandSizing.spaceXs),
          Text(
            showsReceipt
                ? '${Format.posted(strings, message.sentAt, DateTime.now())}'
                      ' · '
                      '${message.isRead ? strings.messageReadReceipt : strings.messageSentReceipt}'
                : Format.posted(strings, message.sentAt, DateTime.now()),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
