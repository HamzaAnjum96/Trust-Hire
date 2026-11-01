import 'ai_model.dart';

/// Whether this browser can run a model, and how.
class BrowserSupport {
  const BrowserSupport.supported({required this.f16})
    : ok = true,
      reason = null;
  const BrowserSupport.unsupported(this.reason) : ok = false, f16 = false;

  final bool ok;

  /// The GPU can do half-precision maths, so the smaller, faster builds of a
  /// model will run. Many phones and older laptops cannot.
  final bool f16;

  /// Why not, when [ok] is false: `not-web`, `no-webgpu`, `no-adapter`,
  /// `error`.
  final String? reason;
}

typedef LoadProgress = void Function(double progress, String text);

/// The browser's model runtime — WebLLM on WebGPU — as the app sees it.
///
/// An interface so the controller above it can be tested without a browser,
/// and so the web half (which imports `dart:js_interop`) never reaches an
/// Android or iOS build.
abstract interface class BrowserEngine {
  Future<BrowserSupport> support();
  Future<bool> isDownloaded(String modelId);
  Future<void> load(String modelId, LoadProgress onProgress);
  Future<String> complete(AiRequest request);
  Future<void> forget(String modelId);
}
