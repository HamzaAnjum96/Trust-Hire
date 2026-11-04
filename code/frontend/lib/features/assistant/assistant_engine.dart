import '../../models/job_tag.dart';
import '../../services/ai/ai_agent.dart';
import '../../services/ai/ai_model.dart';
import '../../services/ai/ai_prompts.dart';
import '../../services/ai/ai_safety.dart';
import 'assistant_intent.dart';
import 'assistant_search.dart';

/// One answer from the assistant.
class AssistantReply {
  const AssistantReply({
    required this.query,
    this.jobs = const [],
    this.workers = const [],
    this.prose,
    this.model,
    this.modelOnDevice = true,
    this.aiFailure,
    this.missingTrades = const {},
  });

  /// What was searched for — what the app's own sentence describes when the
  /// model wrote none.
  final AssistantQuery query;

  /// Results, every one of them returned by a search this turn.
  final List<JobHit> jobs;
  final List<WorkerHit> workers;

  /// The model's words, cleaned by [AiSafety.prose]. Null when the reply is
  /// the app's own sentence.
  final String? prose;

  /// Who answered: a model's name, or null for the word list.
  final String? model;
  final bool modelOnDevice;

  /// Set when the AI was asked and its answer is not what is shown, so the
  /// word list's is: an [AiFailure] code, or [AssistantEngine.setAside].
  final String? aiFailure;

  /// Trades a worker does not have that the search was for. Their jobs do not
  /// reach this worker — Section 8 — and the way to change that is to add the
  /// trade, which the screen says.
  final Set<JobTag> missingTrades;

  bool get isHelp => query.intent == AssistantIntent.unclear;
}

/// Answers a request about jobs or workers — and nothing else.
///
/// **What the model may do, and what it may not.** It reads the request and
/// chooses what to search for; it may write a sentence about what came back.
/// It cannot put a job or a worker on screen: those come only from what the
/// searches returned this turn, matched by id. A job it invents has no id
/// that matches, and does not appear.
///
/// **The word list reads first, and a model cannot do worse than it.** A
/// model small enough for a browser knows little Urdu: asked
/// "rang ka kaam chahiye", Qwen2.5 1.5B searched cleaning and gardening. The
/// word list knows the trades in English, Urdu and Roman Urdu, so the model is
/// told what the list made of the request, and its answer is set aside —
/// the list's shown instead — when it:
///
/// - answers without searching, so whatever it said, it made up;
/// - searches for something other than what the list understood; or
/// - finds nothing where the list finds something.
///
/// What a model adds is a reading of what the list cannot read, and a
/// sentence, which is shown only in the language of the screen.
class AssistantEngine {
  const AssistantEngine({
    this.reader = const AssistantIntentReader(),
    this.search = const AssistantSearch(),
  });

  final AssistantIntentReader reader;
  final AssistantSearch search;

  /// Two searches and an answer at most. A small model given more room
  /// mostly uses it to repeat itself.
  static const maxSteps = 3;

  /// [AssistantReply.aiFailure] when a model answered, but not well enough
  /// to be shown.
  static const setAside = 'set_aside';

  Future<AssistantReply> answer(
    String text, {
    required AssistantData data,
    AiModel? model,
    String language = 'en',
  }) async {
    final request = AiSafety.userText(text);
    if (model != null) {
      try {
        return await _withModel(request, data, model, language);
      } on AiFailure catch (failure) {
        return _fromWords(request, data, aiFailure: failure.code);
      }
    }
    return _fromWords(request, data);
  }

  AssistantReply _fromWords(
    String request,
    AssistantData data, {
    String? aiFailure,
  }) {
    final query = reader.read(request, isWorker: data.isWorker);
    final jobs = query.intent == AssistantIntent.jobs
        ? search.jobs(
            data,
            tags: query.tags,
            nearMe: query.nearMe,
            words: query.words,
          )
        : const <JobHit>[];
    final workers = query.intent == AssistantIntent.workers
        ? search.workers(
            data,
            tags: query.tags,
            nearMe: query.nearMe,
            words: query.words,
          )
        : const <WorkerHit>[];

    return AssistantReply(
      query: query,
      jobs: jobs,
      workers: workers,
      aiFailure: aiFailure,
      missingTrades: _missing(query, data, found: jobs.isNotEmpty),
    );
  }

