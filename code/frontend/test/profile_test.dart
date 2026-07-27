import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trust_hire/app/app.dart';
import 'package:trust_hire/app/profile_controller.dart';
import 'package:trust_hire/app/settings_controller.dart';
import 'package:trust_hire/models/job.dart';
import 'package:trust_hire/models/job_tag.dart';
import 'package:trust_hire/models/worker_profile.dart';
import 'package:trust_hire/services/local_store.dart';

/// Roles and trades as the app actually uses them: what is stored, what
/// survives a restart, and which jobs reach the screen as a result.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    rootBundle.clear();
  });

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  final now = DateTime(2026, 7, 27, 10);
  const islamabad = JobLocation(latitude: 33.7104, longitude: 73.0551);

  Job job(
    String id, {
    Set<JobTag> tags = const {JobTag.misc},
    bool local = false,
  }) => Job(
    id: id,
    location: islamabad,
    createdAt: now,
    tags: tags,
    title: 'Job $id',
    isLocal: local,
  );

  group('what is stored', () {
    test('a fresh device is a worker on general work', () async {
      // Worker, not hirer: a worker's first launch shows the seeded jobs,
      // where a hirer's shows an empty list of their own postings.
      final store = await LocalStore.open();
      final profile = ProfileController(store)..load();

      expect(profile.role, UserRole.worker);
      expect(profile.isWorker, isTrue);
      expect(profile.tags, JobTag.defaultWorkerTags);
      expect(profile.specialities, isEmpty);
    });

    test('the role survives a restart', () async {
      final store = await LocalStore.open();
      await (ProfileController(store)..load()).setRole(UserRole.hirer);

      expect((ProfileController(store)..load()).role, UserRole.hirer);
    });

    test('trades survive a restart', () async {
      final store = await LocalStore.open();
      await (ProfileController(store)..load()).toggleTag(JobTag.plumbing);

      final restored = ProfileController(store)..load();
      expect(restored.tags, {JobTag.misc, JobTag.plumbing});
      expect(restored.specialities, {JobTag.plumbing});
    });

    test('switching role leaves the trades alone', () async {
      // Someone who hires a painter today and looks for work tomorrow should
      // not have to pick their trades again.
      final store = await LocalStore.open();
      final profile = ProfileController(store)..load();
      await profile.toggleTag(JobTag.carpentry);

      await profile.setRole(UserRole.hirer);
      await profile.setRole(UserRole.worker);

      expect(profile.specialities, {JobTag.carpentry});
    });

    test('a trade can be dropped, the default cannot', () async {
      final store = await LocalStore.open();
      final profile = ProfileController(store)..load();

      await profile.toggleTag(JobTag.plumbing);
      await profile.toggleTag(JobTag.plumbing);
      expect(profile.tags, JobTag.defaultWorkerTags);

      await profile.toggleTag(JobTag.misc);
      expect(profile.tags, contains(JobTag.misc));
    });

    test(
      'a corrupt profile falls back rather than failing to launch',
      () async {
        final store = await LocalStore.open();
        await store.writeString(StoreKeys.workerProfile, 'not json');

        final profile = ProfileController(store)..load();
        expect(profile.tags, JobTag.defaultWorkerTags);
      },
    );
  });

  group('what reaches the screen', () {
    test('a worker sees general work and their own trades', () async {
      final store = await LocalStore.open();
      final profile = ProfileController(store)..load();

      final jobs = [
        job('general'),
        job('legal', tags: {JobTag.legal}),
        job('plumbing', tags: {JobTag.plumbing}),
      ];

      expect(profile.visibleTo(jobs).map((j) => j.id), ['general']);

      await profile.toggleTag(JobTag.legal);
      expect(profile.visibleTo(jobs).map((j) => j.id), ['general', 'legal']);
    });

    test('a hirer sees everything', () async {
      // Their map is where they post, not a feed of leads — hiding other
      // people's jobs from it would tell them nothing useful.
      final store = await LocalStore.open();
      final profile = ProfileController(store)..load();
      await profile.setRole(UserRole.hirer);

      final jobs = [
        job('general'),
        job('legal', tags: {JobTag.legal}),
      ];

      expect(profile.visibleTo(jobs), hasLength(2));
    });

    test(
      'a job posted on this device is never hidden from its poster',
      () async {
        // Watching your own job vanish the moment you post it reads as a failed
        // save, whatever the tag rule says.
        final store = await LocalStore.open();
        final profile = ProfileController(store)..load();

        final mine = job('mine', tags: {JobTag.legal}, local: true);
        expect(profile.visibleTo([mine]), hasLength(1));
      },
    );
  });

  group('the app', () {
    testWidgets('a new worker is told why the map is quieter', (tester) async {
      final store = await LocalStore.open();
      await (SettingsController(store)..load()).markIntroSeen();

      await tester.pumpWidget(TrustHireApp(store: store));
      await settle(tester);

      // The seed data is mostly specialty work, so a worker on general work
      // alone sees a fraction of it — and must be able to find out why.
      expect(find.text('Add a trade'), findsOneWidget);
    });

    testWidgets('adding a trade puts those jobs back', (tester) async {
      final store = await LocalStore.open();
      await (SettingsController(store)..load()).markIntroSeen();

      await tester.pumpWidget(TrustHireApp(store: store));
      await settle(tester);

      await tester.tap(find.text('Add a trade'));
      await settle(tester);

      expect(find.text('My trades'), findsOneWidget);

      await tester.tap(find.text('Plumbing'));
      await settle(tester);

      final profile = ProfileController(store)..load();
      expect(profile.specialities, {JobTag.plumbing});

      // Back on the map, the prompt has done its job and gone.
      await tester.pageBack();
      await settle(tester);
      expect(find.text('Add a trade'), findsNothing);
    });

    testWidgets('a hirer is not shown the trades prompt', (tester) async {
      final store = await LocalStore.open();
      await (SettingsController(store)..load()).markIntroSeen();
      await (ProfileController(store)..load()).setRole(UserRole.hirer);

      await tester.pumpWidget(TrustHireApp(store: store));
      await settle(tester);

      expect(find.text('Add a trade'), findsNothing);
    });
  });
}
