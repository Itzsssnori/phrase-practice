import 'dart:math';
import '../models/phrase.dart';
import '../models/quiz.dart';

/// Pure Dart utility for assembling randomized, multi-choice recall quizzes
/// from in-memory cached phrases.
class QuizGenerator {
  /// Filters phrases that have valid, active translations in both
  /// [nativeLanguageCode] and [targetLanguageCode].
  static List<Phrase> getEligiblePhrases(
    List<Phrase> phrases, {
    required String nativeLanguageCode,
    required String targetLanguageCode,
    String? categoryId,
  }) {
    return phrases.where((p) {
      if (!p.isActive) return false;
      if (categoryId != null && categoryId != 'all' && p.categoryId != categoryId) {
        return false;
      }
      final nativeTrans = p.translationFor(nativeLanguageCode);
      final targetTrans = p.translationFor(targetLanguageCode);
      if (nativeTrans == null || nativeTrans.text.trim().isEmpty) return false;
      if (targetTrans == null || targetTrans.text.trim().isEmpty) return false;
      return true;
    }).toList();
  }

  /// Generates a randomized quiz question list.
  ///
  /// - Questions are capped at the number of available eligible phrases.
  /// - Each phrase appears at most once as a question.
  /// - 3 unique distractors per question are drawn from the same category first,
  ///   falling back to other categories as needed.
  /// - Uses [random] for deterministic, testable shuffling.
  static List<QuizQuestion> generateQuestions({
    required List<Phrase> allPhrases,
    required String nativeLanguageCode,
    required String targetLanguageCode,
    String? categoryId,
    int questionCount = 5,
    QuizDirection direction = QuizDirection.nativeToTarget,
    Random? random,
    List<String>? specificPhraseIds,
  }) {
    final rnd = random ?? Random();

    // 1. Determine all eligible phrases across the entire dataset
    final allEligible = getEligiblePhrases(
      allPhrases,
      nativeLanguageCode: nativeLanguageCode,
      targetLanguageCode: targetLanguageCode,
    );

    // If total eligible pool across all categories is < 4, cannot form 4 unique options
    if (allEligible.length < 4) {
      return const [];
    }

    // 2. Determine candidate pool for questions (subject to category / specific phrase filters)
    List<Phrase> questionPool;
    if (specificPhraseIds != null && specificPhraseIds.isNotEmpty) {
      final specificSet = specificPhraseIds.toSet();
      questionPool = allEligible.where((p) => specificSet.contains(p.id)).toList();
    } else if (categoryId != null && categoryId != 'all') {
      questionPool = allEligible.where((p) => p.categoryId == categoryId).toList();
    } else {
      questionPool = List<Phrase>.from(allEligible);
    }

    // If question pool is less than 4 (for category-specific or mistake drills with < 4 questions),
    // we still need at least 1 question phrase and at least 3 distractors from allEligible.
    if (questionPool.isEmpty) {
      return const [];
    }

    // 3. Shuffle question pool and take up to questionCount
    final shuffledCandidates = List<Phrase>.from(questionPool)..shuffle(rnd);
    final count = min(questionCount, shuffledCandidates.length);
    final selectedPhrases = shuffledCandidates.take(count).toList();

    final questions = <QuizQuestion>[];

    for (var i = 0; i < selectedPhrases.length; i++) {
      final phrase = selectedPhrases[i];
      final nativeTrans = phrase.translationFor(nativeLanguageCode)!;
      final targetTrans = phrase.translationFor(targetLanguageCode)!;

      // Determine effective question direction
      final effectiveDirection = direction == QuizDirection.mixed
          ? (rnd.nextBool() ? QuizDirection.nativeToTarget : QuizDirection.targetToNative)
          : direction;

      final bool isNativeToTarget = effectiveDirection == QuizDirection.nativeToTarget;
      final promptText = isNativeToTarget
          ? 'Select the translation'
          : 'Select the meaning';
      final originalPhrase = isNativeToTarget ? nativeTrans.text : targetTrans.text;
      final correctAnswer = isNativeToTarget ? targetTrans.text : nativeTrans.text;
      final pronunciation = targetTrans.pronunciation;
      // Explanation should always be in the native language so the user
      // understands the meaning in terms they already know.
      final explanation = (nativeTrans.meaningNote != null && nativeTrans.meaningNote!.isNotEmpty)
          ? nativeTrans.meaningNote!
          : (phrase.contextNote != null && phrase.contextNote!.isNotEmpty)
              ? phrase.contextNote!
              : (isNativeToTarget
                  ? 'Meaning: ${nativeTrans.text}'
                  : 'Translation: ${targetTrans.text}');

      // 4. Gather 3 unique distractors:
      // Category candidates first, then other categories fallback
      final distractors = <String>[];
      final seenTexts = <String>{correctAnswer.trim().toLowerCase()};

      // Helper to extract option text
      String getOptionText(Phrase p) {
        return isNativeToTarget
            ? p.translationFor(targetLanguageCode)?.text ?? ''
            : p.translationFor(nativeLanguageCode)?.text ?? '';
      }

      // Same-category distractors
      final sameCategory = allEligible
          .where((p) => p.categoryId == phrase.categoryId && p.id != phrase.id)
          .toList()
        ..shuffle(rnd);

      for (final candidate in sameCategory) {
        final optText = getOptionText(candidate).trim();
        final lower = optText.toLowerCase();
        if (optText.isNotEmpty && !seenTexts.contains(lower)) {
          seenTexts.add(lower);
          distractors.add(optText);
          if (distractors.length == 3) break;
        }
      }

      // Other-category distractors if needed
      if (distractors.length < 3) {
        final otherCategories = allEligible
            .where((p) => p.categoryId != phrase.categoryId && p.id != phrase.id)
            .toList()
          ..shuffle(rnd);

        for (final candidate in otherCategories) {
          final optText = getOptionText(candidate).trim();
          final lower = optText.toLowerCase();
          if (optText.isNotEmpty && !seenTexts.contains(lower)) {
            seenTexts.add(lower);
            distractors.add(optText);
            if (distractors.length == 3) break;
          }
        }
      }

      // If we still cannot find 3 unique distractors, abort this question
      if (distractors.length < 3) {
        continue;
      }

      final options = [correctAnswer, ...distractors]..shuffle(rnd);
      final correctIndex = options.indexOf(correctAnswer);

      questions.add(
        QuizQuestion(
          id: '${phrase.id}_$i',
          phrase: phrase,
          prompt: promptText,
          originalPhrase: originalPhrase,
          options: options,
          correctIndex: correctIndex,
          explanation: explanation,
          pronunciation: pronunciation,
          direction: effectiveDirection,
          targetLanguageCode: targetLanguageCode,
          nativeLanguageCode: nativeLanguageCode,
        ),
      );
    }

    return questions;
  }
}