  Future<AssistantReply> _withModel(
    String request,
    AssistantData data,
    AiModel model,
    String language,
  ) async {
    final read = reader.read(request, isWorker: data.isWorker);
    // Every search the model ran, with what it found.
    final searches =
        <
          ({AssistantQuery query, List<JobHit> jobs, List<WorkerHit> workers})
        >[];

    final tagIds = [for (final tag in JobTag.values) tag.id];
    final parameters = <String, Map<String, Object?>>{
      'tags': {
        'type': 'array',
        'items': {'type': 'string', 'enum': tagIds},
      },
      'near_me': {'type': 'boolean'},
      'words': {'type': 'string'},
    };

    final context = [
      AiPrompts.assistantContext(isWorker: data.isWorker),
      if (read.intent != AssistantIntent.unclear)
        AiPrompts.assistantReading(
          workers: read.intent == AssistantIntent.workers,
          tags: [for (final tag in read.tags) tag.id],
          nearMe: read.nearMe,
        ),
    ].join('\n');

    final agent = AiAgent(
      model: model,
      instructions: _instructions(language),
      tools: [
        AiTool(
          name: 'search_jobs',
          description: AiPrompts.searchJobs,
          parameters: parameters,
          run: (arguments) {
            final query = _queryFrom(arguments, AssistantIntent.jobs);
            final hits = search.jobs(
              data,
              tags: query.tags,
              nearMe: query.nearMe,
              words: query.words,
            );
            searches.add((query: query, jobs: hits, workers: const []));
            return {
              'count': hits.length,
              'jobs': [for (final hit in hits) hit.toJson()],
            };
          },
        ),
        AiTool(
          name: 'search_workers',
          description: AiPrompts.searchWorkers,
          parameters: parameters,
          run: (arguments) {
            final query = _queryFrom(arguments, AssistantIntent.workers);
            final hits = search.workers(
              data,
              tags: query.tags,
              nearMe: query.nearMe,
              words: query.words,
            );
            searches.add((query: query, jobs: const [], workers: hits));
            return {
              'count': hits.length,
              'workers': [for (final hit in hits) hit.toJson()],
            };
          },
        ),
      ],
      answer: const {
        'reply': {'type': 'string'},
        'job_ids': {
          'type': 'array',
          'items': {'type': 'string'},
        },
        'worker_ids': {
          'type': 'array',
          'items': {'type': 'string'},
        },
        'off_topic': {'type': 'boolean'},
      },
      requiredAnswer: const ['reply'],
      maxSteps: maxSteps,
      maxTokens: 200,
    );
    final outcome = await agent.run(request, context: context);

    final answer = outcome.answer;

    // Where the word list understood the request, only the searches that
    // agree with it count: the right trade, and jobs or workers as asked.
    bool fits(AssistantQuery search) =>
        search.intent == read.intent &&
        (read.tags.isEmpty || search.tags.any(read.tags.contains));
    final counted = read.intent == AssistantIntent.unclear
        ? searches
        : [
            for (final search in searches)
              if (fits(search.query)) search,
          ];

    // It answered without searching — whatever it said about jobs or
    // workers, it made up — or searched only for something the words do not
    // say. Either way, none of it is shown.
    if (counted.isEmpty) {
      return _fromWords(request, data, aiFailure: setAside);
    }
    final asked = counted.last.query;
    final jobsFound = {
      for (final search in counted)
        for (final hit in search.jobs) hit.id: hit,
    };
    final workersFound = {
      for (final search in counted)
        for (final hit in search.workers) hit.id: hit,
    };

    // Only what a search returned, in the order the model named it; if it
    // named nothing, everything the searches found.
    List<T> chosen<T>(Object? ids, Map<String, T> found) {
      final named = [
        if (ids is List)
          for (final id in ids)
            if (id is String && found.containsKey(id)) found[id] as T,
      ];
      return named.isEmpty ? found.values.toList() : named;
    }

    final jobs = chosen(answer['job_ids'], jobsFound);
    final workers = chosen(answer['worker_ids'], workersFound);

    // Nothing, where the word list finds something: the model narrowed its
    // way to an empty answer. The list's is better.
    if (jobs.isEmpty && workers.isEmpty) {
      final fromWords = _fromWords(request, data, aiFailure: setAside);
      if (fromWords.jobs.isNotEmpty || fromWords.workers.isNotEmpty) {
        return fromWords;
      }
    }

    final prose = AiSafety.firstSentences(AiSafety.prose(answer['reply']), 2);
    return AssistantReply(
      query: asked,
      jobs: jobs,
      workers: workers,
      // A sentence in the other language is not shown, nor one that repeats
      // the model's own instructions: the app's own sentence, in the
      // language of the screen, always is.
      prose:
          prose.isEmpty ||
              !AiSafety.writtenIn(prose, language) ||
              AiSafety.echoes(prose, '${agent.systemPrompt}\n$context')
          ? null
          : prose,
      model: model.name,
      modelOnDevice: model.onDevice,
      missingTrades: _missing(asked, data, found: jobs.isNotEmpty),
    );
  }

  /// A search the model asked for, read back into the app's own terms. Tags
  /// outside the vocabulary are dropped; words are reduced to the kind the
  /// word list keeps — a trade is a tag, not a word to narrow by.
  AssistantQuery _queryFrom(
    Map<String, Object?> arguments,
    AssistantIntent intent,
  ) {
    final tags = <JobTag>{
      if (arguments['tags'] is List)
        for (final id in arguments['tags'] as List)
          for (final tag in JobTag.values)
            if (tag.id == id) tag,
    };
    final words = arguments['words'] is String
        ? reader.narrowingWords(arguments['words'] as String)
        : const <String>[];
    return AssistantQuery(
      intent: intent,
      tags: tags,
      nearMe: arguments['near_me'] == true,
      words: words,
    );
  }

  static Set<JobTag> _missing(
    AssistantQuery query,
    AssistantData data, {
    required bool found,
  }) {
    if (found || !data.isWorker || query.intent != AssistantIntent.jobs) {
      return const {};
    }
    return query.tags.difference(data.myTrades);
  }

  static String _instructions(String language) => AiPrompts.assistant(language);
}
