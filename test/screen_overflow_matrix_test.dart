import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:phrase_practice/models/category.dart';
import 'package:phrase_practice/models/language.dart';
import 'package:phrase_practice/models/phrase.dart';
import 'package:phrase_practice/models/phrase_translation.dart';
import 'package:phrase_practice/screens/categories_screen.dart';
import 'package:phrase_practice/screens/category_phrases_screen.dart';
import 'package:phrase_practice/screens/home_screen.dart';
import 'package:phrase_practice/screens/onboarding_screen.dart';
import 'package:phrase_practice/screens/phrase_study_screen.dart';
import 'package:phrase_practice/screens/quiz_result_screen.dart';
import 'package:phrase_practice/screens/quiz_screen.dart';
import 'package:phrase_practice/screens/quiz_setup_screen.dart';
import 'package:phrase_practice/screens/review_mistakes_screen.dart';
import 'package:phrase_practice/screens/search_screen.dart';
import 'package:phrase_practice/services/browse_data_service.dart';
import 'package:phrase_practice/services/language_settings_controller.dart';
import 'package:phrase_practice/services/quiz_controller.dart';
import 'package:phrase_practice/theme/app_theme.dart';
import 'package:phrase_practice/widgets/app_quiz_scope.dart';
import 'package:phrase_practice/widgets/app_settings_scope.dart';
import 'package:phrase_practice/widgets/language_picker_bottom_sheet.dart';
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
      id: 'emergencies',
      sortOrder: 1,
      iconKey: 'emergencies',
      names: {'en': 'Emergencies and Medical Assistance', 'es': 'Emergencias y Asistencia Médica', 'fil': 'Mga Emergency at Tulong Medikal'},
      phraseCount: 10,
    ),
    const Category(
      id: 'food',
      sortOrder: 2,
      iconKey: 'food',
      names: {'en': 'Food and Dining Out', 'es': 'Comida y Restaurantes Típicos', 'fil': 'Pagkain at Kainan sa Labas'},
      phraseCount: 10,
    ),
  ];

  final mockPhrases = [
    const Phrase(
      id: 'allergic-phrase-slug',
      categoryId: 'food',
      sortOrder: 1,
      translations: {
        'en': PhraseTranslation(
          text: 'I am severely allergic to peanuts, walnuts, and all varieties of tree nuts.',
          pronunciation: null,
          meaningNote: 'Critical allergy advisory. Inform kitchen staff immediately.',
          exampleSentence: 'Excuse me, could you please double-check that this sauce contains no peanuts?',
        ),
        'es': PhraseTranslation(
          text: 'Soy alérgico al maní, a las nueces y a todo tipo de frutos secos.',
          pronunciation: 'soy ah-LEHR-hee-koh ahl mah-NEE ah lahs NWEH-sehs ee ah TOH-doh TEE-poh deh FROO-tohs SEH-kohs',
          meaningNote: 'En México y Centroamérica se utiliza "cacahuate". Si es mujer, diga "alérgica".',
          exampleSentence: 'Por favor verifique cuidadosamente con el chef que este platillo no contenga absolutamente ningún tipo de maní.',
        ),
        'fil': PhraseTranslation(
          text: 'Mayroon po akong napakatinding allergy sa mani at sa lahat ng uri ng buto o mani.',
          pronunciation: 'my-ROH-ohn poh ah-KOHNG nah-pah-kah-TEEN-deeng AH-lehr-jee sah mah-NEE',
          meaningNote: 'Mahalagang sabihin kaagad sa tagapagsilbi bago lutuin ang pagkain upang maiwasan ang panganib.',
          exampleSentence: 'Mawalang-galang na po, pakisigurado po sa kusina na wala pong anumang sangkap na mani sa sabaw na ito.',
        ),
      },
    ),
  ];

  final mockQuizPhrases = [
    const Phrase(
      id: 'p1',
      categoryId: 'food',
      sortOrder: 1,
      translations: {
        'en': PhraseTranslation(text: 'Water please'),
        'es': PhraseTranslation(text: 'Agua por favor'),
      },
    ),
    const Phrase(
      id: 'p2',
      categoryId: 'food',
      sortOrder: 2,
      translations: {
        'en': PhraseTranslation(text: 'The check please'),
        'es': PhraseTranslation(text: 'La cuenta por favor'),
      },
    ),
    const Phrase(
      id: 'p3',
      categoryId: 'food',
      sortOrder: 3,
      translations: {
        'en': PhraseTranslation(text: 'Delicious food'),
        'es': PhraseTranslation(text: 'Comida deliciosa'),
      },
    ),
    const Phrase(
      id: 'p4',
      categoryId: 'food',
      sortOrder: 4,
      translations: {
        'en': PhraseTranslation(text: 'Thank you very much'),
        'es': PhraseTranslation(text: 'Muchas gracias'),
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

  Widget buildTestHost({
    required Widget child,
    required double width,
    required double height,
    required double textScale,
    required bool isDark,
    required LanguageSettingsController controller,
  }) {
    return MediaQuery(
      data: MediaQueryData(
        size: Size(width, height),
        textScaler: TextScaler.linear(textScale),
      ),
      child: AppSettingsScope(
        controller: controller,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
          home: child,
        ),
      ),
    );
  }

  // Matrix of responsive viewport dimensions
  final widths = [320.0, 360.0, 412.0, 768.0, 1280.0];
  const textScales = [1.0, 1.5, 2.0];
  const themeModes = [false, true]; // Light and Dark

  // Language pairs to test
  final languagePairs = [
    ('en', 'es'),
    ('es', 'fil'),
    ('fil', 'en'),
  ];

  group('Responsive Layout Overflow Verification', () {
    testWidgets('OnboardingScreen has zero overflow across widths and text scales', (tester) async {
      for (final w in [320.0, 360.0, 768.0]) {
        for (final scale in [1.0, 2.0]) {
          final controller = LanguageSettingsController();
          await controller.load();

          await tester.pumpWidget(
            buildTestHost(
              child: const OnboardingScreen(),
              width: w,
              height: 600.0,
              textScale: scale,
              isDark: false,
              controller: controller,
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: 'Overflow on Onboarding at width $w scale $scale');
        }
      }
    });

    testWidgets('HomeScreen has zero overflow across widths, text scales, and theme modes', (tester) async {
      for (final w in widths) {
        for (final scale in textScales) {
          for (final isDark in themeModes) {
            final controller = LanguageSettingsController();
            await controller.load();

            await tester.pumpWidget(
              buildTestHost(
                child: const HomeScreen(),
                width: w,
                height: 800.0,
                textScale: scale,
                isDark: isDark,
                controller: controller,
              ),
            );
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull, reason: 'Overflow on Home at width $w scale $scale isDark $isDark');
          }
        }
      }
    });

    testWidgets('CategoriesScreen has zero overflow across widths and text scales', (tester) async {
      for (final w in [320.0, 412.0, 1280.0]) {
        for (final scale in [1.0, 1.5, 2.0]) {
          final controller = LanguageSettingsController();
          await controller.load();

          await tester.pumpWidget(
            buildTestHost(
              child: const CategoriesScreen(),
              width: w,
              height: 700.0,
              textScale: scale,
              isDark: false,
              controller: controller,
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: 'Overflow on Categories at width $w scale $scale');
        }
      }
    });

    testWidgets('CategoryPhrasesScreen has zero overflow with long translations', (tester) async {
      for (final pair in languagePairs) {
        for (final w in [320.0, 360.0, 768.0]) {
          for (final scale in [1.0, 2.0]) {
            final controller = LanguageSettingsController();
            await controller.load();
            await controller.setLanguagePair(nativeCode: pair.$1, targetCode: pair.$2);

            await tester.pumpWidget(
              buildTestHost(
                child: const CategoryPhrasesScreen(categoryId: 'food'),
                width: w,
                height: 800.0,
                textScale: scale,
                isDark: true,
                controller: controller,
              ),
            );
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull, reason: 'Overflow on CategoryPhrases with pair $pair at width $w scale $scale');
          }
        }
      }
    });

    testWidgets('PhraseStudyScreen has zero overflow with long text and Aa zoom', (tester) async {
      for (final pair in languagePairs) {
        for (final w in [320.0, 360.0, 412.0]) {
          for (final scale in [1.0, 2.0]) {
            final controller = LanguageSettingsController();
            await controller.load();
            await controller.setLanguagePair(nativeCode: pair.$1, targetCode: pair.$2);

            await tester.pumpWidget(
              buildTestHost(
                child: const PhraseStudyScreen(
                  initialPhraseSlug: 'allergic-phrase-slug',
                  categoryId: 'food',
                ),
                width: w,
                height: 600.0, // Small height to test scrollability
                textScale: scale,
                isDark: false,
                controller: controller,
              ),
            );
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull, reason: 'Overflow on PhraseStudy with pair $pair at width $w scale $scale');
          }
        }
      }
    });

    testWidgets('SearchScreen has zero overflow across widths and text scales', (tester) async {
      for (final w in [320.0, 360.0, 412.0, 768.0]) {
        for (final scale in [1.0, 2.0]) {
          final controller = LanguageSettingsController();
          await controller.load();

          await tester.pumpWidget(
            buildTestHost(
              child: const SearchScreen(),
              width: w,
              height: 700.0,
              textScale: scale,
              isDark: false,
              controller: controller,
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: 'Overflow on Search at width $w scale $scale');
        }
      }
    });

    testWidgets('Language picker bottom sheet content has zero overflow at 320px and 2.0x scale', (tester) async {
      final controller = LanguageSettingsController();
      await controller.load();

      await tester.pumpWidget(
        buildTestHost(
          child: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => LanguagePickerBottomSheet.showPairPicker(context),
                child: const Text('Open'),
              ),
            ),
          ),
          width: 320.0,
          height: 600.0,
          textScale: 2.0,
          isDark: true,
          controller: controller,
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull, reason: 'Overflow in LanguagePickerBottomSheet modal content');
    });

    testWidgets('QuizSetupScreen has zero overflow at 320px width and 2.0x scale', (tester) async {
      final controller = LanguageSettingsController();
      await controller.load();

      await tester.pumpWidget(
        buildTestHost(
          child: const QuizSetupScreen(),
          width: 320.0,
          height: 600.0,
          textScale: 2.0,
          isDark: false,
          controller: controller,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'Overflow on QuizSetupScreen');
    });

    testWidgets('QuizScreen has zero overflow at 320px width and 1.5x scale', (tester) async {
      final controller = LanguageSettingsController();
      await controller.load();
      final quizCtrl = QuizController();
      quizCtrl.startQuiz(
        allPhrases: mockQuizPhrases,
        nativeLanguageCode: 'en',
        targetLanguageCode: 'es',
        questionCount: 4,
        random: Random(42),
      );

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(320.0, 600.0),
            textScaler: TextScaler.linear(1.5),
          ),
          child: AppSettingsScope(
            controller: controller,
            child: AppQuizScope(
              controller: quizCtrl,
              child: const MaterialApp(
                debugShowCheckedModeBanner: false,
                home: QuizScreen(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'Overflow on QuizScreen');
    });

    testWidgets('QuizResultScreen has zero overflow at 320px width and 1.5x scale', (tester) async {
      final controller = LanguageSettingsController();
      await controller.load();
      final quizCtrl = QuizController();
      quizCtrl.startQuiz(
        allPhrases: mockQuizPhrases,
        nativeLanguageCode: 'en',
        targetLanguageCode: 'es',
        questionCount: 2,
        random: Random(42),
      );
      final q0 = quizCtrl.currentQuestion!;
      quizCtrl.selectOption(q0.correctIndex);
      quizCtrl.submitAnswer();
      quizCtrl.nextQuestion();
      final q1 = quizCtrl.currentQuestion!;
      quizCtrl.selectOption((q1.correctIndex + 1) % 4);
      quizCtrl.submitAnswer();
      await quizCtrl.finishQuiz(uid: null);

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(320.0, 600.0),
            textScaler: TextScaler.linear(1.5),
          ),
          child: AppSettingsScope(
            controller: controller,
            child: AppQuizScope(
              controller: quizCtrl,
              child: const MaterialApp(
                debugShowCheckedModeBanner: false,
                home: QuizResultScreen(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'Overflow on QuizResultScreen');
    });

    testWidgets('ReviewMistakesScreen has zero overflow at 320px width and 1.5x scale', (tester) async {
      final controller = LanguageSettingsController();
      await controller.load();
      final quizCtrl = QuizController();
      quizCtrl.startQuiz(
        allPhrases: mockQuizPhrases,
        nativeLanguageCode: 'en',
        targetLanguageCode: 'es',
        questionCount: 2,
        random: Random(42),
      );
      for (var i = 0; i < 2; i++) {
        quizCtrl.selectOption((quizCtrl.currentQuestion!.correctIndex + 1) % 4);
        quizCtrl.submitAnswer();
        if (i < 1) quizCtrl.nextQuestion();
      }
      await quizCtrl.finishQuiz(uid: null);

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(320.0, 600.0),
            textScaler: TextScaler.linear(1.5),
          ),
          child: AppSettingsScope(
            controller: controller,
            child: AppQuizScope(
              controller: quizCtrl,
              child: const MaterialApp(
                debugShowCheckedModeBanner: false,
                home: ReviewMistakesScreen(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'Overflow on ReviewMistakesScreen');
    });
  });
}
