/// Model representing audio playback state
/// Serializable for debugging and persistence
class PlaybackState {
  final bool isPlaying;
  final int? durationMs;
  final int positionMs;
  final double volume;
  final double speed;
  final bool isShuffling;
  final RepeatMode isRepeating;
  final double progress;
  final String? currentAudioPath;

  const PlaybackState({
    this.isPlaying = false,
    this.durationMs,
    this.positionMs = 0,
    this.volume = 1.0,
    this.speed = 1.0,
    this.isShuffling = false,
    this.isRepeating = RepeatMode.off,
    this.progress = 0.0,
    this.currentAudioPath,
  });

  PlaybackState copyWith({
    bool? isPlaying,
    int? durationMs,
    int? positionMs,
    double? volume,
    double? speed,
    bool? isShuffling,
    RepeatMode? isRepeating,
    double? progress,
    String? currentAudioPath,
  }) {
    return PlaybackState(
      isPlaying: isPlaying ?? this.isPlaying,
      durationMs: durationMs ?? this.durationMs,
      positionMs: positionMs ?? this.positionMs,
      volume: volume ?? this.volume,
      speed: speed ?? this.speed,
      isShuffling: isShuffling ?? this.isShuffling,
      isRepeating: isRepeating ?? this.isRepeating,
      progress: progress ?? this.progress,
      currentAudioPath: currentAudioPath ?? this.currentAudioPath,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isPlaying': isPlaying,
      'duration_ms': durationMs,
      'position_ms': positionMs,
      'volume': volume,
      'speed': speed,
      'isShuffling': isShuffling,
      'isRepeating': isRepeating.name,
      'progress': progress,
      'currentAudioPath': currentAudioPath,
    };
  }

  factory PlaybackState.fromJson(Map<String, dynamic> json) {
    return PlaybackState(
      isPlaying: json['isPlaying'] as bool? ?? false,
      durationMs: json['duration_ms'] as int?,
      positionMs: json['position_ms'] as int? ?? 0,
      volume: (json['volume'] as num?)?.toDouble() ?? 1.0,
      speed: (json['speed'] as num?)?.toDouble() ?? 1.0,
      isShuffling: json['isShuffling'] as bool? ?? false,
      isRepeating: RepeatMode.fromString(json['isRepeating'] as String? ?? 'off'),
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      currentAudioPath: json['currentAudioPath'] as String?,
    );
  }
}

enum RepeatMode {
  off,
  repeatOne,
  repeatAll;

  static RepeatMode fromString(String value) {
    switch (value) {
      case 'repeat_one':
      case 'repeatOne':
        return RepeatMode.repeatOne;
      case 'repeat_all':
      case 'repeatAll':
        return RepeatMode.repeatAll;
      default:
        return RepeatMode.off;
    }
  }
}
