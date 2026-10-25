import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/ai_controller.dart';
import '../../app/job_controller.dart';
import '../../app/premium_controller.dart';
import '../../app/profile_controller.dart';
import '../../app/rating_controller.dart';
import '../../core/layout.dart';
import '../../core/tokens.dart';
import '../../l10n/app_localizations.dart';
import '../../services/ai/ai_safety.dart';
import '../../services/media_store.dart';
import '../ai/ai_consent.dart';
import '../directory/directory_screen.dart';
import '../jobs/job_details_sheet.dart';
import '../jobs/job_row.dart';
import '../map/location_controller.dart';
import 'assistant_engine.dart';
import 'assistant_intent.dart';
import 'assistant_search.dart';

/// "Ask Trust Hire" — a conversation about jobs and workers, and nothing else.
///
/// With the AI on, a model reads the question and chooses what to search
/// for. Without it — most phones today — the word list in
/// [AssistantIntentReader] does, in English, Urdu or Roman Urdu. Either way
/// the results on screen come from the app's own data, through the same rules
/// that decide what the rest of the app shows this person; see
/// [AssistantEngine] for what the model is and is not allowed to do.
///
/// The conversation is not stored. Close the screen and it is gone — it is a
/// way to search, not a record anybody needs to keep.
class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key, this.engine = const AssistantEngine()});

  final AssistantEngine engine;

  static Future<void> open(BuildContext context) => Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => const AssistantScreen()));

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _Turn {
  const _Turn.asked(this.text) : reply = null;
  const _Turn.answered(this.reply) : text = null;

  final String? text;
  final AssistantReply? reply;
}

class _AssistantScreenState extends State<AssistantScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _turns = <_Turn>[];
  bool _thinking = false;

  @override
  void initState() {
    super.initState();
    // Somebody who switched the AI on and opened this screen is about to ask
    // something: start loading now rather than when they press send.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ai = context.read<AiController>();
      if (ai.state == AiState.idle) ai.ensureReady();
    });
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  /// What this person may be shown, right now — built from the same rules
  /// the map, the Jobs list and the Directory use. See [AssistantData].
  AssistantData _data() {
    final jobs = context.read<JobController>();
    final profile = context.read<ProfileController>();
    final premium = context.read<PremiumController>();
    final ratings = context.read<RatingController>();
    final here = context.read<LocationController>().position;

    final listings = premium.directory(hirerAt: here);
    return AssistantData(
      jobs: [
        for (final job in profile.visibleTo(jobs.jobs, from: here))
          if (job.status.isTakingOffers) job,
      ],
      listings: listings,
      names: {
        for (final listing in listings)
          listing.workerId: ?jobs.userById(listing.workerId)?.name,
      },
      standing: {
        for (final listing in listings)
          listing.workerId: ratings.standingFor(
            listing.workerId,
            jobs: jobs.jobs,
          ),
      },
      now: DateTime.now(),
      isWorker: profile.isWorker,
      myTrades: profile.profile.tags,
      here: here,
    );
  }

  Future<void> _ask(String text) async {
    final question = AiSafety.userText(text);
    if (question.isEmpty || _thinking) return;

    final ai = context.read<AiController>();
    final language = AppStrings.of(context).localeName;
    final data = _data();

    setState(() {
      _turns.add(_Turn.asked(question));
      _thinking = true;
      _input.clear();
    });
    _scrollToEnd();

    final model = await ai.ensureReady();
    final reply = await widget.engine.answer(
      question,
      data: data,
      model: model,
      language: language,
    );
    if (!mounted) return;

    setState(() {
      _turns.add(_Turn.answered(reply));
      _thinking = false;
    });
    _scrollToEnd();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: BrandMotion.standard,
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(strings.assistantTitle)),
      body: Column(
        children: [
          const _AiStatusBar(),
          Expanded(
            child: ReadableWidth(
              child: _turns.isEmpty
                  ? _Welcome(onAsk: _ask)
                  : ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.all(BrandSizing.spaceMd),
                      itemCount: _turns.length + (_thinking ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _turns.length) return const _Thinking();
                        final turn = _turns[index];
                        return turn.reply == null
                            ? _Asked(turn.text!)
                            : _Answered(turn.reply!);
                      },
                    ),
            ),
          ),
          ReadableWidth(
            child: _Composer(
              controller: _input,
              busy: _thinking,
              onSend: () => _ask(_input.text),
            ),
          ),
        ],
      ),
    );
  }
}

