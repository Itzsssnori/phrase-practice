export 'quiz_attempt.dart';

import 'phrase.dart';

/// Direction of question recall drills.
enum QuizDirection {
  /// Prompt is shown in native language, user picks target language translation.
  nativeToTarget,

  /// Prompt is shown in target language, user picks native language translation.
  targetToNative,

  /// Mix of both directions.
  mixed,
}

/// Question model for practice quizzes with rich phrase context.
class QuizQuestion {
  final String id;
  final Phrase? _rawPhrase;
  final String prompt;
  final String originalPhrase;
  final List<String> options;
  final int correctIndex;
  final String explanation;
  final String? pronunciation;
  final QuizDirection direction;
  final String targetLanguageCode;
  final String nativeLanguageCode;

  const QuizQuestion({
    required this.id,
    Phrase? phrase,
    required this.prompt,
    required this.originalPhrase,
    required this.options,
    required this.correctIndex,
    required this.explanation,
    this.pronunciation,
    this.direction = QuizDirection.nativeToTarget,
    this.targetLanguageCode = 'es',
    this.nativeLanguageCode = 'en',
  }) : _rawPhrase = phrase;

  Phrase get phrase =>
      _rawPhrase ??
      Phrase(
        id: id,
        categoryId: 'general',
        originalText: originalPhrase,
        translatedText: correctAnswer,
        isActive: true,
      );

  String get correctAnswer =>
      (correctIndex >= 0 && correctIndex < options.length) ? options[correctIndex] : '';
}

/// Record of an incorrect response during a quiz round.
class QuizMistake {
  final QuizQuestion question;
  final int selectedIndex;
  final String selectedAnswer;

  const QuizMistake({
    required this.question,
    required this.selectedIndex,
    required this.selectedAnswer,
  });

  String get correctAnswer => question.correctAnswer;
  Phrase get phrase => question.phrase;
}

/// Result summary of a completed quiz session.
class QuizResult {
  final int totalQuestions;
  final int correctAnswers;
  final List<QuizMistake> mistakes;
  final String targetLanguageCode;
  final String? categoryId;

  const QuizResult({
    required this.totalQuestions,
    required this.correctAnswers,
    this.mistakes = const [],
    this.targetLanguageCode = 'es',
    this.categoryId,
  });

  double get scorePercentage =>
      totalQuestions > 0 ? (correctAnswers / totalQuestions) * 100 : 0.0;

  List<QuizQuestion> get mistakeQuestions =>
      mistakes.map((m) => m.question).toList();
}
