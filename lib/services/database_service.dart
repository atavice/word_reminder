import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/word.dart';

class DatabaseService {
  static Database? _database;
  static const String _webStorageKey = 'saved_words';

  // Native: SQLite
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

  // --- Web helpers using SharedPreferences ---

  Future<List<Word>> _webGetWords() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_webStorageKey);
    if (jsonStr == null) return [];
    final List<dynamic> list = json.decode(jsonStr);
    return list.map((e) => Word.fromMap(Map<String, dynamic>.from(e))).toList();
  }

  Future<void> _webSaveWords(List<Word> words) async {
    final prefs = await SharedPreferences.getInstance();
    final list = words.map((w) => w.toMap()).toList();
    await prefs.setString(_webStorageKey, json.encode(list));
  }

  // --- Public API ---

  Future<int> insertWord(Word word) async {
    if (kIsWeb) {
      final words = await _webGetWords();
      final newId = words.isEmpty ? 1 : (words.map((w) => w.id ?? 0).reduce((a, b) => a > b ? a : b) + 1);
      final newWord = Word(
        id: newId,
        sourceWord: word.sourceWord,
        translatedWord: word.translatedWord,
        sourceLang: word.sourceLang,
        targetLang: word.targetLang,
        createdAt: word.createdAt,
        reviewCount: word.reviewCount,
      );
      words.insert(0, newWord);
      await _webSaveWords(words);
      return newId;
    }

    final db = await database;
    return await db.insert('words', word.toMap());
  }

  Future<List<Word>> getWords() async {
    if (kIsWeb) {
      return await _webGetWords();
    }

    final db = await database;
    final maps = await db.query('words', orderBy: 'createdAt DESC');
    return maps.map((map) => Word.fromMap(map)).toList();
  }

  Future<Word?> getRandomWord() async {
    final words = await getWords();
    if (words.isEmpty) return null;
    words.shuffle();
    return words.first;
  }

  Future<List<Word>> searchWords(String query) async {
    final words = await getWords();
    final q = query.toLowerCase();
    return words
        .where((w) =>
            w.sourceWord.toLowerCase().contains(q) ||
            w.translatedWord.toLowerCase().contains(q))
        .toList();
  }

  Future<int> updateWord(Word word) async {
    if (kIsWeb) {
      final words = await _webGetWords();
      final index = words.indexWhere((w) => w.id == word.id);
      if (index == -1) return 0;
      words[index] = word;
      await _webSaveWords(words);
      return 1;
    }

    final db = await database;
    return await db.update(
      'words',
      word.toMap(),
      where: 'id = ?',
      whereArgs: [word.id],
    );
  }

  Future<int> incrementReviewCount(int id) async {
    if (kIsWeb) {
      final words = await _webGetWords();
      final index = words.indexWhere((w) => w.id == id);
      if (index == -1) return 0;
      final w = words[index];
      words[index] = Word(
        id: w.id,
        sourceWord: w.sourceWord,
        translatedWord: w.translatedWord,
        sourceLang: w.sourceLang,
        targetLang: w.targetLang,
        createdAt: w.createdAt,
        reviewCount: w.reviewCount + 1,
      );
      await _webSaveWords(words);
      return 1;
    }

    final db = await database;
    return await db.rawUpdate(
      'UPDATE words SET reviewCount = reviewCount + 1 WHERE id = ?',
      [id],
    );
  }

  Future<int> deleteWord(int id) async {
    if (kIsWeb) {
      final words = await _webGetWords();
      words.removeWhere((w) => w.id == id);
      await _webSaveWords(words);
      return 1;
    }

    final db = await database;
    return await db.delete('words', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> getWordCount() async {
    final words = await getWords();
    return words.length;
  }
}
