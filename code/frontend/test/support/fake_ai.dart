import 'dart:async';
import 'dart:convert';

import 'package:trust_hire/services/ai/ai_model.dart';

/// A model that answers from a script, in order, and keeps what it was asked.
///
/// Each reply is a JSON-able value (sent as its JSON), a raw [String] (sent
/// as it is — for replies that are not JSON at all), an [AiFailure] (thrown),
/// or a [Future] (returned — one that never completes is a model that hangs).
/// Running out of script is a model that never settles.
class ScriptedModel implements AiModel {
  ScriptedModel(this.replies, {this.name = 'Test model'});

  final List<Object?> replies;
  final requests = <AiRequest>[];
  int _next = 0;

  /// How many times somebody gave up on a reply and said so.
  int cancels = 0;

  @override
  Future<void> cancel() async => cancels++;

  @override
  final String name;

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
