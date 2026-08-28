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

    test('All sound triggers execute safely without exceptions in test mode', () {
      expect(() => SoundService.playClick(), returnsNormally);
      expect(() => SoundService.playTileSelect(), returnsNormally);
      expect(() => SoundService.playTileDrop(), returnsNormally);
      expect(() => SoundService.playEliminate(), returnsNormally);
      expect(() => SoundService.playSuccess(), returnsNormally);
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
