import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'ai_model.dart';
import 'ai_safety.dart';

/// The app's AI: Trust Hire's Cloudflare Worker, which runs a Workers AI
/// model (`code/backend/ai-worker/`).
///
/// Never a vendor's API called directly from the app: that needs a key, and
/// anything shipped to a browser or a phone is public. The Worker holds no
/// key either. Workers AI is authorised by the account it runs in, and the
/// Worker answers only the site's own origins, fixes the model, caps every
/// request and limits each address to a few a minute.
///
/// The build says where it is:
///
/// ```
/// flutter build web --dart-define=AI_ENDPOINT=https://trust-hire-ai.<you>.workers.dev/v1
/// ```
///
/// The deploy workflow passes the repository variable `AI_ENDPOINT`. A build
/// without it has no AI, and every feature still works: the assistant
/// matches words and the fare panel does arithmetic.
class RemoteModel implements AiModel {
  RemoteModel({
    required this.endpoint,
    required this.model,
    String? label,
    http.Client? client,
    this.timeout = const Duration(seconds: 60),
  }) : name = label ?? model,
       _client = client ?? http.Client();

  final Uri endpoint;
  final String model;
  final Duration timeout;
  final http.Client _client;

  @override
  final String name;

  static const _endpoint = String.fromEnvironment('AI_ENDPOINT');
  static const _model = String.fromEnvironment('AI_MODEL');
  static const _label = String.fromEnvironment('AI_MODEL_LABEL');

  /// What the Worker runs unless a build says otherwise. Shown beside every
  /// answer; the Worker, not this, decides the model actually used.
  static const defaultModel = '@cf/meta/llama-3.1-8b-instruct-fast';
  static const defaultLabel = 'Llama 3.1 8B';

  /// The model this build was given, or null when it has no AI.
  static RemoteModel? fromBuild() {
    if (_endpoint.isEmpty) return null;
    final uri = Uri.tryParse(_endpoint);
    // https only: job text crosses the network on this path.
    if (uri == null || uri.scheme != 'https') return null;
    return RemoteModel(
      endpoint: uri,
      model: _model.isEmpty ? defaultModel : _model,
      label: _label.isEmpty ? (_model.isEmpty ? defaultLabel : null) : _label,
    );
  }

  /// A request has its own time limit, and holds nothing here to let go of.
  @override
  Future<void> cancel() async {}

  @override
  Future<String> complete(AiRequest request) async {
    final http.Response response;
    try {
      response = await _client
          .post(
            endpoint.replace(
              path:
                  '${endpoint.path.replaceAll(RegExp(r'/+$'), '')}'
                  '/chat/completions',
            ),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              'model': model,
              'messages': [for (final m in request.messages) m.toJson()],
              'max_tokens': request.maxTokens,
              'temperature': request.temperature,
              'response_format': {
                'type': 'json_schema',
                'json_schema': {'name': 'reply', 'schema': request.schema},
              },
            }),
          )
          .timeout(timeout);
    } on TimeoutException {
      throw const AiFailure('timeout');
    } catch (error) {
      throw AiFailure('failed', error.toString());
    }

    if (response.statusCode != 200) {
      throw AiFailure('failed', 'HTTP ${response.statusCode}');
    }
    final body = AiSafety.jsonObject(utf8.decode(response.bodyBytes));
    final choices = body?['choices'];
    if (choices is! List || choices.isEmpty) throw const AiFailure('bad_reply');
    final message = (choices.first as Map?)?['message'];
    final content = message is Map ? message['content'] : null;
    if (content is! String) throw const AiFailure('bad_reply');
    return content;
  }
}
