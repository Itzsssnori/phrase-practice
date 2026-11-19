import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:phrase_practice/models/category.dart';
import 'package:phrase_practice/models/language.dart';
import 'package:phrase_practice/models/phrase.dart';
import 'package:phrase_practice/models/phrase_translation.dart';
import 'package:phrase_practice/screens/categories_screen.dart';
import 'package:phrase_practice/screens/category_phrases_screen.dart';
import 'package:phrase_practice/screens/home_screen.dart';
import 'package:phrase_practice/screens/phrase_study_screen.dart';
import 'package:phrase_practice/screens/search_screen.dart';
import 'package:phrase_practice/services/browse_data_service.dart';
import 'package:phrase_practice/services/language_settings_controller.dart';
import 'package:phrase_practice/theme/app_theme.dart';
import 'package:phrase_practice/widgets/app_settings_scope.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'stage_3_browse_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final mockLanguages = [
    const Language(code: 'en', name: 'English', nativeName: 'English'),
    const Language(code: 'es', name: 'Spanish', nativeName: 'Español'),
    const Language(code: 'fil', name: 'Filipino', nativeName: 'Filipino'),
  ];

  final mockCategories = [
    const Category(
      id: 'greetings',
      sortOrder: 1,
      iconKey: 'greetings',
      names: {
        'en': 'Greetings',
        'es': 'Saludos',
        'fil': 'Mga Pagbati',
      },
      phraseCount: 1,
    ),
  ];

  final mockPhrases = [
    const Phrase(
      id: 'hello-phrase',
      categoryId: 'greetings',
      sortOrder: 1,
      translations: {
        'en': PhraseTranslation(
          text: 'Hello',
          pronunciation: null,
          meaningNote: 'Standard polite greeting in English.',
          exampleSentence: 'Hello, how can I help you today?',
        ),
        'es': PhraseTranslation(
          text: 'Hola',
          pronunciation: 'OH-lah',
          meaningNote: 'Saludo general en español.',
          exampleSentence: 'Hola, ¿cómo está usted hoy?',
        ),
        'fil': PhraseTranslation(
          text: 'Kamusta po',
          pronunciation: 'kah-moos-TAH poh',
          meaningNote: 'Magalang na pagbati sa wikang Filipino.',
          exampleSentence: 'Kamusta po kayo ngayong araw?',
        ),
      },
    ),
  ];

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    BrowseDataService.setMockInstance(
      BrowseDataService(
        languageRepo: MockLanguageRepository(mockLanguages),
        categoryRepo: MockCategoryRepository(mockCategories),
        phraseRepo: MockPhraseRepository(mockPhrases),
      ),
    );
  });

  Widget createTestWidget({
    required Widget child,
    required LanguageSettingsController controller,
  }) {
    return AppSettingsScope(
      controller: controller,
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: child,
      ),
    );
  }

  group('Language Synchronization Across Screens', () {
    testWidgets('HomeScreen category title and language chip immediately reflect language swaps', (tester) async {
      final controller = LanguageSettingsController();
      await controller.load();
      // Default: native = 'en' ("Greetings"), target = 'es' ("Spanish")

      await tester.pumpWidget(createTestWidget(child: const HomeScreen(), controller: controller));
      await tester.pumpAndSettle();

      // Check English category title in the compact grid
      expect(find.text('Greetings'), findsOneWidget);
      // LanguagePairChip shows native and target language names
      expect(find.text('English'), findsOneWidget);
      expect(find.text('Spanish'), findsOneWidget);

      // Change native language to Spanish ('es') and target to English ('en')
      await controller.setLanguagePair(nativeCode: 'es', targetCode: 'en');
      await tester.pumpAndSettle();

      // Category title should update immediately to "Saludos" without navigating away
      expect(find.text('Saludos'), findsOneWidget);
      expect(find.text('Greetings'), findsNothing);

      // Change native language to Filipino ('fil')
      await controller.setNativeLanguage('fil');
      await tester.pumpAndSettle();

      // Category title should update immediately to "Mga Pagbati"
      expect(find.text('Mga Pagbati'), findsOneWidget);
      expect(find.text('Saludos'), findsNothing);
    });

    testWidgets('CategoriesScreen updates category titles when native language changes', (tester) async {
      final controller = LanguageSettingsController();
      await controller.load();
      await controller.setLanguagePair(nativeCode: 'en', targetCode: 'es');

      await tester.pumpWidget(createTestWidget(child: const CategoriesScreen(), controller: controller));
      await tester.pumpAndSettle();

      expect(find.text('Greetings'), findsOneWidget);

      // Swap languages: native becomes 'es'
      await controller.swapLanguages();
      await tester.pumpAndSettle();

      expect(find.text('Saludos'), findsOneWidget);
      expect(find.text('Greetings'), findsNothing);
    });

    testWidgets('CategoryPhrasesScreen updates phrase card main and sub texts when languages change', (tester) async {
      final controller = LanguageSettingsController();
      await controller.load();
      // native: 'en', target: 'es'
      await controller.setLanguagePair(nativeCode: 'en', targetCode: 'es');

      await tester.pumpWidget(createTestWidget(
        child: const CategoryPhrasesScreen(categoryId: 'greetings'),
        controller: controller,
      ));
      await tester.pumpAndSettle();

      // In CategoryPhrasesScreen:
      // Header category title in native language ('Greetings')
      expect(find.text('Greetings'), findsWidgets);
      // Main text: target language ('Hola')
      expect(find.text('Hola'), findsOneWidget);
      // Sub text: native language ('Hello')
      expect(find.text('Hello'), findsOneWidget);

      // Change target language to Filipino ('fil') while keeping native as English ('en')
      await controller.setTargetLanguage('fil');
      await tester.pumpAndSettle();

      // Main text should now immediately be 'Kamusta po'
      expect(find.text('Kamusta po'), findsOneWidget);
      expect(find.text('Hello'), findsOneWidget);
      expect(find.text('Hola'), findsNothing);
    });

    testWidgets('PhraseStudyScreen updates translation and native text immediately when settings change', (tester) async {
      final controller = LanguageSettingsController();
      await controller.load();
      await controller.setLanguagePair(nativeCode: 'en', targetCode: 'es');

      await tester.pumpWidget(createTestWidget(
        child: const PhraseStudyScreen(
          initialPhraseSlug: 'hello-phrase',
          categoryId: 'greetings',
        ),
        controller: controller,
      ));
      await tester.pumpAndSettle();

      // Target language: 'Hola'
      expect(find.text('Hola'), findsOneWidget);
      // Native language: 'Hello'
      expect(find.text('Hello'), findsOneWidget);

      // Change target language to Filipino ('fil')
      await controller.setTargetLanguage('fil');
      await tester.pumpAndSettle();

      // Study screen immediately displays 'Kamusta po'
      expect(find.text('Kamusta po'), findsOneWidget);
      expect(find.text('Hello'), findsOneWidget);
      expect(find.text('Hola'), findsNothing);
    });

    testWidgets('SearchScreen updates category filter chip labels when native language changes', (tester) async {
      final controller = LanguageSettingsController();
      await controller.load();
      await controller.setLanguagePair(nativeCode: 'en', targetCode: 'es');

      await tester.pumpWidget(createTestWidget(child: const SearchScreen(), controller: controller));
      await tester.pumpAndSettle();

      expect(find.text('Greetings'), findsOneWidget);

      // Change native language to Spanish
      await controller.setNativeLanguage('es');
      await tester.pumpAndSettle();

      expect(find.text('Saludos'), findsOneWidget);
      expect(find.text('Greetings'), findsNothing);
    });

    testWidgets('HomeScreen Daily Focus Phrase displays real loaded phrase and details link', (tester) async {
      final controller = LanguageSettingsController();
      await controller.load();
      await controller.setLanguagePair(nativeCode: 'en', targetCode: 'es');

      await tester.pumpWidget(createTestWidget(child: const HomeScreen(), controller: controller));
      await tester.pumpAndSettle();

      // Featured Daily Phrase card should be present with real data from mock repository
      expect(find.text('FEATURED DAILY PHRASE'), findsOneWidget);
      expect(find.text('GREETINGS'), findsOneWidget);
      expect(find.text('Hola'), findsOneWidget);
      expect(find.text('"Hello"'), findsOneWidget);
      expect(find.text('View phrase details →'), findsOneWidget);
    });
  });
}
