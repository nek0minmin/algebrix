import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Regression guard for the app's longest-standing security finding.
///
/// `.env` used to be listed under `flutter: assets:`, which copies it into the
/// APK verbatim — anyone could unzip an installed build and read the Gemini,
/// Groq and NVIDIA keys. The keys now live in Supabase Edge Function secrets
/// and the app reaches them through `ai-proxy`.
///
/// These tests fail the moment something starts walking that back.
void main() {
  final libFiles = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'))
      .toList();

  setUpAll(() {
    expect(libFiles, isNotEmpty, reason: 'run this test from the package root');
  });

  test('pubspec does not bundle an env file as an asset', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();

    for (final line in pubspec.split('\n')) {
      final trimmed = line.trim();
      if (!trimmed.startsWith('- ')) continue;
      expect(
        trimmed.contains('.env'),
        isFalse,
        reason: 'pubspec.yaml bundles "$trimmed" into the build. Secrets must '
            'stay server-side in the ai-proxy Edge Function.',
      );
    }
  });

  test('no dependency reads a bundled env file at runtime', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(
      pubspec.contains('flutter_dotenv'),
      isFalse,
      reason: 'flutter_dotenv only exists to read a bundled .env; the app has '
          'no secrets left to read',
    );

    for (final file in libFiles) {
      expect(
        file.readAsStringSync().contains('flutter_dotenv'),
        isFalse,
        reason: '${file.path} imports flutter_dotenv',
      );
    }
  });

  test('no provider API key is hard-coded in the app', () {
    // Live-key prefixes for the three providers Algebrix uses.
    final keyShapes = <String, RegExp>{
      'Groq': RegExp(r'gsk_[A-Za-z0-9]{20,}'),
      'NVIDIA': RegExp(r'nvapi-[A-Za-z0-9_-]{20,}'),
      'Google': RegExp(r'AIza[A-Za-z0-9_-]{30,}'),
      'OpenAI-style': RegExp(r'sk-[A-Za-z0-9]{32,}'),
    };

    for (final file in libFiles) {
      final source = file.readAsStringSync();
      keyShapes.forEach((provider, shape) {
        expect(
          shape.hasMatch(source),
          isFalse,
          reason: 'a $provider key appears to be hard-coded in ${file.path}',
        );
      });
    }
  });

  test('the app never calls an AI provider directly', () {
    // Every one of these has to be reached through the Edge Function, which is
    // the only place a key exists.
    const providerHosts = [
      'api.groq.com',
      'integrate.api.nvidia.com',
      'generativelanguage.googleapis.com',
      'api.openai.com',
      'api.anthropic.com',
    ];

    for (final file in libFiles) {
      final source = file.readAsStringSync();
      for (final host in providerHosts) {
        expect(
          source.contains(host),
          isFalse,
          reason: '${file.path} reaches $host directly. Route it through '
              'AiGateway so the key stays on the server.',
        );
      }
    }
  });

  test('the proxy function exists and reads its keys from the environment', () {
    final proxy = File('supabase/functions/ai-proxy/index.ts');
    expect(proxy.existsSync(), isTrue,
        reason: 'the ai-proxy Edge Function is where the keys moved to');

    final source = proxy.readAsStringSync();

    for (final key in ['GEMINI_API_KEY', 'GROQ_API_KEY', 'NVIDIA_API_KEY']) {
      expect(
        source.contains("Deno.env.get('$key')"),
        isTrue,
        reason: '$key must come from a deployed secret, never a literal',
      );
    }

    expect(
      source.contains('consume_ai_quota'),
      isTrue,
      reason: 'an authenticated proxy without a quota is still a spendable key',
    );
  });
}
