import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/word.dart';

class DatabaseService {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'word_reminder.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE words(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            sourceWord TEXT NOT NULL,
            translatedWord TEXT NOT NULL,
            sourceLang TEXT NOT NULL DEFAULT 'en',
            targetLang TEXT NOT NULL DEFAULT 'tr',
            createdAt TEXT NOT NULL,
            reviewCount INTEGER NOT NULL DEFAULT 0
          )
        ''');
      },
    );
  }

  Future<int> insertWord(Word word) async {
    final db = await database;
    return await db.insert('words', word.toMap());
  }

  Future<List<Word>> getWords() async {
    final db = await database;
    final maps = await db.query('words', orderBy: 'createdAt DESC');
    return maps.map((map) => Word.fromMap(map)).toList();
  }

  Future<Word?> getRandomWord() async {
    final db = await database;
    final maps = await db.rawQuery(
      'SELECT * FROM words ORDER BY RANDOM() LIMIT 1',
    );
    if (maps.isEmpty) return null;
    return Word.fromMap(maps.first);
  }

  Future<List<Word>> searchWords(String query) async {
    final db = await database;
    final maps = await db.query(
      'words',
      where: 'sourceWord LIKE ? OR translatedWord LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'createdAt DESC',
    );
    return maps.map((map) => Word.fromMap(map)).toList();
  }

  Future<int> updateWord(Word word) async {
    final db = await database;
    return await db.update(
      'words',
      word.toMap(),
      where: 'id = ?',
      whereArgs: [word.id],
    );
  }

  Future<int> incrementReviewCount(int id) async {
    final db = await database;
    return await db.rawUpdate(
      'UPDATE words SET reviewCount = reviewCount + 1 WHERE id = ?',
      [id],
    );
  }

  Future<int> deleteWord(int id) async {
    final db = await database;
    return await db.delete('words', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> getWordCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM words');
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
