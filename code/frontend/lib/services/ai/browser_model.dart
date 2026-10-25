import 'ai_model.dart';
import 'browser_engine.dart';

/// Which on-device model to run. Two sizes, because the people this is for
/// have very different phones and very different data plans.
enum BrowserModelChoice {
  /// Better answers; about a gigabyte, once.
  standard(
    label: 'Qwen2.5 1.5B',
    f16Id: 'Qwen2.5-1.5B-Instruct-q4f16_1-MLC',
    f32Id: 'Qwen2.5-1.5B-Instruct-q4f32_1-MLC',
    downloadMb: 1000,
  ),

  /// Plainer answers; about 400 MB, and runs on more devices.
  light(
    label: 'Qwen2.5 0.5B',
    f16Id: 'Qwen2.5-0.5B-Instruct-q4f16_1-MLC',
    f32Id: 'Qwen2.5-0.5B-Instruct-q4f32_1-MLC',
    downloadMb: 400,
  );

  const BrowserModelChoice({
    required this.label,
    required this.f16Id,
    required this.f32Id,
    required this.downloadMb,
  });

  /// A proper name, shown as it is in every language.
  final String label;

  /// The WebLLM build for GPUs with half-precision maths, and the one for
  /// GPUs without — slower and larger, but it runs.
  final String f16Id;
  final String f32Id;

  /// Roughly how much a first download costs, for the consent prompt.
  final int downloadMb;

  String idFor(BrowserSupport support) => support.f16 ? f16Id : f32Id;

  static BrowserModelChoice fromName(String? name) => BrowserModelChoice.values
      .firstWhere((c) => c.name == name, orElse: () => standard);
}

/// A model running in this browser. Nothing it is asked leaves the device.
class BrowserModel implements AiModel {
  BrowserModel(this._engine, this.choice);

  final BrowserEngine _engine;
  final BrowserModelChoice choice;

  /// One question at a time. A browser has one GPU and WebLLM one
  /// conversation; two screens asking at once would talk over each other.
  Future<void> _queue = Future.value();

  @override
  String get name => choice.label;

  @override
  bool get onDevice => true;

  @override
  Future<String> complete(AiRequest request) {
    final reply = _queue.then((_) => _engine.complete(request));
    _queue = reply.then((_) {}, onError: (_) {});
    return reply;
  }
}
