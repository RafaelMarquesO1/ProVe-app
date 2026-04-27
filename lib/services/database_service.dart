
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

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

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE notes(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        date TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE favorites(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        proverb_id INTEGER NOT NULL
      )
    ''');
  }

  // Note methods
  Future<int> createNote({required String title, required String content}) async {
    final db = await instance.database;
    final id = await db.insert('notes', {
      'title': title,
      'content': content,
      'date': DateTime.now().toIso8601String(),
    });
    return id;
  }

  Future<Map<String, dynamic>?> getNote(int id) async {
    final db = await instance.database;
    final maps = await db.query(
      'notes',
      columns: ['id', 'title', 'content', 'date'],
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return maps.first;
    } else {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getAllNotes() async {
    final db = await instance.database;
    return await db.query('notes', orderBy: 'date DESC');
  }

  Future<int> updateNote({required int id, required String title, required String content}) async {
    final db = await instance.database;
    return await db.update(
      'notes',
      {
        'title': title,
        'content': content,
        'date': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteNote(int id) async {
    final db = await instance.database;
    return await db.delete(
      'notes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Favorite methods
  Future<int> addFavorite(int proverbId) async {
    final db = await instance.database;
    return await db.insert('favorites', {'proverb_id': proverbId});
  }

  Future<int> removeFavorite(int proverbId) async {
    final db = await instance.database;
    return await db.delete(
      'favorites',
      where: 'proverb_id = ?',
      whereArgs: [proverbId],
    );
  }

  Future<bool> isFavorite(int proverbId) async {
    final db = await instance.database;
    final maps = await db.query(
      'favorites',
      columns: ['id'],
      where: 'proverb_id = ?',
      whereArgs: [proverbId],
    );
    return maps.isNotEmpty;
  }

  Future<List<int>> getAllFavorites() async {
    final db = await instance.database;
    final maps = await db.query('favorites');
    return maps.map((map) => map['proverb_id'] as int).toList();
  }
}
