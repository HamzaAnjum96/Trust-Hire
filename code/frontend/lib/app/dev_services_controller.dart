import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../services/dev_services.dart';
import '../services/local_store.dart';

/// Whether the dev server is there, and what it can do.
///
/// Off unless somebody points the app at one — from Profile, or at build time
/// with `--dart-define=DEV_SERVER=http://localhost:8787`. **The deployed app
/// makes no network call it did not make before** until a person types a URL
/// in, which keeps the POC's "no network calls" rule true for everyone who
/// has not asked for this.
class DevServicesController extends ChangeNotifier {
  DevServicesController(this._store, {http.Client? client})
    : _httpClient = client;

  final LocalStore _store;
  final http.Client? _httpClient;

  /// From the build, so `flutter run --dart-define=DEV_SERVER=…` needs no
  /// typing. A URL saved on the device wins over it.
  static const fromBuild = String.fromEnvironment('DEV_SERVER');

  String _url = '';
  String get url => _url;

  DevServicesClient? _client;

  /// Null when no dev server is set.
  DevServicesClient? get client => _client;

  DevServicesStatus? _status;

  /// What the last check found. Null before one has finished, and after one
  /// failed — see [unreachable].
  DevServicesStatus? get status => _status;

  bool _checking = false;
  bool get checking => _checking;

  bool _unreachable = false;
  bool get unreachable => _unreachable;

  bool get isSet => _client != null;
  bool get paymentsReady => _status?.paymentsEnabled ?? false;
  bool get agentReady => _status?.agentEnabled ?? false;

  void load() {
    final stored = _store.readString(StoreKeys.devServer);
    _use(stored == null || stored.isEmpty ? fromBuild : stored);
    notifyListeners();
    if (isSet) refresh();
  }

  /// Points the app at [value], or at nothing when it is empty. Saved, so the
  /// next launch does not need it typed again.
  Future<void> setUrl(String value) async {
    _use(value);
    notifyListeners();
    await _store.writeString(StoreKeys.devServer, _url);
    if (isSet) await refresh();
  }

  /// An address someone could have meant, or null. A bare `localhost:8787`
  /// is what people type, so it gets a scheme rather than a refusal.
  static Uri? parse(String value) {
    var text = value.trim();
    if (text.isEmpty) return null;
    if (!text.contains('://')) text = 'http://$text';
    final uri = Uri.tryParse(text);
    if (uri == null || uri.host.isEmpty) return null;
    if (uri.scheme != 'http' && uri.scheme != 'https') return null;
    return uri;
  }

  void _use(String value) {
    final uri = parse(value);
    _url = uri?.toString() ?? '';
    _client = uri == null ? null : DevServicesClient(uri, client: _httpClient);
    _status = null;
    _unreachable = false;
    _checking = false;
  }

  /// Asks the server what it has switched on.
  Future<void> refresh() async {
    final client = _client;
    if (client == null) return;

    _checking = true;
    notifyListeners();

    // A URL changed while the check was out makes this answer describe a
    // server nobody is pointed at any more, so it is dropped.
    bool stillCurrent() => identical(client, _client);
    try {
      final status = await client.health();
      if (!stillCurrent()) return;
      _status = status;
      _unreachable = false;
    } on DevServicesException {
      if (!stillCurrent()) return;
      _status = null;
      _unreachable = true;
    } finally {
      if (stillCurrent()) {
        _checking = false;
        notifyListeners();
      }
    }
  }
}
