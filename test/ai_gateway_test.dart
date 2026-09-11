import 'dart:convert';

import 'package:algebrix/services/ai_gateway.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _endpoint = 'https://example.supabase.co/functions/v1/ai-proxy';

AiGateway _gateway(MockClient client, {String? token = 'test-access-token'}) {
  return AiGateway(
    client: client,
    endpoint: _endpoint,
    accessTokenReader: () => token,
  );
}

Future<AiGatewayException> _failureFrom(AiGateway gateway) async {
  try {
    await gateway.complete(
      task: 'quiz',
      systemPrompt: 'system',
      userPrompt: 'user',
    );
  } on AiGatewayException catch (e) {
    return e;
  }
  fail('expected the gateway to throw');
}

void main() {
  group('AiGateway', () {
    test('sends the task, prompts and session token to the proxy', () async {
      late http.Request seen;
      final client = MockClient((request) async {
        seen = request;
        return http.Response.bytes(
          utf8.encode(jsonEncode({'text': 'hello', 'provider': 'Groq (test)'})),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final result = await _gateway(client).complete(
        task: 'quiz',
        systemPrompt: 'You are Xy.',
        userPrompt: 'Make a quiz.',
      );

      expect(result.text, 'hello');
      expect(result.provider, 'Groq (test)');

      expect(seen.method, 'POST');
      expect(seen.url.toString(), _endpoint);
      expect(seen.headers['Authorization'], 'Bearer test-access-token');

      final body = jsonDecode(seen.body) as Map<String, dynamic>;
      expect(body['task'], 'quiz');
      expect(body['system'], 'You are Xy.');
      expect(body['user'], 'Make a quiz.');
      expect(body['jsonMode'], isTrue);
    });

    test('carries no provider API key of its own', () async {
      late http.Request seen;
      final client = MockClient((request) async {
        seen = request;
        return http.Response.bytes(
          utf8.encode(jsonEncode({'text': 'ok', 'provider': 'p'})),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      await _gateway(client).complete(
        task: 'tutor',
        systemPrompt: 's',
        userPrompt: 'u',
      );

      // The only credential that may leave the device is the learner's own
      // Supabase session, plus the public anon key. A provider key here would
      // mean the bundle is leaking again.
      final headerBlob = seen.headers.entries
          .map((e) => '${e.key}: ${e.value}')
          .join('\n')
          .toLowerCase();

      expect(headerBlob, isNot(contains('gsk_')), reason: 'Groq key prefix');
      expect(headerBlob, isNot(contains('nvapi-')), reason: 'NVIDIA key prefix');
      expect(headerBlob, isNot(contains('aiza')), reason: 'Google key prefix');
      expect(seen.url.queryParameters, isEmpty,
          reason: 'no key may be smuggled in the query string');
    });

    test('refuses to call out when there is no session', () async {
      var called = false;
      final client = MockClient((request) async {
        called = true;
        return http.Response('{}', 200);
      });

      final gateway = _gateway(client, token: null);
      expect(gateway.isAvailable, isFalse);

      final failure = await _failureFrom(gateway);
      expect(failure.failure, AiGatewayFailure.noSession);
      expect(called, isFalse);
    });

    test('maps 429 to rateLimited and keeps the reset time', () async {
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'error': 'Quota spent.',
            'code': 'rate_limited',
            'resetsAt': '2026-09-12T10:00:00.000Z',
          }),
          429,
        );
      });

      final failure = await _failureFrom(_gateway(client));

      expect(failure.failure, AiGatewayFailure.rateLimited);
      expect(failure.message, 'Quota spent.');
      expect(failure.resetsAt, DateTime.utc(2026, 9, 12, 10));
    });

    test('maps 401 to noSession and 502 to providerUnavailable', () async {
      final unauthorized = MockClient(
        (request) async => http.Response(jsonEncode({'error': 'nope'}), 401),
      );
      final downstream = MockClient(
        (request) async => http.Response(jsonEncode({'error': 'no provider'}), 502),
      );

      expect(
        (await _failureFrom(_gateway(unauthorized))).failure,
        AiGatewayFailure.noSession,
      );
      expect(
        (await _failureFrom(_gateway(downstream))).failure,
        AiGatewayFailure.providerUnavailable,
      );
    });

    test('treats an empty completion as a provider failure', () async {
      final client = MockClient((request) async {
        return http.Response.bytes(
          utf8.encode(jsonEncode({'text': '', 'provider': 'Groq'})),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final failure = await _failureFrom(_gateway(client));
      expect(failure.failure, AiGatewayFailure.providerUnavailable);
    });

    test('turns a transport error into a typed failure', () async {
      final client = MockClient((request) async {
        throw http.ClientException('connection closed');
      });

      final failure = await _failureFrom(_gateway(client));
      expect(failure.failure, AiGatewayFailure.transport);
    });
  });
}
