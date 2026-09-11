import 'dart:convert';
import 'package:algebrix/services/ai_gateway.dart';
import 'package:algebrix/services/ai_tutor_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _endpoint = 'https://example.supabase.co/functions/v1/ai-proxy';

/// A gateway wired to a stub transport with a pretend signed-in session.
///
/// The provider chain now runs inside the Edge Function, so from Dart's side
/// there is exactly one host to mock — and that is the point of the change.
AiGateway _gateway(MockClient client, {String? token = 'test-access-token'}) {
  return AiGateway(
    client: client,
    endpoint: _endpoint,
    accessTokenReader: () => token,
  );
}

http.Response _proxyResponse(Object content, {String provider = 'Groq (test)'}) {
  return http.Response.bytes(
    utf8.encode(jsonEncode({
      'text': content is String ? content : jsonEncode(content),
      'provider': provider,
    })),
    200,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );
}

void main() {
  group('AiTutorService tests', () {
    test('checkWorkedExample returns parsed json result from the proxy',
        () async {
      final mockClient = MockClient((request) async {
        expect(request.url.toString(), _endpoint);
        expect(request.headers['Authorization'], 'Bearer test-access-token');

        final sent = jsonDecode(request.body) as Map<String, dynamic>;
        expect(sent['task'], 'tutor');
        expect(sent['system'], contains('Xy'));
        expect(sent['user'], contains('2x + 5 = 15'));

        return _proxyResponse({
          'isCorrect': true,
          'title': '🐙 Looks good!',
          'message': 'You correctly subtracted 5 and divided by 2.',
          'whyItWorks': 'Inverse operations isolate X.',
          'keyConcept': 'Subtraction property of equality',
        });
      });

      final service = AiTutorService(gateway: _gateway(mockClient));
      final result = await service.checkWorkedExample(
        problem: '2x + 5 = 15',
        solution: '2x = 10 -> x = 5',
      );

      expect(result.isCorrect, isTrue);
      expect(result.title, contains('Looks good!'));
      expect(result.whyItWorks, contains('Inverse operations isolate X.'));
      expect(result.providerUsed, 'Groq (test)');
    });

    test('reports whichever provider the proxy actually used', () async {
      final mockClient = MockClient((request) async {
        return _proxyResponse(
          {
            'isCorrect': false,
            'title': "Let's look at what happened!",
            'message': 'You tried to divide first before undoing +4.',
            'keyConcept': 'Undo addition first',
          },
          provider: 'NVIDIA NIM (meta/llama-3.3-70b-instruct)',
        );
      });

      final service = AiTutorService(gateway: _gateway(mockClient));
      final result = await service.diagnoseMistake(
        problem: '3x + 4 = 16',
        incorrectAnswer: 'x = 16 / 3',
      );

      expect(result.isCorrect, isFalse);
      expect(result.title, contains('what happened'));
      expect(result.providerUsed, startsWith('NVIDIA NIM'));
    });

    test('falls back offline when the proxy has no provider left', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({'error': 'No AI provider answered.', 'code': 'providers_unavailable'}),
          502,
        );
      });

      final service = AiTutorService(gateway: _gateway(mockClient));
      final result = await service.getSocraticHint(question: 'Why subtract 5?');

      expect(result.title, contains('Learning Nudge'));
      expect(result.providerUsed, 'Offline Knowledge');
    });

    test('falls back offline when the hourly quota is spent', () async {
      var calls = 0;
      final mockClient = MockClient((request) async {
        calls++;
        return http.Response(
          jsonEncode({
            'error': 'You have used this hour\'s AI requests.',
            'code': 'rate_limited',
            'resetsAt': '2026-09-12T10:00:00Z',
          }),
          429,
        );
      });

      final service = AiTutorService(gateway: _gateway(mockClient));
      final result = await service.getSocraticHint(question: 'Why subtract 5?');

      expect(calls, 1, reason: 'a refused call must not be retried in a loop');
      expect(result.providerUsed, 'Offline Knowledge');
    });

    test('never calls the proxy when nobody is signed in', () async {
      var called = false;
      final mockClient = MockClient((request) async {
        called = true;
        return _proxyResponse({'title': 'should not happen'});
      });

      final service = AiTutorService(
        gateway: _gateway(mockClient, token: null),
      );
      final result = await service.getSocraticHint(question: 'Why subtract 5?');

      expect(called, isFalse);
      expect(result.providerUsed, 'Offline Knowledge');
    });

    test('improveUnderstanding returns polished text from the proxy', () async {
      final mockClient = MockClient((request) async {
        final sent = jsonDecode(request.body) as Map<String, dynamic>;
        expect(sent['jsonMode'], isFalse,
            reason: 'note polishing wants prose, not JSON');
        return _proxyResponse(
          '```markdown\nWhat I learned:\n• **2x = 10** means **x = 5**.\n```',
        );
      });

      final service = AiTutorService(gateway: _gateway(mockClient));
      final polished = await service.improveUnderstanding(rawNote: 'x is 5 i think');

      expect(polished, startsWith('What I learned:'));
      expect(polished, isNot(contains('```')));
    });

    test('isOffTopicText correctly identifies math notes vs off-topic content', () {
      final service = AiTutorService();

      // Math worked examples with mistakes should NOT be off-topic
      expect(service.isOffTopicText('Problem: 3x + 4 = 16\nMy answer:\nx = 16'), isFalse);
      expect(service.isOffTopicText('2x + 5 = 15 -> 2x = 20 -> x = 10'), isFalse);

      // Verbal algebra reflections should NOT be off-topic
      expect(service.isOffTopicText('To isolate the variable, perform inverse operations on both sides'), isFalse);
      expect(service.isOffTopicText('Commutative property states that the order of addition does not matter'), isFalse);
      expect(service.isOffTopicText('Like terms share the exact same variable part'), isFalse);

      // True off-topic notes SHOULD be detected as off-topic
      expect(service.isOffTopicText('like\nI like watermelons and strawberries'), isTrue);
      expect(service.isOffTopicText('like\nI hate watermelons and strawberries'), isTrue);
      expect(service.isOffTopicText('My delicious lumpia recipe with ground pork and wrappers'), isTrue);
      expect(service.isOffTopicText('How to bake chocolate chip cookies in the oven with sugar and flour'), isTrue);
    });
  });
}
