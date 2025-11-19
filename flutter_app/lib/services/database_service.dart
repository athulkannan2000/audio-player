import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/note.dart';

/// Database service for storing notes and playback state
class DatabaseService {
  static Database? _database;
  
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }
  
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'audio_player.db');
    
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }
  
  Future<void> _onCreate(Database db, int version) async {
    // Notes table
    await db.execute('''
      CREATE TABLE notes (
        id TEXT PRIMARY KEY,
        timestamp_ms INTEGER NOT NULL,
        note_text TEXT NOT NULL,
        created_at TEXT NOT NULL,
        edited_at TEXT,
        audio_path TEXT
      )
    ''');
    
    // Create index for faster timestamp queries
    await db.execute('''
      CREATE INDEX idx_notes_timestamp ON notes(timestamp_ms)
    ''');
  }
  
  /// Insert a note
  Future<void> insertNote(AudioNote note, {String? audioPath}) async {
    final db = await database;
    final map = note.toMap();
    if (audioPath != null) {
      map['audio_path'] = audioPath;
    }
    await db.insert('notes', map, conflictAlgorithm: ConflictAlgorithm.replace);
  }
  
  /// Update a note
  Future<void> updateNote(AudioNote note) async {
    final db = await database;
    await db.update(
      'notes',
      note.toMap(),
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }
  
  /// Delete a note
  Future<void> deleteNote(String id) async {
    final db = await database;
    await db.delete('notes', where: 'id = ?', whereArgs: [id]);
  }
  
  /// Get all notes for current audio
  Future<List<AudioNote>> getNotes({String? audioPath}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps;
    
    if (audioPath != null) {
      maps = await db.query(
        'notes',
        where: 'audio_path = ?',
        whereArgs: [audioPath],
        orderBy: 'timestamp_ms ASC',
      );
    } else {
      maps = await db.query('notes', orderBy: 'timestamp_ms ASC');
    }
    
    return List.generate(maps.length, (i) => AudioNote.fromMap(maps[i]));
  }
  
  /// Get notes in a time range
  Future<List<AudioNote>> getNotesInRange(int startMs, int endMs) async {
    final db = await database;
    final maps = await db.query(
      'notes',
      where: 'timestamp_ms BETWEEN ? AND ?',
      whereArgs: [startMs, endMs],
      orderBy: 'timestamp_ms ASC',
    );
    
    return List.generate(maps.length, (i) => AudioNote.fromMap(maps[i]));
  }
  
  /// Search notes by text
  Future<List<AudioNote>> searchNotes(String query) async {
    final db = await database;
    final maps = await db.query(
      'notes',
      where: 'note_text LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: 'timestamp_ms ASC',
    );
    
    return List.generate(maps.length, (i) => AudioNote.fromMap(maps[i]));
  }
  
  /// Clear all notes
  Future<void> clearAllNotes() async {
    final db = await database;
    await db.delete('notes');
  }
  
  /// Export notes as JSON
  Future<List<Map<String, dynamic>>> exportNotes() async {
    final notes = await getNotes();
    return notes.map((note) => note.toJson()).toList();
  }
  
  /// Close database
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}

/// Provider for database service
final databaseServiceProvider = Provider<DatabaseService>((ref) {
  final service = DatabaseService();
  ref.onDispose(() => service.close());
  return service;
});

/// Provider for notes stream
final notesProvider = StreamProvider.family<List<AudioNote>, String?>((ref, audioPath) {
  final dbService = ref.watch(databaseServiceProvider);
  final controller = StreamController<List<AudioNote>>();
  
  // Initial load
  dbService.getNotes(audioPath: audioPath).then((notes) {
    controller.add(notes);
  });
  
  return controller.stream;
});
