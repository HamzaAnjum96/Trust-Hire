import 'package:flutter/foundation.dart';

import '../services/ai/ai_model.dart';
import '../services/ai/remote_model.dart';
import '../services/local_store.dart';

enum AiState {
  /// This build has no AI (no `AI_ENDPOINT`). The fare estimate and the
  /// assistant still work; they match words and do arithmetic instead.
  unavailable,

  /// It has one, and nobody has switched it on.
  off,

  /// Switched on: questions go to the model.
  on,
}

/// Whether the AI is on, and the one place that decides which model answers.
///
/// **Consent first.** The AI is Trust Hire's Cloudflare Worker, so a question,
/// and the job details it needs, leave the device. Nothing is sent until
/// somebody switches it on, having been told that, and the choice is
/// remembered.
///
/// Since 0.25 there is one model, in the cloud ([RemoteModel]). The model that
/// ran in the browser went with its download, its WebGPU checks and its two
/// sizes; see [AiModel] for why. Features ask [ensureReady] and get an
/// [AiModel] or null.
class AiController extends ChangeNotifier {
  AiController(this._store, {AiModel? model, bool modelFromBuild = true})
    : _model = model ?? (modelFromBuild ? RemoteModel.fromBuild() : null);

  final LocalStore _store;
  final AiModel? _model;

  AiState _state = AiState.unavailable;
  AiState get state => _state;

  bool _enabled = false;
  bool get enabled => _enabled;

  /// Whether this build has an AI at all, switched on or not.
  bool get available => _model != null;

  /// What answers, for the screens: a model's proper name.
  String get modelName => _model?.name ?? '';

  /// What went wrong last time the AI was asked — its code and, where there
  /// is one, what came back. Shown in the profile so a failure can be
  /// reported, not just seen. Cleared by a good answer.
  String? _lastProblem;
  String? get lastProblem => _lastProblem;

  /// Records what went wrong, for [lastProblem] and the browser's console.
  void noteProblem(String code, [String detail = '']) {
    final text = detail.isEmpty ? code : '$code: $detail';
    _lastProblem = text.length > 240 ? '${text.substring(0, 240)}…' : text;
    debugPrint('Trust Hire AI — $_lastProblem');
    notifyListeners();
  }

  /// A good answer: whatever went wrong before no longer describes now.
  void noteAnswered() {
    if (_lastProblem == null) return;
    _lastProblem = null;
    notifyListeners();
  }

  /// The model, if it is switched on right now.
  AiModel? get readyModel => _state == AiState.on ? _model : null;

  Future<void> load() async {
    _enabled = _store.readFlag(StoreKeys.aiEnabled);
    _state = _stateNow();
    notifyListeners();
  }

  AiState _stateNow() => _model == null
      ? AiState.unavailable
      : (_enabled ? AiState.on : AiState.off);

  /// The model when it is switched on, or null. Nothing is sent before
  /// somebody says yes. Never throws: every caller has something to fall
  /// back on.
  Future<AiModel?> ensureReady() =>
      Future.value(!_enabled || _model == null ? null : _model);

  /// Switches the AI on — the consent sending needs.
  Future<AiModel?> enable() async {
    _enabled = true;
    await _store.writeFlag(StoreKeys.aiEnabled, true);
    _state = _stateNow();
    notifyListeners();
    return ensureReady();
  }

  /// Stops using the AI. Nothing more is sent.
  Future<void> disable() async {
    _enabled = false;
    await _store.writeFlag(StoreKeys.aiEnabled, false);
    _state = _stateNow();
    notifyListeners();
  }
}
