import 'package:flutter_test/flutter_test.dart';
import 'package:trust_hire/l10n/app_localizations.dart';
import 'package:trust_hire/features/map/location_controller.dart';
import 'package:trust_hire/models/job.dart';
import 'package:trust_hire/services/location_service.dart';

import 'support/test_strings.dart';

/// A refused location is a normal state, not an error: the map still works,
/// it just centres on the fallback. These tests pin that down without relying
/// on a platform plugin.
class _FakeLocationService implements LocationService {
  _FakeLocationService(this.result);

  final LocationResult result;
  int calls = 0;

  @override
  Future<LocationResult> current() async {
    calls++;
    return result;
  }
}

void main() {
  late AppStrings strings;

  setUpAll(() async => strings = await loadStrings());

  // Between Islamabad and Rawalpindi, where most of the seed data now is.
  const twinCities = JobLocation(latitude: 33.6280, longitude: 73.0530);

  test('starts with no position and nothing to explain', () {
    final controller = LocationController(
      _FakeLocationService(const LocationResult(LocationStatus.unknown)),
    );

    expect(controller.position, isNull);
    expect(controller.explanation(strings), isNull);
    expect(controller.mapCentre, LocationService.fallback);
  });

  test('exposes the position once granted', () async {
    const found = JobLocation(latitude: 31.55, longitude: 74.40);
    final controller = LocationController(
      _FakeLocationService(
        const LocationResult(LocationStatus.available, found),
      ),
    );

    await controller.request();

    expect(controller.position, found);
    expect(controller.mapCentre, found);
    expect(controller.explanation(strings), isNull);
  });

  test('falls back to the twin cities and explains when refused', () async {
    final controller = LocationController(
      _FakeLocationService(const LocationResult(LocationStatus.denied)),
    );

    await controller.request();

    expect(controller.position, isNull);
    // The seed data is around Islamabad and Rawalpindi, so the user still
    // lands on something rather than the middle of the ocean.
    expect(controller.mapCentre, twinCities);
    expect(
      controller.explanation(strings),
      contains('You can still move the map'),
    );
  });

  test(
    'every unavailable status explains what the user can still do',
    () async {
      for (final status in <LocationStatus>[
        LocationStatus.denied,
        LocationStatus.deniedForever,
        LocationStatus.serviceDisabled,
        LocationStatus.failed,
      ]) {
        final controller = LocationController(
          _FakeLocationService(LocationResult(status)),
        );
        await controller.request();

        expect(
          controller.explanation(strings),
          isNotNull,
          reason: '$status should be explained',
        );
        expect(
          controller.explanation(strings),
          contains('choose an area manually'),
          reason: '$status should say what is still possible',
        );
      }
    },
  );

  test('an explanation stays dismissed', () async {
    final controller = LocationController(
      _FakeLocationService(const LocationResult(LocationStatus.denied)),
    );

    await controller.request();
    expect(controller.explanation(strings), isNotNull);

    controller.dismissExplanation();
    expect(controller.explanation(strings), isNull);
  });

  test('concurrent requests do not stack up', () async {
    final service = _FakeLocationService(
      const LocationResult(LocationStatus.denied),
    );
    final controller = LocationController(service);

    await Future.wait([controller.request(), controller.request()]);

    expect(service.calls, 1);
    expect(controller.isRequesting, isFalse);
  });
}
