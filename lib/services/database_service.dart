import 'dart:convert';

import 'package:prove/models/user_model.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('app.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return openDatabase(
      path,
      version: 8,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await _createUserTable(db);
    await _createFavoritesTable(db);
    await _createNotesTable(db);
    await _createHighlightsTable(db);
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE notes RENAME TO legacy_notes');
      await db.execute('ALTER TABLE favorites RENAME TO legacy_favorites');
      await _createUserTable(db);
      await _createFavoritesTable(db);
      await _createNotesTable(db);
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE notes ADD COLUMN mood TEXT');
      await db.execute('ALTER TABLE notes ADD COLUMN image_path TEXT');
    }
    if (oldVersion < 4) {
      await db.execute('ALTER TABLE notes ADD COLUMN verse_keys TEXT');
    }
    if (oldVersion < 5) {
      await db.execute('ALTER TABLE notes ADD COLUMN title TEXT');
    }
    if (oldVersion < 6) {
      await db.execute('ALTER TABLE notes ADD COLUMN accent_color INTEGER');
      await db.execute('ALTER TABLE notes ADD COLUMN font_size REAL');
      await db.execute('ALTER TABLE notes ADD COLUMN font_style TEXT');
    }
    if (oldVersion < 7) {
      await db.execute('ALTER TABLE notes ADD COLUMN updated_at TEXT');
    }
    if (oldVersion < 8) {
      await _createHighlightsTable(db);
    }
  }

  Future<void> _createUserTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS user_profile(
        uid TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        photo_path TEXT,
        last_read_date TEXT,
        reading_streak INTEGER NOT NULL DEFAULT 0,
        longest_streak INTEGER NOT NULL DEFAULT 0,
        completed_days TEXT NOT NULL DEFAULT '[]',
        current_chapter INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> _createFavoritesTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS favorites(
        id TEXT PRIMARY KEY,
        chapter TEXT NOT NULL,
        verse_number TEXT NOT NULL,
        text TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_favorites_created_at ON favorites(created_at DESC)',
    );
  }

  Future<void> _createNotesTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS notes(
        id TEXT PRIMARY KEY,
        reference TEXT NOT NULL,
        verse_text TEXT NOT NULL,
        note_text TEXT NOT NULL,
        mood TEXT,
        image_path TEXT,
        verse_keys TEXT,
        title TEXT,
        accent_color INTEGER,
        font_size REAL,
        font_style TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_notes_created_at ON notes(created_at DESC)',
    );
  }

  Future<void> _createHighlightsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS highlights(
        id TEXT PRIMARY KEY,
        chapter TEXT NOT NULL,
        verse_number TEXT NOT NULL,
        color_value INTEGER NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_highlights_chapter ON highlights(chapter)',
    );
  }

  Future<UserModel?> getUserProfile() async {
    final db = await database;
    final rows = await db.query('user_profile', limit: 1);
    if (rows.isEmpty) return null;
    return _userFromRow(rows.first);
  }

  Future<void> upsertUserProfile(UserModel user) async {
    final db = await database;
    await db.insert(
      'user_profile',
      _userToRow(user),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> updateUserProfile({
    required String name,
    required String? photoPath,
  }) async {
    final db = await database;
    return db.update(
      'user_profile',
      {
        'name': name,
        'photo_path': photoPath,
        'updated_at': DateTime.now().toIso8601String(),
      },
    );
  }

  Future<void> updateReadingProgress(UserModel user) async {
    await upsertUserProfile(user);
  }

  Future<void> toggleFavorite({
    required String chapter,
    required String verseNumber,
    required String verseText,
  }) async {
    final db = await database;
    final id = '${chapter}_$verseNumber';
    final existing = await db.query(
      'favorites',
      columns: ['id'],
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (existing.isNotEmpty) {
      await db.delete('favorites', where: 'id = ?', whereArgs: [id]);
      return;
    }

    await db.insert('favorites', {
      'id': id,
      'chapter': chapter,
      'verse_number': verseNumber,
      'text': verseText,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<bool> isFavorite(String chapter, String verseNumber) async {
    final db = await database;
    final rows = await db.query(
      'favorites',
      columns: ['id'],
      where: 'id = ?',
      whereArgs: ['${chapter}_$verseNumber'],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<List<Map<String, dynamic>>> getFavorites() async {
    final db = await database;
    return db.query('favorites', orderBy: 'created_at DESC');
  }

  Future<int> deleteFavorite(String id) async {
    final db = await database;
    return db.delete('favorites', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> saveNote({
    required String reference,
    required String verseText,
    required String noteText,
    String? mood,
    String? imagePath,
    List<String>? verseKeys,
    String? title,
    int? accentColor,
  }) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    await db.insert('notes', {
      'id': 'note_${DateTime.now().microsecondsSinceEpoch}',
      'reference': reference,
      'verse_text': verseText,
      'note_text': noteText,
      'mood': mood,
      'image_path': imagePath,
      'verse_keys': verseKeys?.join(','),
      'title': title,
      'accent_color': accentColor,
      'created_at': now,
    });
  }

  Future<List<Map<String, dynamic>>> getNotes() async {
    final db = await database;
    return db.query('notes', orderBy: 'created_at DESC');
  }

  Future<int> updateNote({
    required String id,
    required String noteText,
    String? mood,
    String? title,
    int? accentColor,
    String? imagePath,
  }) async {
    final db = await database;
    return db.update(
      'notes',
      {
        'note_text': noteText,
        'mood': mood,
        'title': title,
        'accent_color': accentColor,
        'image_path': imagePath,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteNote(String id) async {
    final db = await database;
    return db.delete('notes', where: 'id = ?', whereArgs: [id]);
  }

  UserModel _userFromRow(Map<String, dynamic> row) {
    return UserModel.fromMap({
      'uid': row['uid'],
      'name': row['name'],
      'photoPath': row['photo_path'],
      'lastReadDate': row['last_read_date'],
      'readingStreak': row['reading_streak'],
      'longestStreak': row['longest_streak'],
      'completedDays': jsonDecode(row['completed_days'] as String),
      'currentChapter': row['current_chapter'],
      'createdAt': row['created_at'],
    });
  }

  Map<String, dynamic> _userToRow(UserModel user) {
    final now = DateTime.now().toIso8601String();
    return {
      'uid': user.uid,
      'name': user.name,
      'photo_path': user.photoPath,
      'last_read_date': user.lastReadDate?.toIso8601String(),
      'reading_streak': user.readingStreak,
      'longest_streak': user.longestStreak,
      'completed_days': jsonEncode(
        user.completedDays.map((date) => date.toIso8601String()).toList(),
      ),
      'current_chapter': user.currentChapter,
      'created_at': user.createdAt.toIso8601String(),
      'updated_at': now,
    };
  }

  Future<void> saveHighlight({
    required String chapter,
    required String verseNumber,
    required int colorValue,
  }) async {
    final db = await database;
    final id = '${chapter}_$verseNumber';
    await db.insert(
      'highlights',
      {
        'id': id,
        'chapter': chapter,
        'verse_number': verseNumber,
        'color_value': colorValue,
        'created_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> removeHighlight(String chapter, String verseNumber) async {
    final db = await database;
    final id = '${chapter}_$verseNumber';
    return db.delete('highlights', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getHighlights() async {
    final db = await database;
    return db.query('highlights');
  }
}
