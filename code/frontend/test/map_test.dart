import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trust_hire/core/map_theme.dart';
import 'package:trust_hire/core/theme.dart';
import 'package:trust_hire/features/map/job_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:trust_hire/features/map/job_marker.dart';
import 'package:trust_hire/models/job.dart';

import 'support/offline_tiles.dart';
import 'package:trust_hire/l10n/app_localizations.dart';

/// Sprint 1's definition of done is "user can browse seeded jobs". These tests
/// cover the map surface itself: markers render for every job, tapping one
/// reports it back, and the selected job's approximate work area is drawn.
void main() {
  final now = DateTime(2026, 7, 27, 10);

  Job job(String id, double lat, double lng, {bool isLocal = false}) {
    return Job(
      id: id,
      location: JobLocation(latitude: lat, longitude: lng),
      createdAt: now,
      title: 'Job $id',
      radiusMetres: 1000,
      isLocal: isLocal,
    );
  }

  final jobs = <Job>[
    job('a', 31.5204, 74.3587),
    job('b', 31.5310, 74.3721),
    job('c', 31.5102, 74.3450, isLocal: true),
  ];

  Widget harness({
    String? selectedJobId,
    JobLocation? userLocation,
    ValueChanged<Job>? onJobTapped,
    VoidCallback? onMapTapped,
  }) {
    return MaterialApp(
      localizationsDelegates: AppStrings.localizationsDelegates,
      supportedLocales: AppStrings.supportedLocales,
      theme: BrandTheme.light,
      home: Scaffold(
        body: JobMap(
          jobs: jobs,
          centre: const JobLocation(latitude: 31.5204, longitude: 74.3587),
          selectedJobId: selectedJobId,
          userLocation: userLocation,
          onJobTapped: onJobTapped ?? (_) {},
          onMapTapped: onMapTapped ?? () {},
          tileProvider: OfflineTileProvider(),
        ),
      ),
    );
  }

  testWidgets('renders a marker for every job', (tester) async {
    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    expect(find.byType(JobMarker), findsNWidgets(3));
  });

  testWidgets('tapping a marker reports the job back', (tester) async {
    Job? tapped;
    await tester.pumpWidget(harness(onJobTapped: (job) => tapped = job));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(JobMarker).first, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(tapped, isNotNull);
    expect(jobs.map((j) => j.id), contains(tapped!.id));
  });

  testWidgets('draws the work area only for the selected job', (tester) async {
    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();
    expect(find.byType(CircleLayer), findsNothing);

    await tester.pumpWidget(harness(selectedJobId: 'b'));
    await tester.pumpAndSettle();

    final layer = tester.widget<CircleLayer>(find.byType(CircleLayer));
    expect(layer.circles, hasLength(1));
    expect(layer.circles.first.radius, 1000);
    expect(layer.circles.first.useRadiusInMeter, isTrue);
  });

  testWidgets('shows the user location only when it is known', (tester) async {
    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();
    expect(find.byType(UserLocationMarker), findsNothing);

    await tester.pumpWidget(
      harness(
        userLocation: const JobLocation(latitude: 31.52, longitude: 74.35),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(UserLocationMarker), findsOneWidget);
  });

  testWidgets('credits both tile sources', (tester) async {
    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    expect(find.text('© OpenStreetMap contributors © CARTO'), findsOneWidget);
  });

  testWidgets('uses a purpose-built basemap per brightness', (tester) async {
    // Section 15 wants a low-noise light map and section 30 a warm dark one.
    // Darkening a single raster satisfies neither, so each brightness has its
    // own tile style rather than a filter over a shared one.
    expect(MapTheme.light.tileUrl, isNot(MapTheme.dark.tileUrl));
    expect(MapTheme.light.tileUrl, contains('light_all'));
    expect(MapTheme.dark.tileUrl, contains('dark_all'));

    // The brand tint must stay subtle enough to leave labels readable.
    expect(MapTheme.light.tintOpacity, lessThan(0.35));
    expect(MapTheme.dark.tintOpacity, lessThan(0.35));
  });

  testWidgets('dark mode uses the dark basemap', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppStrings.localizationsDelegates,
        supportedLocales: AppStrings.supportedLocales,
        theme: BrandTheme.dark,
        home: Scaffold(
          body: JobMap(
            jobs: jobs,
            centre: const JobLocation(latitude: 31.5204, longitude: 74.3587),
            onJobTapped: (_) {},
            onMapTapped: () {},
            tileProvider: OfflineTileProvider(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final layer = tester.widget<TileLayer>(find.byType(TileLayer));
    expect(layer.urlTemplate, MapTheme.dark.tileUrl);
  });

  group('regrouping waits for the map to settle', () {
    /// Far enough apart to stand alone at street level, close enough to merge
    /// when the whole city is in view.
    final spread = <Job>[
      job('a', 31.5204, 74.3587),
      job('b', 31.5310, 74.3721),
      job('c', 31.5102, 74.3450),
    ];

    Widget movingHarness(MapController controller) => MaterialApp(
      localizationsDelegates: AppStrings.localizationsDelegates,
      supportedLocales: AppStrings.supportedLocales,
      theme: BrandTheme.light,
      home: Scaffold(
        body: JobMap(
          jobs: spread,
          centre: const JobLocation(latitude: 31.5204, longitude: 74.3587),
          controller: controller,
          initialZoom: 15,
          onJobTapped: (_) {},
          onMapTapped: () {},
          tileProvider: OfflineTileProvider(),
        ),
      ),
    );

    testWidgets('the grouping is held while the camera is moving', (
      tester,
    ) async {
      final controller = MapController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(movingHarness(controller));
      await tester.pumpAndSettle();
      expect(find.byType(JobMarker), findsNWidgets(3));

      // Zoom out far enough that all three belong in one cluster.
      controller.move(const LatLng(31.5204, 74.3587), 9);
      await tester.pump();

      // Still three: recomputing here is what makes pins flicker mid-drag.
      expect(find.byType(JobMarker), findsNWidgets(3));
      expect(find.byType(ClusterMarker), findsNothing);

      // Once the camera settles, the grouping catches up.
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();
      expect(find.byType(ClusterMarker), findsOneWidget);
    });

    testWidgets('a changed job list does not wait for the camera', (
      tester,
    ) async {
      // Filtering is not camera movement. Holding the old grouping there
      // would leave a removed job on the map.
      final controller = MapController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(movingHarness(controller));
      await tester.pumpAndSettle();

      controller.move(const LatLng(31.5204, 74.3587), 15.5);
      await tester.pump();

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppStrings.localizationsDelegates,
          supportedLocales: AppStrings.supportedLocales,
          theme: BrandTheme.light,
          home: Scaffold(
            body: JobMap(
              jobs: [spread.first],
              centre: const JobLocation(latitude: 31.5204, longitude: 74.3587),
              controller: controller,
              initialZoom: 15,
              onJobTapped: (_) {},
              onMapTapped: () {},
              tileProvider: OfflineTileProvider(),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(JobMarker), findsOneWidget);
    });
  });

  testWidgets('the selected marker grows so colour is not the only cue', (
    tester,
  ) async {
    await tester.pumpWidget(harness(selectedJobId: 'a'));
    await tester.pumpAndSettle();

    final markers = tester
        .widgetList<JobMarker>(find.byType(JobMarker))
        .toList();
    final selected = markers.firstWhere((m) => m.job.id == 'a');
    final unselected = markers.firstWhere((m) => m.job.id == 'b');

    expect(selected.isSelected, isTrue);
    expect(unselected.isSelected, isFalse);
    expect(JobMarker.selectedSize, greaterThan(JobMarker.size));
  });
}
