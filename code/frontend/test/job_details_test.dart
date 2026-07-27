import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trust_hire/app/job_controller.dart';
import 'package:trust_hire/core/theme.dart';
import 'package:trust_hire/l10n/app_localizations.dart';
import 'package:trust_hire/features/jobs/job_details_sheet.dart';
import 'package:trust_hire/features/jobs/photo_gallery.dart';
import 'package:trust_hire/features/jobs/saved_jobs_controller.dart';
import 'package:trust_hire/models/job.dart';
import 'package:trust_hire/services/job_repository.dart';
import 'package:trust_hire/app/bid_controller.dart';
import 'package:trust_hire/app/profile_controller.dart';
import 'package:trust_hire/services/bid_repository.dart';
import 'package:trust_hire/services/local_store.dart';
import 'package:trust_hire/services/media_store.dart';
import 'package:trust_hire/widgets/voice_note_player.dart';

import 'support/test_strings.dart';

/// Sprint 2's definition of done is "every seeded job opens correctly" — which
/// matters most for the jobs that carry only some of the information, since
/// the product treats missing information as normal.
void main() {
  late AppStrings strings;

  setUpAll(() async => strings = await loadStrings());

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    rootBundle.clear();
  });

  late SavedJobsController savedJobs;
  late BidController bids;
  late ProfileController profile;

  Future<(JobController, MediaStore)> buildControllers() async {
    final store = await LocalStore.open();
    savedJobs = SavedJobsController(store)..load();
    bids = BidController(BidRepository(store))..load();
    profile = ProfileController(store)..load();
    final media = MediaStore(store);
    final controller = JobController(JobRepository(store, media));
    await controller.load();
    return (controller, media);
  }

  Future<void> openSheet(
    WidgetTester tester,
    JobController controller,
    MediaStore media,
    String jobId, {
    JobLocation? viewerLocation,
    // Enough frames for the sheet's own content. The embedded map preview
    // needs more, so tests that assert on it ask for more.
    int pumps = 8,
  }) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: controller),
          ChangeNotifierProvider.value(value: savedJobs),
          ChangeNotifierProvider.value(value: bids),
          ChangeNotifierProvider.value(value: profile),
          Provider<MediaStore>.value(value: media),
        ],
        child: MaterialApp(
          localizationsDelegates: AppStrings.localizationsDelegates,
          supportedLocales: AppStrings.supportedLocales,
          theme: BrandTheme.light,
          home: Scaffold(
            body: JobDetailsSheet(
              jobId: jobId,
              mediaStore: media,
              viewerLocation: viewerLocation,
            ),
          ),
        ),
      ),
    );
    // The embedded map preview keeps tile requests in flight, so pump a fixed
    // span rather than settling.
    for (var i = 0; i < pumps; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  /// The first seeded job matching [wanted]. Selecting by shape rather than by
  /// id: the seed is generated, so `seed-002` is whatever the generator put
  /// there this time, and a test that names one is testing the generator.
  Job jobWhere(JobController controller, bool Function(Job) wanted) {
    return controller.jobs.firstWhere(
      wanted,
      orElse: () => throw StateError('no seeded job matches'),
    );
  }

  /// Brings one thing into view.
  ///
  /// Preferred over scrolling to the bottom: the sheet has grown twice now
  /// (bidding, then the audio notice), and each time a label that used to sit
  /// at the end ended up in the middle, off-screen above a bottom-scrolled
  /// list. Scrolling to the target cannot go stale that way.
  Future<void> scrollTo(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    for (var i = 0; i < 3; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  /// The sheet is a ListView, which does not build children below the fold —
  /// so anything further down has to be scrolled into view before asserting.
  Future<void> scrollToBottom(WidgetTester tester) async {
    // Repeated drags rather than one: the list grows as children build, so a
    // single large drag stops short of the real bottom.
    for (var attempt = 0; attempt < 4; attempt++) {
      await tester.drag(find.byType(ListView), const Offset(0, -400));
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }
  }

  testWidgets('every shape of seeded job opens without error', (tester) async {
    // One job per distinct *shape*, not one per row.
    //
    // This used to open all of them. That was fine at sixteen and took seven
    // minutes at a hundred and eighty, which is the kind of test people start
    // skipping. What it was ever really checking is that no combination of
    // present and absent fields breaks the sheet — a title with no photos, a
    // voice note with no words, no contact, no fare — and a hundred and forty
    // more plumbing jobs prove none of that a second time.
    //
    // The signature is derived from the data rather than listed here, so a
    // shape nobody has thought of yet still gets covered the moment the seed
    // contains one.
    final (controller, media) = await buildControllers();

    // Only the fields that change what the sheet *builds*. A different fare
    // or a second tag renders the same widgets with different text, and
    // opening thirty more sheets to find that out is what made this slow.
    final representatives = <String, Job>{};
    for (final job in controller.jobs) {
      final signature = [
        job.hasTextDescription,
        job.title != null,
        job.hasVoiceNote,
        job.hasPhotos,
        job.hasContact,
        job.startingFare != null,
      ].join('|');

      representatives.putIfAbsent(signature, () => job);
    }

    expect(
      representatives.length,
      greaterThan(8),
      reason: 'the seed should exercise more shapes than this',
    );

    for (final job in representatives.values) {
      await openSheet(tester, controller, media, job.id, pumps: 3);

      expect(
        find.text(job.displayTitle(strings)),
        findsOneWidget,
        reason: 'job ${job.id} should show a heading',
      );
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('shows a gallery only for jobs with photos', (tester) async {
    final (controller, media) = await buildControllers();

    final withPhotos = jobWhere(controller, (j) => j.hasPhotos);
    await openSheet(tester, controller, media, withPhotos.id);
    expect(find.byType(PhotoGallery), findsOneWidget);

    final withoutPhotos = jobWhere(controller, (j) => !j.hasPhotos);
    await openSheet(tester, controller, media, withoutPhotos.id);
    expect(find.byType(PhotoGallery), findsNothing);
  });

  testWidgets('shows a player only for jobs with a voice note', (tester) async {
    final (controller, media) = await buildControllers();

    final spoken = jobWhere(controller, (j) => j.hasVoiceNote);
    await openSheet(tester, controller, media, spoken.id);
    expect(find.byType(VoiceNotePlayer), findsOneWidget);

    final written = jobWhere(controller, (j) => !j.hasVoiceNote);
    await openSheet(tester, controller, media, written.id);
    expect(find.byType(VoiceNotePlayer), findsNothing);
  });

  testWidgets('a job with only a voice note still opens usefully', (
    tester,
  ) async {
    final (controller, media) = await buildControllers();

    final audioOnly = jobWhere(
      controller,
      (j) => j.isAudioOnly && !j.hasPhotos,
    );
    await openSheet(tester, controller, media, audioOnly.id);

    // Since P1-1 the heading falls back to the job's tag when it has one, so
    // "Voice note job" only appears on a job whose tag says nothing either.
    // Either way it has a heading, a player, and — since 0.3.1 — a line
    // saying there is nothing to read.
    expect(find.text(audioOnly.displayTitle(strings)), findsOneWidget);
    expect(find.byType(VoiceNotePlayer), findsOneWidget);
    // The wording depends on whether there is anyone to ask — a job with no
    // contact cannot suggest asking the poster.
    expect(
      audioOnly.hasContact
          ? find.textContaining('no written description')
          : find.text('Described by voice only'),
      findsOneWidget,
    );

    await scrollTo(tester, find.text('When'));
    expect(find.text('When'), findsOneWidget);

    await scrollTo(tester, find.text('Area'));
    expect(find.text('Area'), findsOneWidget);
  });

  testWidgets('shows distance only when the viewer location is known', (
    tester,
  ) async {
    final (controller, media) = await buildControllers();

    final anyJob = controller.jobs.first;
    await openSheet(tester, controller, media, anyJob.id);
    await scrollToBottom(tester);
    expect(find.textContaining('away'), findsNothing);

    await openSheet(
      tester,
      controller,
      media,
      anyJob.id,
      viewerLocation: const JobLocation(latitude: 31.60, longitude: 74.40),
    );
    await scrollToBottom(tester);
    expect(find.textContaining('away'), findsOneWidget);
  });

  testWidgets('says the area is approximate, and when that changes', (
    tester,
  ) async {
    // P1-3 replaced the POC's promise that an exact location is never shown.
    // On a job still taking offers it is approximate and says so; once a
    // worker is chosen the caption has to change with the behaviour, or the
    // app is reassuring people about something it has already given away.
    final (controller, media) = await buildControllers();
    final anyJob = controller.jobs.first;

    await openSheet(tester, controller, media, anyJob.id);
    await scrollTo(tester, find.text(strings.generalAreaNotice));
    expect(find.text(strings.generalAreaNotice), findsOneWidget);
    expect(find.text(strings.exactLocationShown), findsNothing);

    await controller.saveJob(
      anyJob.copyWith().withAcceptedBid(
        workerId: BidController.localWorkerId,
        fare: 1500,
      ),
    );
    await openSheet(tester, controller, media, anyJob.id);
    await scrollTo(tester, find.text(strings.exactLocationShown));

    expect(find.text(strings.exactLocationShown), findsOneWidget);
    expect(find.text(strings.generalAreaNotice), findsNothing);
  });

  testWidgets('handles a job deleted while its sheet is open', (tester) async {
    final (controller, media) = await buildControllers();
    final anyJob = controller.jobs.first;
    await openSheet(tester, controller, media, anyJob.id);
    expect(find.text(anyJob.displayTitle(strings)), findsOneWidget);

    await controller.deleteJob(anyJob.id);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('This job is no longer here.'), findsOneWidget);
  });

  group('MediaStore', () {
    test('round-trips bytes through local storage', () async {
      final store = await LocalStore.open();
      final media = MediaStore(store);

      final bytes = Uint8List.fromList(utf8.encode('a photo'));
      final reference = await media.save(bytes, extension: 'png');

      expect(MediaStore.isLocal(reference), isTrue);
      expect(media.read(reference), bytes);
    });

    test('asset references are left alone', () async {
      final store = await LocalStore.open();
      final media = MediaStore(store);

      const asset = 'assets/images/jobs/plumbing-01.png';
      expect(MediaStore.isLocal(asset), isFalse);
      expect(media.read(asset), isNull);
      // audioplayers wants the path relative to assets/.
      expect(
        MediaStore.assetKeyFor('assets/audio/voice-01.wav'),
        'audio/voice-01.wav',
      );
    });

    test('pruning drops blobs no job references', () async {
      final store = await LocalStore.open();
      final media = MediaStore(store);

      final kept = await media.save(
        Uint8List.fromList([1, 2, 3]),
        extension: 'png',
      );
      final dropped = await media.save(
        Uint8List.fromList([4, 5, 6]),
        extension: 'png',
      );

      await media.pruneExcept({kept});

      expect(media.read(kept), isNotNull);
      expect(media.read(dropped), isNull);
    });

    test('restoring the seed clears locally captured media', () async {
      final store = await LocalStore.open();
      final media = MediaStore(store);
      final repository = JobRepository(store, media);
      await repository.ensureSeeded();

      final reference = await media.save(
        Uint8List.fromList([9, 9, 9]),
        extension: 'png',
      );
      expect(media.read(reference), isNotNull);

      await repository.resetToSeed();
      expect(media.read(reference), isNull);
    });
  });
}
