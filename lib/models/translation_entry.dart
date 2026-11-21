import 'package:cloud_firestore/cloud_firestore.dart';

/// Structured outcome status returned by the AI translator.
enum TranslationStatus {
  ok,
  notAPhrase,
  unsupported,
}

/// Immutable result of an AI translation or history lookup.
///
/// Stores the language pair with the result so changing app languages later
/// never corrupts the displayed labels.
class TranslationResult {
  final TranslationStatus status;
  final String inputText;
  final String sourceLanguageCode;
  final String targetLanguageCode;
  final String sourceLanguageName;
  final String targetLanguageName;
  final String translatedText;
  final String pronunciation;
  final String exampleSentence;
  final String exampleTranslation;
  final String note;
  final bool fromHistory;

  const TranslationResult({
    required this.status,
    required this.inputText,
    required this.sourceLanguageCode,
    required this.targetLanguageCode,
    required this.sourceLanguageName,
    required this.targetLanguageName,
    this.translatedText = '',
    this.pronunciation = '',
    this.exampleSentence = '',
    this.exampleTranslation = '',
    this.note = '',
    this.fromHistory = false,
  });

  bool get isOk => status == TranslationStatus.ok;
}

/// Persisted translation history document at `users/{uid}/translationHistory/{id}`.
class TranslationHistoryItem {
  final String id;
  final String inputText;
  final String sourceLanguageCode;
  final String targetLanguageCode;
  final String translatedText;
  final String pronunciation;
  final String exampleSentence;
  final String exampleTranslation;
  final String note;
  final bool isSaved;
  final DateTime createdAt;

  const TranslationHistoryItem({
    required this.id,
    required this.inputText,
    required this.sourceLanguageCode,
    required this.targetLanguageCode,
    required this.translatedText,
    this.pronunciation = '',
    this.exampleSentence = '',
    this.exampleTranslation = '',
    this.note = '',
    this.isSaved = false,
    required this.createdAt,
  });

  TranslationHistoryItem copyWith({
    String? id,
    bool? isSaved,
  }) {
    return TranslationHistoryItem(
      id: id ?? this.id,
      inputText: inputText,
      sourceLanguageCode: sourceLanguageCode,
      targetLanguageCode: targetLanguageCode,
      translatedText: translatedText,
      pronunciation: pronunciation,
      exampleSentence: exampleSentence,
      exampleTranslation: exampleTranslation,
      note: note,
      isSaved: isSaved ?? this.isSaved,
      createdAt: createdAt,
    );
  }

  /// Exact Firestore create payload containing ONLY the allowed fields.
  static Map<String, dynamic> toCreatePayload(TranslationResult result) {
    return <String, dynamic>{
      'inputText': result.inputText,
      'sourceLanguageCode': result.sourceLanguageCode,
      'targetLanguageCode': result.targetLanguageCode,
      'translatedText': result.translatedText,
      'pronunciation': result.pronunciation,
      'exampleSentence': result.exampleSentence,
      'exampleTranslation': result.exampleTranslation,
      'note': result.note,
      'isSaved': false,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  factory TranslationHistoryItem.fromMap(String id, Map<String, dynamic> map) {
    DateTime createdAt = DateTime.now();
    final rawCreatedAt = map['createdAt'];
    if (rawCreatedAt is Timestamp) {
      createdAt = rawCreatedAt.toDate();
    } else if (rawCreatedAt is DateTime) {
      createdAt = rawCreatedAt;
    } else if (rawCreatedAt is String) {
      createdAt = DateTime.tryParse(rawCreatedAt) ?? DateTime.now();
    }

    return TranslationHistoryItem(
      id: id,
      inputText: (map['inputText'] as String?) ?? '',
      sourceLanguageCode: (map['sourceLanguageCode'] as String?) ?? 'en',
      targetLanguageCode: (map['targetLanguageCode'] as String?) ?? 'es',
      translatedText: (map['translatedText'] as String?) ?? '',
      pronunciation: (map['pronunciation'] as String?) ?? '',
      exampleSentence: (map['exampleSentence'] as String?) ?? '',
      exampleTranslation: (map['exampleTranslation'] as String?) ?? '',
      note: (map['note'] as String?) ?? '',
      isSaved: (map['isSaved'] as bool?) ?? false,
      createdAt: createdAt,
    );
  }

  TranslationResult toTranslationResult({
    required String sourceLanguageName,
    required String targetLanguageName,
    bool fromHistory = true,
  }) {
    return TranslationResult(
      status: TranslationStatus.ok,
      inputText: inputText,
      sourceLanguageCode: sourceLanguageCode,
      targetLanguageCode: targetLanguageCode,
      sourceLanguageName: sourceLanguageName,
      targetLanguageName: targetLanguageName,
      translatedText: translatedText,
      pronunciation: pronunciation,
      exampleSentence: exampleSentence,
      exampleTranslation: exampleTranslation,
      note: note,
      fromHistory: fromHistory,
    );
  }
}
