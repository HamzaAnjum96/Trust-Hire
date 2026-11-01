import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trust_hire/app/ai_controller.dart';
import 'package:trust_hire/features/assistant/assistant_engine.dart';
import 'package:trust_hire/features/assistant/assistant_intent.dart';
import 'package:trust_hire/features/assistant/assistant_screen.dart';
import 'package:trust_hire/features/assistant/assistant_search.dart';
import 'package:trust_hire/models/job.dart';
import 'package:trust_hire/models/job_tag.dart';
import 'package:trust_hire/models/premium.dart';
import 'package:trust_hire/models/rating.dart';
import 'package:trust_hire/services/ai/ai_model.dart';
import 'package:trust_hire/services/ai/ai_prompts.dart';
import 'package:trust_hire/services/local_store.dart';

import 'support/fake_ai.dart';
import 'support/harness.dart';

/// "Ask Trust Hire": what it understands, what it may show, and what a model
/// may and may not do with it.
///
/// The promise worth testing is the last one. A model chooses what to
/// search for and may write a sentence; **it cannot put a job or a worker on
/// screen** — those come only from what a search returned this turn.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    rootBundle.clear();
  });

  final now = DateTime(2026, 11, 1, 10);
  const here = JobLocation(latitude: 31.52, longitude: 74.35);

  Job job(
    String id, {
    Set<JobTag> tags = const {JobTag.painting},
    String? title,
    String? area,
    double lat = 31.52,
    int daysAgo = 1,
  }) => Job(
    id: id,
    location: JobLocation(latitude: lat, longitude: 74.35),
    createdAt: now.subtract(Duration(days: daysAgo)),
    title: title ?? 'Job $id',
    area: area,
    tags: tags,
    contactNumber: '0300 1234567',
    postedBy: 'hirer-$id',
  );

  DirectoryListing listing(String worker, JobTag tag, {int price = 2000}) =>
      DirectoryListing(
        workerId: worker,
        headline: '$worker does ${tag.id}',
        services: [
          ServiceOffering(
            id: '$worker-1',
            tag: tag,
            title: '${tag.id} visit',
            priceRupees: price,
          ),
        ],
      );

  AssistantData data({
    List<Job> jobs = const [],
    List<DirectoryListing> listings = const [],
    Map<String, WorkerStanding> standing = const {},
    bool isWorker = true,
    Set<JobTag> myTrades = const {JobTag.painting},
    JobLocation? at = here,
  }) => AssistantData(
    jobs: jobs,
    listings: listings,
    names: {for (final l in listings) l.workerId: 'Name of ${l.workerId}'},
    standing: standing,
    now: now,
    isWorker: isWorker,
    myTrades: myTrades,
    here: at,
  );

  group('understanding a request without a model', () {
    const reader = AssistantIntentReader();

    test('work, a trade and a place, in English', () {
      final query = reader.read('Painting jobs near me', isWorker: false);

      expect(query.intent, AssistantIntent.jobs, reason: 'it says jobs');
      expect(query.tags, {JobTag.painting});
      expect(query.nearMe, isTrue);
      expect(query.words, isEmpty);
    });

    test('a person to do it', () {
      final query = reader.read('Who can fix wiring?', isWorker: true);

      expect(query.intent, AssistantIntent.workers);
      expect(query.tags, {JobTag.electrical});
    });

    test('Roman Urdu', () {
      expect(
        reader.read('plumber chahiye', isWorker: true).intent,
        AssistantIntent.workers,
      );
      final work = reader.read('rang ka kaam chahiye', isWorker: false);
      expect(work.intent, AssistantIntent.jobs);
      expect(work.tags, {JobTag.painting});
    });

    test('Urdu script', () {
      final query = reader.read('وائرنگ کون ٹھیک کر سکتا ہے؟', isWorker: true);

      expect(query.intent, AssistantIntent.workers);
      expect(query.tags, {JobTag.electrical});
    });

    test('an Urdu word is matched from its start, not inside another', () {
      // وائرنگ is wiring. It ends in رنگ, colour, and once came back as
      // painting as well.
      expect(reader.read('وائرنگ', isWorker: true).tags, {JobTag.electrical});
      expect(reader.read('رنگوں والا کام', isWorker: true).tags, {
        JobTag.painting,
      });
    });

    test('a trade alone goes by who is asking', () {
      expect(
        reader.read('painting', isWorker: true).intent,
        AssistantIntent.jobs,
      );
      expect(
        reader.read('painting', isWorker: false).intent,
        AssistantIntent.workers,
      );
    });

    test('a place is kept to narrow by', () {
      final query = reader.read('electrician in Lahore', isWorker: false);
      expect(query.words, ['lahore']);
    });

    test('a short word is matched whole, not as a prefix', () {
      // "mali" is a gardener; "Malik" is a name.
      expect(
        reader.read('Malik sahab', isWorker: true).tags,
        isNot(contains(JobTag.gardening)),
      );
      expect(
        reader.read('mali chahiye', isWorker: false).tags,
        contains(JobTag.gardening),
      );
    });

    test('anything else is answered with what it can do, not a guess', () {
      expect(
        reader.read('what is the weather', isWorker: true).intent,
        AssistantIntent.unclear,
      );
    });
  });

  group('the searches', () {
    const search = AssistantSearch();

    test('see only the jobs they are given', () {
      final hits = search.jobs(
        data(
          jobs: [
            job('a'),
            job('b', tags: {JobTag.plumbing}),
          ],
        ),
        tags: {JobTag.painting},
      );
      expect([for (final h in hits) h.id], ['a']);
    });

    test('never hand over who posted a job or how to reach them', () {
      final hit = search.jobs(data(jobs: [job('a')])).single;
      final json = hit.toJson().toString();

      expect(json, isNot(contains('0300')));
      expect(json, isNot(contains('hirer-')));
    });

    test('a gap is said outright, not left for a model to fill', () {
      // Given nothing, Qwen2.5 1.5B gave an unrated worker the rating of the
      // one listed before them.
      final worker = search
          .workers(data(listings: [listing('new', JobTag.painting)]))
          .single;
      expect(worker.toJson()['rating'], AiPrompts.notRatedYet);

      final hit = search.jobs(data(jobs: [job('a')])).single;
      expect(hit.toJson()['startingFareRupees'], AiPrompts.openToOffers);
    });

    test('near me means near, nearest first', () {
      final hits = search.jobs(
        data(
          jobs: [
            job('far', lat: 32.5),
            job('next', lat: 31.53),
            job('here', lat: 31.52),
          ],
        ),
        nearMe: true,
      );
      expect([for (final h in hits) h.id], ['here', 'next']);
    });

    test('a word narrows when it matches, and is ignored when it would '
        'leave nothing', () {
      final jobs = [
        job('a', area: 'Gulberg, Lahore'),
        job('b', area: 'G-9, Islamabad'),
      ];
      expect(
        [
          for (final h in search.jobs(data(jobs: jobs), words: ['lahore']))
            h.id,
        ],
        ['a'],
      );
      expect(search.jobs(data(jobs: jobs), words: ['please']).length, 2);
    });

    test('workers come best record first — what "who is good" asks', () {
      final hits = search.workers(
        data(
          listings: [
            listing('new', JobTag.electrical),
            listing('good', JobTag.electrical),
            listing('ok', JobTag.electrical),
          ],
          standing: {
            'good': const WorkerStanding(completedJobs: 9, averageStars: 4.8),
            'ok': const WorkerStanding(completedJobs: 3, averageStars: 3.9),
          },
        ),
        tags: {JobTag.electrical},
      );
      expect([for (final h in hits) h.id], ['good', 'ok', 'new']);
    });
  });

  group('the engine', () {
    const engine = AssistantEngine();
    final jobs = [job('real-1'), job('real-2')];

    test('without a model, the word list answers', () async {
      final reply = await engine.answer(
        'painting jobs',
        data: data(jobs: jobs),
      );

      expect(reply.model, isNull);
      expect([for (final j in reply.jobs) j.id], ['real-1', 'real-2']);
    });

    test(
      '**a model cannot put a job on screen that no search returned**',
      () async {
        final model = ScriptedModel([
          {
            'action': 'search_jobs',
            'arguments': {
              'tags': ['painting'],
            },
          },
          {
            'action': 'answer',
            'answer': {
              'reply': 'Here are two.',
              'job_ids': ['invented-99', 'real-2'],
            },
          },
        ]);

        final reply = await engine.answer(
          'painting work',
          data: data(jobs: jobs),
          model: model,
        );

        expect([for (final j in reply.jobs) j.id], ['real-2']);
        expect(reply.prose, 'Here are two.');
        expect(reply.model, 'Test model');
      },
    );

    test('an answer given without searching is not believed', () async {
      final model = ScriptedModel([
        {
          'action': 'answer',
          'answer': {
            'reply': 'There are 40 painting jobs paying Rs. 90,000.',
            'job_ids': ['real-1'],
          },
        },
      ]);

      final reply = await engine.answer(
        'painting jobs',
        data: data(jobs: jobs),
        model: model,
      );

      expect(reply.prose, isNull, reason: 'its words were made up');
      expect(reply.model, isNull, reason: 'the word list answered');
      expect(reply.aiFailure, AssistantEngine.setAside);
      expect(
        [for (final j in reply.jobs) j.id],
        ['real-1', 'real-2'],
        reason: 'answered from the data instead',
      );
    });

    test('an off-topic answer is not shown', () async {
      // What Qwen2.5 1.5B said, asked about the weather — without searching
      // anything, and with nothing in the app to say it.
      final model = ScriptedModel([
        {
          'action': 'answer',
          'answer': {
            'reply': 'The weather in Lahore is sunny, 25 degrees.',
            'job_ids': <String>[],
          },
        },
      ]);

      final reply = await engine.answer(
        'What is the weather in Lahore?',
        data: data(jobs: jobs),
        model: model,
      );

      expect(reply.prose, isNull);
      expect(reply.isHelp, isTrue, reason: 'it says what it can do instead');
      expect(reply.aiFailure, AssistantEngine.setAside);
    });

    test('the model is told what the word list read', () async {
      final model = ScriptedModel([
        {
          'action': 'search_workers',
          'arguments': {
            'tags': ['electrical'],
          },
        },
        {
          'action': 'answer',
          'answer': {'reply': 'Two electricians.'},
        },
      ]);

      await engine.answer(
        'bijli wala chahiye',
        data: data(isWorker: false),
        model: model,
      );

      expect(
        model.transcript,
        contains('a search for workers, with search_workers, tags electrical'),
      );
    });

    test('**where the word list understood, a model that searched for '
        'something else is overruled**', () async {
      // What Qwen2.5 1.5B did with this request: searched gardening jobs.
      final model = ScriptedModel([
        {
          'action': 'search_jobs',
          'arguments': {
            'tags': ['gardening'],
          },
        },
        {
          'action': 'answer',
          'answer': {'reply': 'کوئی کام نہیں ملا۔'},
        },
      ]);

      final reply = await engine.answer(
        'وائرنگ کون ٹھیک کر سکتا ہے؟',
        data: data(
          isWorker: false,
          jobs: [
            job('garden-1', tags: {JobTag.gardening}),
          ],
          listings: [listing('sparky', JobTag.electrical)],
        ),
        model: model,
        language: 'ur',
      );

      expect(reply.aiFailure, AssistantEngine.setAside);
      expect(reply.query.intent, AssistantIntent.workers);
      expect([for (final w in reply.workers) w.id], ['sparky']);
      expect(reply.jobs, isEmpty, reason: 'what it found was not asked for');
      expect(reply.prose, isNull);
    });

    test('of two searches, only the one the words agree with counts', () async {
      final model = ScriptedModel([
        {
          'action': 'search_jobs',
          'arguments': {
            'tags': ['gardening'],
          },
        },
        {
          'action': 'search_workers',
          'arguments': {
            'tags': ['electrical'],
          },
        },
        {
          'action': 'answer',
          'answer': {'reply': 'An electrician.'},
        },
      ]);

      final reply = await engine.answer(
        'Who can fix wiring?',
        data: data(
          isWorker: false,
          jobs: [
            job('garden-1', tags: {JobTag.gardening}),
          ],
          listings: [listing('sparky', JobTag.electrical)],
        ),
        model: model,
      );

      expect(reply.aiFailure, isNull);
      expect(reply.jobs, isEmpty, reason: 'gardening was not asked for');
      expect([for (final w in reply.workers) w.id], ['sparky']);
      expect(reply.query.tags, {JobTag.electrical});
    });

    test('a model that finds nothing, where the words find something, is '
        'set aside', () async {
      final model = ScriptedModel([
        {
          'action': 'search_jobs',
          'arguments': {
            'tags': ['painting'],
            'near_me': true,
          },
        },
        {
          'action': 'answer',
          'answer': {'reply': 'No painting jobs near you.'},
        },
      ]);

      final reply = await engine.answer(
        'painting jobs',
        data: data(jobs: [job('far-1', lat: 32.5)]),
        model: model,
      );

      expect(reply.aiFailure, AssistantEngine.setAside);
      expect([for (final j in reply.jobs) j.id], ['far-1']);
    });

    test('a model still reads what the word list cannot', () async {
      final model = ScriptedModel([
        {
          'action': 'search_workers',
          'arguments': {
            'tags': ['masonry'],
          },
        },
        {
          'action': 'answer',
          'answer': {'reply': 'One mason can help with that.'},
        },
      ]);

      final reply = await engine.answer(
        'my boundary wall is cracking',
        data: data(isWorker: false, listings: [listing('ali', JobTag.masonry)]),
        model: model,
      );

      expect(reply.aiFailure, isNull);
      expect(reply.model, 'Test model');
      expect([for (final w in reply.workers) w.id], ['ali']);
      expect(reply.prose, 'One mason can help with that.');
    });

    test('a trade the model searches "for" is a tag, not a word to narrow '
        'by', () async {
      final model = ScriptedModel([
        {
          'action': 'search_workers',
          'arguments': {
            'tags': ['electrical'],
            'words': 'wiring',
          },
        },
        {
          'action': 'answer',
          'answer': {'reply': 'Two electricians.'},
        },
      ]);

      final reply = await engine.answer(
        'Who can fix wiring?',
        data: data(
          isWorker: false,
          listings: [
            listing('imran', JobTag.electrical),
            listing('sana', JobTag.electrical),
          ],
        ),
        model: model,
      );

      expect(
        [for (final w in reply.workers) w.id],
        unorderedEquals(['imran', 'sana']),
        reason: 'neither headline says "wiring"; both do electrical work',
      );
    });

    test('a sentence in the other language is not shown', () async {
      List<Object?> script(String sentence) => [
        {
          'action': 'search_jobs',
          'arguments': {
            'tags': ['painting'],
          },
        },
        {
          'action': 'answer',
          'answer': {'reply': sentence},
        },
      ];

      final english = await engine.answer(
        'rang ka kaam',
        data: data(jobs: jobs),
        model: ScriptedModel(script('Two painting jobs found.')),
        language: 'ur',
      );
      expect(english.prose, isNull);
      expect(english.model, 'Test model', reason: 'its search still counts');
      expect(english.jobs, hasLength(2));

      final urdu = await engine.answer(
        'rang ka kaam',
        data: data(jobs: jobs),
        model: ScriptedModel(script('رنگ کے دو کام ملے۔')),
        language: 'ur',
      );
      expect(urdu.prose, 'رنگ کے دو کام ملے۔');
    });

    test(
      'a model that fails hands over to the word list, and says so',
      () async {
        final reply = await engine.answer(
          'painting jobs',
          data: data(jobs: jobs),
          model: ScriptedModel([const AiFailure('timeout')]),
        );

        expect(reply.aiFailure, 'timeout');
        expect(reply.jobs, hasLength(2));
      },
    );

    test('what a model writes is cleaned before it is shown', () async {
      final model = ScriptedModel([
        {
          'action': 'search_jobs',
          'arguments': {
            'tags': ['painting'],
          },
        },
        {
          'action': 'answer',
          'answer': {'reply': 'Call 0300 7654321 or visit www.scam.pk now.'},
        },
      ]);

      final reply = await engine.answer(
        'painting',
        data: data(jobs: jobs),
        model: model,
      );

      expect(reply.prose, isNot(contains('7654321')));
      expect(reply.prose, isNot(contains('scam')));
    });

    test('a worker told why a trade they lack finds nothing', () async {
      final reply = await engine.answer(
        'plumbing jobs',
        data: data(myTrades: {JobTag.painting}),
      );
      expect(reply.missingTrades, {JobTag.plumbing});
    });
  });

  testWidgets('a model\'s answer set aside is not shown, and the screen '
      'says why', (tester) async {
    final store = (await tester.runAsync(LocalStore.open))!;
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    // Answers at once, without searching — what Qwen2.5 1.5B did when asked
    // about the weather.
    final ai = AiController(
      store,
      remote: ScriptedModel(
        [
          {
            'action': 'answer',
            'answer': {'reply': 'It is sunny in Lahore today.'},
          },
        ],
        name: 'Hosted test model',
        onDevice: false,
      ),
      remoteFromBuild: false,
    );
    await tester.runAsync(() async {
      await ai.load();
      await ai.enable();
    });

    await tester.pumpWidget(
      appHarness(store: store, ai: ai, child: const AssistantScreen()),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Who can fix wiring?'));
    await tester.pumpAndSettle();

    expect(find.text('It is sunny in Lahore today.'), findsNothing);
    expect(
      find.text(
        "The AI's answer did not fit your words, so this was matched from "
        'them instead.',
      ),
      findsOneWidget,
    );
    expect(
      find.textContaining('Electrical'),
      findsWidgets,
      reason: 'the word list answered the question that was asked',
    );
  });

  testWidgets('the screen answers from the word list where there is no AI', (
    tester,
  ) async {
    final store = (await tester.runAsync(LocalStore.open))!;
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      appHarness(store: store, child: const AssistantScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.text('What are you looking for?'), findsOneWidget);
    expect(
      find.text('Matched from your words. No AI is involved.'),
      findsOneWidget,
      reason: 'off the web there is no model, and the screen says so',
    );

    await tester.tap(find.text('Who can fix wiring?'));
    await tester.pumpAndSettle();

    expect(find.text('Who can fix wiring?'), findsOneWidget);
    expect(
      find.textContaining('Electrical'),
      findsWidgets,
      reason: 'the answer names the trade it searched for',
    );
  });
}