/// Which brain is answering, said once at the top rather than on every reply.
class _AiStatusBar extends StatelessWidget {
  const _AiStatusBar();

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final ai = context.watch<AiController>();

    final (IconData icon, String text, Widget? action) = switch (ai.state) {
      AiState.ready || AiState.idle => (
        Icons.auto_awesome,
        ai.onDevice
            ? strings.aiAnsweredBy(ai.modelName)
            : strings.aiAnsweredByRemote(ai.modelName),
        null,
      ),
      AiState.loading => (
        Icons.downloading,
        strings.aiStatusLoading((ai.progress * 100).round()),
        null,
      ),
      AiState.off => (
        Icons.text_fields,
        strings.assistantAiOffNote,
        TextButton(
          onPressed: () => askToTurnOnAi(context),
          child: Text(strings.aiTurnOn),
        ),
      ),
      AiState.failed => (
        Icons.text_fields,
        strings.assistantAiFailedNote,
        TextButton(onPressed: ai.ensureReady, child: Text(strings.aiTryAgain)),
      ),
      AiState.checking || AiState.unsupported => (
        Icons.text_fields,
        strings.aiAnsweredByWords,
        null,
      ),
    };

    return Material(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
      child: ReadableWidth(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: BrandSizing.spaceMd,
            vertical: BrandSizing.spaceXs,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(icon, size: 18, color: theme.colorScheme.primary),
                  const SizedBox(width: BrandSizing.spaceSm),
                  Expanded(
                    child: Text(text, style: theme.textTheme.labelMedium),
                  ),
                  ?action,
                ],
              ),
              if (ai.state == AiState.loading)
                LinearProgressIndicator(
                  value: ai.progress > 0 ? ai.progress : null,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Welcome extends StatelessWidget {
  const _Welcome({required this.onAsk});

  final ValueChanged<String> onAsk;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final examples = [
      strings.assistantExampleJobs,
      strings.assistantExampleWiring,
      strings.assistantExampleCity,
      strings.assistantExampleRoman,
    ];

    return ListView(
      padding: const EdgeInsets.all(BrandSizing.spaceLg),
      children: [
        Icon(
          Icons.auto_awesome_outlined,
          size: 40,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: BrandSizing.spaceMd),
        Text(strings.assistantWelcome, style: theme.textTheme.headlineSmall),
        const SizedBox(height: BrandSizing.spaceSm),
        Text(strings.assistantIntro, style: theme.textTheme.bodyMedium),
        const SizedBox(height: BrandSizing.spaceLg),
        Wrap(
          spacing: BrandSizing.spaceSm,
          runSpacing: BrandSizing.spaceSm,
          children: [
            for (final example in examples)
              ActionChip(
                avatar: const Icon(Icons.search, size: 18),
                label: Text(example),
                onPressed: () => onAsk(example),
              ),
          ],
        ),
      ],
    );
  }
}

class _Asked extends StatelessWidget {
  const _Asked(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: AlignmentDirectional.centerEnd,
      child: Container(
        margin: const EdgeInsets.only(
          bottom: BrandSizing.spaceMd,
          left: BrandSizing.spaceXl,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: BrandSizing.spaceMd,
          vertical: BrandSizing.spaceSm,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary,
          borderRadius: BrandRadius.largeAll,
        ),
        child: Text(
          text,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onPrimary,
          ),
        ),
      ),
    );
  }
}

