import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// The optional dev server — `code/backend/dev_server/` — from the app's side.
///
/// Two things cannot be done from a client: holding a Stripe secret key, and
/// running a language model. The dev server does both, on the developer's own
/// machine, and nothing else. **The app never depends on it.** With no URL set,
/// or with the server switched off, the wallet tops up the way it always has
/// and the fare suggestion comes from the device; every caller here handles
/// [DevServicesException] by falling back rather than by failing.
class DevServicesClient {
  DevServicesClient(this.baseUrl, {http.Client? client})
    : _client = client ?? http.Client();

  final Uri baseUrl;
  final http.Client _client;

  /// Long enough for a small model on a laptop CPU to make three or four
  /// tool calls; a dev server that takes longer has stopped.
  static const adviceTimeout = Duration(minutes: 3);
  static const quickTimeout = Duration(seconds: 5);
  static const paymentTimeout = Duration(seconds: 30);

  Uri _at(String path) => baseUrl.replace(
    path: '${baseUrl.path.replaceAll(RegExp(r'/+$'), '')}$path',
  );

  Future<Map<String, dynamic>> _send(
    Future<http.Response> request,
    Duration timeout,
  ) async {
    final http.Response response;
    try {
      response = await request.timeout(timeout);
    } on TimeoutException {
      throw const DevServicesException('timeout');
    } catch (_) {
      // A refused connection, a CORS refusal in a browser, no network — all
      // the same to the person looking at the screen.
      throw const DevServicesException('unreachable');
    }

    final Object? body;
    try {
      body = jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      throw const DevServicesException('bad_response');
    }
    if (body is! Map<String, dynamic>) {
      throw const DevServicesException('bad_response');
    }
    if (response.statusCode != 200) {
      throw DevServicesException(body['error'] as String? ?? 'refused');
    }
    return body;
  }

  Future<Map<String, dynamic>> _get(String path, Duration timeout) =>
      _send(_client.get(_at(path)), timeout);

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body,
    Duration timeout,
  ) => _send(
    _client.post(
      _at(path),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    ),
    timeout,
  );

  Future<DevServicesStatus> health() async =>
      DevServicesStatus.fromJson(await _get('/health', quickTimeout));

  /// Opens a Stripe Checkout Session for [tokens] rupees of tokens.
  Future<CheckoutSession> startCheckout({
    required int tokens,
    required String account,
  }) async {
    final json = await _post('/payments/checkout', {
      'tokens': tokens,
      'account': account,
    }, paymentTimeout);
    final id = json['id'];
    final url = json['url'];
    if (id is! String || url is! String) {
      throw const DevServicesException('bad_response');
    }
    return CheckoutSession(id: id, url: Uri.parse(url));
  }

  Future<CheckoutStatus> checkoutStatus(String id) async =>
      CheckoutStatus.fromJson(
        await _get('/payments/checkout/$id', paymentTimeout),
      );

  /// Asks the fare agent. The answer is a proposal: the caller holds it to
  /// the evidence before showing it — see `FareGuard`.
  Future<Map<String, dynamic>> fareAdvice(Map<String, dynamic> request) =>
      _post('/fares/advice', request, adviceTimeout);
}

/// Why the dev server could not help. [code] is the server's own, or one of
/// `unreachable`, `timeout` and `bad_response` from this side.
class DevServicesException implements Exception {
  const DevServicesException(this.code);

  final String code;

  @override
  String toString() => 'DevServicesException($code)';
}

/// What `/health` reported.
class DevServicesStatus {
  const DevServicesStatus({
    required this.paymentsEnabled,
    required this.agentEnabled,
    this.paymentsProblem,
    this.model,
    this.modelReachable = false,
  });

  final bool paymentsEnabled;
  final String? paymentsProblem;

  final bool agentEnabled;
  final String? model;

  /// The model server answered, whether or not it has [model].
  final bool modelReachable;

  factory DevServicesStatus.fromJson(Map<String, dynamic> json) {
    final payments = json['payments'] as Map<String, dynamic>? ?? const {};
    final agent = json['fareAgent'] as Map<String, dynamic>? ?? const {};
    return DevServicesStatus(
      paymentsEnabled: payments['enabled'] == true,
      paymentsProblem: payments['problem'] as String?,
      agentEnabled: agent['enabled'] == true,
      model: agent['model'] as String?,
      modelReachable: agent['reachable'] == true,
    );
  }
}

class CheckoutSession {
  const CheckoutSession({required this.id, required this.url});

  final String id;
  final Uri url;
}

/// Whether a Checkout Session has been paid — as Stripe says, read through
/// the dev server with the secret key. [tokens] is what Stripe recorded on the
/// session and actually charged for, never the number the app asked for.
class CheckoutStatus {
  const CheckoutStatus({
    required this.id,
    required this.paid,
    required this.tokens,
    this.account,
    this.expired = false,
    this.problem,
  });

  final String id;
  final bool paid;
  final int tokens;
  final String? account;
  final bool expired;
  final String? problem;

  factory CheckoutStatus.fromJson(Map<String, dynamic> json) => CheckoutStatus(
    id: json['id'] as String? ?? '',
    paid: json['paid'] == true,
    tokens: (json['tokens'] as num?)?.round() ?? 0,
    account: json['account'] as String?,
    expired: json['status'] == 'expired',
    problem: json['problem'] as String?,
  );
}
