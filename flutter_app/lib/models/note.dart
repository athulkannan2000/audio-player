/// Model representing a time-linked note
class AudioNote {
  final String id;
  final int timestampMs;
  final String noteText;
  final DateTime createdAt;
  final DateTime? editedAt;

  const AudioNote({
    required this.id,
    required this.timestampMs,
    required this.noteText,
    required this.createdAt,
    this.editedAt,
  });

  AudioNote copyWith({
    String? id,
    int? timestampMs,
    String? noteText,
    DateTime? createdAt,
    DateTime? editedAt,
  }) {
    return AudioNote(
      id: id ?? this.id,
      timestampMs: timestampMs ?? this.timestampMs,
      noteText: noteText ?? this.noteText,
      createdAt: createdAt ?? this.createdAt,
      editedAt: editedAt ?? this.editedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp_ms': timestampMs,
      'note_text': noteText,
      'created_at': createdAt.toIso8601String(),
      'edited_at': editedAt?.toIso8601String(),
    };
  }

  factory AudioNote.fromJson(Map<String, dynamic> json) {
    return AudioNote(
      id: json['id'] as String,
      timestampMs: json['timestamp_ms'] as int,
      noteText: json['note_text'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      editedAt: json['edited_at'] != null
          ? DateTime.parse(json['edited_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp_ms': timestampMs,
      'note_text': noteText,
      'created_at': createdAt.toIso8601String(),
      'edited_at': editedAt?.toIso8601String(),
    };
  }

  factory AudioNote.fromMap(Map<String, dynamic> map) {
    return AudioNote(
      id: map['id'] as String,
      timestampMs: map['timestamp_ms'] as int,
      noteText: map['note_text'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      editedAt: map['edited_at'] != null
          ? DateTime.parse(map['edited_at'] as String)
          : null,
    );
  }

  /// Format timestamp as human-readable time (e.g., "2:15")
  String get formattedTimestamp {
    final seconds = timestampMs ~/ 1000;
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    
    if (minutes >= 60) {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      return '$hours:${remainingMinutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
    }
    
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}
