import 'package:flutter_test/flutter_test.dart';
import 'package:phrase_practice/models/category.dart';
import 'package:phrase_practice/models/language.dart';
import 'package:phrase_practice/models/phrase.dart';
import 'package:phrase_practice/models/phrase_translation.dart';
import 'package:phrase_practice/models/result.dart';
import 'package:phrase_practice/services/browse_data_service.dart';
import 'package:phrase_practice/services/category_repository.dart';
import 'package:phrase_practice/services/language_repository.dart';
import 'package:phrase_practice/services/language_settings_controller.dart';
import 'package:phrase_practice/services/phrase_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Mock repository implementations for isolated deterministic unit tests
class MockLanguageRepository implements LanguageRepository {
  final List<Language> languages;
  MockLanguageRepository(this.languages);

  @override
  Future<RepoResult<List<Language>>> getActiveLanguages({bool forceRefresh = false}) async {
    return RepoResult.success(languages);
  }
}

class MockCategoryRepository implements CategoryRepository {
  final List<Category> categories;
  MockCategoryRepository(this.categories);

  @override
  Future<RepoResult<List<Category>>> getCategories(String languageCode, {bool forceRefresh = false}) async {
    return RepoResult.success(categories);
  }
}

class MockPhraseRepository implements PhraseRepository {
  final List<Phrase> phrases;
  MockPhraseRepository(this.phrases);

  @override
  Future<RepoResult<List<Phrase>>> getAllPhrases() async {
    return RepoResult.success(phrases);
  }

  @override
  Future<RepoResult<List<Phrase>>> getPhrasesByCategory(String categoryId) async {
    final matches = phrases.where((p) => p.categoryId == categoryId && p.isActive).toList();
    matches.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return RepoResult.success(matches);
  }

  @override
  Future<RepoResult<Phrase>> getPhraseById(String id) async {
    final phrase = phrases.where((p) => p.id == id).firstOrNull;
    if (phrase != null) return RepoResult.success(phrase);
    return RepoResult.empty('Not found');
  }

  @override
  Future<RepoResult<List<Phrase>>> searchPhrases(String query, String languageCode) async {
    return RepoResult.success(phrases);
  }

  @override
  void invalidateSearchCache() {}
}

