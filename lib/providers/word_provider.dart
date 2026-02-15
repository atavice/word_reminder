import 'package:flutter/foundation.dart';
import '../models/word.dart';
import '../services/database_service.dart';
import '../services/translation_service.dart';
import '../services/notification_service.dart';

class WordProvider extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  final TranslationService _translationService = TranslationService();
  final NotificationService _notificationService = NotificationService();

  List<Word> _words = [];
  List<Word> _filteredWords = [];
  String _searchQuery = '';
  bool _isLoading = false;
  String? _translationResult;
  String _sourceLang = 'en';
  String _targetLang = 'tr';

  List<Word> get words => _searchQuery.isEmpty ? _words : _filteredWords;
  bool get isLoading => _isLoading;
  String? get translationResult => _translationResult;
  String get sourceLang => _sourceLang;
  String get targetLang => _targetLang;
  DatabaseService get dbService => _dbService;
  NotificationService get notificationService => _notificationService;

  Future<void> initialize() async {
    await _notificationService.initialize();
    await _notificationService.requestPermissions();
    await loadWords();
  }

  Future<void> loadWords() async {
    _words = await _dbService.getWords();
    notifyListeners();
  }

  Future<String?> translate(String text) async {
    _isLoading = true;
    _translationResult = null;
    notifyListeners();

    _translationResult = await _translationService.translate(
      text: text,
      sourceLang: _sourceLang,
      targetLang: _targetLang,
    );

    _isLoading = false;
    notifyListeners();
    return _translationResult;
  }

  Future<void> addWord(String sourceWord, String translatedWord) async {
    final word = Word(
      sourceWord: sourceWord,
      translatedWord: translatedWord,
      sourceLang: _sourceLang,
      targetLang: _targetLang,
    );
    await _dbService.insertWord(word);
    await loadWords();
    await _notificationService.scheduleWordReminders(_dbService);
  }

  Future<void> deleteWord(int id) async {
    await _dbService.deleteWord(id);
    await loadWords();
  }

  void searchWords(String query) {
    _searchQuery = query;
    if (query.isEmpty) {
      _filteredWords = [];
    } else {
      _filteredWords = _words
          .where((w) =>
              w.sourceWord.toLowerCase().contains(query.toLowerCase()) ||
              w.translatedWord.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
    notifyListeners();
  }

  void swapLanguages() {
    final temp = _sourceLang;
    _sourceLang = _targetLang;
    _targetLang = temp;
    notifyListeners();
  }

  void setSourceLang(String lang) {
    _sourceLang = lang;
    notifyListeners();
  }

  void setTargetLang(String lang) {
    _targetLang = lang;
    notifyListeners();
  }

  void clearTranslation() {
    _translationResult = null;
    notifyListeners();
  }
}
