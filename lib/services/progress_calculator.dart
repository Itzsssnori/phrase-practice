import '../models/category.dart';
import '../models/phrase.dart';
import '../models/quiz_attempt.dart';

/// Computed overview of phrases learned in a specific target language.
class LanguageProgressSummary {
  final int learnedCount;
  final int totalCount;

  const LanguageProgressSummary({
    required this.learnedCount,
    required this.totalCount,
  });

  double get ratio => totalCount > 0 ? (learnedCount / totalCount).clamp(0.0, 1.0) : 0.0;

  int get percentage => (ratio * 100).round();
}

/// Computed learned-phrase breakdown for a single category in a specific target language.
class CategoryProgressItem {
  final Category category;
  final int learnedCount;
  final int totalCount;

  const CategoryProgressItem({
    required this.category,
    required this.learnedCount,
    required this.totalCount,
  });

  double get ratio => totalCount > 0 ? (learnedCount / totalCount).clamp(0.0, 1.0) : 0.0;
}

/// Computed quiz performance statistics from a bounded list of recent attempts.
class QuizStatsSummary {
  final int quizzesTaken;
  final double averagePercentage;
  final double bestPercentage;
  final List<QuizAttempt> recentAttempts;
  final int windowLimit;

  const QuizStatsSummary({
    required this.quizzesTaken,
    required this.averagePercentage,
    required this.bestPercentage,
    required this.recentAttempts,
    required this.windowLimit,
  });

  int get averagePercentRounded => averagePercentage.round();
  int get bestPercentRounded => bestPercentage.round();
}

/// Pure Dart progress computation utilities backed strictly by real app data.
class ProgressCalculator {
  ProgressCalculator._();

  static const int defaultAttemptWindowLimit = 20;
  static const int defaultDisplayAttemptLimit = 10;

  /// Returns active phrases that have a non-empty translation in [targetLanguageCode].
  static List<Phrase> availablePhrasesForLanguage(
    List<Phrase> allPhrases,
    String targetLanguageCode,
  ) {
    return allPhrases.where((p) {
      if (!p.isActive) return false;
      final trans = p.translationFor(targetLanguageCode);
      return trans != null && trans.text.trim().isNotEmpty;
    }).toList();
  }

  /// Computes overall learned count vs total available phrases for [targetLanguageCode].
  static LanguageProgressSummary computeLanguageProgress({
    required List<Phrase> allPhrases,
    required String targetLanguageCode,
    required bool Function(String phraseId, String targetLanguageCode) isLearned,
  }) {
    final available = availablePhrasesForLanguage(allPhrases, targetLanguageCode);
    int learned = 0;
    for (final phrase in available) {
      if (isLearned(phrase.id, targetLanguageCode)) {
        learned++;
      }
    }
    return LanguageProgressSummary(
      learnedCount: learned,
      totalCount: available.length,
    );
  }

  /// Computes per-category learned counts for [targetLanguageCode].
  static List<CategoryProgressItem> computeCategoryProgress({
    required List<Category> categories,
    required List<Phrase> allPhrases,
    required String targetLanguageCode,
    required bool Function(String phraseId, String targetLanguageCode) isLearned,
  }) {
    final available = availablePhrasesForLanguage(allPhrases, targetLanguageCode);

    final totalByCategory = <String, int>{};
    final learnedByCategory = <String, int>{};

    for (final phrase in available) {
      totalByCategory[phrase.categoryId] = (totalByCategory[phrase.categoryId] ?? 0) + 1;
      if (isLearned(phrase.id, targetLanguageCode)) {
        learnedByCategory[phrase.categoryId] = (learnedByCategory[phrase.categoryId] ?? 0) + 1;
      }
    }

    return categories.map((cat) {
      return CategoryProgressItem(
        category: cat,
        learnedCount: learnedByCategory[cat.id] ?? 0,
        totalCount: totalByCategory[cat.id] ?? 0,
      );
    }).toList();
  }

  /// Computes quiz stats from up to [windowLimit] most recent attempts,
  /// returning at most [maxDisplay] attempts for the list display.
  static QuizStatsSummary computeQuizStats(
    List<QuizAttempt> attempts, {
    int maxDisplay = defaultDisplayAttemptLimit,
    int windowLimit = defaultAttemptWindowLimit,
  }) {
    final bounded = attempts.length > windowLimit
        ? attempts.take(windowLimit).toList()
        : List<QuizAttempt>.from(attempts);

    if (bounded.isEmpty) {
      return QuizStatsSummary(
        quizzesTaken: 0,
        averagePercentage: 0.0,
        bestPercentage: 0.0,
        recentAttempts: const [],
        windowLimit: windowLimit,
      );
    }

    double sumPct = 0.0;
    double bestPct = 0.0;

    for (final attempt in bounded) {
      final pct = attempt.total > 0 ? (attempt.score / attempt.total) * 100.0 : 0.0;
      sumPct += pct;
      if (pct > bestPct) {
        bestPct = pct;
      }
    }

    final avgPct = sumPct / bounded.length;
    final displayList = bounded.length > maxDisplay
        ? bounded.take(maxDisplay).toList()
        : bounded;

    return QuizStatsSummary(
      quizzesTaken: bounded.length,
      averagePercentage: avgPct,
      bestPercentage: bestPct,
      recentAttempts: List.unmodifiable(displayList),
      windowLimit: windowLimit,
    );
  }
}
