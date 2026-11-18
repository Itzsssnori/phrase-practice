/// Phrase model representing a study phrase with translation and context.
class Phrase {
  final String id;
  final String originalText;
  final String translatedText;
  final String? phonetic;
  final String? contextNote;
  final String categoryId;
  final bool isFavorite;

  const Phrase({
    required this.id,
    required this.originalText,
    required this.translatedText,
    this.phonetic,
    this.contextNote,
    required this.categoryId,
    this.isFavorite = false,
  });

  Phrase copyWith({
    String? id,
    String? originalText,
    String? translatedText,
    String? phonetic,
    String? contextNote,
    String? categoryId,
    bool? isFavorite,
  }) {
    return Phrase(
      id: id ?? this.id,
      originalText: originalText ?? this.originalText,
      translatedText: translatedText ?? this.translatedText,
      phonetic: phonetic ?? this.phonetic,
      contextNote: contextNote ?? this.contextNote,
      categoryId: categoryId ?? this.categoryId,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}
