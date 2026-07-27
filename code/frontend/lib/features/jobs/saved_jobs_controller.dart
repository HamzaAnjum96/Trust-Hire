import 'package:flutter/foundation.dart';

import '../../models/job.dart';
import '../../services/local_store.dart';

/// Which jobs the user has bookmarked.
///
/// Until now there was no way to keep hold of work you found: you tapped a
/// pin, read it, closed the sheet, and had to find it again. Saving is the
/// smallest thing that fixes that, and it needs no backend — a list of ids in
/// local storage.
///
/// Ids rather than copies of the job, deliberately: a saved job that has since
/// been edited should show the edit, and one that has been deleted should
/// disappear rather than linger as a stale duplicate.
class SavedJobsController extends ChangeNotifier {
  SavedJobsController(this._store);

  final LocalStore _store;

  Set<String> _saved = <String>{};

  /// Ids in the order they were saved, newest first.
  List<String> _order = <String>[];

  void load() {
    final raw = _store.readString(StoreKeys.savedJobs) ?? '';
    _order = raw.split(',').where((id) => id.isNotEmpty).toList();
    _saved = _order.toSet();
    notifyListeners();
  }

  bool isSaved(String jobId) => _saved.contains(jobId);

  int get count => _saved.length;

  /// Saves or unsaves, and reports which it did so the caller can confirm it.
  Future<bool> toggle(String jobId) async {
    final nowSaved = !_saved.contains(jobId);

    if (nowSaved) {
      _saved.add(jobId);
      _order.insert(0, jobId);
    } else {
      _saved.remove(jobId);
      _order.remove(jobId);
    }

    notifyListeners();
    await _persist();
    return nowSaved;
  }

  /// The saved jobs, newest save first.
  ///
  /// Jobs that no longer exist are skipped rather than shown as gaps — and
  /// [hasMissing] lets the screen mention it once instead of silently
  /// shrinking the list.
  List<Job> resolve(List<Job> all) {
    final byId = {for (final job in all) job.id: job};
    return [
      for (final id in _order)
        if (byId[id] != null) byId[id]!,
    ];
  }

  /// True when something saved has since been deleted.
  bool hasMissing(List<Job> all) {
    final ids = all.map((job) => job.id).toSet();
    return _order.any((id) => !ids.contains(id));
  }

  /// Drops ids whose jobs are gone, so the list does not grow forever.
  Future<void> prune(List<Job> all) async {
    final ids = all.map((job) => job.id).toSet();
    final kept = _order.where(ids.contains).toList();
    if (kept.length == _order.length) return;

    _order = kept;
    _saved = kept.toSet();
    notifyListeners();
    await _persist();
  }

  Future<void> _persist() =>
      _store.writeString(StoreKeys.savedJobs, _order.join(','));
}
