import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/word_provider.dart';
import 'defter_detail_screen.dart';

class WordListScreen extends StatelessWidget {
  const WordListScreen({super.key});

  static const _langNames = {
    'en': 'English',
    'de': 'Deutsch',
    'tr': 'Türkçe',
    'es': 'Español',
    'fr': 'Français',
    'it': 'Italiano',
  };

  String _langName(String code) => _langNames[code] ?? code;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelime Defterim'),
        centerTitle: true,
      ),
      body: Consumer<WordProvider>(
        builder: (context, provider, _) {
          final pairs = provider.getLanguagePairs();

          if (pairs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.book_outlined, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Henüz kelime eklemediniz',
                    style: TextStyle(fontSize: 16, color: Colors.grey[500]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ana sayfadan kelime çevirip kaydedin',
                    style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: pairs.length,
            itemBuilder: (context, index) {
              final pair = pairs[index];
              final sourceLang = pair['lang1'] as String;
              final targetLang = pair['lang2'] as String;
              final count = pair['count'] as int;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 2,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.menu_book,
                      color: Theme.of(context)
                          .colorScheme
                          .onPrimaryContainer,
                    ),
                  ),
                  title: Text(
                    '${_langName(sourceLang)} ↔ ${_langName(targetLang)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Text(
                    '$count kelime',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 13,
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DefterDetailScreen(
                          sourceLang: sourceLang,
                          targetLang: targetLang,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
