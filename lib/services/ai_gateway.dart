import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:algebrix/core/constants/app_constants.dart';

/// Why a proxied AI call could not be completed.
enum AiGatewayFailure {
  /// Nobody is signed in, so there is no token to send.
  noSession,

  /// The learner has spent this hour's allowance.
  rateLimited,

  /// The proxy rejected the request shape.
  badRequest,

  /// The proxy is reachable but no provider answered.
  providerUnavailable,

  /// The network, or something we did not anticipate.
  transport,
}

class AiGatewayException implements Exception {
  const AiGatewayException(this.failure, this.message, {this.resetsAt});

  final AiGatewayFailure failure;
  final String message;

  /// When [failure] is [AiGatewayFailure.rateLimited], when the quota refills.
  final DateTime? resetsAt;

  @override
  String toString() => 'AiGatewayException(${failure.name}): $message';
}

/// One completion returned by the proxy.
class AiCompletion {
  const AiCompletion({required this.text, required this.provider});

  final String text;

  /// Which upstream model answered, e.g. "Groq (openai/gpt-oss-120b)".
  final String provider;
}

/// The app's single door to any AI provider.
///
/// Provider API keys are not in the bundle any more — they live in Supabase
/// Edge Function secrets, and this class talks to that function with the
/// learner's own session token. The function charges a per-user hourly quota
/// before spending anything upstream.
///
/// Callers are expected to treat every failure as "use the offline fallback",
/// which is what both AI services already did when a key was missing.
class AiGateway {
  AiGateway({
    http.Client? client,
    String? endpoint,
    String? Function()? accessTokenReader,
    this.timeout = const Duration(seconds: 25),
  })  : _client = client ?? http.Client(),
        _endpoint = Uri.parse(
          endpoint ?? '${AppConstants.supabaseUrl}/functions/v1/ai-proxy',
        ),
        _accessTokenReader = accessTokenReader ?? _sessionAccessToken;

  final http.Client _client;
  final Uri _endpoint;
  final String? Function() _accessTokenReader;
  final Duration timeout;

  /// Reads the current Supabase session, tolerating an uninitialised client.
  ///
  /// Widget and unit tests construct services without booting Supabase, and
  /// `Supabase.instance` throws in that state rather than returning null.
  static String? _sessionAccessToken() {
    try {
      return Supabase.instance.client.auth.currentSession?.accessToken;
    } catch (_) {
      return null;
    }
  }

  /// Whether a proxied call is worth attempting at all.
  bool get isAvailable => _accessTokenReader() != null;

  /// Sends one completion request.
  ///
  /// [task] must be a task the proxy knows: `quiz` or `tutor`. Throws an
  /// [AiGatewayException] for every failure mode, including a missing session.
  Future<AiCompletion> complete({
    required String task,
    required String systemPrompt,
    required String userPrompt,
    bool jsonMode = true,
  }) async {
    final token = _accessTokenReader();
    if (token == null) {
      throw const AiGatewayException(
        AiGatewayFailure.noSession,
        'No signed-in session, so the AI proxy cannot be called.',
      );
    }

    http.Response response;
    try {
      response = await _client
          .post(
            _endpoint,
            headers: {
              'Authorization': 'Bearer $token',
              'apikey': AppConstants.supabaseAnonKey,
              'Content-Type': 'application/json; charset=utf-8',
            },
            body: jsonEncode({
              'task': task,
              'system': systemPrompt,
              'user': userPrompt,
              'jsonMode': jsonMode,
            }),
          )
          .timeout(timeout);
    } catch (e) {
      throw AiGatewayException(
        AiGatewayFailure.transport,
        'Could not reach the AI proxy: $e',
      );
    }

    if (response.statusCode == 200) {
      final decoded =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final text = decoded['text'];
      if (text is! String || text.isEmpty) {
        throw const AiGatewayException(
          AiGatewayFailure.providerUnavailable,
          'The AI proxy returned an empty completion.',
        );
      }
      return AiCompletion(
        text: text,
        provider: decoded['provider'] as String? ?? 'Algebrix AI',
      );
    }

    throw _errorFor(response);
  }

  AiGatewayException _errorFor(http.Response response) {
    Map<String, dynamic> body;
    try {
      body = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    } catch (_) {
      body = const {};
    }

    final message = body['error'] as String? ??
        'The AI proxy returned status ${response.statusCode}.';

    switch (response.statusCode) {
      case 401:
      case 403:
        return AiGatewayException(AiGatewayFailure.noSession, message);
      case 429:
        return AiGatewayException(
          AiGatewayFailure.rateLimited,
          message,
          resetsAt: DateTime.tryParse(body['resetsAt'] as String? ?? ''),
        );
      case 400:
        debugPrint('AI proxy rejected the request: $message');
        return AiGatewayException(AiGatewayFailure.badRequest, message);
      default:
        return AiGatewayException(AiGatewayFailure.providerUnavailable, message);
    }
  }
}
