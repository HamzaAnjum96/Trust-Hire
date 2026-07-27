import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trust_hire/core/theme.dart';
import 'package:trust_hire/features/map/job_map.dart';
import 'package:trust_hire/features/map/job_marker.dart';
import 'package:trust_hire/models/job.dart';

import 'support/offline_tiles.dart';

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

  testWidgets('draws the work area only for the selected job',
      (tester) async {
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

  testWidgets('shows the user location only when it is known',
      (tester) async {
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

  testWidgets('credits OpenStreetMap', (tester) async {
    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    expect(find.text('© OpenStreetMap'), findsOneWidget);
  });

  testWidgets('the selected marker grows so colour is not the only cue',
      (tester) async {
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
