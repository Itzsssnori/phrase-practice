import 'package:cloud_firestore/cloud_firestore.dart';

/// Single question answer record in a completed quiz attempt.
class QuizAnswerRecord {
  final String phraseId;
  final bool wasCorrect;

  const QuizAnswerRecord({
    required this.phraseId,
    required this.wasCorrect,
  });

  factory QuizAnswerRecord.fromMap(Map<String, dynamic> map) {
    return QuizAnswerRecord(
      phraseId: (map['phraseId'] as String?)?.trim() ?? '',
      wasCorrect: (map['wasCorrect'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'phraseId': phraseId,
      'wasCorrect': wasCorrect,
    };
  }

  @override
  String toString() => 'QuizAnswerRecord(phraseId: $phraseId, wasCorrect: $wasCorrect)';
}

/// Domain model representing a user's logged quiz round attempt.
class QuizAttempt {
  final String id;
  final String targetLanguageCode;
  final String? categoryId;
  final int score;
  final int total;
  final DateTime takenAt;
  final List<QuizAnswerRecord> answers;

  const QuizAttempt({
    required this.id,
    required this.targetLanguageCode,
    this.categoryId,
    required this.score,
    required this.total,
    required this.takenAt,
    this.answers = const [],
  });

  double get accuracy => total > 0 ? (score / total) * 100 : 0.0;

  factory QuizAttempt.fromMap(String id, Map<String, dynamic> map) {
    DateTime parsedTakenAt = DateTime.now();
    final rawTakenAt = map['takenAt'];
    if (rawTakenAt is Timestamp) {
      parsedTakenAt = rawTakenAt.toDate();
    } else if (rawTakenAt is String) {
      parsedTakenAt = DateTime.tryParse(rawTakenAt) ?? DateTime.now();
    }

    final rawAnswers = map['answers'] as List<dynamic>? ?? [];
    final parsedAnswers = rawAnswers
        .whereType<Map<String, dynamic>>()
        .map((a) => QuizAnswerRecord.fromMap(a))
        .toList();

    return QuizAttempt(
      id: id,
      targetLanguageCode: (map['targetLanguageCode'] as String?)?.trim() ?? 'en',
      categoryId: (map['categoryId'] as String?)?.trim(),
      score: (map['score'] as num?)?.toInt() ?? 0,
      total: (map['total'] as num?)?.toInt() ?? 0,
      takenAt: parsedTakenAt,
      answers: parsedAnswers,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'targetLanguageCode': targetLanguageCode,
      'categoryId': categoryId,
      'score': score,
      'total': total,
      'takenAt': Timestamp.fromDate(takenAt),
      'answers': answers.map((a) => a.toMap()).toList(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is QuizAttempt && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'QuizAttempt($id, score: $score/$total, target: $targetLanguageCode)';
}
