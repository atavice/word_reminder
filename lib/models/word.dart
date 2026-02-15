class Word {
  final int? id;
  final String sourceWord;
  final String translatedWord;
  final String sourceLang;
  final String targetLang;
  final DateTime createdAt;
  final int reviewCount;

  Word({
    this.id,
    required this.sourceWord,
    required this.translatedWord,
    this.sourceLang = 'en',
    this.targetLang = 'tr',
    DateTime? createdAt,
    this.reviewCount = 0,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sourceWord': sourceWord,
      'translatedWord': translatedWord,
      'sourceLang': sourceLang,
      'targetLang': targetLang,
      'createdAt': createdAt.toIso8601String(),
      'reviewCount': reviewCount,
    };
  }

  factory Word.fromMap(Map<String, dynamic> map) {
    return Word(
      id: map['id'] as int?,
      sourceWord: map['sourceWord'] as String,
      translatedWord: map['translatedWord'] as String,
      sourceLang: map['sourceLang'] as String,
      targetLang: map['targetLang'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      reviewCount: map['reviewCount'] as int? ?? 0,
    );
  }

  Word copyWith({
    int? id,
    String? sourceWord,
    String? translatedWord,
    String? sourceLang,
    String? targetLang,
    DateTime? createdAt,
    int? reviewCount,
  }) {
    return Word(
      id: id ?? this.id,
      sourceWord: sourceWord ?? this.sourceWord,
      translatedWord: translatedWord ?? this.translatedWord,
      sourceLang: sourceLang ?? this.sourceLang,
      targetLang: targetLang ?? this.targetLang,
      createdAt: createdAt ?? this.createdAt,
      reviewCount: reviewCount ?? this.reviewCount,
    );
  }
}
