import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/note.dart';
import '../models/ble_command.dart';
import '../services/audio_service.dart';
import '../services/ble_service.dart';
import '../services/database_service.dart';

/// Command handler provider that integrates BLE commands with audio player
final commandHandlerProvider = Provider((ref) {
  return CommandHandler(ref);
});

class CommandHandler {
  final Ref ref;
  
  CommandHandler(this.ref) {
    // Listen to BLE commands
    ref.listen(bleCommandProvider, (previous, next) {
      next.whenData((command) => handleCommand(command));
    });
  }
  
  /// Handle incoming BLE command
  Future<void> handleCommand(BLECommand command) async {
    final audioService = ref.read(audioServiceProvider);
    final bleService = ref.read(bleServiceProvider);
    
    try {
      switch (command.cmd) {
        case 'play_pause':
          await audioService.togglePlay();
          break;
          
        case 'next':
          await audioService.skipForward(seconds: 15);
          break;
          
        case 'prev':
          await audioService.skipBackward(seconds: 15);
          break;
          
        case 'volume_up':
          await audioService.volumeUp();
          break;
          
        case 'volume_down':
          await audioService.volumeDown();
          break;
          
        case 'volume_max':
          await audioService.setMaxVolume();
          break;
          
        case 'volume_mute':
          await audioService.toggleMute();
          break;
          
        case 'speed_cycle':
          await audioService.cycleSpeed();
          break;
          
        case 'speed_reset':
          await audioService.resetSpeed();
          break;
          
        case 'repeat_cycle':
          await audioService.cycleRepeat();
          break;
          
        case 'note':
          await _handleNoteCommand(audioService);
          break;
          
        case 'ping':
          // Keep-alive, do nothing
          break;
          
        default:
          // Unknown command
          await bleService.sendStatus({
            'error': 'unknown_cmd',
            'cmd': command.cmd,
          });
          return;
      }
      
      // Send acknowledgment
      await bleService.sendStatus({
        'ack': command.seq,
        'state': 'ok',
      });
      
    } catch (e) {
      // Send error status
      await bleService.sendStatus({
        'error': 'execution_failed',
        'cmd': command.cmd,
        'message': e.toString(),
      });
    }
  }
  
  /// Handle note command - pause and trigger note creation
  Future<void> _handleNoteCommand(AudioPlayerService audioService) async {
    // Pause playback
    if (audioService.currentState.isPlaying) {
      await audioService.pause();
    }
    
    // Note: The UI should show a note dialog when this is called
    // This is handled by listening to a note trigger state in the UI
    ref.read(noteTriggerProvider.notifier).state++;
  }
}

/// Provider to trigger note dialog in UI
final noteTriggerProvider = StateProvider<int>((ref) => 0);

/// Notes manager provider
final notesManagerProvider = Provider((ref) {
  return NotesManager(ref);
});

class NotesManager {
  final Ref ref;
  final _uuid = const Uuid();
  
  NotesManager(this.ref);
  
  /// Create a new note
  Future<AudioNote> createNote({
    required String noteText,
    int? timestampMs,
  }) async {
    final audioService = ref.read(audioServiceProvider);
    final dbService = ref.read(databaseServiceProvider);
    
    final timestamp = timestampMs ?? audioService.currentState.positionMs;
    final audioPath = audioService.currentState.currentAudioPath;
    
    final note = AudioNote(
      id: _uuid.v4(),
      timestampMs: timestamp,
      noteText: noteText,
      createdAt: DateTime.now(),
    );
    
    await dbService.insertNote(note, audioPath: audioPath);
    
    // Refresh notes list
    ref.invalidate(notesProvider);
    
    return note;
  }
  
  /// Update a note
  Future<void> updateNote(AudioNote note, String newText) async {
    final dbService = ref.read(databaseServiceProvider);
    
    final updatedNote = note.copyWith(
      noteText: newText,
      editedAt: DateTime.now(),
    );
    
    await dbService.updateNote(updatedNote);
    
    // Refresh notes list
    ref.invalidate(notesProvider);
  }
  
  /// Delete a note
  Future<void> deleteNote(String id) async {
    final dbService = ref.read(databaseServiceProvider);
    await dbService.deleteNote(id);
    
    // Refresh notes list
    ref.invalidate(notesProvider);
  }
  
  /// Get notes for current audio
  Future<List<AudioNote>> getCurrentAudioNotes() async {
    final audioService = ref.read(audioServiceProvider);
    final dbService = ref.read(databaseServiceProvider);
    final audioPath = audioService.currentState.currentAudioPath;
    
    return await dbService.getNotes(audioPath: audioPath);
  }
  
  /// Jump to note timestamp
  Future<void> jumpToNote(AudioNote note) async {
    final audioService = ref.read(audioServiceProvider);
    await audioService.seek(note.timestampMs);
  }
  
  /// Export all notes
  Future<List<Map<String, dynamic>>> exportNotes() async {
    final dbService = ref.read(databaseServiceProvider);
    return await dbService.exportNotes();
  }
}

/// Current audio notes provider
final currentAudioNotesProvider = FutureProvider<List<AudioNote>>((ref) async {
  final notesManager = ref.watch(notesManagerProvider);
  return await notesManager.getCurrentAudioNotes();
});