void main() {
  group('LanguageSettingsController', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('defaults to English as native and Spanish as target on first launch', () async {
      final controller = LanguageSettingsController();
      await controller.load();

      expect(controller.nativeLanguageCode, 'en');
      expect(controller.targetLanguageCode, 'es');
      expect(controller.hasOnboarded, false);
    });

    test('persists language selection across reloads', () async {
      SharedPreferences.setMockInitialValues({
        LanguageSettingsController.keyNativeLanguage: 'fil',
        LanguageSettingsController.keyTargetLanguage: 'en',
        LanguageSettingsController.keyHasOnboarded: true,
      });

      final controller = LanguageSettingsController();
      await controller.load();

      expect(controller.nativeLanguageCode, 'fil');
      expect(controller.targetLanguageCode, 'en');
      expect(controller.hasOnboarded, true);
    });

    test('same-language selection automatically swaps languages', () async {
      final controller = LanguageSettingsController();
      await controller.load();
      // Initially: native = 'en', target = 'es'

      // Selecting 'es' for native (which is current target) must swap them
      await controller.setNativeLanguage('es');
      expect(controller.nativeLanguageCode, 'es');
      expect(controller.targetLanguageCode, 'en');

      // Selecting 'es' for target (which is current native) must swap them back
      await controller.setTargetLanguage('es');
      expect(controller.nativeLanguageCode, 'en');
      expect(controller.targetLanguageCode, 'es');
    });

    test('setLanguagePair prevents identical languages', () async {
      final controller = LanguageSettingsController();
      await controller.load();

      await controller.setLanguagePair(nativeCode: 'es', targetCode: 'es');
      expect(controller.nativeLanguageCode != controller.targetLanguageCode, true);
    });

    test('swapLanguages inverts the pair', () async {
      final controller = LanguageSettingsController();
      await controller.load();

      await controller.swapLanguages();
      expect(controller.nativeLanguageCode, 'es');
      expect(controller.targetLanguageCode, 'en');
    });

    test('completeOnboarding marks hasOnboarded as true and persists it', () async {
      final controller = LanguageSettingsController();
      await controller.load();
      expect(controller.hasOnboarded, false);

      await controller.completeOnboarding();
      expect(controller.hasOnboarded, true);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(LanguageSettingsController.keyHasOnboarded), true);
    });
  });

  group('Category and Phrase Ordering & Filtering', () {
    late List<Category> testCategories;
    late List<Phrase> testPhrases;
    late BrowseDataService browseService;

    setUp(() {
      testCategories = [
        const Category(
          id: 'food',
          sortOrder: 2,
          iconKey: 'food',
          names: {'en': 'Food and Dining', 'es': 'Comida y Restaurantes'},
        ),
        const Category(
          id: 'greetings',
          sortOrder: 1,
          iconKey: 'greetings',
          names: {'en': 'Greetings', 'es': 'Saludos'},
        ),
      ];

      testPhrases = [
        const Phrase(
          id: 'phrase-2',
          categoryId: 'greetings',
          sortOrder: 2,
          translations: {
            'en': PhraseTranslation(text: 'Good morning', exampleSentence: 'Good morning team'),
            'es': PhraseTranslation(text: 'Buenos días', pronunciation: 'BWEH-nohs DEE-ahs'),
          },
        ),
        const Phrase(
          id: 'phrase-1',
          categoryId: 'greetings',
          sortOrder: 1,
          translations: {
            'en': PhraseTranslation(text: 'Hello', exampleSentence: 'Hello there'),
            'es': PhraseTranslation(text: 'Hola', pronunciation: 'OH-lah'),
          },
        ),
        const Phrase(
          id: 'phrase-food-1',
          categoryId: 'food',
          sortOrder: 1,
          translations: {
            'en': PhraseTranslation(text: 'Water, please', exampleSentence: 'A glass of water'),
            'es': PhraseTranslation(text: 'Agua, por favor', pronunciation: 'AH-gwah pohr fah-VOHR'),
          },
        ),
      ];

      browseService = BrowseDataService(
        languageRepo: MockLanguageRepository([
          const Language(code: 'en', name: 'English', nativeName: 'English'),
          const Language(code: 'es', name: 'Spanish', nativeName: 'Español'),
        ]),
        categoryRepo: MockCategoryRepository(testCategories),
        phraseRepo: MockPhraseRepository(testPhrases),
      );
    });

    test('getCategories enriches categories with phrase counts and native titles', () async {
      final result = await browseService.getCategories('es');
      expect(result.isSuccess, true);

      final categories = result.dataOrNull!;
      expect(categories.length, 2);

      final greetings = categories.firstWhere((c) => c.id == 'greetings');
      expect(greetings.phraseCount, 2);
      expect(greetings.nameFor('es'), 'Saludos');

      final food = categories.firstWhere((c) => c.id == 'food');
      expect(food.phraseCount, 1);
      expect(food.nameFor('es'), 'Comida y Restaurantes');
    });

    test('getPhrasesByCategory returns phrases sorted by sortOrder', () async {
      final result = await browseService.getPhrasesByCategory('greetings');
      expect(result.isSuccess, true);

      final phrases = result.dataOrNull!;
      expect(phrases.length, 2);
      expect(phrases[0].id, 'phrase-1'); // sortOrder 1
      expect(phrases[1].id, 'phrase-2'); // sortOrder 2
    });

    test('getPhraseBySlug finds phrase accurately', () async {
      final result = await browseService.getPhraseBySlug('phrase-food-1');
      expect(result.isSuccess, true);
      expect(result.dataOrNull?.translationFor('es')?.text, 'Agua, por favor');
    });
  });

  group('Accent-Insensitive Search Logic', () {
    late BrowseDataService browseService;

    setUp(() {
      final phrases = [
        const Phrase(
          id: 'i-am-allergic-to-peanuts',
          categoryId: 'food',
          sortOrder: 1,
          translations: {
            'en': PhraseTranslation(
              text: 'I am allergic to peanuts',
              exampleSentence: 'I am allergic to peanuts.',
            ),
            'es': PhraseTranslation(
              text: 'Soy alérgico al maní',
              pronunciation: 'soy ah-LEHR-hee-koh ahl mah-NEE',
              meaningNote: 'En México se dice cacahuate.',
            ),
            'fil': PhraseTranslation(
              text: 'May allergy po ako sa mani',
              pronunciation: 'my AH-lehr-jee poh ah-KOH sah mah-NEE',
            ),
          },
        ),
        const Phrase(
          id: 'where-is-the-bathroom',
          categoryId: 'directions',
          sortOrder: 2,
          translations: {
            'en': PhraseTranslation(text: 'Where is the bathroom?'),
            'es': PhraseTranslation(
              text: '¿Dónde está el baño?',
              pronunciation: 'DOHN-deh ehs-TAH ehl BAHN-yoh',
            ),
          },
        ),
      ];

      browseService = BrowseDataService(
        phraseRepo: MockPhraseRepository(phrases),
      );
    });

    test('normalizes accents and diacritics', () {
      expect(BrowseDataService.normalize('maní'), 'mani');
      expect(BrowseDataService.normalize('¿Dónde está el baño?'), '¿donde esta el bano?');
      expect(BrowseDataService.normalize('CAFÉ'), 'cafe');
      expect(BrowseDataService.normalize('Niño'), 'nino');
    });

    test('searches unaccented query against accented target text', () async {
      // Searching "mani" finds "Soy alérgico al maní"
      final result = await browseService.searchPhrases(
        query: 'mani',
        nativeLang: 'en',
        targetLang: 'es',
      );

      expect(result.isSuccess, true);
      expect(result.dataOrNull?.length, 1);
      expect(result.dataOrNull?.first.id, 'i-am-allergic-to-peanuts');
    });

    test('searches accented query against target text', () async {
      // Searching "donde" finds "¿Dónde está el baño?"
      final result = await browseService.searchPhrases(
        query: 'donde',
        nativeLang: 'en',
        targetLang: 'es',
      );

      expect(result.isSuccess, true);
      expect(result.dataOrNull?.first.id, 'where-is-the-bathroom');
    });

    test('searches native language keyword', () async {
      // Searching "peanuts" finds phrase via English translation
      final result = await browseService.searchPhrases(
        query: 'peanuts',
        nativeLang: 'en',
        targetLang: 'es',
      );

      expect(result.isSuccess, true);
      expect(result.dataOrNull?.first.id, 'i-am-allergic-to-peanuts');
    });

    test('searches meaning notes', () async {
      // Searching "cacahuate" finds phrase via meaningNote
      final result = await browseService.searchPhrases(
        query: 'cacahuate',
        nativeLang: 'en',
        targetLang: 'es',
      );

      expect(result.isSuccess, true);
      expect(result.dataOrNull?.first.id, 'i-am-allergic-to-peanuts');
    });

    test('filters search results by category', () async {
      // Searching "allergic" inside "directions" category returns 0
      final emptyResult = await browseService.searchPhrases(
        query: 'allergic',
        categoryId: 'directions',
        nativeLang: 'en',
        targetLang: 'es',
      );
      expect(emptyResult.isEmpty, true);

      // Searching inside "food" category returns the phrase
      final matchResult = await browseService.searchPhrases(
        query: 'allergic',
        categoryId: 'food',
        nativeLang: 'en',
        targetLang: 'es',
      );
      expect(matchResult.isSuccess, true);
      expect(matchResult.dataOrNull?.length, 1);
    });

    test('with no query and a category selected, returns all phrases in that category', () async {
      final result = await browseService.searchPhrases(
        query: '',
        categoryId: 'food',
        nativeLang: 'en',
        targetLang: 'es',
      );

      expect(result.isSuccess, true);
      expect(result.dataOrNull?.length, 1);
      expect(result.dataOrNull?.first.categoryId, 'food');
    });

    test('with no query and no category, returns empty prompt', () async {
      final result = await browseService.searchPhrases(
        query: '',
        categoryId: null,
        nativeLang: 'en',
        targetLang: 'es',
      );

      expect(result.isEmpty, true);
      expect(result.errorMessageOrNull, 'Type to search.');
    });
  });
}
