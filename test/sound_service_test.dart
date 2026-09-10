import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:algebrix/services/sound_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({'algebrix_sound_enabled': true});
  });

  group('SoundService Tests', () {
    test('SoundService initializes properly', () async {
      await SoundService.init();
      expect(SoundService.isSoundEnabled, isTrue);
    });

    test('SoundService toggles sound state and preferences', () async {
      await SoundService.setSoundEnabled(false);
      expect(SoundService.isSoundEnabled, isFalse);

      await SoundService.toggleSound();
      expect(SoundService.isSoundEnabled, isTrue);
    });

    test('SoundService clamps the master volume to 0..1', () async {
      await SoundService.setSoundVolume(0.4);
      expect(SoundService.soundVolume, 0.4);

      await SoundService.setSoundVolume(2.5);
      expect(SoundService.soundVolume, SoundService.maxVolume);

      await SoundService.setSoundVolume(-1);
      expect(SoundService.soundVolume, SoundService.minVolume);
    });

    test('nothing is audible when muted or at zero volume', () async {
      await SoundService.setSoundEnabled(true);
      await SoundService.setSoundVolume(0.5);
      expect(SoundService.isAudible, isTrue);

      await SoundService.setSoundVolume(0);
      expect(
        SoundService.isAudible,
        isFalse,
        reason: 'volume 0 is silent even with the toggle on',
      );

      await SoundService.setSoundVolume(0.8);
      await SoundService.setSoundEnabled(false);
      expect(
        SoundService.isAudible,
        isFalse,
        reason: 'the toggle still mutes regardless of volume',
      );

      // Restore for the remaining cases.
      await SoundService.setSoundEnabled(true);
    });

    test('All sound triggers execute safely without exceptions in test mode', () {
      expect(() => SoundService.playClick(), returnsNormally);
      expect(() => SoundService.playTileSelect(), returnsNormally);
      expect(() => SoundService.playTileDrop(), returnsNormally);
      expect(() => SoundService.playEliminate(), returnsNormally);
      expect(() => SoundService.playCorrect(), returnsNormally);
      expect(() => SoundService.playWrong(), returnsNormally);
      expect(() => SoundService.playStar(), returnsNormally);
      expect(() => SoundService.playComplete(), returnsNormally);
      expect(() => SoundService.playCountdownTick(), returnsNormally);
      expect(() => SoundService.playCountdownGo(), returnsNormally);
      expect(() => SoundService.playQuizLoading(), returnsNormally);
      expect(() => SoundService.startQuizLoadingLoop(), returnsNormally);
      expect(() => SoundService.stopQuizLoadingLoop(), returnsNormally);
    });
  });
}
