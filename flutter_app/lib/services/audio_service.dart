import 'dart:async';
import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/playback_state.dart' as models;

/// Audio service for managing audio playback
class AudioPlayerService {
  final AudioPlayer _player = AudioPlayer();
  
  final _stateController = StreamController<models.PlaybackState>.broadcast();
  Stream<models.PlaybackState> get stateStream => _stateController.stream;
  
  models.PlaybackState _currentState = const models.PlaybackState();
  
  AudioPlayerService() {
    _initializeListeners();
  }
  
  void _initializeListeners() {
    // Listen to player state changes
    _player.playerStateStream.listen((state) {
      _updateState(_currentState.copyWith(
        isPlaying: state.playing,
      ));
    });
    
    // Listen to duration changes
    _player.durationStream.listen((duration) {
      if (duration != null) {
        _updateState(_currentState.copyWith(
          durationMs: duration.inMilliseconds,
        ));
      }
    });
    
    // Listen to position changes (throttled)
    _player.positionStream.listen((position) {
      final positionMs = position.inMilliseconds;
      final progress = _currentState.durationMs != null
          ? positionMs / _currentState.durationMs!
          : 0.0;
      
      _updateState(_currentState.copyWith(
        positionMs: positionMs,
        progress: progress,
      ));
    });
    
    // Listen to volume changes
    _player.volumeStream.listen((volume) {
      _updateState(_currentState.copyWith(volume: volume));
    });
    
    // Listen to speed changes
    _player.speedStream.listen((speed) {
      _updateState(_currentState.copyWith(speed: speed));
    });
    
    // Listen to loop mode changes
    _player.loopModeStream.listen((loopMode) {
      final repeatMode = _loopModeToRepeatMode(loopMode);
      _updateState(_currentState.copyWith(isRepeating: repeatMode));
    });
    
    // Listen to shuffle mode changes
    _player.shuffleModeEnabledStream.listen((shuffling) {
      _updateState(_currentState.copyWith(isShuffling: shuffling));
    });
  }
  
  void _updateState(models.PlaybackState newState) {
    _currentState = newState;
    _stateController.add(newState);
  }
  
  models.RepeatMode _loopModeToRepeatMode(LoopMode loopMode) {
    switch (loopMode) {
      case LoopMode.one:
        return models.RepeatMode.repeatOne;
      case LoopMode.all:
        return models.RepeatMode.repeatAll;
      default:
        return models.RepeatMode.off;
    }
  }
  
  LoopMode _repeatModeToLoopMode(models.RepeatMode repeatMode) {
    switch (repeatMode) {
      case models.RepeatMode.repeatOne:
        return LoopMode.one;
      case models.RepeatMode.repeatAll:
        return LoopMode.all;
      default:
        return LoopMode.off;
    }
  }
  
  /// Load audio file
  Future<void> loadAudio(String path) async {
    try {
      await _player.setFilePath(path);
      _updateState(_currentState.copyWith(currentAudioPath: path));
    } catch (e) {
      rethrow;
    }
  }
  
  /// Load audio from URL
  Future<void> loadAudioUrl(String url) async {
    try {
      await _player.setUrl(url);
      _updateState(_currentState.copyWith(currentAudioPath: url));
    } catch (e) {
      rethrow;
    }
  }
  
  /// Play
  Future<void> play() async {
    await _player.play();
  }
  
  /// Pause
  Future<void> pause() async {
    await _player.pause();
  }
  
  /// Toggle play/pause
  Future<void> togglePlay() async {
    if (_player.playing) {
      await pause();
    } else {
      await play();
    }
  }
  
  /// Seek to position
  Future<void> seek(int milliseconds) async {
    await _player.seek(Duration(milliseconds: milliseconds));
  }
  
  /// Skip forward (default 15 seconds)
  Future<void> skipForward({int seconds = 15}) async {
    final newPosition = _currentState.positionMs + (seconds * 1000);
    final maxPosition = _currentState.durationMs ?? newPosition;
    await seek(newPosition.clamp(0, maxPosition));
  }
  
  /// Skip backward (default 15 seconds)
  Future<void> skipBackward({int seconds = 15}) async {
    final newPosition = _currentState.positionMs - (seconds * 1000);
    await seek(newPosition.clamp(0, _currentState.durationMs ?? 0));
  }
  
  /// Set volume (0.0 - 1.0)
  Future<void> setVolume(double volume) async {
    await _player.setVolume(volume.clamp(0.0, 1.0));
  }
  
  /// Increase volume by 10%
  Future<void> volumeUp() async {
    final newVolume = (_currentState.volume + 0.1).clamp(0.0, 1.0);
    await setVolume(newVolume);
  }
  
  /// Decrease volume by 10%
  Future<void> volumeDown() async {
    final newVolume = (_currentState.volume - 0.1).clamp(0.0, 1.0);
    await setVolume(newVolume);
  }
  
  /// Set max volume
  Future<void> setMaxVolume() async {
    await setVolume(1.0);
  }
  
  /// Toggle mute
  bool _wasMuted = false;
  double _volumeBeforeMute = 1.0;
  
  Future<void> toggleMute() async {
    if (_wasMuted) {
      await setVolume(_volumeBeforeMute);
      _wasMuted = false;
    } else {
      _volumeBeforeMute = _currentState.volume;
      await setVolume(0.0);
      _wasMuted = true;
    }
  }
  
  /// Set playback speed
  Future<void> setSpeed(double speed) async {
    await _player.setSpeed(speed.clamp(0.5, 2.0));
  }
  
  /// Cycle through speed presets (1.0 -> 1.25 -> 1.5 -> 2.0 -> 0.75 -> 1.0)
  Future<void> cycleSpeed() async {
    const speeds = [1.0, 1.25, 1.5, 2.0, 0.75];
    final currentSpeed = _currentState.speed;
    final currentIndex = speeds.indexOf(currentSpeed);
    final nextIndex = (currentIndex + 1) % speeds.length;
    await setSpeed(speeds[nextIndex]);
  }
  
  /// Reset speed to 1.0x
  Future<void> resetSpeed() async {
    await setSpeed(1.0);
  }
  
  /// Toggle shuffle
  Future<void> toggleShuffle() async {
    await _player.setShuffleModeEnabled(!_currentState.isShuffling);
  }
  
  /// Cycle repeat mode (off -> one -> all -> off)
  Future<void> cycleRepeat() async {
    final modes = [
      models.RepeatMode.off,
      models.RepeatMode.repeatOne,
      models.RepeatMode.repeatAll,
    ];
    final currentIndex = modes.indexOf(_currentState.isRepeating);
    final nextIndex = (currentIndex + 1) % modes.length;
    final nextMode = modes[nextIndex];
    
    await _player.setLoopMode(_repeatModeToLoopMode(nextMode));
  }
  
  /// Get current state
  models.PlaybackState get currentState => _currentState;
  
  /// Dispose
  void dispose() {
    _player.dispose();
    _stateController.close();
  }
}

/// Provider for audio service
final audioServiceProvider = Provider<AudioPlayerService>((ref) {
  final service = AudioPlayerService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Provider for playback state
final playbackStateProvider = StreamProvider<models.PlaybackState>((ref) {
  final service = ref.watch(audioServiceProvider);
  return service.stateStream;
});