class _Thinking extends StatelessWidget {
  const _Thinking();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: BrandSizing.spaceMd),
      child: Row(
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: BrandSizing.spaceSm),
          Text(
            AppStrings.of(context).assistantThinking,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

/// One answer: a sentence, then the results it is about, then who answered.
class _Answered extends StatelessWidget {
  const _Answered(this.reply);

  final AssistantReply reply;

  /// The app's own sentence about what was found — always available, and the
  /// only sentence shown when the model wrote none.
  String _sentence(AppStrings strings) {
    final query = reply.query;
    if (reply.isHelp) return strings.assistantHelp;

    final joiner = strings.localeName == 'ur' ? '، ' : ', ';
    final what = query.tags.map((tag) => tag.label(strings)).join(joiner);

    if (query.intent == AssistantIntent.workers) {
      final count = reply.workers.length;
      if (count == 0) {
        return what.isEmpty
            ? strings.assistantNoWorkersAny
            : strings.assistantNoWorkers(what);
      }
      return what.isEmpty
          ? strings.assistantFoundWorkersAny(count)
          : strings.assistantFoundWorkers(count, what);
    }

    final count = reply.jobs.length;
    if (count == 0) {
      return what.isEmpty
          ? strings.assistantNoJobsAny
          : strings.assistantNoJobs(what);
    }
    return what.isEmpty
        ? strings.assistantFoundJobsAny(count)
        : strings.assistantFoundJobs(count, what);
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final jobs = context.read<JobController>();
    final premium = context.read<PremiumController>();
    final here = context.read<LocationController>().position;
    final now = DateTime.now();
    final joiner = strings.localeName == 'ur' ? '، ' : ', ';

    final author = reply.model == null
        ? strings.aiAnsweredByWords
        : reply.modelOnDevice
        ? strings.aiAnsweredBy(reply.model!)
        : strings.aiAnsweredByRemote(reply.model!);

    return Padding(
      padding: const EdgeInsets.only(bottom: BrandSizing.spaceLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            reply.prose ?? _sentence(strings),
            style: theme.textTheme.bodyLarge,
          ),
          // The model's sentence can be wrong about a count; the app's
          // cannot. When the model wrote one, the app's goes underneath.
          if (reply.prose != null && !reply.isHelp) ...[
            const SizedBox(height: BrandSizing.spaceXs),
            Text(_sentence(strings), style: theme.textTheme.labelMedium),
          ],
          if (reply.missingTrades.isNotEmpty) ...[
            const SizedBox(height: BrandSizing.spaceSm),
            Text(
              strings.assistantAddTrade(
                reply.missingTrades
                    .map((tag) => tag.label(strings))
                    .join(joiner),
              ),
              style: theme.textTheme.bodyMedium,
            ),
          ],
          const SizedBox(height: BrandSizing.spaceSm),
          for (final hit in reply.jobs)
            if (jobs.jobById(hit.id) case final job?)
              Padding(
                padding: const EdgeInsets.only(bottom: BrandSizing.spaceSm),
                child: JobRow(
                  job: job,
                  now: now,
                  onTap: () => JobDetailsSheet.open(
                    context,
                    jobId: job.id,
                    mediaStore: context.read<MediaStore>(),
                    viewerLocation: here,
                  ),
                ),
              ),
          for (final hit in reply.workers)
            if (premium.listingFor(hit.id) case final listing?)
              Padding(
                padding: const EdgeInsets.only(bottom: BrandSizing.spaceSm),
                child: DirectoryListingCard(
                  listing: listing,
                  name: hit.name.isEmpty ? null : hit.name,
                  distanceMetres: hit.km == null ? null : hit.km! * 1000,
                ),
              ),
          Row(
            children: [
              Icon(
                reply.model == null ? Icons.text_fields : Icons.auto_awesome,
                size: 14,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: BrandSizing.spaceXs),
              Expanded(
                child: Text(
                  reply.aiFailure != null
                      ? strings.assistantAiFailedNote
                      : author,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.busy,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool busy;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          BrandSizing.spaceMd,
          BrandSizing.spaceSm,
          BrandSizing.spaceSm,
          BrandSizing.spaceSm,
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                enabled: !busy,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                maxLength: AiSafety.maxRequestLength,
                decoration: InputDecoration(
                  hintText: strings.assistantHint,
                  counterText: '',
                ),
              ),
            ),
            const SizedBox(width: BrandSizing.spaceXs),
            IconButton.filled(
              onPressed: busy ? null : onSend,
              tooltip: strings.assistantSend,
              icon: const Icon(Icons.arrow_upward),
            ),
          ],
        ),
      ),
    );
  }
}

/// The way in, wherever it is offered: an "Ask" button.
class AskButton extends StatelessWidget {
  const AskButton({super.key});

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: AppStrings.of(context).assistantTitle,
    icon: const Icon(Icons.auto_awesome_outlined),
    onPressed: () => AssistantScreen.open(context),
  );
}
