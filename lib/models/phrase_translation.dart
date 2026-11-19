/// Single language translation unit for a phrase document.
class PhraseTranslation {
  final String text;
  final String? pronunciation;
  final String? meaningNote;
  final String? exampleSentence;
  final bool verified;

  const PhraseTranslation({
    required this.text,
    this.pronunciation,
    this.meaningNote,
    this.exampleSentence,
    this.verified = false,
  });

  factory PhraseTranslation.fromMap(Map<String, dynamic> map) {
    return PhraseTranslation(
      text: (map['text'] as String?)?.trim() ?? '',
      pronunciation: (map['pronunciation'] as String?)?.trim(),
      meaningNote: (map['meaningNote'] as String?)?.trim(),
      exampleSentence: (map['exampleSentence'] as String?)?.trim(),
      verified: (map['verified'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'pronunciation': pronunciation,
      'meaningNote': meaningNote,
      'exampleSentence': exampleSentence,
      'verified': verified,
    };
  }

  PhraseTranslation copyWith({
    String? text,
    String? pronunciation,
    String? meaningNote,
    String? exampleSentence,
    bool? verified,
  }) {
    return PhraseTranslation(
      text: text ?? this.text,
      pronunciation: pronunciation ?? this.pronunciation,
      meaningNote: meaningNote ?? this.meaningNote,
      exampleSentence: exampleSentence ?? this.exampleSentence,
      verified: verified ?? this.verified,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PhraseTranslation &&
          runtimeType == other.runtimeType &&
          text == other.text &&
          pronunciation == other.pronunciation &&
          meaningNote == other.meaningNote &&
          exampleSentence == other.exampleSentence &&
          verified == other.verified;

  @override
  int get hashCode => Object.hash(text, pronunciation, meaningNote, exampleSentence, verified);

  @override
  String toString() => 'PhraseTranslation(text: "$text", verified: $verified)';
}
