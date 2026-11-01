import 'ai_model.dart';
import 'browser_engine_base.dart';

/// Off the web there is no WebGPU to run a model on. Android and iOS builds
/// get the deterministic paths — the fare estimate and the word-matching
/// assistant — which is what they had before.
BrowserEngine createBrowserEngine() => const _NoBrowserEngine();

class _NoBrowserEngine implements BrowserEngine {
  const _NoBrowserEngine();

  @override
  Future<BrowserSupport> support() async =>
      const BrowserSupport.unsupported('not-web');

  @override
  Future<bool> isDownloaded(String modelId) async => false;

  @override
  Future<void> load(String modelId, LoadProgress onProgress) =>
      Future.error(const AiFailure('unsupported'));

  @override
  Future<String> complete(AiRequest request) =>
      Future.error(const AiFailure('unsupported'));

  @override
  Future<void> forget(String modelId) async {}
}
