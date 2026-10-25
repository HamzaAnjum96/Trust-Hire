import '../../models/job_tag.dart';
import '../../services/ai/ai_agent.dart';
import '../../services/ai/ai_model.dart';
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

  /// Set when the AI was asked and could not answer, so the word list did.
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
/// that matches, and does not appear. If it answers without searching at
/// all, its words are dropped and the request is answered from the data.
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
    String? model,
    bool modelOnDevice = true,
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
      model: model,
      modelOnDevice: modelOnDevice,
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
    final jobsFound = <String, JobHit>{};
    final workersFound = <String, WorkerHit>{};
    var asked = const AssistantQuery(intent: AssistantIntent.unclear);

    final tagIds = [for (final tag in JobTag.values) tag.id];
    final parameters = <String, Map<String, Object?>>{
      'tags': {
        'type': 'array',
        'items': {'type': 'string', 'enum': tagIds},
      },
      'near_me': {'type': 'boolean'},
      'words': {'type': 'string'},
    };

    final outcome = await AiAgent(
      model: model,
      instructions: _instructions(language),
      tools: [
        AiTool(
          name: 'search_jobs',
          description:
              'Open jobs this person can see, for some job tags. near_me '
              'keeps to the nearest; words narrows by place or title.',
          parameters: parameters,
          run: (arguments) {
            asked = _queryFrom(arguments, AssistantIntent.jobs);
            final hits = search.jobs(
              data,
              tags: asked.tags,
              nearMe: asked.nearMe,
              words: asked.words,
            );
            for (final hit in hits) {
              jobsFound[hit.id] = hit;
            }
            return {
              'count': hits.length,
              'jobs': [for (final hit in hits) hit.toJson()],
            };
          },
        ),
        AiTool(
          name: 'search_workers',
          description:
              'Workers in the directory who would come to this person, best '
              'rated first, for some job tags.',
          parameters: parameters,
          run: (arguments) {
            asked = _queryFrom(arguments, AssistantIntent.workers);
            final hits = search.workers(
              data,
              tags: asked.tags,
              nearMe: asked.nearMe,
              words: asked.words,
            );
            for (final hit in hits) {
              workersFound[hit.id] = hit;
            }
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
    ).run(
      request,
      context:
          'This person uses Trust Hire as a '
          '${data.isWorker ? 'worker looking for jobs' : 'hirer looking for workers'}.',
    );

    final answer = outcome.answer;

    // It answered without searching. Whatever it said about jobs or workers,
    // it made up — so none of it is shown. Answer from the data instead.
    if (outcome.steps.isEmpty) {
      return _fromWords(
        request,
        data,
        model: model.name,
        modelOnDevice: model.onDevice,
      );
    }

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
    final prose = AiSafety.prose(answer['reply']);

    return AssistantReply(
      query: asked,
      jobs: jobs,
      workers: workers,
      prose: prose.isEmpty ? null : prose,
      model: model.name,
      modelOnDevice: model.onDevice,
      missingTrades: _missing(asked, data, found: jobs.isNotEmpty),
    );
  }

  /// A search the model asked for, read back into the app's own terms. Tags
  /// outside the vocabulary are dropped; words are reduced to the same kind
  /// the word list produces.
  static AssistantQuery _queryFrom(
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
        ? [
            for (final word
                in (arguments['words'] as String).toLowerCase().split(
                  RegExp(r'[^a-z0-9]+'),
                ))
              if (word.length > 2) word,
          ]
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

  static String _instructions(String language) =>
      "You are Trust Hire's assistant. You help people find open jobs and "
      'directory workers on Trust Hire, and nothing else.\n'
      'For work to do, call search_jobs. For somebody to do work, call '
      'search_workers. Pick the job tags that fit the request.\n'
      'Then answer: reply is one or two short sentences in '
      '${language == 'ur' ? 'Urdu' : 'English'} about what the search found, '
      'and job_ids or worker_ids are the ids of the results you mention.\n'
      'If the request is not about finding jobs or workers on Trust Hire, '
      'answer straight away with off_topic true and no ids.\n'
      'Only mention jobs and workers a tool returned.';
}
