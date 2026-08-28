import 'dart:async';
import 'dart:io' show Platform;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Centralized, test-safe, rock-solid audio service for Algebrix.
///
/// Features an 8-player round-robin concurrency pool to guarantee rapid successive
/// sound playback across games, quizzes, lessons, and notes.
class SoundService {
  static const String _prefSoundEnabledKey = 'algebrix_sound_enabled';

  static bool _isSoundEnabled = true;
  static bool _isInitialized = false;

  // Pool of AudioPlayers for concurrent playback
  static final List<AudioPlayer> _playerPool =
      List.generate(8, (_) => AudioPlayer());
  static int _poolIndex = 0;

  static Timer? _loadingLoopTimer;

  /// Whether sound effects are currently enabled.
  static bool get isSoundEnabled => _isSoundEnabled;

  static bool get _isTesting {
    if (kIsWeb) return false;
    return Platform.environment.containsKey('FLUTTER_TEST');
  }

  /// Initialize sound settings from [SharedPreferences] and configure player pool
  static Future<void> init() async {
    if (_isInitialized) return;
    try {
      if (!_isTesting) {
        final prefs = await SharedPreferences.getInstance();
        _isSoundEnabled = prefs.getBool(_prefSoundEnabledKey) ?? true;

        for (final player in _playerPool) {
          try {
            await player.setReleaseMode(ReleaseMode.stop);
          } catch (_) {}
        }
      }
      _isInitialized = true;
    } catch (e) {
      debugPrint('SoundService.init error: $e');
    }
  }

  /// Toggle sound on/off and persist preference
  static Future<void> setSoundEnabled(bool enabled) async {
    _isSoundEnabled = enabled;
    if (!enabled) {
      stopQuizLoadingLoop();
    }
    try {
      if (!_isTesting) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_prefSoundEnabledKey, enabled);
      }
    } catch (e) {
      debugPrint('SoundService.setSoundEnabled error: $e');
    }
  }

  /// Toggle current sound state
  static Future<void> toggleSound() async {
    await setSoundEnabled(!_isSoundEnabled);
  }

  // ===========================================================================
  // Sound Effect Triggers
  // ===========================================================================

  /// Subtle wooden/tactile click for button presses.
  static void playClick({double volume = 0.90}) {
    _play('audio/click.wav', volume: volume);
  }

  /// Cheerful marimba pop when tapping or selecting a math stone/tile/option.
  static void playTileSelect({double volume = 0.95}) {
    _play('audio/tile_select.wav', volume: volume);
  }

  /// Snappy soft snap when dropping or placing a tile into a slot/pan.
  static void playTileDrop({double volume = 0.90}) {
    _play('audio/tile_drop.wav', volume: volume);
  }

  /// Crisp soft swoosh/cross-out when eliminating a candidate pair.
  static void playEliminate({double volume = 0.95}) {
    _play('audio/eliminate.wav', volume: volume);
  }

  /// Sweet, bright ascending chime when an equation balances, clue passes, or answer is correct.
  static void playSuccess({double volume = 0.95}) {
    _play('audio/success.wav', volume: volume);
  }

  /// Crisp, audible swoosh/cross-out when an answer or verification is wrong (uses elimination sound).
  static void playWrong({double volume = 0.95}) {
    _play('audio/eliminate.wav', volume: volume);
  }

  /// Soft, lower-pitched warm star chime when stars animate in on victory screens.
  static void playStar({double volume = 0.95}) {
    _play('audio/star.wav', volume: volume);
  }

  /// Warm celebratory 3-note mini fanfare on module/quiz finish.
  static void playComplete({double volume = 1.0}) {
    _play('audio/complete.wav', volume: volume);
  }

  /// Crisp woodblock metronome tick for 3, 2, 1 quiz countdown.
  static void playCountdownTick({double volume = 0.90}) {
    _play('audio/countdown_tick.wav', volume: volume);
  }

  /// Energetic bright start chime for GO!
  static void playCountdownGo({double volume = 1.0}) {
    _play('audio/countdown_go.wav', volume: volume);
  }

  /// Soft, gentle bubble/pulse sound while quiz is generating.
  static void playQuizLoading({double volume = 0.80}) {
    _play('audio/quiz_loading.wav', volume: volume);
  }

  /// Starts repeating quiz loading pulse while AI quiz generation is in progress.
  static void startQuizLoadingLoop() {
    stopQuizLoadingLoop();
    if (!_isSoundEnabled || _isTesting) return;
    playQuizLoading();
    _loadingLoopTimer = Timer.periodic(
      const Duration(milliseconds: 850),
      (_) {
        if (!_isSoundEnabled) {
          stopQuizLoadingLoop();
          return;
        }
        playQuizLoading();
      },
    );
  }

  /// Stops the quiz loading pulse loop.
  static void stopQuizLoadingLoop() {
    _loadingLoopTimer?.cancel();
    _loadingLoopTimer = null;
  }

  // ===========================================================================
  // Internal Dispatch
  // ===========================================================================

  static AudioPlayer _nextPlayer() {
    final player = _playerPool[_poolIndex];
    _poolIndex = (_poolIndex + 1) % _playerPool.length;
    return player;
  }

  static void _play(
    String relativePath, {
    double volume = 0.90,
  }) {
    if (!_isSoundEnabled || _isTesting) return;
    try {
      final player = _nextPlayer();
      player.stop().then((_) {
        player.setVolume(volume);
        player.play(AssetSource(relativePath));
      }).catchError((_) {
        player.setVolume(volume);
        player.play(AssetSource(relativePath));
      });
    } catch (e) {
      debugPrint('SoundService._play error ($relativePath): $e');
    }
  }
}
