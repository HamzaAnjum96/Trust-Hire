import 'dart:convert';
import 'dart:typed_data';

import 'package:uuid/uuid.dart';

import 'local_store.dart';

/// Stores photos and voice notes recorded on the device.
///
/// Media is referenced by a string that is either a bundled asset path
/// (`assets/images/jobs/x.png`, used by the seed data) or a local reference
/// (`local:<id>`) whose bytes live in local storage.
///
/// Bytes are held as base64 rather than files because it is the one approach
/// that behaves identically on Android, iOS and web. A file path recorded on
/// web is a blob URL that dies on reload, which would break the sprint plan's
/// requirement that locally created jobs persist. The cost is size, which the
/// capture settings keep in check.
class MediaStore {
  MediaStore(this._store, [this._uuid = const Uuid()]);

  final LocalStore _store;
  final Uuid _uuid;

  static const localPrefix = 'local:';
  static const _keyPrefix = 'trust_hire.media.';

  /// True when [reference] points at bytes in local storage rather than an
  /// asset bundled with the app.
  static bool isLocal(String reference) => reference.startsWith(localPrefix);

  /// The asset path audioplayers expects, which is relative to `assets/`.
  static String assetKeyFor(String reference) =>
      reference.startsWith('assets/') ? reference.substring(7) : reference;

  Future<String> save(Uint8List bytes, {required String extension}) async {
    final id = '${_uuid.v4()}.$extension';
    final reference = '$localPrefix$id';

    await _store.writeString(_keyPrefix + id, base64Encode(bytes));
    await _addToIndex(id);

    return reference;
  }

  Uint8List? read(String reference) {
    if (!isLocal(reference)) return null;

    final encoded = _store.readString(_keyPrefix + _idOf(reference));
    if (encoded == null) return null;

    try {
      return base64Decode(encoded);
    } on FormatException {
      return null;
    }
  }

  Future<void> delete(String reference) async {
    if (!isLocal(reference)) return;

    final id = _idOf(reference);
    await _store.remove(_keyPrefix + id);

    final index = _index()..remove(id);
    await _writeIndex(index);
  }

  /// Removes every stored blob. Used when restoring the seed data, so deleted
  /// jobs do not leave their photos and recordings behind.
  Future<void> clear() async {
    for (final id in _index()) {
      await _store.remove(_keyPrefix + id);
    }
    await _writeIndex(const <String>[]);
  }

  /// Drops blobs no longer referenced by any job.
  Future<void> pruneExcept(Set<String> referencesInUse) async {
    final keep = referencesInUse.where(isLocal).map(_idOf).toSet();

    final remaining = <String>[];
    for (final id in _index()) {
      if (keep.contains(id)) {
        remaining.add(id);
      } else {
        await _store.remove(_keyPrefix + id);
      }
    }
    await _writeIndex(remaining);
  }

  String _idOf(String reference) => reference.substring(localPrefix.length);

  List<String> _index() {
    final raw = _store.readString(StoreKeys.mediaIndex);
    if (raw == null || raw.isEmpty) return <String>[];
    return raw.split(',').where((s) => s.isNotEmpty).toList();
  }

  Future<void> _addToIndex(String id) async {
    final index = _index();
    if (index.contains(id)) return;
    index.add(id);
    await _writeIndex(index);
  }

  Future<void> _writeIndex(List<String> index) async {
    await _store.writeString(StoreKeys.mediaIndex, index.join(','));
  }
}
