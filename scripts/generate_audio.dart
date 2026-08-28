import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

/// Generates simple, subtle, delightful sound effects in standard 16-bit 44.1kHz WAV format.
void main() async {
  final outDir = Directory('assets/audio');
  if (!outDir.existsSync()) {
    outDir.createSync(recursive: true);
  }

  // 1. Click: subtle tactile button tap (28ms)
  _generateWav('assets/audio/click.wav', _synthesizeClick());

  // 2. Tile Select: cheerful soft marimba pop (75ms)
  _generateWav('assets/audio/tile_select.wav', _synthesizeTileSelect());

  // 3. Tile Drop: pleasant soft snap/plop (60ms)
  _generateWav('assets/audio/tile_drop.wav', _synthesizeTileDrop());

  // 4. Eliminate: crisp soft swoosh/cross-out (75ms)
  _generateWav('assets/audio/eliminate.wav', _synthesizeEliminate());

  // 5. Success: gentle bright 2-note ascending chime (240ms)
  _generateWav('assets/audio/success.wav', _synthesizeSuccess());

  // 6. Wrong: soft friendly wobble (150ms)
  _generateWav('assets/audio/wrong.wav', _synthesizeWrong());

  // 7. Star: soft, lower-pitched warm chime (180ms)
  _generateWav('assets/audio/star.wav', _synthesizeStar());

  // 8. Complete: warm celebratory 3-note mini fanfare (360ms)
  _generateWav('assets/audio/complete.wav', _synthesizeComplete());

  // 9. Countdown Tick: subtle tactile metronome beat for 3, 2, 1 (45ms)
  _generateWav('assets/audio/countdown_tick.wav', _synthesizeCountdownTick());

  // 10. Countdown Go: bright cheerful start chime for GO! (150ms)
  _generateWav('assets/audio/countdown_go.wav', _synthesizeCountdownGo());

  // 11. Quiz Loading: subtle soft bubble/pulse while generating quiz (90ms)
  _generateWav('assets/audio/quiz_loading.wav', _synthesizeQuizLoading());

  print('All sound effect assets successfully generated in assets/audio/');
}

const int sampleRate = 44100;

Uint8List _synthesizeClick() {
  const durationMs = 65;
  final numSamples = (sampleRate * (durationMs / 1000)).toInt();
  final samples = Float64List(numSamples);

  for (int i = 0; i < numSamples; i++) {
    final t = i / sampleRate;
    final env = exp(-t * 75.0);
    final freq = 620.0 - (t * 4500.0).clamp(0.0, 360.0);
    samples[i] = (sin(2 * pi * freq * t) + 0.15 * sin(4 * pi * freq * t)) * env * 0.88;
  }
  return _encodeWav(samples);
}

Uint8List _synthesizeTileSelect() {
  const durationMs = 220;
  final numSamples = (sampleRate * (durationMs / 1000)).toInt();
  final samples = Float64List(numSamples);

  for (int i = 0; i < numSamples; i++) {
    final t = i / sampleRate;
    final attack = (t / 0.003).clamp(0.0, 1.0);
    final decay = exp(-t * 16.0);
    final env = attack * decay;
    // D5 tone (587.33 Hz) with warm wood harmonics (1174.66 Hz & 1762 Hz)
    final wave = sin(2 * pi * 587.33 * t) * 0.70 +
        sin(2 * pi * 1174.66 * t) * 0.22 +
        sin(2 * pi * 1762.00 * t) * 0.08;
    samples[i] = wave * env * 0.90;
  }
  return _encodeWav(samples);
}

Uint8List _synthesizeTileDrop() {
  const durationMs = 150;
  final numSamples = (sampleRate * (durationMs / 1000)).toInt();
  final samples = Float64List(numSamples);

  for (int i = 0; i < numSamples; i++) {
    final t = i / sampleRate;
    final attack = (t / 0.003).clamp(0.0, 1.0);
    final env = attack * exp(-t * 24.0);
    final freq = 480.0 - (t * 1800.0).clamp(0.0, 240.0);
    samples[i] = (sin(2 * pi * freq * t) + 0.18 * sin(2 * pi * freq * 2 * t)) * env * 0.86;
  }
  return _encodeWav(samples);
}

Uint8List _synthesizeEliminate() {
  const durationMs = 260;
  final numSamples = (sampleRate * (durationMs / 1000)).toInt();
  final samples = Float64List(numSamples);
  final rand = Random(42);

  for (int i = 0; i < numSamples; i++) {
    final t = i / sampleRate;
    final attack = (t / 0.008).clamp(0.0, 1.0);
    final env = attack * exp(-t * 14.0);
    final tone = sin(2 * pi * 520.0 * t) * 0.40 + sin(2 * pi * 780.0 * t) * 0.30;
    final noise = (rand.nextDouble() * 2.0 - 1.0) * 0.20;
    samples[i] = (tone + noise) * env * 0.88;
  }
  return _encodeWav(samples);
}

