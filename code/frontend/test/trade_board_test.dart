import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trust_hire/core/theme.dart';
import 'package:trust_hire/features/jobs/trade_board.dart';
import 'package:trust_hire/l10n/app_localizations.dart';
import 'package:trust_hire/models/job.dart';
import 'package:trust_hire/models/job_tag.dart';

/// The trade board heading Jobs since 0.26: one row per trade near you.
void main() {
  final now = DateTime(2026, 11, 18, 10);
  const islamabad = JobLocation(latitude: 33.7104, longitude: 73.0551);
  const rawalpindi = JobLocation(latitude: 33.5651, longitude: 73.0169);

  Job job(
    String id,
    Set<JobTag> tags, {
    int? fare,
    JobLocation location = islamabad,
  }) => Job(
    id: id,
    location: location,
    createdAt: now,
    tags: tags,
    title: 'Job $id',
    startingFare: fare,
  );

  group('lines', () {
    test('busiest trade first, a two-trade job counted under both', () {
      final lines = TradeBoard.linesFor([
        job('a', {JobTag.plumbing}, fare: 1500),
        job('b', {JobTag.plumbing, JobTag.electrical}, fare: 4000),
        job('c', {JobTag.electrical}),
        job('d', {JobTag.plumbing}, fare: 2500),
      ], null);

      expect(lines.map((l) => l.tag), [JobTag.plumbing, JobTag.electrical]);
      expect(lines.first.count, 3);
      expect((lines.first.low, lines.first.high), (1500, 4000));
      expect(lines.last.count, 2);
      // A job without a fare does not drag the range to zero.
      expect((lines.last.low, lines.last.high), (4000, 4000));
      // Nobody's position, so no "nearest".
      expect(lines.first.nearest, isNull);
    });

    test('the nearest is measured from the viewer', () {
      final lines = TradeBoard.linesFor([
        job('far', {JobTag.cleaning}, location: rawalpindi),
        job('near', {JobTag.cleaning}),
      ], islamabad);

      expect(lines.single.nearest, 0);
    });
  });

  Future<void> pumpBoard(
    WidgetTester tester, {
    required List<Job> jobs,
    Set<JobTag> selected = const {},
    ValueChanged<JobTag>? onSelect,
    int hiddenJobs = 0,
    VoidCallback? onAddTrade,
    double width = 358,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppStrings.localizationsDelegates,
        supportedLocales: AppStrings.supportedLocales,
        theme: BrandTheme.light,
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: width,
              child: SingleChildScrollView(
                child: TradeBoard(
                  jobs: jobs,
                  viewerLocation: null,
                  selected: selected,
                  onSelect: onSelect ?? (_) {},
                  hiddenJobs: hiddenJobs,
                  onAddTrade: onAddTrade,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('tapping a trade chooses it', (tester) async {
    JobTag? chosen;
    await pumpBoard(
      tester,
      jobs: [
        job('a', {JobTag.plumbing}, fare: 1500),
      ],
      onSelect: (tag) => chosen = tag,
    );

    await tester.tap(find.text('Plumbing'));
    expect(chosen, JobTag.plumbing);
  });

  testWidgets('a narrow board puts the fares under the trade', (tester) async {
    final jobs = [
      job('a', {JobTag.plumbing}, fare: 1500),
    ];

    await pumpBoard(tester, jobs: jobs);
    expect(find.text('Fares'), findsOneWidget);

    // The rail beside a desktop map is about 348px.
    await pumpBoard(tester, jobs: jobs, width: 340);
    expect(find.text('Fares'), findsNothing);
    expect(find.textContaining('Rs.'), findsOneWidget);
  });

  testWidgets('ends with "Add a trade" while trades leave jobs out', (
    tester,
  ) async {
    var opened = false;
    final jobs = [
      job('a', {JobTag.misc}),
    ];

    await pumpBoard(
      tester,
      jobs: jobs,
      hiddenJobs: 12,
      onAddTrade: () => opened = true,
    );
    expect(find.text('12 more jobs near you need a trade'), findsOneWidget);
    await tester.tap(find.text('Add a trade'));
    expect(opened, isTrue);

    // Nothing left out, nothing to add.
    await pumpBoard(tester, jobs: jobs, onAddTrade: () {});
    expect(find.text('Add a trade'), findsNothing);
  });

  testWidgets('one trade is its own button, apart from the heading', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpBoard(
      tester,
      jobs: [
        job('a', {JobTag.plumbing}, fare: 1500),
      ],
    );

    final row = tester.getSemantics(find.text('Plumbing'));
    expect(row.label, 'Plumbing, 1 job, Rs. 1,500');
    expect(row.flagsCollection.isButton, isTrue);
    expect(row.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
    handle.dispose();
  });
}
