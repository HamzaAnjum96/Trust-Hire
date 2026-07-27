import 'package:flutter/foundation.dart';

import '../../l10n/app_localizations.dart';
import '../../models/job.dart';
import '../../services/location_service.dart';

/// Holds the device location and the reason it is missing when it is.
///
/// A refusal is a normal state here, not an error: the map still works, it
/// just centres on the fallback and hides distances.
class LocationController extends ChangeNotifier {
  LocationController([this._service = const LocationService()]);

  final LocationService _service;

  LocationResult _result = const LocationResult(LocationStatus.unknown);
  bool _isRequesting = false;

  /// True once the user has dismissed the permission explanation, so it is
  /// not shown again for the rest of the session.
  bool _explanationDismissed = false;

  LocationResult get result => _result;
  bool get isRequesting => _isRequesting;

  /// The device location, or null when it is unavailable.
  JobLocation? get position => _result.position;

  /// Where the map should open — the real location when known, the twin
  /// cities otherwise, since that is where most of the seed data is.
  JobLocation get mapCentre => _result.position ?? LocationService.fallback;

  /// Explanation to surface, or null when there is nothing to say.
  String? explanation(AppStrings strings) =>
      _explanationDismissed ? null : _result.explanation(strings);

  Future<void> request() async {
    if (_isRequesting) return;

    _isRequesting = true;
    notifyListeners();

    _result = await _service.current();
    _isRequesting = false;
    _explanationDismissed = false;
    notifyListeners();
  }

  void dismissExplanation() {
    if (_explanationDismissed) return;
    _explanationDismissed = true;
    notifyListeners();
  }
}