Uint8List _synthesizeSuccess() {
  const durationMs = 750;
  final numSamples = (sampleRate * (durationMs / 1000)).toInt();
  final samples = Float64List(numSamples);

  for (int i = 0; i < numSamples; i++) {
    final t = i / sampleRate;
    double sample = 0.0;

    // Note 1: G5 (784 Hz)
    if (t < 0.45) {
      final t1 = t;
      final env1 = (t1 / 0.004).clamp(0.0, 1.0) * exp(-t1 * 9.0);
      sample += (sin(2 * pi * 783.99 * t1) + 0.22 * sin(2 * pi * 1567.98 * t1)) * env1 * 0.55;
    }

    // Note 2: C6 (1046.5 Hz) - lingering resonant bell tail
    if (t >= 0.09) {
      final t2 = t - 0.09;
      final env2 = (t2 / 0.004).clamp(0.0, 1.0) * exp(-t2 * 5.2);
      sample += (sin(2 * pi * 1046.50 * t2) * 0.75 +
              0.25 * sin(2 * pi * 2093.00 * t2) +
              0.12 * sin(2 * pi * 3139.50 * t2)) *
          env2 *
          0.70;
    }

    samples[i] = sample.clamp(-1.0, 1.0);
  }
  return _encodeWav(samples);
}

Uint8List _synthesizeWrong() {
  const durationMs = 380;
  final numSamples = (sampleRate * (durationMs / 1000)).toInt();
  final samples = Float64List(numSamples);

  for (int i = 0; i < numSamples; i++) {
    final t = i / sampleRate;
    final env = (t / 0.008).clamp(0.0, 1.0) * exp(-t * 9.0);
    final freq = 260.0 - (t / 0.38) * 90.0;
    final wave = sin(2 * pi * freq * t) + 0.2 * sin(4 * pi * freq * t);
    samples[i] = wave * env * 0.85;
  }
  return _encodeWav(samples);
}

Uint8List _synthesizeStar() {
  // Sustained 850ms crystal bell chime ("chinggggg") with lingering natural acoustic ring
  const durationMs = 850;
  final numSamples = (sampleRate * (durationMs / 1000)).toInt();
  final samples = Float64List(numSamples);

  for (int i = 0; i < numSamples; i++) {
    final t = i / sampleRate;
    final attack = (t / 0.006).clamp(0.0, 1.0);
    // Gentle natural acoustic exponential decay (not cut off abruptly)
    final env = attack * exp(-t * 4.6);
    // Warm crystal bell chime: F5 (698.46 Hz) fundamental + harmonious shimmer
    final wave = sin(2 * pi * 698.46 * t) * 0.60 +
        sin(2 * pi * 880.00 * t) * 0.30 +
        sin(2 * pi * 1396.92 * t) * 0.16 +
        sin(2 * pi * 2093.00 * t) * 0.06;
    samples[i] = wave * env * 0.90;
  }
  return _encodeWav(samples);
}

Uint8List _synthesizeComplete() {
  // 1100ms celebratory fanfare with sustained final chord
  const durationMs = 1100;
  final numSamples = (sampleRate * (durationMs / 1000)).toInt();
  final samples = Float64List(numSamples);

  final notes = [
    {'time': 0.0, 'freq': 523.25, 'dur': 0.30, 'decay': 8.0}, // C5
    {'time': 0.10, 'freq': 659.25, 'dur': 0.30, 'decay': 7.0}, // E5
    {'time': 0.20, 'freq': 783.99, 'dur': 0.90, 'decay': 3.8}, // G5 (sustained bell tail)
  ];

  for (int i = 0; i < numSamples; i++) {
    final t = i / sampleRate;
    double sample = 0.0;

    for (final note in notes) {
      final startTime = note['time'] as double;
      final freq = note['freq'] as double;
      final decay = note['decay'] as double;
      if (t >= startTime) {
        final nt = t - startTime;
        final env = (nt / 0.004).clamp(0.0, 1.0) * exp(-nt * decay);
        sample += (sin(2 * pi * freq * nt) + 0.25 * sin(2 * pi * freq * 2 * nt)) * env * 0.55;
      }
    }
    samples[i] = sample.clamp(-1.0, 1.0);
  }
  return _encodeWav(samples);
}

Uint8List _synthesizeCountdownTick() {
  const durationMs = 120;
  final numSamples = (sampleRate * (durationMs / 1000)).toInt();
  final samples = Float64List(numSamples);

  for (int i = 0; i < numSamples; i++) {
    final t = i / sampleRate;
    final env = exp(-t * 32.0);
    // Clear woodblock metronome tick with acoustic resonance
    final wave = sin(2 * pi * 540.0 * t) * 0.75 + sin(2 * pi * 1080.0 * t) * 0.25;
    samples[i] = wave * env * 0.90;
  }
  return _encodeWav(samples);
}

