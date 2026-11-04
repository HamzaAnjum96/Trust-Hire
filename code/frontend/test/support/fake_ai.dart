import 'dart:async';
import 'dart:convert';

import 'package:trust_hire/services/ai/ai_model.dart';
import 'package:trust_hire/services/ai/browser_engine.dart';

/// A model that answers from a script, in order, and keeps what it was asked.
///
/// Each reply is a JSON-able value (sent as its JSON), a raw [String] (sent
/// as it is — for replies that are not JSON at all), an [AiFailure] (thrown),
/// or a [Future] (returned — one that never completes is a model that hangs).
/// Running out of script is a model that never settles.
class ScriptedModel implements AiModel {
  ScriptedModel(this.replies, {this.name = 'Test model', this.onDevice = true});

  final List<Object?> replies;
  final requests = <AiRequest>[];
  int _next = 0;

  /// How many times somebody gave up on a reply and said so.
  int cancels = 0;

  @override
  Future<void> cancel() async => cancels++;

  @override
  final String name;

  @override
  final bool onDevice;

  /// Everything the model was sent, as one string — for asserting what it
  /// saw, and what it never did.
  String get transcript => [
    for (final request in requests)
      for (final message in request.messages) message.content,
  ].join('\n');

  @override
  Future<String> complete(AiRequest request) async {
    requests.add(request);
    if (_next >= replies.length) throw const AiFailure('no_answer');
    final reply = replies[_next++];
    if (reply is AiFailure) throw reply;
    if (reply is Future<String>) return reply;
    if (reply is String) return reply;
    return jsonEncode(reply);
  }
}

/// The browser's model runtime, without a browser.
class FakeBrowserEngine implements BrowserEngine {
  FakeBrowserEngine({
    this.supported = const BrowserSupport.supported(f16: true),
    this.cached = false,
    this.loadFailure,
    this.reply = '{}',
    this.hangs = false,
  });

  final BrowserSupport supported;
  bool cached;
  AiFailure? loadFailure;
  String reply;

  /// Every reply is written forever — until [interrupt], as WebLLM's is,
  /// which then hands back what it had.
  bool hangs;

  final loads = <String>[];
  final forgets = <String>[];
  final completes = <AiRequest>[];
  int interrupts = 0;
  Completer<String>? _writing;

  @override
  Future<BrowserSupport> support() async => supported;

  @override
  Future<bool> isDownloaded(String modelId) async => cached;

  @override
  Future<void> load(String modelId, LoadProgress onProgress) async {
    loads.add(modelId);
    onProgress(0.5, 'half');
    if (loadFailure != null) throw loadFailure!;
    onProgress(1, 'done');
    cached = true;
  }

  @override
  Future<String> complete(AiRequest request) {
    completes.add(request);
    if (!hangs) return Future.value(reply);
    return (_writing = Completer<String>()).future;
  }

  @override
  Future<void> interrupt() async {
    interrupts++;
    final writing = _writing;
    _writing = null;
    if (writing != null && !writing.isCompleted) writing.complete('{');
  }

  @override
  Future<void> forget(String modelId) async {
    forgets.add(modelId);
    cached = false;
  }
}
