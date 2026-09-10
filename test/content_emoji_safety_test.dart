import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Unicode block "Symbols and Pictographs Extended-A" (U+1FA70–U+1FAFF).
///
/// Everything in it landed in Unicode 12.0 or later, and much of it in 14.0
/// and 15.0 (2021–2022). Devices whose system emoji font predates those
/// releases draw a blank box instead — which is exactly what happened to 🩵
/// (U+1FA75, light blue heart) in the PEMDAS lesson and the Pairadise intro.
///
/// The rest of the app's emoji come from Unicode 6.0–12.0 and render
/// everywhere, so this range is the one worth fencing off.
const int _extendedAStart = 0x1FA70;
const int _extendedAEnd = 0x1FAFF;

bool _isTooNew(int rune) => rune >= _extendedAStart && rune <= _extendedAEnd;

String _describe(int rune) =>
    'U+${rune.toRadixString(16).toUpperCase().padLeft(4, '0')} '
    '(${String.fromCharCode(rune)})';

void main() {
  test('app copy avoids emoji too new for common device fonts', () {
    final libDirectory = Directory('lib');
    expect(
      libDirectory.existsSync(),
      isTrue,
      reason: 'run this test from the package root',
    );

    final offenders = <String>[];

    final dartFiles = libDirectory
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));

    for (final file in dartFiles) {
      final lines = const LineSplitter().convert(file.readAsStringSync());

      for (var i = 0; i < lines.length; i++) {
        for (final rune in lines[i].runes) {
          if (_isTooNew(rune)) {
            offenders.add('${file.path}:${i + 1} — ${_describe(rune)}');
          }
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'These characters render as an empty box on devices with an older '
          'emoji font. Swap them for a Unicode 6.0-era equivalent, e.g. 🔵 '
          'instead of 🩵, or 💙 instead of a newer heart.\n'
          '${offenders.join('\n')}',
    );
  });
}
