import 'package:flutter/foundation.dart';

import '../../models/job.dart';
import '../../models/job_type.dart';
import 'job_filter.dart';

/// The current search and filter, shared by the map and the list.
///
/// One controller for both so narrowing on the map carries over to the list
/// and back — switching tabs should not silently change what you are looking
/// at.
class JobFilterController extends ChangeNotifier {
  JobFilter _filter = const JobFilter();

  JobFilter get filter => _filter;
  bool get isActive => _filter.isActive;
  int get activeCount => _filter.activeCount;

  void setQuery(String value) {
    if (_filter.query == value) return;
    _filter = _filter.copyWith(query: value);
    notifyListeners();
  }

  void setTime(TimeFilter value) {
    if (_filter.time == value) return;
    _filter = _filter.copyWith(time: value);
    notifyListeners();
  }

  void setDistance(DistanceFilter value) {
    if (_filter.distance == value) return;
    _filter = _filter.copyWith(distance: value);
    notifyListeners();
  }

  void setWithVoiceNote(bool value) {
    if (_filter.withVoiceNote == value) return;
    _filter = _filter.copyWith(withVoiceNote: value);
    notifyListeners();
  }

  void setWithPhotos(bool value) {
    if (_filter.withPhotos == value) return;
    _filter = _filter.copyWith(withPhotos: value);
    notifyListeners();
  }

  /// Toggles "Today's Jobs" — tapping the active chip clears it.
  void toggleToday() {
    setTime(
      _filter.time == TimeFilter.today ? TimeFilter.any : TimeFilter.today,
    );
  }

  /// Toggles "Near Me".
  void toggleNearMe() {
    setDistance(
      _filter.distance == DistanceFilter.nearMe
          ? DistanceFilter.any
          : DistanceFilter.nearMe,
    );
  }

  /// Adds or removes a kind of work from the filter.
  void toggleType(JobType type) {
    final next = Set<JobType>.from(_filter.types);
    if (!next.remove(type)) next.add(type);

    _filter = _filter.copyWith(types: next);
    notifyListeners();
  }

  void clear() {
    if (!_filter.isActive) return;
    _filter = const JobFilter();
    notifyListeners();
  }

  List<Job> apply(List<Job> jobs, {DateTime? now, JobLocation? from}) =>
      _filter.apply(jobs, now: now ?? DateTime.now(), from: from);
}
