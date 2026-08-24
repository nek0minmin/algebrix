import 'dart:convert';
import 'package:algebrix/services/ai_tutor_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  setUp(() async {
    await dotenv.load(
      mergeWith: {
        'GROQ_API_KEY': 'test_groq_key',
        'NVIDIA_NIM_API_KEY': 'test_nvidia_key',
      },
    );
  });

  group('AiTutorService tests', () {
    test('checkWorkedExample returns parsed json result from Groq API', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.host, 'api.groq.com');
        final body = jsonEncode({
          'choices': [
            {
              'message': {
                'content': jsonEncode({
                  'isCorrect': true,
                  'title': '🐙 Looks good!',
                  'message': 'You correctly subtracted 5 and divided by 2.',
                  'whyItWorks': 'Inverse operations isolate X.',
                  'keyConcept': 'Subtraction property of equality',
                }),
              },
            }
          ],
        });
        return http.Response.bytes(
          utf8.encode(body),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final service = AiTutorService(client: mockClient);
      final result = await service.checkWorkedExample(
        problem: '2x + 5 = 15',
        solution: '2x = 10 -> x = 5',
      );

      expect(result.isCorrect, isTrue);
      expect(result.title, contains('Looks good!'));
      expect(result.whyItWorks, contains('Inverse operations isolate X.'));
      expect(result.providerUsed, contains('Groq'));
    });

    test('falls back to NVIDIA NIM when Groq API returns non-200 status', () async {
      final mockClient = MockClient((request) async {
        if (request.url.host == 'api.groq.com') {
          return http.Response('Rate limit exceeded', 429);
        }
        expect(request.url.host, 'integrate.api.nvidia.com');
        final body = jsonEncode({
          'choices': [
            {
              'message': {
                'content': jsonEncode({
                  'isCorrect': false,
                  'title': "Let's look at what happened!",
                  'message': 'You tried to divide first before undoing +4.',
                  'keyConcept': 'Undo addition first',
                  'promptForStudent': '💡 What did you learn?',
                }),
              },
            }
          ],
        });
        return http.Response.bytes(
          utf8.encode(body),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final service = AiTutorService(client: mockClient);
      final result = await service.diagnoseMistake(
        problem: '3x + 4 = 16',
        incorrectAnswer: 'x = 16 / 3',
      );

      expect(result.isCorrect, isFalse);
      expect(result.title, contains('what happened'));
      expect(result.providerUsed, 'NVIDIA NIM');
    });

    test('returns friendly offline fallback when both APIs fail', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Server error', 500);
      });

      final service = AiTutorService(client: mockClient);
      final result = await service.getSocraticHint(question: 'Why subtract 5?');

      expect(result.title, contains('Learning Nudge'));
      expect(result.providerUsed, 'Offline Knowledge');
    });
  });
}
