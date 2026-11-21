import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:phrase_practice/models/category.dart';
import 'package:phrase_practice/models/language.dart';
import 'package:phrase_practice/models/phrase.dart';
import 'package:phrase_practice/models/phrase_translation.dart';
import 'package:phrase_practice/models/translation_entry.dart';
import 'package:phrase_practice/screens/categories_screen.dart';
import 'package:phrase_practice/screens/home_screen.dart';
import 'package:phrase_practice/screens/phrase_study_screen.dart';
import 'package:phrase_practice/screens/quiz_screen.dart';
import 'package:phrase_practice/screens/search_screen.dart';
import 'package:phrase_practice/services/browse_data_service.dart';
import 'package:phrase_practice/services/language_settings_controller.dart';
import 'package:phrase_practice/services/quiz_controller.dart';
import 'package:phrase_practice/services/search_normalizer.dart';
import 'package:phrase_practice/services/translator_language_guidance.dart';
import 'package:phrase_practice/services/translator_repository.dart';
import 'package:phrase_practice/theme/app_colors.dart';
import 'package:phrase_practice/theme/app_theme.dart';
import 'package:phrase_practice/widgets/app_quiz_scope.dart';
import 'package:phrase_practice/widgets/app_settings_scope.dart';
import 'package:phrase_practice/widgets/localized_phrase_text.dart';
import 'package:phrase_practice/widgets/phrase_card.dart';
import 'package:phrase_practice/widgets/translation_result_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'stage_3_browse_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const allEightLanguages = [
    Language(
      code: 'en',
      name: 'English',
      nativeName: 'English',
      script: 'Latin',
      isActive: true,
      sortOrder: 1,
      ttsLocale: 'en-US',
      pronunciationSystem: 'Respelling',
    ),
    Language(
      code: 'es',
      name: 'Spanish',
      nativeName: 'Español',
      script: 'Latin',
      isActive: true,
      sortOrder: 2,
      ttsLocale: 'es-MX',
      pronunciationSystem: 'Respelling',
    ),
    Language(
      code: 'fil',
      name: 'Filipino',
      nativeName: 'Filipino',
      script: 'Latin',
      isActive: true,
      sortOrder: 3,
      ttsLocale: 'fil-PH',
      pronunciationSystem: 'Respelling',
    ),
    Language(
      code: 'fr',
      name: 'French',
      nativeName: 'Français',
      script: 'Latin',
      isActive: false,
      sortOrder: 4,
      ttsLocale: 'fr-FR',
      pronunciationSystem: 'Respelling',
    ),
    Language(
      code: 'ru',
      name: 'Russian',
      nativeName: 'Русский',
      script: 'Cyrillic',
      isActive: false,
      sortOrder: 5,
      ttsLocale: 'ru-RU',
      pronunciationSystem: 'Latin transliteration',
    ),
    Language(
      code: 'ja',
      name: 'Japanese',
      nativeName: '日本語',
      script: 'Japanese',
      isActive: false,
      sortOrder: 6,
      ttsLocale: 'ja-JP',
      pronunciationSystem: 'Romaji',
    ),
    Language(
      code: 'ko',
      name: 'Korean',
      nativeName: '한국어',
      script: 'Hangul',
      isActive: false,
      sortOrder: 7,
      ttsLocale: 'ko-KR',
      pronunciationSystem: 'Revised Romanization',
    ),
    Language(
      code: 'zh',
      name: 'Chinese (Mandarin, Simplified)',
      nativeName: '中文（简体）',
      script: 'Han (Simplified)',
      isActive: false,
      sortOrder: 8,
      ttsLocale: 'zh-CN',
      pronunciationSystem: 'Pinyin',
    ),
  ];

  const multiScriptPhrase = Phrase(
    id: 'where-is-the-bathroom',
    categoryId: 'directions',
    sortOrder: 1,
    translations: {
      'en': PhraseTranslation(
        text: 'Excuse me, where is the restroom?',
        pronunciation: '',
        meaningNote: 'Essential navigational inquiry.',
        exampleSentence: 'Excuse me, where is the restroom on this floor?',
        verified: false,
      ),
      'es': PhraseTranslation(
        text: 'Disculpe, ¿dónde está el baño?',
        pronunciation: 'dees-KOOL-peh DOHN-deh ehs-TAH ehl BAH-nyoh',
        meaningNote: 'Across Latin America, "el baño" is universally used.',
        exampleSentence: 'Disculpe, ¿dónde está el baño más cercano?',
        verified: false,
      ),
      'fil': PhraseTranslation(
        text: 'ipagpaumanhin po, saan po ang banyo?',
        pronunciation: 'ee-pahg-pah-oo-mahn-HEEN poh sah-AHN poh ahng BAHN-yoh',
        meaningNote: 'Restrooms are commonly called "banyo" or "CR" in the Philippines.',
        exampleSentence: 'Maaari po bang magtanong kung saan ang banyo?',
        verified: false,
      ),
      'fr': PhraseTranslation(
        text: 'Excusez-moi, où sont les toilettes ?',
        pronunciation: 'eks-kyoo-zay-MWAH oo sohn lay twah-LET',
        meaningNote: 'Always use the plural "les toilettes" in French.',
        exampleSentence: 'Excusez-moi, où sont les toilettes, s’il vous plaît ?',
        verified: false,
      ),
      'ru': PhraseTranslation(
        text: 'Извините, пожалуйста, где находится туалет?',
        pronunciation: 'Izvinite, pozhaluysta, gde nakhoditsya tualet?',
        meaningNote: 'Polite form addressing a stranger with "вы".',
        exampleSentence: 'Подскажите, пожалуйста, где здесь ближайший туалет?',
        verified: false,
      ),
      'ja': PhraseTranslation(
        text: 'すみません、お手洗いはどこですか？',
        pronunciation: 'Sumimasen, otearai wa doko desu ka?',
        meaningNote: '"Otearai" is polite and natural in restaurants and stations.',
        exampleSentence: 'すみません、一番近いお手洗いはどこですか？',
        verified: false,
      ),
      'ko': PhraseTranslation(
        text: '실례합니다, 화장실이 어디에 있어요?',
        pronunciation: 'Sillyehamnida, hwajangsiri eodie isseoyo?',
        meaningNote: 'Polite 해요체 form suitable for any public place.',
        exampleSentence: '저기요, 가장 가까운 화장실이 어디에 있어요?',
        verified: false,
      ),
      'zh': PhraseTranslation(
        text: '请问，洗手间在哪里？',
        pronunciation: 'Qǐngwèn, xǐshǒujiān zài nǎlǐ?',
        meaningNote: '"Xǐshǒujiān" is the polite everyday term for restroom.',
        exampleSentence: '请问一下，附近的洗手间在哪里？',
        verified: false,
      ),
    },
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  // ─── 1. Language & Category Model Defaults ─────────────────────────────────

  group('Language & Category Model Backward Compatibility Defaults', () {
    test('Language.fromMap fills missing new fields with sensible code-based defaults', () {
      final legacyEs = Language.fromMap('es', const {
        'name': 'Spanish',
        'nativeName': 'Español',
      });
      expect(legacyEs.script, 'Latin');
      expect(legacyEs.isActive, isTrue);
      expect(legacyEs.effectiveSortOrder, 2);
      expect(legacyEs.effectiveTtsLocale, 'es-MX');
      expect(legacyEs.effectivePronunciationSystem, 'Respelling');

      final legacyJa = Language.fromMap('ja', const {
        'name': 'Japanese',
        'nativeName': '日本語',
        'isActive': false,
      });
      expect(legacyJa.script, 'Japanese');
      expect(legacyJa.isActive, isFalse);
      expect(legacyJa.effectiveSortOrder, 6);
      expect(legacyJa.effectiveTtsLocale, 'ja-JP');
      expect(legacyJa.effectivePronunciationSystem, 'Romaji');

      final legacyZh = Language.fromMap('zh', const {'name': 'Chinese'});
      expect(legacyZh.script, 'Han (Simplified)');
      expect(legacyZh.effectiveTtsLocale, 'zh-CN');
      expect(legacyZh.effectivePronunciationSystem, 'Pinyin');
    });

    test('Category.fromMap fills missing group and priority with slug-based defaults', () {
      final legacyFood = Category.fromMap('food', const {
        'sortOrder': 2,
        'names': {'en': 'Food'},
      });
      expect(legacyFood.effectiveGroup, 'everyday');
      expect(legacyFood.effectivePriority, 'essential');
      expect(legacyFood.isCritical, isFalse);

      final legacyEmergencies = Category.fromMap('emergencies', const {
        'sortOrder': 5,
        'names': {'en': 'Emergencies'},
      });
      expect(legacyEmergencies.effectiveGroup, 'safety');
      expect(legacyEmergencies.effectivePriority, 'critical');
      expect(legacyEmergencies.isCritical, isTrue);
    });

    test('Category grouping, active filtering, and Home 6-category limit work accurately', () {
      const sampleCategories = [
        Category(id: 'emergencies', sortOrder: 5, group: 'safety', priority: 'critical', isActive: true),
        Category(id: 'shopping', sortOrder: 7, group: 'everyday', priority: 'high', isActive: true),
        Category(id: 'greetings', sortOrder: 1, group: 'everyday', priority: 'essential', isActive: true),
        Category(id: 'food', sortOrder: 2, group: 'everyday', priority: 'essential', isActive: true),
        Category(id: 'directions', sortOrder: 3, group: 'travel', priority: 'essential', isActive: true),
        Category(id: 'travel', sortOrder: 4, group: 'travel', priority: 'essential', isActive: true),
        Category(id: 'transportation', sortOrder: 11, group: 'travel', priority: 'essential', isActive: true),
        Category(id: 'accommodation', sortOrder: 13, group: 'travel', priority: 'essential', isActive: true),
        Category(id: 'inactive-cat', sortOrder: 0, group: 'everyday', priority: 'essential', isActive: false),
      ];

      // Active in group ordered by sortOrder
      final everyday = Category.activeInGroup(sampleCategories, 'everyday');
      expect(everyday.map((c) => c.id).toList(), ['greetings', 'food', 'shopping']);

      // Home limit: at most 6, essential first, then group (everyday -> travel -> safety) and sortOrder
      final homeSix = Category.selectForHome(sampleCategories, maxCount: 6);
      expect(homeSix.length, 6);
      expect(
        homeSix.map((c) => c.id).toList(),
        ['greetings', 'food', 'directions', 'travel', 'transportation', 'accommodation'],
      );
      expect(homeSix.any((c) => !c.isActive), isFalse);
    });

    test('BrowseDataService filters out inactive languages and orders active languages by sortOrder', () async {
      final service = BrowseDataService(
        languageRepo: MockLanguageRepository(allEightLanguages.reversed.toList()),
        categoryRepo: MockCategoryRepository(const []),
        phraseRepo: MockPhraseRepository(const []),
      );

      final res = await service.getLanguages();
      expect(res.isSuccess, isTrue);
      final langs = res.dataOrNull!;
      expect(langs.map((l) => l.code).toList(), ['en', 'es', 'fil']);
    });
  });

  // ─── 2. Per-Script Search Normalization ────────────────────────────────────

  group('Per-Script SearchNormalizer', () {
    test('Japanese: が and か do NOT match (even if decomposed NFD か + dakuten is passed)', () {
      expect(
        SearchNormalizer.matchesText(
          text: 'ありがとうございます',
          query: 'ありかとう',
          languageCode: 'ja',
        ),
        isFalse,
      );
      expect(
        SearchNormalizer.matchesText(
          text: 'ありがとうございます',
          query: 'ありがとう',
          languageCode: 'ja',
        ),
        isTrue,
      );
      // Decomposed NFD か (\u304B) + combining dakuten (\u3099) composes to NFC が (\u304C)
      expect(
        SearchNormalizer.normalize('か\u3099', languageCode: 'ja'),
        SearchNormalizer.normalize('が', languageCode: 'ja'),
      );
      expect(
        SearchNormalizer.normalize('か\u3099', languageCode: 'ja'),
        isNot(SearchNormalizer.normalize('か', languageCode: 'ja')),
      );
    });

    test('Russian: ё matches е, and й does NOT match и', () {
      // ё matches е
      expect(
        SearchNormalizer.matchesText(
          text: 'Где здесь ёлка и туалет?',
          query: 'елка',
          languageCode: 'ru',
        ),
        isTrue,
      );
      // й does NOT match и (both precomposed й and decomposed и\u0306)
      expect(
        SearchNormalizer.matchesText(
          text: 'ближайший',
          query: 'ближаишии',
          languageCode: 'ru',
        ),
        isFalse,
      );
      expect(
        SearchNormalizer.normalize('и\u0306', languageCode: 'ru'),
        'й',
      );
      expect(
        SearchNormalizer.normalize('й', languageCode: 'ru'),
        isNot(SearchNormalizer.normalize('и', languageCode: 'ru')),
      );
    });

    test('Pinyin tone marks are ignored and Romaji matches in pronunciation search', () {
      expect(
        SearchNormalizer.matchesPronunciation(
          pronunciation: 'Nǐ hǎo, qǐngwèn xǐshǒujiān zài nǎlǐ?',
          query: 'ni hao',
        ),
        isTrue,
      );
      expect(
        SearchNormalizer.matchesPronunciation(
          pronunciation: 'Konnichiwa, otearai wa doko desu ka?',
          query: 'konnichiwa',
        ),
        isTrue,
      );
    });

    test('Spanish café matches cafe, and Hangul & Chinese match exactly', () {
      expect(
        SearchNormalizer.matchesText(
          text: 'Quiero un café con leche',
          query: 'cafe',
          languageCode: 'es',
        ),
        isTrue,
      );
      expect(
        SearchNormalizer.matchesText(
          text: '화장실이 어디에 있어요?',
          query: '화장실',
          languageCode: 'ko',
        ),
        isTrue,
      );
      expect(
        SearchNormalizer.matchesText(
          text: '화장실이 어디에 있어요?',
          query: '화창실',
          languageCode: 'ko',
        ),
        isFalse,
      );
      expect(
        SearchNormalizer.matchesText(
          text: '请问，洗手间在哪里？',
          query: '洗手间',
          languageCode: 'zh',
        ),
        isTrue,
      );
      expect(
        SearchNormalizer.matchesText(
          text: '请问，洗手间在哪里？',
          query: '卫生间',
          languageCode: 'zh',
        ),
        isFalse,
      );
    });
  });

  // ─── 3. Translator Language Guidance & Delimiters ──────────────────────────

  group('TranslatorLanguageGuidance & PromptBuilder', () {
    test('has explicit guidance for all 8 language codes and keeps user text inside delimiters', () {
      for (final lang in allEightLanguages) {
        expect(
          TranslatorLanguageGuidance.guidanceByCode.containsKey(lang.code),
          isTrue,
          reason: 'Missing guidance for ${lang.code}',
        );

        const userText = 'Where is the train station?';
        final prompt = TranslatorPromptBuilder.buildUserPrompt(
          normalizedInput: userText,
          sourceLanguageName: 'English',
          targetLanguageName: lang.name,
          targetLanguage: lang,
        );

        expect(prompt, contains(lang.effectivePronunciationSystem));
        expect(prompt, contains(lang.script));
        expect(prompt, contains(TranslatorLanguageGuidance.guidanceFor(lang.code)));

        final startIdx = prompt.indexOf(TranslatorPromptBuilder.startDelimiter);
        final endIdx = prompt.indexOf(TranslatorPromptBuilder.endDelimiter);
        expect(startIdx, greaterThan(-1));
        expect(endIdx, greaterThan(startIdx));
        final extracted = prompt
            .substring(startIdx + TranslatorPromptBuilder.startDelimiter.length, endIdx)
            .trim();
        expect(extracted, userText);
      }
    });
  });

  // ─── 4. Draft-Translation Notice on PhraseStudyScreen ──────────────────────

  group('Draft-translation notice on PhraseStudyScreen', () {
    const draftCaption =
        'Draft translation. Not yet reviewed by a native speaker. For health, safety, or legal situations, confirm with a person.';

    testWidgets('shows warning-colored draft notice for unverified critical category and hides when verified', (tester) async {
      final settings = LanguageSettingsController();
      await settings.load();

      const unverifiedCritical = Phrase(
        id: 'help-me',
        categoryId: 'emergencies',
        translations: {
          'en': PhraseTranslation(text: 'Help me!', verified: true),
          'es': PhraseTranslation(
            text: '¡Ayúdeme, por favor!',
            pronunciation: 'ah-YOO-deh-meh',
            verified: false,
          ),
        },
      );

      const verifiedEveryday = Phrase(
        id: 'hello-verified',
        categoryId: 'greetings',
        translations: {
          'en': PhraseTranslation(text: 'Hello', verified: true),
          'es': PhraseTranslation(
            text: 'Hola',
            pronunciation: 'OH-lah',
            verified: true,
          ),
        },
      );

      BrowseDataService.setMockInstance(
        BrowseDataService(
          languageRepo: MockLanguageRepository(allEightLanguages),
          categoryRepo: MockCategoryRepository(const [
            Category(id: 'emergencies', group: 'safety', priority: 'critical'),
            Category(id: 'greetings', group: 'everyday', priority: 'essential'),
          ]),
          phraseRepo: MockPhraseRepository(const [unverifiedCritical, verifiedEveryday]),
        ),
      );

      // 1. Unverified critical phrase -> shows draft notice with warning color token
      await tester.pumpWidget(
        AppSettingsScope(
          controller: settings,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const PhraseStudyScreen(
              initialPhraseSlug: 'help-me',
              categoryId: 'emergencies',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final textFinder = find.text(draftCaption);
      expect(textFinder, findsOneWidget);
      final textWidget = tester.widget<Text>(textFinder);
      expect(textWidget.style?.color, AppColors.lightWarning);

      // 2. Verified phrase -> shows no draft notice
      await tester.pumpWidget(
        AppSettingsScope(
          controller: settings,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const PhraseStudyScreen(
              initialPhraseSlug: 'hello-verified',
              categoryId: 'greetings',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(draftCaption), findsNothing);
    });
  });

  // ─── 5. Multi-Script Rendering & Zero-Overflow Matrix (All 8 Languages) ────

  group('Multi-script rendering & overflow across all 8 languages', () {
    testWidgets('renders sample strings in all 8 languages at widths 320 & 360 and scales 1.0, 1.5, 2.0 with zero overflow', (tester) async {
      final activeAllEight = allEightLanguages
          .map((l) => l.copyWith(isActive: true))
          .toList();

      final fourQuizPhrases = [
        multiScriptPhrase,
        for (int idx = 2; idx <= 4; idx++)
          Phrase(
            id: 'p$idx',
            categoryId: 'directions',
            sortOrder: idx,
            translations: {
              for (final entry in multiScriptPhrase.translations.entries)
                entry.key: entry.value.copyWith(
                  text: '${entry.value.text} ($idx)',
                ),
            },
          ),
      ];

      BrowseDataService.setMockInstance(
        BrowseDataService(
          languageRepo: MockLanguageRepository(activeAllEight),
          categoryRepo: MockCategoryRepository(const [
            Category(
              id: 'directions',
              sortOrder: 1,
              group: 'travel',
              priority: 'essential',
              names: {'en': 'Directions'},
            ),
            Category(
              id: 'greetings',
              sortOrder: 2,
              group: 'everyday',
              priority: 'essential',
              names: {'en': 'Greetings'},
            ),
            Category(
              id: 'emergencies',
              sortOrder: 3,
              group: 'safety',
              priority: 'critical',
              names: {'en': 'Emergencies'},
            ),
          ]),
          phraseRepo: MockPhraseRepository(fourQuizPhrases),
        ),
      );

      final settings = LanguageSettingsController();
      await settings.load();

      for (final lang in activeAllEight) {
        // Verify Locale & fontFallback mapping for each language
        expect(LocalizedPhraseText.localeFor(lang.code).languageCode, isNotEmpty);
        expect(LocalizedPhraseText.fontFallbackFor(lang.code), isNotEmpty);

        final nativeCode = lang.code == 'en' ? 'es' : 'en';
        await settings.setLanguagePair(nativeCode: nativeCode, targetCode: lang.code);
        final trans = multiScriptPhrase.translationFor(lang.code)!;

        for (final width in [320.0, 360.0]) {
          for (final scale in [1.0, 1.5, 2.0]) {
            // Test PhraseCard + TranslationResultCard in a scrollable scaffold
            final aiResult = TranslationResult(
              status: TranslationStatus.ok,
              inputText: 'Excuse me, where is the restroom?',
              sourceLanguageCode: nativeCode,
              targetLanguageCode: lang.code,
              sourceLanguageName: 'English',
              targetLanguageName: lang.name,
              translatedText: trans.text,
              pronunciation: trans.pronunciation ?? '',
              exampleSentence: trans.exampleSentence ?? '',
              exampleTranslation: 'Excuse me, where is the restroom on this floor?',
              note: trans.meaningNote ?? '',
            );

            await tester.pumpWidget(
              MediaQuery(
                data: MediaQueryData(
                  size: Size(width, 700),
                  textScaler: TextScaler.linear(scale),
                ),
                child: AppSettingsScope(
                  controller: settings,
                  child: MaterialApp(
                    debugShowCheckedModeBanner: false,
                    theme: AppTheme.lightTheme,
                    home: Scaffold(
                      body: ListView(
                        padding: const EdgeInsets.all(12),
                        children: [
                          PhraseCard(phrase: multiScriptPhrase),
                          const SizedBox(height: 12),
                          TranslationResultCard(result: aiResult),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();
            expect(
              tester.takeException(),
              isNull,
              reason: 'Overflow on PhraseCard/TranslationResultCard for ${lang.code} at ${width}px / ${scale}x',
            );
          }
        }

        // Also test PhraseStudyScreen, CategoriesScreen, HomeScreen, SearchScreen, and QuizScreen at 320px / 2.0x
        final quizCtrl = QuizController();
        quizCtrl.startQuiz(
          allPhrases: fourQuizPhrases,
          nativeLanguageCode: nativeCode,
          targetLanguageCode: lang.code,
          questionCount: 2,
          random: Random(7),
        );
        quizCtrl.selectOption(0);
        quizCtrl.submitAnswer();

        for (final screen in <Widget>[
          const PhraseStudyScreen(
            initialPhraseSlug: 'where-is-the-bathroom',
            categoryId: 'directions',
          ),
          const CategoriesScreen(),
          const HomeScreen(),
          const SearchScreen(),
          const QuizScreen(),
        ]) {
          await tester.pumpWidget(
            MediaQuery(
              data: const MediaQueryData(
                size: Size(320.0, 700.0),
                textScaler: TextScaler.linear(2.0),
              ),
              child: AppSettingsScope(
                controller: settings,
                child: AppQuizScope(
                  controller: quizCtrl,
                  child: MaterialApp(
                    debugShowCheckedModeBanner: false,
                    theme: AppTheme.lightTheme,
                    home: screen,
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(
            tester.takeException(),
            isNull,
            reason: 'Overflow on ${screen.runtimeType} for ${lang.code} at 320px / 2.0x',
          );
        }
      }
    });
  });
}
