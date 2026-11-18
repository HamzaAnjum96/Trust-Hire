/// The one thing the rest of the app knows about a language model.
///
/// **One model, in the cloud, since 0.25.** The app asks Trust Hire's own
/// Cloudflare Worker (`code/backend/ai-worker/`), which runs a Workers AI
/// model; [RemoteModel] is the client. Until 0.25 a small model ran in the
/// visitor's browser through WebLLM, which needed WebGPU (most phones have
/// none) and a download of hundreds of megabytes; it read little Urdu. No
/// feature changed when it went, because no feature ever sees anything but
/// [AiModel].
///
/// **Every model is asked for JSON, never prose to act on.** A request carries
/// the JSON Schema its reply must satisfy; Workers AI holds the model to it
/// (JSON mode), and [AiAgent] validates it again — so nothing a model writes
/// is acted on unless it has the exact shape the app expected.
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

  /// One of: `not_ready` (switched off, or this build has no AI), `timeout`,
  /// `bad_reply` (the model said something that was not the shape asked for),
  /// `no_answer` (it never settled), `failed` (anything else, an HTTP error
  /// included).
  final String code;
  final String detail;

  @override
  String toString() => 'AiFailure($code${detail.isEmpty ? '' : ': $detail'})';
}

/// A language model the app can ask things.
abstract interface class AiModel {
  /// Shown beside everything it says — "Llama 3.1 8B". An answer is never
  /// shown without its author.
  String get name;

  /// One reply, as JSON text matching [AiRequest.schema].
  Future<String> complete(AiRequest request);

  /// Stops a reply nobody is waiting for any more. Called when an agent gives
  /// up on its time limit.
  Future<void> cancel();
}
