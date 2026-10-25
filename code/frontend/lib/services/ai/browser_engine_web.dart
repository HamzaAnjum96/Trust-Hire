import 'dart:convert';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

import 'ai_model.dart';
import 'browser_engine_base.dart';

BrowserEngine createBrowserEngine() => _WebBrowserEngine();

/// `web/ai/bridge.js`, as Dart sees it. Strings and booleans only.
extension type _Bridge._(JSObject _) implements JSObject {
  external JSPromise<JSString> support();
  external JSPromise<JSBoolean> cached(JSString model);
  external JSPromise<JSAny?> load(JSString model, JSFunction onProgress);
  external JSPromise<JSString> complete(JSString request);
  external JSPromise<JSAny?> forget(JSString model);
}

class _WebBrowserEngine implements BrowserEngine {
  Future<_Bridge>? _bridge;

  /// The bridge, imported on first use. Resolved against the page's base so
  /// it is found under `/Trust-Hire/` on GitHub Pages and at `/` locally.
  Future<_Bridge> _get() => _bridge ??= () async {
    final url = Uri.parse(web.document.baseURI).resolve('ai/bridge.js');
    final module = await importModule(url.toString().toJS).toDart;
    return module as _Bridge;
  }();

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on AiFailure {
      rethrow;
    } catch (error) {
      // A JS exception: out of GPU memory, a lost device, a failed fetch.
      throw AiFailure('failed', error.toString());
    }
  }

  @override
  Future<BrowserSupport> support() async {
    try {
      final bridge = await _get();
      final json =
          jsonDecode((await bridge.support().toDart).toDart)
              as Map<String, dynamic>;
      return json['ok'] == true
          ? BrowserSupport.supported(f16: json['f16'] == true)
          : BrowserSupport.unsupported(json['reason'] as String? ?? 'error');
    } catch (_) {
      return const BrowserSupport.unsupported('error');
    }
  }

  @override
  Future<bool> isDownloaded(String modelId) => _guard(() async {
    final bridge = await _get();
    return (await bridge.cached(modelId.toJS).toDart).toDart;
  });

  @override
  Future<void> load(String modelId, LoadProgress onProgress) =>
      _guard(() async {
        final bridge = await _get();
        await bridge
            .load(
              modelId.toJS,
              ((JSNumber progress, JSString text) =>
                      onProgress(progress.toDartDouble, text.toDart))
                  .toJS,
            )
            .toDart;
      });

  @override
  Future<String> complete(AiRequest request) => _guard(() async {
    final bridge = await _get();
    return (await bridge.complete(jsonEncode(request.toJson()).toJS).toDart)
        .toDart;
  });

  @override
  Future<void> forget(String modelId) => _guard(() async {
    final bridge = await _get();
    await bridge.forget(modelId.toJS).toDart;
  });
}
