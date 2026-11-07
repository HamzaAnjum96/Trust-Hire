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

    // Kept where it can be read back — Profile, On-device AI — so a failure
    // can be reported rather than only seen.
    if (model != null) {
      switch (reply.aiFailure) {
        case null:
          ai.noteAnswered();
        case AssistantEngine.setAside:
          break;
        case final failure:
          ai.noteProblem(failure, reply.aiFailureDetail);
      }
    }

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
        curve: BrandMotion.curve,
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
///
/// No sparkles anywhere on this screen: the brand guidelines rule out "AI
/// sparkle symbols", and what is worth saying is plainer — a model on *this
/// device*, a hosted one, or the word list.
class _AiStatusBar extends StatelessWidget {
  const _AiStatusBar();

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final ai = context.watch<AiController>();

    final (IconData icon, String text, Widget? action) = switch (ai.state) {
      // Who will answer, not who did: nothing has been asked yet.
      AiState.ready || AiState.idle => (
        ai.onDevice ? Icons.devices_outlined : Icons.cloud_outlined,
        ai.onDevice
            ? strings.aiAnswersHere(ai.modelName)
            : strings.aiAnswersHereRemote(ai.modelName),
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
        strings.aiStartFailedNote,
        TextButton(onPressed: ai.ensureReady, child: Text(strings.aiTryAgain)),
      ),
      AiState.checking || AiState.unsupported => (
        Icons.text_fields,
        strings.aiAnsweredByWords,
        null,
      ),
    };

    return Material(
      color: isLight ? BrandColours.warmSand : BrandColours.darkElevated,
      child: ReadableWidth(
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            BrandSizing.spaceMd,
            BrandSizing.spaceXs,
            BrandSizing.spaceSm,
            BrandSizing.spaceXs,
          ),
          child: Column(
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: BrandSizing.touchTargetMinimum,
                ),
                child: Row(
                  children: [
                    Icon(icon, size: 18, color: theme.colorScheme.primary),
                    const SizedBox(width: BrandSizing.spaceSm),
                    Expanded(
                      child: Text(
                        text,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                    ?action,
                  ],
                ),
              ),
              if (ai.state == AiState.loading)
                Padding(
                  padding: const EdgeInsets.only(bottom: BrandSizing.spaceXs),
                  child: LinearProgressIndicator(
                    value: ai.progress > 0 ? ai.progress : null,
                  ),
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
    final isLight = theme.brightness == Brightness.light;
    final examples = [
      strings.assistantExampleJobs,
      strings.assistantExampleWiring,
      strings.assistantExampleCity,
      strings.assistantExampleRoman,
    ];

    return ListView(
      padding: const EdgeInsets.all(BrandSizing.spaceLg),
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: isLight
                  ? BrandColours.warmSand
                  : BrandColours.darkElevated,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.question_answer_outlined,
              size: 30,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        const SizedBox(height: BrandSizing.spaceMd),
        Text(strings.assistantWelcome, style: theme.textTheme.headlineMedium),
        const SizedBox(height: BrandSizing.spaceSm),
        Text(strings.assistantIntro, style: theme.textTheme.bodyLarge),
        const SizedBox(height: BrandSizing.spaceLg),
        Text(
          strings.assistantTry,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: BrandSizing.spaceSm),
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
        margin: const EdgeInsetsDirectional.only(
          bottom: BrandSizing.spaceMd,
          start: BrandSizing.spaceXl,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: BrandSizing.spaceMd,
          vertical: BrandSizing.spaceSm + 2,
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
          Expanded(
            child: Text(
              AppStrings.of(context).assistantThinking,
              style: theme.textTheme.bodyMedium,
            ),
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
                // Rows are flat on a page since 0.23; inside an answer each
                // result keeps a frame, so it reads as one thing found.
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  child: JobRow(
                    job: job,
                    now: now,
                    viewerLocation: here,
                    onTap: () => JobDetailsSheet.open(
                      context,
                      jobId: job.id,
                      mediaStore: context.read<MediaStore>(),
                      viewerLocation: here,
                    ),
                  ),
                ),
              ),
          for (final hit in reply.workers)
            if (premium.listingFor(hit.id) case final listing?)
              Padding(
                padding: const EdgeInsets.only(bottom: BrandSizing.spaceSm),
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  child: DirectoryListingCard(
                    listing: listing,
                    name: hit.name.isEmpty ? null : hit.name,
                    distanceMetres: hit.km == null ? null : hit.km! * 1000,
                  ),
                ),
              ),
          Row(
            children: [
              Icon(
                reply.model == null
                    ? Icons.text_fields
                    : (reply.modelOnDevice
                          ? Icons.devices_outlined
                          : Icons.cloud_outlined),
                size: 14,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: BrandSizing.spaceXs),
              Expanded(
                child: Text(
                  switch (reply.aiFailure) {
                    null => author,
                    AssistantEngine.setAside => strings.assistantAiSetAsideNote,
                    'timeout' => strings.assistantAiSlowNote,
                    _ => strings.assistantAiFailedNote,
                  },
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
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
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
              const SizedBox(width: BrandSizing.spaceSm),
              IconButton.filled(
                onPressed: busy ? null : onSend,
                tooltip: strings.assistantSend,
                constraints: const BoxConstraints(
                  minWidth: BrandSizing.touchTargetPreferred,
                  minHeight: BrandSizing.touchTargetPreferred,
                ),
                icon: const Icon(Icons.arrow_upward),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The way in, wherever it is offered: the word "Ask", inside a search bar.
///
/// A word rather than an icon since 0.23. It was a pair of speech bubbles,
/// which is what Messages looks like, so two features shared one symbol. And
/// it sits *in* the search bar because it is another way of searching: type
/// to filter what is here, or ask in your own words.
class AskButton extends StatelessWidget {
  const AskButton({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Tooltip(
      message: strings.assistantTitle,
      child: TextButton(
        onPressed: () => AssistantScreen.open(context),
        style: TextButton.styleFrom(
          minimumSize: const Size(
            BrandSizing.touchTargetPreferred,
            BrandSizing.touchTargetPreferred,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: BrandSizing.spaceSm + 4,
          ),
        ),
        child: Text(strings.ask),
      ),
    );
  }
}
