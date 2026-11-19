import 'phrase_translation.dart';

/// Phrase domain entity representing a multi-language study phrase.
class Phrase {
  final String id;
  final String categoryId;
  final int difficulty;
  final int sortOrder;
  final bool isActive;
  final Map<String, PhraseTranslation> translations;
  final bool isFavorite;

  // Backwards compatibility legacy fields for existing UI/mock services
  final String? _legacyOriginalText;
  final String? _legacyTranslatedText;
  final String? _legacyPhonetic;
  final String? _legacyContextNote;

  const Phrase({
    required this.id,
    required this.categoryId,
    this.difficulty = 1,
    this.sortOrder = 0,
    this.isActive = true,
    this.translations = const {},
    this.isFavorite = false,
    String? originalText,
    String? translatedText,
    String? phonetic,
    String? contextNote,
  })  : _legacyOriginalText = originalText,
        _legacyTranslatedText = translatedText,
        _legacyPhonetic = phonetic,
        _legacyContextNote = contextNote;

  /// Helper to get translation details for a specific language code.
  PhraseTranslation? translationFor(String languageCode) => translations[languageCode];

  /// Synonym helper for [translationFor].
  PhraseTranslation? getTranslation(String languageCode) => translations[languageCode];

  /// Backward-compatible getter for English or primary source phrase.
  String get originalText {
    final legacy = _legacyOriginalText;
    if (legacy != null && legacy.isNotEmpty) {
      return legacy;
    }
    return translationFor('en')?.text ?? (translations.isNotEmpty ? translations.values.first.text : '');
  }

  /// Backward-compatible getter for target translated phrase.
  String get translatedText {
    final legacy = _legacyTranslatedText;
    if (legacy != null && legacy.isNotEmpty) {
      return legacy;
    }
    return translationFor('es')?.text ??
        translationFor('fil')?.text ??
        (translations.isNotEmpty ? translations.values.first.text : '');
  }

  /// Backward-compatible getter for phonetic pronunciation.
  String? get phonetic {
    if (_legacyPhonetic != null) return _legacyPhonetic;
    return translationFor('es')?.pronunciation ?? translationFor('fil')?.pronunciation;
  }

  /// Backward-compatible getter for meaning note.
  String? get contextNote {
    if (_legacyContextNote != null) return _legacyContextNote;
    return translationFor('es')?.meaningNote ?? translationFor('en')?.meaningNote;
  }

  factory Phrase.fromMap(String id, Map<String, dynamic> map, {bool isFavorite = false}) {
    final rawTranslations = map['translations'] as Map<String, dynamic>? ?? {};
    final parsedTranslations = <String, PhraseTranslation>{};

    rawTranslations.forEach((code, data) {
      if (data is Map<String, dynamic>) {
        parsedTranslations[code] = PhraseTranslation.fromMap(data);
      }
    });

    return Phrase(
      id: id,
      categoryId: (map['categoryId'] as String?)?.trim() ?? '',
      difficulty: (map['difficulty'] as num?)?.toInt() ?? 1,
      sortOrder: (map['sortOrder'] as num?)?.toInt() ?? 0,
      isActive: (map['isActive'] as bool?) ?? true,
      translations: parsedTranslations,
      isFavorite: isFavorite,
    );
  }

  Map<String, dynamic> toMap() {
    final transMap = <String, dynamic>{};
    translations.forEach((key, val) {
      transMap[key] = val.toMap();
    });

    return {
      'categoryId': categoryId,
      'difficulty': difficulty,
      'sortOrder': sortOrder,
      'isActive': isActive,
      'translations': transMap,
    };
  }

  Phrase copyWith({
    String? id,
    String? categoryId,
    int? difficulty,
    int? sortOrder,
    bool? isActive,
    Map<String, PhraseTranslation>? translations,
    bool? isFavorite,
    String? originalText,
    String? translatedText,
    String? phonetic,
    String? contextNote,
  }) {
    return Phrase(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      difficulty: difficulty ?? this.difficulty,
      sortOrder: sortOrder ?? this.sortOrder,
      isActive: isActive ?? this.isActive,
      translations: translations ?? this.translations,
      isFavorite: isFavorite ?? this.isFavorite,
      originalText: originalText ?? _legacyOriginalText,
      translatedText: translatedText ?? _legacyTranslatedText,
      phonetic: phonetic ?? _legacyPhonetic,
      contextNote: contextNote ?? _legacyContextNote,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Phrase && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Phrase($id: "$originalText" -> "$translatedText", category: $categoryId)';
}