Uint8List _synthesizeCountdownGo() {
  const durationMs = 600;
  final numSamples = (sampleRate * (durationMs / 1000)).toInt();
  final samples = Float64List(numSamples);

  for (int i = 0; i < numSamples; i++) {
    final t = i / sampleRate;
    final attack = (t / 0.004).clamp(0.0, 1.0);
    final env = attack * exp(-t * 5.8);
    // Bright G5 (784 Hz) transitioning into bright ringing C6 (1046.5 Hz)
    final freq = 784.0 + (t / 0.20).clamp(0.0, 1.0) * (1046.5 - 784.0);
    final wave = sin(2 * pi * freq * t) * 0.70 + sin(2 * pi * freq * 2 * t) * 0.25;
    samples[i] = wave * env * 0.92;
  }
  return _encodeWav(samples);
}

Uint8List _synthesizeQuizLoading() {
  const durationMs = 280;
  final numSamples = (sampleRate * (durationMs / 1000)).toInt();
  final samples = Float64List(numSamples);

  for (int i = 0; i < numSamples; i++) {
    final t = i / sampleRate;
    final attack = (t / 0.006).clamp(0.0, 1.0);
    final env = attack * exp(-t * 12.0);
    // Gentle water-drop tone (460Hz -> 640Hz) with natural acoustic ring
    final freq = 460.0 + (t / 0.14).clamp(0.0, 1.0) * 180.0;
    final wave = sin(2 * pi * freq * t) * 0.85 + 0.15 * sin(2 * pi * freq * 2 * t);
    samples[i] = wave * env * 0.82;
  }
  return _encodeWav(samples);
}

Uint8List _encodeWav(Float64List samples) {
  final numSamples = samples.length;
  final byteRate = sampleRate * 2; // 16-bit mono
  final dataSize = numSamples * 2;
  final fileSize = 36 + dataSize;

  final bytes = ByteData(44 + dataSize);

  // RIFF Chunk
  bytes.setUint8(0, 0x52); // 'R'
  bytes.setUint8(1, 0x49); // 'I'
  bytes.setUint8(2, 0x46); // 'F'
  bytes.setUint8(3, 0x46); // 'F'
  bytes.setUint32(4, fileSize, Endian.little);
  bytes.setUint8(8, 0x57); // 'W'
  bytes.setUint8(9, 0x41); // 'A'
  bytes.setUint8(10, 0x56); // 'V'
  bytes.setUint8(11, 0x45); // 'E'

  // fmt Chunk
  bytes.setUint8(12, 0x66); // 'f'
  bytes.setUint8(13, 0x6D); // 'm'
  bytes.setUint8(14, 0x74); // 't'
  bytes.setUint8(15, 0x20); // ' '
  bytes.setUint32(16, 16, Endian.little); // chunk size (16 for PCM)
  bytes.setUint16(20, 1, Endian.little); // audio format (1 = PCM)
  bytes.setUint16(22, 1, Endian.little); // channels (1 = mono)
  bytes.setUint32(24, sampleRate, Endian.little); // sample rate
  bytes.setUint32(28, byteRate, Endian.little); // byte rate
  bytes.setUint16(32, 2, Endian.little); // block align (2 bytes)
  bytes.setUint16(34, 16, Endian.little); // bits per sample (16)

  // data Chunk
  bytes.setUint8(36, 0x64); // 'd'
  bytes.setUint8(37, 0x61); // 'a'
  bytes.setUint8(38, 0x74); // 't'
  bytes.setUint8(39, 0x61); // 'a'
  bytes.setUint32(40, dataSize, Endian.little);

  // PCM Samples with smooth anti-pop cosine fade-out at the end of the buffer
  final fadeSamples = (numSamples * 0.05).toInt().clamp(64, 4410);
  int offset = 44;

  for (int i = 0; i < numSamples; i++) {
    double s = samples[i];
    final samplesLeft = numSamples - 1 - i;
    if (samplesLeft < fadeSamples) {
      final fade = samplesLeft / fadeSamples;
      final window = 0.5 * (1 - cos(pi * fade));
      s *= window;
    }

    final clamped = s.clamp(-1.0, 1.0);
    final pcm = (clamped * 32767.0).toInt();
    bytes.setInt16(offset, pcm, Endian.little);
    offset += 2;
  }

  return bytes.buffer.asUint8List();
}

void _generateWav(String path, Uint8List wavBytes) {
  final file = File(path);
  file.writeAsBytesSync(wavBytes);
}
