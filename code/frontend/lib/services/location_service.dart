import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../models/job.dart';

/// Why the app does not have a location, so the UI can explain rather than
/// silently show nothing.
enum LocationStatus {
  /// Not asked yet.
  unknown,

  /// Location is available and [LocationResult.position] is set.
  available,

  /// The user refused. Recoverable — they can grant it later.
  denied,

  /// Refused permanently; only the system settings can change it.
  deniedForever,

  /// Location services are switched off on the device.
  serviceDisabled,

  /// Something else went wrong, including the request timing out.
  failed,
}

class LocationResult {
  const LocationResult(this.status, [this.position]);

  final LocationStatus status;
  final JobLocation? position;

  bool get isAvailable =>
      status == LocationStatus.available && position != null;

  /// Plain-language explanation, following section 19 — say what the user can
  /// still do, never what the system failed to do.
  String? get explanation => switch (status) {
    LocationStatus.available || LocationStatus.unknown => null,
    LocationStatus.denied =>
      'Location access is off. You can still move the map and choose an '
          'area manually.',
    LocationStatus.deniedForever =>
      'Location access is off for this app. You can still move the map and '
          'choose an area manually.',
    LocationStatus.serviceDisabled =>
      'Location is switched off on this device. You can still move the map '
          'and choose an area manually.',
    LocationStatus.failed =>
      'Could not find your location. You can still move the map and choose '
          'an area manually.',
  };
}

/// Wraps geolocator so screens deal in [LocationResult] rather than platform
/// permission enums, and so a refusal is never treated as an error.
class LocationService {
  const LocationService();

  /// Between Islamabad and Rawalpindi. Used as the map's opening view when the
  /// real location is unavailable — most of the seed data is in the twin
  /// cities, so the user still lands on something meaningful rather than the
  /// middle of the ocean.
  static const fallback = JobLocation(latitude: 33.6280, longitude: 73.0530);

  Future<LocationResult> current() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return const LocationResult(LocationStatus.serviceDisabled);
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        return const LocationResult(LocationStatus.deniedForever);
      }
      if (permission == LocationPermission.denied) {
        return const LocationResult(LocationStatus.denied);
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          // The map only needs a rough fix, and a slow one is worse than a
          // fallback the user can pan away from.
          timeLimit: Duration(seconds: 12),
        ),
      );

      return LocationResult(
        LocationStatus.available,
        JobLocation(latitude: position.latitude, longitude: position.longitude),
      );
    } catch (error) {
      if (kDebugMode) {
        debugPrint('LocationService.current failed: $error');
      }
      return const LocationResult(LocationStatus.failed);
    }
  }
}
