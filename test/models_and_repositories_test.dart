import 'package:flutter_test/flutter_test.dart';
import 'package:phrase_practice/models/category.dart';
import 'package:phrase_practice/models/language.dart';
import 'package:phrase_practice/models/phrase.dart';
import 'package:phrase_practice/models/quiz_attempt.dart';
import 'package:phrase_practice/models/result.dart';
import 'package:phrase_practice/models/user_profile.dart';

void main() {
  group('Language Model', () {
    test('fromMap and toMap work correctly', () {
      final map = {
        'name': 'Spanish',
        'nativeName': 'Español',
        'script': 'Latin',
        'isActive': true,
      };

      final lang = Language.fromMap('es', map);
      expect(lang.code, 'es');
      expect(lang.name, 'Spanish');
      expect(lang.nativeName, 'Español');
      expect(lang.flag, '🇪🇸');
      expect(lang.isActive, true);

      final outMap = lang.toMap();
      expect(outMap['name'], 'Spanish');
      expect(outMap['script'], 'Latin');
    });

    test('defaultFlagFor falls back sensibly', () {
      expect(Language.defaultFlagFor('fil'), '🇵🇭');
      expect(Language.defaultFlagFor('en'), '🇺🇸');
      expect(Language.defaultFlagFor('xx'), '🌐');
    });
  });

  group('Category Model', () {
    test('fromMap parses multilingual names map', () {
      final map = {
        'sortOrder': 2,
        'iconKey': 'food',
        'isActive': true,
        'names': {
          'en': 'Food and Dining',
          'es': 'Comida y Restaurantes',
          'fil': 'Pagkain at Kainan',
        },
      };

      final cat = Category.fromMap('food', map, 'fil');
      expect(cat.id, 'food');
      expect(cat.sortOrder, 2);
      expect(cat.nameFor('es'), 'Comida y Restaurantes');
      expect(cat.nameFor('fil'), 'Pagkain at Kainan');
      expect(cat.title, 'Pagkain at Kainan');
    });
  });

  group('Phrase and PhraseTranslation Models', () {
    test('Phrase handles multi-language translations and fallback getters', () {
      final phrase = Phrase.fromMap('where-is-the-bathroom', {
        'categoryId': 'directions',
        'difficulty': 1,
        'sortOrder': 1,
        'isActive': true,
        'translations': {
          'en': {
            'text': 'Where is the bathroom?',
            'pronunciation': null,
            'meaningNote': 'Essential question',
            'exampleSentence': 'Excuse me, where is the bathroom?',
            'verified': false,
          },
          'es': {
            'text': '¿Dónde está el baño?',
            'pronunciation': 'DOHN-deh ehs-TAH ehl BAHN-yoh',
            'meaningNote': 'En España también el aseo',
            'exampleSentence': 'Disculpe, ¿dónde está el baño?',
            'verified': false,
          },
          'fil': {
            'text': 'Saan po ang banyo?',
            'pronunciation': 'sah-AHN poh ahng BAHN-yoh',
            'meaningNote': 'Banyo o CR',
            'exampleSentence': 'Mawalang-galang na po, saan po ang banyo?',
            'verified': false,
          },
        },
      });

      expect(phrase.id, 'where-is-the-bathroom');
      expect(phrase.translationFor('fil')?.text, 'Saan po ang banyo?');
      expect(phrase.translationFor('es')?.pronunciation, 'DOHN-deh ehs-TAH ehl BAHN-yoh');
      expect(phrase.originalText, 'Where is the bathroom?');
      expect(phrase.translatedText, '¿Dónde está el baño?');

      final serialized = phrase.toMap();
      expect(serialized['categoryId'], 'directions');
      expect((serialized['translations'] as Map)['fil']['text'], 'Saan po ang banyo?');
    });
  });

  group('UserProfile Model', () {
    test('UserProfile handles defaults and mapping', () {
      final profile = UserProfile.fromMap('user123', {
        'displayName': 'Maria',
        'nativeLanguageCode': 'en',
        'targetLanguageCode': 'fil',
        'preferences': {'recallMode': true},
      });

      expect(profile.uid, 'user123');
      expect(profile.displayName, 'Maria');
      expect(profile.targetLanguageCode, 'fil');
      expect(profile.preferences['recallMode'], true);
    });
  });

  group('QuizAttempt Model', () {
    test('QuizAttempt parses answers and computes accuracy', () {
      final attempt = QuizAttempt.fromMap('attempt_1', {
        'targetLanguageCode': 'es',
        'categoryId': 'food',
        'score': 8,
        'total': 10,
        'takenAt': DateTime.now().toIso8601String(),
        'answers': [
          {'phraseId': 'a-table-for-two-please', 'wasCorrect': true},
          {'phraseId': 'the-check-please', 'wasCorrect': false},
        ],
      });

      expect(attempt.score, 8);
      expect(attempt.total, 10);
      expect(attempt.accuracy, 80.0);
      expect(attempt.answers.length, 2);
      expect(attempt.answers.first.phraseId, 'a-table-for-two-please');
      expect(attempt.answers.first.wasCorrect, true);
    });
  });

  group('RepoResult Type', () {
    test('discriminates states properly', () {
      const success = RepoResult.success('sample_data');
      expect(success.isSuccess, true);
      expect(success.dataOrNull, 'sample_data');

      const empty = RepoResult<String>.empty('Nothing here');
      expect(empty.isEmpty, true);
      expect(empty.dataOrNull, null);

      const error = RepoResult<String>.error('Boom');
      expect(error.isError, true);
      expect(error.errorMessageOrNull, 'Boom');
    });
  });
}
