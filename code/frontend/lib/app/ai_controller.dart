import 'package:flutter/foundation.dart';

import '../services/ai/ai_model.dart';
import '../services/ai/browser_engine.dart';
import '../services/ai/browser_model.dart';
import '../services/ai/remote_model.dart';
import '../services/local_store.dart';

enum AiState {
  /// Working out whether this browser can run a model.
  checking,

  /// It cannot — no WebGPU, or not the web at all. The fare estimate and the
  /// assistant still work; they match words and do arithmetic instead.
  unsupported,

  /// It can, and nobody has switched it on.
  off,

  /// Switched on, but the model is not in memory yet. It starts on first use,
  /// not on every page load — a gigabyte of GPU memory is not something to
  /// take from somebody who only came to check a job.
  idle,

  /// Downloading (the first time) or loading from the browser's cache.
  loading,

  ready,

  /// The last attempt to start failed. Trying again is allowed.
  failed,
}

/// The AI's state, and the one place that decides which model answers.
///
/// **Consent first.** A model is downloaded only after somebody switches the
/// AI on, having been told how big it is — the people this app is for pay for
/// data by the megabyte. Nothing is fetched until then, and the choice is
/// remembered.
///
/// **Which model.** A build given a remote endpoint (see [RemoteModel]) uses
/// that — the premium path, for later. Otherwise it is the on-device model,
/// where the browser can run one. Features ask [ensureReady] and get an
/// [AiModel] or null, and never know which they got.
class AiController extends ChangeNotifier {
  AiController(
    this._store, {
    BrowserEngine? engine,
    AiModel? remote,
    bool remoteFromBuild = true,
  }) : _engine = engine ?? createBrowserEngine(),
       _remote = remote ?? (remoteFromBuild ? RemoteModel.fromBuild() : null);

  final LocalStore _store;
  final BrowserEngine _engine;
  final AiModel? _remote;

  AiState _state = AiState.checking;
  AiState get state => _state;

  bool _enabled = false;
  bool get enabled => _enabled;

  BrowserModelChoice _choice = BrowserModelChoice.standard;
  BrowserModelChoice get choice => _choice;

  BrowserSupport? _support;

  double _progress = 0;

  /// 0 to 1 while [AiState.loading].
  double get progress => _progress;

  bool? _downloaded;

  /// Whether the chosen model's weights are already in this browser — so
  /// switching it on costs no data. Null when not yet known.
  bool? get downloaded => _downloaded;

  String? _failure;
  String? get failure => _failure;

  AiModel? _model;
  Future<AiModel?>? _starting;

  bool get isRemote => _remote != null;

  /// What answers, for the screens: a model's proper name.
  String get modelName => _remote?.name ?? _choice.label;

  /// True when nothing leaves the device.
  bool get onDevice => _remote?.onDevice ?? true;

  /// Can this device use the AI at all, switched on or not?
  bool get available => isRemote || (_support?.ok ?? false);

  /// The model, if it is ready right now. Does not start it — see
  /// [ensureReady].
  AiModel? get readyModel => _state == AiState.ready ? _model : null;

  Future<void> load() async {
    _enabled = _store.readFlag(StoreKeys.aiEnabled);
    _choice = BrowserModelChoice.fromName(_store.readString(StoreKeys.aiModel));

    if (_remote != null) {
      _state = _enabled ? AiState.ready : AiState.off;
      _model = _remote;
      notifyListeners();
      return;
    }

    _state = AiState.checking;
    notifyListeners();

    _support = await _engine.support();
    if (!(_support?.ok ?? false)) {
      _state = AiState.unsupported;
    } else {
      _state = _enabled ? AiState.idle : AiState.off;
      await _checkDownloaded(notify: false);
    }
    notifyListeners();
  }

  Future<void> _checkDownloaded({bool notify = true}) async {
    final support = _support;
    if (support == null || !support.ok) return;
    try {
      _downloaded = await _engine.isDownloaded(_choice.idFor(support));
    } on AiFailure {
      _downloaded = null;
    }
    if (notify) notifyListeners();
  }

  /// The model, started if it is switched on and not yet running — or null
  /// when it is off, unsupported, or failed to start. Never throws: every
  /// caller has something to fall back on.
  Future<AiModel?> ensureReady() {
    if (_remote != null) return Future.value(_enabled ? _remote : null);
    if (!_enabled || !(_support?.ok ?? false)) return Future.value(null);
    if (_state == AiState.ready) return Future.value(_model);
    return _starting ??= _start().whenComplete(() => _starting = null);
  }

  Future<AiModel?> _start() async {
    final support = _support!;
    final choice = _choice;
    _state = AiState.loading;
    _progress = 0;
    _failure = null;
    notifyListeners();

    try {
      await _engine.load(choice.idFor(support), (progress, _) {
        _progress = progress.clamp(0, 1).toDouble();
        notifyListeners();
      });
      // Switched off, or to the other size, while it loaded.
      if (!_enabled || choice != _choice) return null;
      _model = BrowserModel(_engine, choice);
      _downloaded = true;
      _state = AiState.ready;
      return _model;
    } on AiFailure catch (error) {
      _failure = error.code;
      _state = AiState.failed;
      return null;
    } finally {
      notifyListeners();
    }
  }

  /// Switches the AI on — the consent the download needs — and starts it.
  Future<AiModel?> enable() async {
    _enabled = true;
    await _store.writeFlag(StoreKeys.aiEnabled, true);
    if (_remote == null && _state != AiState.unsupported) {
      _state = AiState.idle;
    }
    notifyListeners();
    return ensureReady();
  }

  /// Stops using the AI. The download is kept unless [removeDownload] is
  /// asked for, so switching it back on costs nothing.
  Future<void> disable() async {
    _enabled = false;
    await _store.writeFlag(StoreKeys.aiEnabled, false);
    if (_state != AiState.unsupported) _state = AiState.off;
    _model = _remote;
    notifyListeners();
  }

  /// Deletes the downloaded model from this browser, and switches the AI off.
  Future<void> removeDownload() async {
    final support = _support;
    if (support != null && support.ok) {
      for (final choice in BrowserModelChoice.values) {
        try {
          await _engine.forget(choice.idFor(support));
        } on AiFailure {
          // Already gone, or never there.
        }
      }
    }
    _downloaded = false;
    await disable();
  }

  /// Chooses the other size. A model already running is let go; the new one
  /// starts on next use.
  Future<void> setChoice(BrowserModelChoice choice) async {
    if (choice == _choice) return;
    _choice = choice;
    await _store.writeString(StoreKeys.aiModel, choice.name);
    _model = _remote;
    if (_state == AiState.ready ||
        _state == AiState.loading ||
        _state == AiState.failed) {
      _state = _enabled ? AiState.idle : AiState.off;
    }
    _downloaded = null;
    notifyListeners();
    await _checkDownloaded();
  }
}
