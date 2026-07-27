import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:trust_hire/core/theme.dart';
import 'package:trust_hire/features/map/job_map.dart';
import 'package:trust_hire/features/map/job_marker.dart';
import 'package:trust_hire/features/map/marker_cluster.dart';
import 'package:trust_hire/models/job.dart';
import 'package:trust_hire/models/job_type.dart';

import 'support/offline_tiles.dart';
import 'package:trust_hire/l10n/app_localizations.dart';

/// Clustering was optional in Sprint 1 and became necessary once the seed data
/// spanned Islamabad to Muzaffarabad: at any zoom showing the whole picture,
/// the twin-cities pins pile up and none of them can be tapped.
void main() {
  final now = DateTime(2026, 7, 27, 10);

  Job job(String id, double lat, double lng, {JobType? type}) => Job(
    id: id,
    location: JobLocation(latitude: lat, longitude: lng),
    createdAt: now,
    type: type,
    title: 'Job $id',
  );

  /// A camera at a given zoom, which the clusterer needs to work in screen
  /// space rather than degrees.
  MapCamera cameraAt(double zoom) => MapCamera(
    crs: const Epsg3857(),
    center: const LatLng(33.6280, 73.0530),
    zoom: zoom,
    rotation: 0,
    nonRotatedSize: const Size(400, 800),
  );

  group('grouping', () {
    test('leaves well-separated jobs alone', () {
      // Islamabad and Muzaffarabad, ~130 km apart, at street zoom.
      final jobs = [
        job('isb', 33.6844, 73.0479),
        job('muz', 34.3700, 73.4711),
      ];

      final clusters = const MarkerClusterer().cluster(
        jobs,
        camera: cameraAt(14),
      );

      expect(clusters, hasLength(2));
      expect(clusters.every((c) => c.isSingle), isTrue);
    });

    test('groups jobs that would overlap on screen', () {
      // Two jobs a few hundred metres apart, viewed from far out.
      final jobs = [
        job('a', 33.6844, 73.0479),
        job('b', 33.6850, 73.0485),
      ];

      final clusters = const MarkerClusterer().cluster(
        jobs,
        camera: cameraAt(9),
      );

      expect(clusters, hasLength(1));
      expect(clusters.single.count, 2);
      expect(clusters.single.isSingle, isFalse);
    });

    test('the same jobs separate again as you zoom in', () {
      final jobs = [
        job('a', 33.6844, 73.0479),
        job('b', 33.6900, 73.0540),
      ];

      final farOut = const MarkerClusterer().cluster(
        jobs,
        camera: cameraAt(9),
      );
      final closeIn = const MarkerClusterer().cluster(
        jobs,
        camera: cameraAt(16),
      );

      expect(farOut, hasLength(1));
      expect(closeIn, hasLength(2));
    });

    test('every job ends up in exactly one group', () {
      final jobs = [
        for (var i = 0; i < 20; i++)
          job('j$i', 33.60 + i * 0.01, 73.00 + i * 0.01),
      ];

      final clusters = const MarkerClusterer().cluster(
        jobs,
        camera: cameraAt(11),
      );

      final ids = clusters.expand((c) => c.jobs).map((j) => j.id).toList();
      expect(ids, hasLength(jobs.length));
      expect(ids.toSet(), hasLength(jobs.length));
    });

    test('an empty list produces no clusters', () {
      expect(
        const MarkerClusterer().cluster(const [], camera: cameraAt(12)),
        isEmpty,
      );
    });

    test('a cluster sits between the jobs it covers', () {
      final jobs = [
        job('a', 33.60, 73.00),
        job('b', 33.62, 73.04),
      ];

      final cluster = const MarkerClusterer()
          .cluster(jobs, camera: cameraAt(9))
          .single;

      expect(cluster.centre.latitude, closeTo(33.61, 0.001));
      expect(cluster.centre.longitude, closeTo(73.02, 0.001));
    });
  });

  group('uniform clusters keep their glyph', () {
    test('all the same kind counts as uniform', () {
      final jobs = [
        job('a', 33.6844, 73.0479, type: JobType.plumbing),
        job('b', 33.6850, 73.0485, type: JobType.plumbing),
      ];

      final cluster = const MarkerClusterer()
          .cluster(jobs, camera: cameraAt(9))
          .single;

      expect(cluster.isUniform, isTrue);
    });

    test('mixed kinds are not uniform', () {
      final jobs = [
        job('a', 33.6844, 73.0479, type: JobType.plumbing),
        job('b', 33.6850, 73.0485, type: JobType.driving),
      ];

      final cluster = const MarkerClusterer()
          .cluster(jobs, camera: cameraAt(9))
          .single;

      expect(cluster.isUniform, isFalse);
    });

    test('untyped jobs are never uniform', () {
      final jobs = [
        job('a', 33.6844, 73.0479),
        job('b', 33.6850, 73.0485),
      ];

      final cluster = const MarkerClusterer()
          .cluster(jobs, camera: cameraAt(9))
          .single;

      expect(cluster.isUniform, isFalse);
    });
  });

  group('bounds', () {
    test('contain every job, with room to breathe', () {
      final jobs = [
        job('isb', 33.6844, 73.0479),
        job('muz', 34.3700, 73.4711),
        job('mir', 33.1478, 73.7519),
      ];

      final bounds = boundsOf(jobs)!;

      for (final j in jobs) {
        expect(
          bounds.contains(
            LatLng(j.location.latitude, j.location.longitude),
          ),
          isTrue,
          reason: '${j.id} should be inside the bounds',
        );
      }

      // Padded outwards, so pins are not flush against the screen edge.
      expect(bounds.south, lessThan(33.1478));
      expect(bounds.north, greaterThan(34.3700));
    });

    test('are null when there is nothing to fit', () {
      expect(boundsOf(const []), isNull);
    });
  });

  group('on the map', () {
    testWidgets('draws a cluster marker for overlapping jobs', (tester) async {
      // Six jobs within a few hundred metres, viewed from a low zoom.
      final jobs = [
        for (var i = 0; i < 6; i++)
          job('j$i', 33.6844 + i * 0.0008, 73.0479 + i * 0.0008),
      ];

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppStrings.localizationsDelegates,
          supportedLocales: AppStrings.supportedLocales,
          theme: BrandTheme.light,
          home: Scaffold(
            body: JobMap(
              jobs: jobs,
              centre: const JobLocation(
                latitude: 33.6844,
                longitude: 73.0479,
              ),
              initialZoom: 9,
              onJobTapped: (_) {},
              onMapTapped: () {},
              tileProvider: OfflineTileProvider(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ClusterMarker), findsWidgets);
      // The individual pins are folded into it.
      expect(find.byType(JobMarker), findsNothing);
    });

    testWidgets('tapping a cluster reports it back', (tester) async {
      JobCluster? tapped;
      final jobs = [
        for (var i = 0; i < 4; i++)
          job('j$i', 33.6844 + i * 0.0008, 73.0479 + i * 0.0008),
      ];

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppStrings.localizationsDelegates,
          supportedLocales: AppStrings.supportedLocales,
          theme: BrandTheme.light,
          home: Scaffold(
            body: JobMap(
              jobs: jobs,
              centre: const JobLocation(
                latitude: 33.6844,
                longitude: 73.0479,
              ),
              initialZoom: 9,
              onJobTapped: (_) {},
              onMapTapped: () {},
              onClusterTapped: (cluster) => tapped = cluster,
              tileProvider: OfflineTileProvider(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byType(ClusterMarker).first,
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();

      expect(tapped, isNotNull);
      expect(tapped!.count, greaterThan(1));
    });

    testWidgets('shows individual pins once zoomed in', (tester) async {
      // Both on screen at this zoom, but far enough apart not to merge.
      final jobs = [
        job('a', 33.6844, 73.0479),
        job('b', 33.6870, 73.0510),
      ];

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppStrings.localizationsDelegates,
          supportedLocales: AppStrings.supportedLocales,
          theme: BrandTheme.light,
          home: Scaffold(
            body: JobMap(
              jobs: jobs,
              centre: const JobLocation(
                latitude: 33.6844,
                longitude: 73.0479,
              ),
              initialZoom: 14,
              onJobTapped: (_) {},
              onMapTapped: () {},
              tileProvider: OfflineTileProvider(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(JobMarker), findsNWidgets(2));
      expect(find.byType(ClusterMarker), findsNothing);
    });
  });
}
