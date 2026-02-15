import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/word_provider.dart';
import '../widgets/word_card.dart';

class DefterDetailScreen extends StatefulWidget {
  final String sourceLang;
  final String targetLang;

  const DefterDetailScreen({
    super.key,
    required this.sourceLang,
    required this.targetLang,
  });

  @override
  State<DefterDetailScreen> createState() => _DefterDetailScreenState();
}

class _DefterDetailScreenState extends State<DefterDetailScreen> {
  final _searchController = TextEditingController();
  bool _isSearching = false;

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
  void dispose() {
    // Clear search when leaving
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) return;
    });
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Kelime ara...',
                  border: InputBorder.none,
                ),
                onChanged: (query) {
                  context.read<WordProvider>().searchWords(query);
                },
              )
            : Text('${_langName(widget.sourceLang)} ↔ ${_langName(widget.targetLang)}'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  context.read<WordProvider>().searchWords('');
                }
              });
            },
          ),
        ],
      ),
      body: Consumer<WordProvider>(
        builder: (context, provider, _) {
          final words = provider.getWordsForPair(
            widget.sourceLang,
            widget.targetLang,
          );

          if (words.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.book_outlined, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    _isSearching
                        ? 'Sonuç bulunamadı'
                        : 'Bu defterde kelime yok',
                    style: TextStyle(fontSize: 16, color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  '${words.length} kelime',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: words.length,
                  itemBuilder: (context, index) {
                    final word = words[index];
                    return WordCard(
                      word: word,
                      onDelete: () {
                        if (word.id != null) {
                          provider.deleteWord(word.id!);
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
