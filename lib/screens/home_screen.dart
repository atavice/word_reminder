import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/word_provider.dart';
import 'word_list_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  String? _currentSourceWord;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _translate() async {
    final text = _searchController.text.trim();
    if (text.isEmpty) return;

    FocusScope.of(context).unfocus();
    _currentSourceWord = text;
    await context.read<WordProvider>().translate(text);
  }

  Future<void> _saveWord() async {
    final provider = context.read<WordProvider>();
    if (_currentSourceWord == null || provider.translationResult == null) return;

    await provider.addWord(_currentSourceWord!, provider.translationResult!);
    provider.clearTranslation();
    _searchController.clear();
    _currentSourceWord = null;

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kelime kaydedildi!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WordReminder'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.list),
            tooltip: 'Kelime Listem',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const WordListScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Ayarlar',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Language selector row
            Consumer<WordProvider>(
              builder: (context, provider, _) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _LanguageChip(
                      label: _langDisplayName(provider.sourceLang),
                      onTap: () => _showLangPicker(context, isSource: true),
                    ),
                    IconButton(
                      icon: const Icon(Icons.swap_horiz, size: 28),
                      onPressed: provider.swapLanguages,
                    ),
                    _LanguageChip(
                      label: _langDisplayName(provider.targetLang),
                      onTap: () => _showLangPicker(context, isSource: false),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),

            // Search bar
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Çevirmek istediğiniz kelimeyi yazın...',
                prefixIcon: const Icon(Icons.translate),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _translate,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              ),
              onSubmitted: (_) => _translate(),
              textInputAction: TextInputAction.search,
            ),
            const SizedBox(height: 24),

            // Translation result
            Consumer<WordProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return const Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  );
                }

                if (provider.translationResult == null) {
                  return Expanded(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.translate,
                            size: 80,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Bir kelime yazıp çevirin',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return _TranslationResultCard(
                  sourceWord: _currentSourceWord ?? '',
                  translatedWord: provider.translationResult!,
                  onSave: _saveWord,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _langDisplayName(String code) {
    const names = {
      'en': 'English',
      'tr': 'Türkçe',
      'de': 'Deutsch',
      'fr': 'Français',
      'es': 'Español',
      'it': 'Italiano',
      'pt': 'Português',
      'ru': 'Русский',
      'ja': '日本語',
      'ko': '한국어',
      'zh': '中文',
      'ar': 'العربية',
    };
    return names[code] ?? code;
  }

  void _showLangPicker(BuildContext context, {required bool isSource}) {
    final provider = context.read<WordProvider>();
    final langs = ['en', 'tr', 'de', 'fr', 'es', 'it', 'pt', 'ru', 'ja', 'ko', 'zh', 'ar'];

    showModalBottomSheet(
      context: context,
      builder: (ctx) => ListView(
        shrinkWrap: true,
        children: langs.map((code) {
          return ListTile(
            title: Text(_langDisplayName(code)),
            trailing: Text(code.toUpperCase()),
            onTap: () {
              if (isSource) {
                provider.setSourceLang(code);
              } else {
                provider.setTargetLang(code);
              }
              Navigator.pop(ctx);
            },
          );
        }).toList(),
      ),
    );
  }
}

class _LanguageChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _LanguageChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
      ),
    );
  }
}

class _TranslationResultCard extends StatelessWidget {
  final String sourceWord;
  final String translatedWord;
  final VoidCallback onSave;

  const _TranslationResultCard({
    required this.sourceWord,
    required this.translatedWord,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              sourceWord,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            const Icon(Icons.arrow_downward, color: Colors.grey),
            const SizedBox(height: 8),
            Text(
              translatedWord,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onSave,
                icon: const Icon(Icons.bookmark_add),
                label: const Text('Kaydet'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
