import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/word_provider.dart';
import '../widgets/word_card.dart';

class WordListScreen extends StatefulWidget {
  const WordListScreen({super.key});

  @override
  State<WordListScreen> createState() => _WordListScreenState();
}

class _WordListScreenState extends State<WordListScreen> {
  final _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void dispose() {
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
            : const Text('Kelime Defterim'),
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
          final words = provider.words;

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
                        : 'Henüz kelime eklemediniz',
                    style: TextStyle(fontSize: 16, color: Colors.grey[500]),
                  ),
                  if (!_isSearching) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Ana sayfadan kelime çevirip kaydedin',
                      style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                    ),
                  ],
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
