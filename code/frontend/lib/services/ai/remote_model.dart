import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'ai_model.dart';
import 'ai_safety.dart';

/// A hosted model — the premium option, for later — behind **your own**
/// endpoint.
///
/// Never a vendor's API called directly from the app: that needs the vendor's
/// key, and anything shipped to a browser or a phone is public. The endpoint
/// is a small proxy you run (a Cloudflare Worker, a Supabase Edge Function)
/// that holds the key, limits requests, and forwards an OpenAI-style chat
/// completion with structured output. Most providers speak that shape, or
/// have a gateway that does.
///
/// Off unless the build says otherwise:
///
/// ```
/// flutter build web --dart-define=AI_ENDPOINT=https://ai.example.com/v1 \
///                   --dart-define=AI_MODEL=<the provider's model id> \
///                   --dart-define=AI_MODEL_LABEL='<what people are shown>'
/// ```
///
/// With it set, the app uses this instead of the on-device model. Nothing
/// above [AiModel] changes — that is the point of the interface.
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

  @override
  bool get onDevice => false;

  static const _endpoint = String.fromEnvironment('AI_ENDPOINT');
  static const _model = String.fromEnvironment('AI_MODEL');
  static const _label = String.fromEnvironment('AI_MODEL_LABEL');

  /// The remote model this build was given, or null — the usual case.
  static RemoteModel? fromBuild() {
    if (_endpoint.isEmpty || _model.isEmpty) return null;
    final uri = Uri.tryParse(_endpoint);
    // https only: job text crosses the network on this path.
    if (uri == null || uri.scheme != 'https') return null;
    return RemoteModel(
      endpoint: uri,
      model: _model,
      label: _label.isEmpty ? null : _label,
    );
  }

  @override
  Future<String> complete(AiRequest request) async {
    final http.Response response;
    try {
      response = await _client
          .post(
            endpoint.replace(
              path: '${endpoint.path.replaceAll(RegExp(r'/+$'), '')}'
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
