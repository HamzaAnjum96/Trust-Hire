/// The one thing the rest of the app knows about a language model.
///
/// **Swappable by design.** Today the model runs in the visitor's own browser
/// ([BrowserModel] — WebLLM on WebGPU, nothing leaves the device). A premium
/// hosted model later is a second implementation of this interface
/// ([RemoteModel]) and a build flag; no feature changes, because no feature
/// ever sees anything but [AiModel].
///
/// **Every model is asked for JSON, never prose to act on.** A request carries
/// the JSON Schema its reply must satisfy. The browser model enforces it while
/// generating (grammar-constrained decoding), a hosted one through its
/// structured-output mode, and [AiAgent] validates it again either way — so
/// nothing a model writes is acted on unless it has the exact shape the app
/// expected.
library;

enum AiRole { system, user, assistant }

class AiMessage {
  const AiMessage(this.role, this.content);

  const AiMessage.system(this.content) : role = AiRole.system;
  const AiMessage.user(this.content) : role = AiRole.user;
  const AiMessage.assistant(this.content) : role = AiRole.assistant;

  final AiRole role;
  final String content;

  Map<String, String> toJson() => {'role': role.name, 'content': content};
}

class AiRequest {
  const AiRequest({
    required this.messages,
    required this.schema,
    this.maxTokens = 320,
    this.temperature = 0.2,
  });

  final List<AiMessage> messages;

  /// The JSON Schema the reply must satisfy.
  final Map<String, Object?> schema;

  final int maxTokens;
  final double temperature;

  Map<String, Object?> toJson() => {
    'messages': [for (final m in messages) m.toJson()],
    'schema': schema,
    'max_tokens': maxTokens,
    'temperature': temperature,
  };
}

/// Why a model could not answer. Features fall back on every one of these —
/// none of them is an error a person needs to see in technical terms.
class AiFailure implements Exception {
  const AiFailure(this.code, [this.detail = '']);

  /// One of: `unsupported` (this device cannot run it), `not_ready` (not
  /// downloaded or not switched on), `timeout`, `bad_reply` (the model said
  /// something that was not the shape asked for), `no_answer` (it never
  /// settled), `failed` (anything else).
  final String code;
  final String detail;

  @override
  String toString() => 'AiFailure($code${detail.isEmpty ? '' : ': $detail'})';
}

/// A language model the app can ask things.
abstract interface class AiModel {
  /// Shown beside everything it says — "Qwen2.5 1.5B, on this device". An
  /// answer is never shown without its author.
  String get name;

  /// True when nothing leaves the device. The screens say which it is.
  bool get onDevice;

  /// One reply, as JSON text matching [AiRequest.schema].
  Future<String> complete(AiRequest request);
}
