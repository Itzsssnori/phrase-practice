import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tts/flutter_tts.dart'
    show SpeechRateValidRange, TextToSpeechPlatform;
import 'package:material_ui/material_ui.dart';
import 'package:phrase_practice/content/privacy_copy.dart';
import 'package:phrase_practice/models/auth_user.dart';
import 'package:phrase_practice/models/category.dart';
import 'package:phrase_practice/models/language.dart';
import 'package:phrase_practice/models/phrase.dart';
import 'package:phrase_practice/models/phrase_translation.dart';
import 'package:phrase_practice/models/quiz.dart';
import 'package:phrase_practice/models/translation_entry.dart';
import 'package:phrase_practice/screens/phrase_study_screen.dart';
import 'package:phrase_practice/screens/profile_screen.dart';
import 'package:phrase_practice/screens/quiz_screen.dart';
import 'package:phrase_practice/services/auth_controller.dart';
import 'package:phrase_practice/services/browse_data_service.dart';
import 'package:phrase_practice/services/language_settings_controller.dart';
import 'package:phrase_practice/services/quiz_controller.dart';
import 'package:phrase_practice/services/speech_service.dart';
import 'package:phrase_practice/services/tts_engine.dart';
import 'package:phrase_practice/services/tts_voice_selector.dart';
import 'package:phrase_practice/theme/app_theme.dart';
import 'package:phrase_practice/widgets/app_audio_button.dart';
import 'package:phrase_practice/widgets/app_auth_scope.dart';
import 'package:phrase_practice/widgets/app_quiz_scope.dart';
import 'package:phrase_practice/widgets/app_settings_scope.dart';
import 'package:phrase_practice/widgets/app_speech_scope.dart';
import 'package:phrase_practice/widgets/translation_result_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'stage_3_browse_test.dart';
import 'stage_4_auth_test.dart' as auth_fakes;

/// Deterministic fake [TtsEngine] for testing [SpeechService] and UI widgets
/// without invoking native channels or real audio output.
class FakeTtsEngine implements TtsEngine {
  @override
  bool isWeb;

  List<TtsVoice> voicesToReturn;
  List<String> languagesToReturn;
  Set<String> availableLocales;
  SpeechRateValidRange? validRangeToReturn;

  /// When true, `speak()` automatically fires the registered `startHandler`.
  bool autoFireStartOnSpeak;

  /// When true, `speak()` throws an exception.
  bool throwOnSpeak;

  /// Value returned by `speak()` (defaults to `1`).
  dynamic speakReturnValue;

  final List<String> spokenTexts = [];
  final List<String> setLanguages = [];
  final List<TtsVoice> setVoices = [];
  final List<double> setSpeechRates = [];
  int stopCallCount = 0;
  int getVoicesCallCount = 0;

  VoidCallback? startHandler;
  VoidCallback? completionHandler;
  VoidCallback? cancelHandler;
  void Function(dynamic message)? errorHandler;

  FakeTtsEngine({
    this.isWeb = false,
    List<TtsVoice>? voices,
    List<String>? languages,
    Set<String>? availableLocales,
    this.validRangeToReturn,
    this.autoFireStartOnSpeak = true,
    this.throwOnSpeak = false,
    this.speakReturnValue = 1,
  })  : voicesToReturn = voices ??
            const [
              TtsVoice(name: 'English US', locale: 'en-US'),
              TtsVoice(name: 'Spanish Mexico', locale: 'es-MX'),
              TtsVoice(name: 'Filipino PH', locale: 'fil-PH'),
              TtsVoice(name: 'French France', locale: 'fr-FR'),
            ],
        languagesToReturn = languages ?? const [],
        availableLocales = availableLocales ?? <String>{};

  @override
  Future<List<TtsVoice>> getVoices() async {
    getVoicesCallCount++;
    return List<TtsVoice>.from(voicesToReturn);
  }

  @override
  Future<List<String>> getLanguages() async {
    return List<String>.from(languagesToReturn);
  }

  @override
  Future<bool> isLanguageAvailable(String locale) async {
    return availableLocales.contains(locale);
  }

  @override
  Future<SpeechRateValidRange?> getSpeechRateValidRange() async {
    return validRangeToReturn;
  }

  @override
  Future<void> setLanguage(String locale) async {
    setLanguages.add(locale);
  }

  @override
  Future<void> setVoice(TtsVoice voice) async {
    setVoices.add(voice);
  }

  @override
  Future<void> setSpeechRate(double rate) async {
    setSpeechRates.add(rate);
  }

  @override
  Future<dynamic> speak(String text) async {
    if (throwOnSpeak) {
      throw StateError('Simulated TTS speak failure');
    }
    spokenTexts.add(text);
    if (autoFireStartOnSpeak) {
      startHandler?.call();
    }
    return speakReturnValue;
  }

  @override
  Future<void> stop() async {
    stopCallCount++;
  }

  @override
  void setStartHandler(VoidCallback callback) {
    startHandler = callback;
  }

  @override
  void setCompletionHandler(VoidCallback callback) {
    completionHandler = callback;
  }

  @override
  void setCancelHandler(VoidCallback callback) {
    cancelHandler = callback;
  }

  @override
  void setErrorHandler(void Function(dynamic message) handler) {
    errorHandler = handler;
  }

  void simulateComplete() => completionHandler?.call();
  void simulateCancel() => cancelHandler?.call();
  void simulateError([dynamic msg = 'tts-error']) => errorHandler?.call(msg);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testLanguages = [
    const Language(code: 'en', name: 'English', nativeName: 'English', sortOrder: 1),
    const Language(code: 'es', name: 'Spanish', nativeName: 'Español', sortOrder: 2),
    const Language(code: 'fil', name: 'Filipino', nativeName: 'Filipino', sortOrder: 3),
    const Language(code: 'fr', name: 'French', nativeName: 'Français', sortOrder: 4),
  ];

  final testCategories = [
    const Category(
      id: 'greetings',
      sortOrder: 1,
      iconKey: 'greetings',
      names: {'en': 'Greetings', 'es': 'Saludos', 'fil': 'Mga Pagbati', 'fr': 'Salutations'},
      phraseCount: 2,
    ),
  ];

  final testPhrases = [
    const Phrase(
      id: 'hello-polite',
      categoryId: 'greetings',
      sortOrder: 1,
      translations: {
        'en': PhraseTranslation(
          text: 'Hello / Good day',
          pronunciation: '',
          meaningNote: 'Standard polite greeting.',
          exampleSentence: 'Hello, nice to meet you.',
        ),
        'es': PhraseTranslation(
          text: 'Hola, buenos días',
          pronunciation: 'OH-lah, BWEH-nohs DEE-ahs',
          meaningNote: 'Polite morning greeting.',
          exampleSentence: 'Hola, buenos días, ¿cómo está usted?',
        ),
        'fil': PhraseTranslation(
          text: 'Magandang araw po',
          pronunciation: 'mah-gahn-DAHNG AH-raw poh',
          meaningNote: 'Polite daytime greeting.',
          exampleSentence: 'Magandang araw po sa inyo.',
        ),
        'fr': PhraseTranslation(
          text: 'Bonjour, Madame / Monsieur',
          pronunciation: 'bon-ZHOOR, mah-DAHM / muh-SYUH',
          meaningNote: 'Polite French daytime greeting.',
          exampleSentence: 'Bonjour Monsieur, comment allez-vous ?',
        ),
      },
    ),
    const Phrase(
      id: 'thank-you-very-much',
      categoryId: 'greetings',
      sortOrder: 2,
      translations: {
        'en': PhraseTranslation(text: 'Thank you very much', exampleSentence: 'Thank you!'),
        'es': PhraseTranslation(
          text: 'Muchas gracias',
          pronunciation: 'MOO-chahs GRAH-syahs',
          exampleSentence: 'Muchas gracias por su ayuda.',
        ),
        'fil': PhraseTranslation(
          text: 'Maraming salamat po',
          pronunciation: 'mah-rah-MEENG sah-LAH-maht poh',
          exampleSentence: 'Maraming salamat po sa tulong.',
        ),
        'fr': PhraseTranslation(
          text: 'Merci beaucoup',
          pronunciation: 'mehr-SEE boh-KOO',
          exampleSentence: 'Merci beaucoup pour votre aide.',
        ),
      },
    ),
  ];

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    BrowseDataService.setMockInstance(
      BrowseDataService(
        languageRepo: MockLanguageRepository(testLanguages),
        categoryRepo: MockCategoryRepository(testCategories),
        phraseRepo: MockPhraseRepository(testPhrases),
      ),
    );
  });

  group('1. Pure Voice Selection & Rate Mapping (TtsVoiceSelector)', () {
    test('selects preferred locale in fallback order for every language code (en, es, fil, fr, ru, ja, ko, zh)', () {
      // en: en-US before en-GB
      final enMatch = TtsVoiceSelector.selectVoice(
        languageCode: 'en',
        voices: const [
          TtsVoice(name: 'UK English', locale: 'en-GB'),
          TtsVoice(name: 'US English', locale: 'en-US'),
        ],
      );
      expect(enMatch?.voice?.name, 'US English');

      // en fallback to en-* when en-US is absent
      final enFallback = TtsVoiceSelector.selectVoice(
        languageCode: 'en',
        voices: const [TtsVoice(name: 'AU English', locale: 'en-AU')],
      );
      expect(enFallback?.voice?.name, 'AU English');

      // es: es-MX -> es-419 -> es-US -> es-* (es-MX before es-ES)
      final esMxOverEsEs = TtsVoiceSelector.selectVoice(
        languageCode: 'es',
        voices: const [
          TtsVoice(name: 'Spain Spanish', locale: 'es-ES'),
          TtsVoice(name: 'Mexico Spanish', locale: 'es-MX'),
        ],
      );
      expect(esMxOverEsEs?.voice?.name, 'Mexico Spanish');

      final es419OverEsEs = TtsVoiceSelector.selectVoice(
        languageCode: 'es',
        voices: const [
          TtsVoice(name: 'Spain Spanish', locale: 'es-ES'),
          TtsVoice(name: 'LatAm Spanish', locale: 'es-419'),
        ],
      );
      expect(es419OverEsEs?.voice?.name, 'LatAm Spanish');

      final esUsOverEsEs = TtsVoiceSelector.selectVoice(
        languageCode: 'es',
        voices: const [
          TtsVoice(name: 'Spain Spanish', locale: 'es-ES'),
          TtsVoice(name: 'US Spanish', locale: 'es-US'),
        ],
      );
      expect(esUsOverEsEs?.voice?.name, 'US Spanish');

      final esAnyFallback = TtsVoiceSelector.selectVoice(
        languageCode: 'es',
        voices: const [TtsVoice(name: 'Spain Spanish', locale: 'es-ES')],
      );
      expect(esAnyFallback?.voice?.name, 'Spain Spanish');

      // fil: fil-PH -> fil -> tl-PH -> tl
      final filToTlPh = TtsVoiceSelector.selectVoice(
        languageCode: 'fil',
        voices: const [
          TtsVoice(name: 'Tagalog Bare', locale: 'tl'),
          TtsVoice(name: 'Tagalog PH', locale: 'tl-PH'),
        ],
      );
      expect(filToTlPh?.voice?.name, 'Tagalog PH');

      final filToTl = TtsVoiceSelector.selectVoice(
        languageCode: 'fil',
        availableLocales: const ['en-US', 'tl'],
      );
      expect(filToTl?.locale, 'tl');

      // fr: fr-FR before fr-CA, then any fr-*
      final frMatch = TtsVoiceSelector.selectVoice(
        languageCode: 'fr',
        voices: const [
          TtsVoice(name: 'Quebec French', locale: 'fr-CA'),
          TtsVoice(name: 'France French', locale: 'fr-FR'),
        ],
      );
      expect(frMatch?.voice?.name, 'France French');

      final frFallback = TtsVoiceSelector.selectVoice(
        languageCode: 'fr',
        voices: const [TtsVoice(name: 'Quebec French', locale: 'fr-CA')],
      );
      expect(frFallback?.voice?.name, 'Quebec French');

      // ru, ja, ko, zh
      expect(
        TtsVoiceSelector.selectVoice(
          languageCode: 'ru',
          voices: const [TtsVoice(name: 'Russian', locale: 'ru-RU')],
        )?.locale,
        'ru-RU',
      );
      expect(
        TtsVoiceSelector.selectVoice(
          languageCode: 'ja',
          voices: const [TtsVoice(name: 'Japanese', locale: 'ja-JP')],
        )?.locale,
        'ja-JP',
      );
      expect(
        TtsVoiceSelector.selectVoice(
          languageCode: 'ko',
          voices: const [TtsVoice(name: 'Korean', locale: 'ko-KR')],
        )?.locale,
        'ko-KR',
      );
      expect(
        TtsVoiceSelector.selectVoice(
          languageCode: 'zh',
          voices: const [
            TtsVoice(name: 'TW Mandarin', locale: 'zh-TW'),
            TtsVoice(name: 'CN Mandarin', locale: 'zh-CN'),
          ],
        )?.voice?.name,
        'CN Mandarin',
      );
      expect(
        TtsVoiceSelector.selectVoice(
          languageCode: 'zh',
          voices: const [TtsVoice(name: 'TW Mandarin', locale: 'zh-TW')],
        )?.voice?.name,
        'TW Mandarin',
      );
    });

    test('handles case-insensitivity and underscores (_) vs hyphens (-), and returns null when none match', () {
      final underscoreMatch = TtsVoiceSelector.selectVoice(
        languageCode: 'es',
        voices: const [TtsVoice(name: 'Android MX', locale: 'ES_mx')],
      );
      expect(underscoreMatch?.voice?.name, 'Android MX');

      final filUnderscore = TtsVoiceSelector.selectVoice(
        languageCode: 'fil',
        availableLocales: const ['TL_PH'],
      );
      expect(filUnderscore?.locale, 'TL_PH');

      final noneMatch = TtsVoiceSelector.selectVoice(
        languageCode: 'ja',
        voices: const [
          TtsVoice(name: 'English', locale: 'en-US'),
          TtsVoice(name: 'Spanish', locale: 'es-MX'),
        ],
        availableLocales: const ['en-US', 'es-MX'],
      );
      expect(noneMatch, isNull);
    });

    test('mapSpeechRate maps Normal and Slow for web and platform SpeechRateValidRange cases', () {
      // Web: 1.0 and 0.6
      expect(
        TtsVoiceSelector.mapSpeechRate(speed: SpeechSpeed.normal, isWeb: true),
        1.0,
      );
      expect(
        TtsVoiceSelector.mapSpeechRate(speed: SpeechSpeed.slow, isWeb: true),
        0.6,
      );

      // Android range (0.1 .. 2.0, normal 1.0) -> normal 1.0, slow 0.6
      final androidRange =
          SpeechRateValidRange(0.1, 1.0, 2.0, TextToSpeechPlatform.android);
      expect(
        TtsVoiceSelector.mapSpeechRate(
          speed: SpeechSpeed.normal,
          validRange: androidRange,
        ),
        closeTo(1.0, 1e-6),
      );
      expect(
        TtsVoiceSelector.mapSpeechRate(
          speed: SpeechSpeed.slow,
          validRange: androidRange,
        ),
        closeTo(0.6, 1e-6),
      );

      // iOS range (0.0 .. 1.0, normal 0.5) -> normal 0.5, slow 0.3
      final iosRange =
          SpeechRateValidRange(0.0, 0.5, 1.0, TextToSpeechPlatform.ios);
      expect(
        TtsVoiceSelector.mapSpeechRate(
          speed: SpeechSpeed.normal,
          validRange: iosRange,
        ),
        closeTo(0.5, 1e-6),
      );
      expect(
        TtsVoiceSelector.mapSpeechRate(
          speed: SpeechSpeed.slow,
          validRange: iosRange,
        ),
        closeTo(0.3, 1e-6),
      );

      // High-minimum range (0.4 .. 1.0, normal 0.5) -> slow never below minimum (0.4)
      final highMinRange =
          SpeechRateValidRange(0.4, 0.5, 1.0, TextToSpeechPlatform.android);
      expect(
        TtsVoiceSelector.mapSpeechRate(
          speed: SpeechSpeed.slow,
          validRange: highMinRange,
        ),
        closeTo(0.4, 1e-6),
      );
    });
  });

  group('2. SpeechService Lifecycle, Late-Loading Web Voices & Error Handling', () {
    test('resolves availability states and retries for late-loading web voices', () async {
      final engine = FakeTtsEngine(
        isWeb: true,
        voices: const [],
      );
      final service = SpeechService(
        engine: engine,
        maxVoiceLoadWait: const Duration(milliseconds: 200),
        voicePollInterval: const Duration(milliseconds: 40),
      );

      // Initially checking before any resolution
      expect(service.availabilityFor('fr'), VoiceAvailability.checking);

      // Simulate voices loading 80ms after check starts
      Future<void>.delayed(const Duration(milliseconds: 80), () {
        engine.voicesToReturn = const [
          TtsVoice(name: 'Web French', locale: 'fr-FR'),
        ];
      });

      final status = await service.checkAvailability('fr');
      expect(status, VoiceAvailability.available);
      expect(engine.getVoicesCallCount, greaterThan(1));

      // Language with no voice resolves to unavailable after retry window
      final missingStatus = await service.checkAvailability('ko');
      expect(missingStatus, VoiceAvailability.unavailable);

      // Lazy re-check when screen opens again after voices load later
      engine.voicesToReturn = const [
        TtsVoice(name: 'Web French', locale: 'fr-FR'),
        TtsVoice(name: 'Web Korean', locale: 'ko-KR'),
      ];
      final rechecked = await service.ensureLanguageChecked('ko');
      expect(rechecked, VoiceAvailability.available);

      service.dispose();
    });

    test('enforces one playback at a time, tap-to-stop, stop on language change, and stop on background', () async {
      final settings = LanguageSettingsController();
      await settings.load();
      final engine = FakeTtsEngine();
      final service = SpeechService(
        engine: engine,
        settingsController: settings,
      );

      // Start first utterance
      final started1 = await service.speak(
        text: 'Hola, buenos días',
        languageCode: 'es',
        utteranceId: 'u1',
      );
      expect(started1, isTrue);
      expect(service.isPlaying, isTrue);
      expect(service.isPlayingUtterance('u1'), isTrue);
      expect(engine.spokenTexts, ['Hola, buenos días']);

      // Tapping a different button stops current playback first
      final started2 = await service.speak(
        text: 'Muchas gracias',
        languageCode: 'es',
        utteranceId: 'u2',
      );
      expect(started2, isTrue);
      expect(engine.stopCallCount, 1);
      expect(service.isPlayingUtterance('u1'), isFalse);
      expect(service.isPlayingUtterance('u2'), isTrue);
      expect(engine.spokenTexts, ['Hola, buenos días', 'Muchas gracias']);

      // Tapping the active button stops it without speaking again
      await service.speak(
        text: 'Muchas gracias',
        languageCode: 'es',
        utteranceId: 'u2',
      );
      expect(service.isPlaying, isFalse);
      expect(engine.stopCallCount, 2);
      expect(engine.spokenTexts.length, 2);

      // Changing target language stops active playback
      await service.speak(
        text: 'Hola, buenos días',
        languageCode: 'es',
        utteranceId: 'u1',
      );
      expect(service.isPlaying, isTrue);
      await settings.setTargetLanguage('fil');
      expect(service.isPlaying, isFalse);
      expect(engine.stopCallCount, 3);

      // App going to background stops active playback
      await service.speak(
        text: 'Magandang araw po',
        languageCode: 'fil',
        utteranceId: 'u3',
      );
      expect(service.isPlaying, isTrue);
      service.didChangeAppLifecycleState(AppLifecycleState.paused);
      expect(service.isPlaying, isFalse);
      expect(engine.stopCallCount, 4);

      service.dispose();
    });

    test('handles engine error and 10-second start timeout gracefully without throwing', () async {
      // 1. Exception / error callback during speak
      final engine = FakeTtsEngine(throwOnSpeak: true);
      final service = SpeechService(engine: engine);
      bool errorNotified = false;

      final ok = await service.speak(
        text: 'Hola',
        languageCode: 'es',
        utteranceId: 'err-1',
        onError: () => errorNotified = true,
      );
      expect(ok, isFalse);
      expect(service.isPlaying, isFalse);
      expect(errorNotified, isTrue);
      expect(service.hasErrorForUtterance('err-1'), isTrue);
      service.dispose();

      // 2. Start timeout when no start event fires
      final timeoutEngine = FakeTtsEngine(autoFireStartOnSpeak: false);
      final timeoutService = SpeechService(
        engine: timeoutEngine,
        startTimeoutDuration: const Duration(milliseconds: 60),
      );
      bool timeoutNotified = false;

      await timeoutService.speak(
        text: 'Bonjour',
        languageCode: 'fr',
        utteranceId: 'timeout-1',
        onError: () => timeoutNotified = true,
      );
      expect(timeoutService.isPlaying, isTrue);

      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(timeoutService.isPlaying, isFalse);
      expect(timeoutNotified, isTrue);
      timeoutService.dispose();
    });
  });

  group('3. UI & Accessibility: AppAudioButton, PhraseStudy, Translator, Quiz, Settings, Privacy', () {
    testWidgets('No autoplay on PhraseStudy, speaks target text only, and recall mode stays hidden on audio tap', (tester) async {
      final settings = LanguageSettingsController();
      await settings.load();
      await settings.setStudyRecallMode(true);

      final engine = FakeTtsEngine();
      final speech = SpeechService(engine: engine, settingsController: settings);

      await tester.pumpWidget(
        AppSettingsScope(
          controller: settings,
          child: AppSpeechScope(
            controller: speech,
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const PhraseStudyScreen(
                initialPhraseSlug: 'hello-polite',
                categoryId: 'greetings',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Never autoplays on mount
      expect(engine.spokenTexts, isEmpty);

      // Recall mode hides main translation and pronunciation
      expect(find.text('Tap to reveal'), findsOneWidget);
      expect(find.text('Hola, buenos días'), findsNothing);

      // Tap main pronunciation audio button while recall mode hides translation
      final playMainBtn = find.byTooltip('Play pronunciation in Spanish');
      expect(playMainBtn, findsOneWidget);
      await tester.tap(playMainBtn);
      await tester.pump();

      // Speaks target-language translation text ONLY (never pronunciation or native text)
      expect(engine.spokenTexts, ['Hola, buenos días']);
      // Hidden translation text MUST remain hidden!
      expect(find.text('Tap to reveal'), findsOneWidget);
      expect(find.text('Hola, buenos días'), findsNothing);

      // While playing, button shows Stop tooltip
      expect(find.byTooltip('Stop'), findsOneWidget);

      // Tap example sentence audio button -> stops main and speaks target example sentence
      final playExampleBtn = find.byTooltip('Play example in Spanish');
      expect(playExampleBtn, findsOneWidget);
      await tester.tap(playExampleBtn);
      await tester.pump();

      expect(engine.spokenTexts, [
        'Hola, buenos días',
        'Hola, buenos días, ¿cómo está usted?',
      ]);

      speech.dispose();
    });

    testWidgets('Unavailable voice disables AppAudioButton with clear tooltip and semantics label', (tester) async {
      final settings = LanguageSettingsController();
      await settings.load();
      final engine = FakeTtsEngine(voices: const []); // No voices available
      final speech = SpeechService(engine: engine, settingsController: settings);

      await tester.pumpWidget(
        AppSettingsScope(
          controller: settings,
          child: AppSpeechScope(
            controller: speech,
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const Scaffold(
                body: Center(
                  child: AppAudioButton(
                    text: 'Hola',
                    languageCode: 'es',
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byTooltip('No voice for Spanish on this device'),
        findsOneWidget,
      );
      final iconButton = tester.widget<IconButton>(find.byType(IconButton));
      expect(iconButton.onPressed, isNull);

      // Verify minimum 48x48 touch target
      final box = tester.getSize(find.byType(AppAudioButton));
      expect(box.width, greaterThanOrEqualTo(48.0));
      expect(box.height, greaterThanOrEqualTo(48.0));

      speech.dispose();
    });

    testWidgets('Playback error shows "Couldn\'t play audio" snackbar and returns button to idle', (tester) async {
      final settings = LanguageSettingsController();
      await settings.load();
      final engine = FakeTtsEngine(throwOnSpeak: true);
      final speech = SpeechService(engine: engine, settingsController: settings);

      await tester.pumpWidget(
        AppSettingsScope(
          controller: settings,
          child: AppSpeechScope(
            controller: speech,
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const Scaffold(
                body: Center(
                  child: AppAudioButton(
                    text: 'Hola',
                    languageCode: 'es',
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Play pronunciation in Spanish'));
      await tester.pump();

      expect(find.text("Couldn't play audio"), findsOneWidget);
      expect(find.byTooltip('Play pronunciation in Spanish'), findsOneWidget);

      speech.dispose();
    });

    testWidgets('TranslationResultCard provides audio buttons for both translation and example sentence', (tester) async {
      final engine = FakeTtsEngine();
      final speech = SpeechService(engine: engine);

      const result = TranslationResult(
        status: TranslationStatus.ok,
        inputText: 'Good morning',
        translatedText: 'Buenos días',
        pronunciation: 'BWEH-nohs DEE-ahs',
        exampleSentence: 'Buenos días a todos.',
        exampleTranslation: 'Good morning everyone.',
        note: '',
        sourceLanguageCode: 'en',
        sourceLanguageName: 'English',
        targetLanguageCode: 'es',
        targetLanguageName: 'Spanish',
        fromHistory: false,
      );

      await tester.pumpWidget(
        AppSpeechScope(
          controller: speech,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(
              body: SingleChildScrollView(
                child: TranslationResultCard(result: result),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(engine.spokenTexts, isEmpty);

      await tester.tap(find.byTooltip('Play pronunciation in Spanish'));
      await tester.pump();
      expect(engine.spokenTexts, ['Buenos días']);

      await tester.tap(find.byTooltip('Play example in Spanish'));
      await tester.pump();
      expect(engine.spokenTexts, ['Buenos días', 'Buenos días a todos.']);

      speech.dispose();
    });

    testWidgets('QuizScreen places audio button on target->native question and on native->target feedback panel', (tester) async {
      final settings = LanguageSettingsController();
      await settings.load();
      final engine = FakeTtsEngine();
      final speech = SpeechService(engine: engine, settingsController: settings);

      final quizPhrases = [
        ...testPhrases,
        const Phrase(
          id: 'p3',
          categoryId: 'greetings',
          sortOrder: 3,
          translations: {
            'en': PhraseTranslation(text: 'Good evening'),
            'es': PhraseTranslation(text: 'Buenas noches'),
          },
        ),
        const Phrase(
          id: 'p4',
          categoryId: 'greetings',
          sortOrder: 4,
          translations: {
            'en': PhraseTranslation(text: 'Please'),
            'es': PhraseTranslation(text: 'Por favor'),
          },
        ),
      ];

      final quizCtrl = QuizController();
      quizCtrl.startQuiz(
        allPhrases: quizPhrases,
        nativeLanguageCode: 'en',
        targetLanguageCode: 'es',
        questionCount: 4,
        random: Random(7),
      );

      await tester.pumpWidget(
        AppSettingsScope(
          controller: settings,
          child: AppSpeechScope(
            controller: speech,
            child: AppQuizScope(
              controller: quizCtrl,
              child: MaterialApp(
                theme: AppTheme.lightTheme,
                home: const QuizScreen(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final q = quizCtrl.currentQuestion!;
      if (q.direction == QuizDirection.targetToNative) {
        // Question card has audio button before answering
        expect(find.byTooltip('Play pronunciation in Spanish'), findsOneWidget);
      } else {
        // Native -> target: no audio button before answering, appears in feedback panel after answering
        expect(find.byTooltip('Play pronunciation in Spanish'), findsNothing);
        quizCtrl.selectOption(q.correctIndex);
        quizCtrl.submitAnswer();
        await tester.pumpAndSettle();
        expect(find.byTooltip('Play pronunciation in Spanish'), findsOneWidget);
      }

      speech.dispose();
    });

    testWidgets('Speech speed persists and stays in sync between Settings and Phrase Study, and Audio voices section lists active languages', (tester) async {
      final settings = LanguageSettingsController();
      await settings.load();
      expect(settings.speechSpeed, SpeechSpeed.normal);

      // Only English and Spanish voices present; Filipino & French unavailable
      final engine = FakeTtsEngine(
        voices: const [
          TtsVoice(name: 'English US', locale: 'en-US'),
          TtsVoice(name: 'Spanish MX', locale: 'es-MX'),
        ],
      );
      final speech = SpeechService(engine: engine, settingsController: settings);
      final authRepo = auth_fakes.FakeAuthRepository(
        initialUser: const AuthUser(uid: 'u1', email: 'ana@example.com', emailVerified: true),
      );
      final authCtrl = AuthController(
        authRepository: authRepo,
        profileRepository: auth_fakes.FakeProfileRepository(),
      );

      // 1. Toggle Speech speed on PhraseStudyScreen from Normal -> Slow
      await tester.pumpWidget(
        AppAuthScope(
          controller: authCtrl,
          child: AppSettingsScope(
            controller: settings,
            child: AppSpeechScope(
              controller: speech,
              child: MaterialApp(
                theme: AppTheme.lightTheme,
                home: const PhraseStudyScreen(
                  initialPhraseSlug: 'hello-polite',
                  categoryId: 'greetings',
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Normal'), findsOneWidget);
      await tester.tap(find.text('Normal'));
      await tester.pumpAndSettle();
      expect(settings.speechSpeed, SpeechSpeed.slow);
      expect(find.text('Slow'), findsOneWidget);

      // Verify persistence in SharedPreferences
      final reloaded = LanguageSettingsController();
      await reloaded.load();
      expect(reloaded.speechSpeed, SpeechSpeed.slow);

      // 2. Open ProfileScreen (Settings) and confirm Slow is selected and Audio voices section shows statuses
      await tester.pumpWidget(
        AppAuthScope(
          controller: authCtrl,
          child: AppSettingsScope(
            controller: settings,
            child: AppSpeechScope(
              controller: speech,
              child: MaterialApp(
                theme: AppTheme.lightTheme,
                home: const ProfileScreen(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Scroll down to Speech Speed in the Reading section first
      await tester.scrollUntilVisible(
        find.text('Speech Speed'),
        150.0,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(find.text('Speech Speed'), findsOneWidget);
      final slowChip = tester.widget<ChoiceChip>(
        find.widgetWithText(ChoiceChip, 'Slow'),
      );
      expect(slowChip.selected, isTrue);

      // Scroll down to Audio voices section
      await tester.scrollUntilVisible(
        find.text('Audio voices'),
        100.0,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(find.text('Audio voices'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('French'),
        100.0,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Availability depends on the device or browser.'),
        findsOneWidget,
      );
      expect(find.text('Available'), findsAtLeastNWidgets(2));
      expect(find.text('Not available on this device'), findsAtLeastNWidgets(1));
      expect(find.text('Recheck'), findsOneWidget);

      // Tap Recheck after adding Filipino voice
      engine.voicesToReturn = const [
        TtsVoice(name: 'English US', locale: 'en-US'),
        TtsVoice(name: 'Spanish MX', locale: 'es-MX'),
        TtsVoice(name: 'Filipino PH', locale: 'fil-PH'),
        TtsVoice(name: 'French FR', locale: 'fr-FR'),
      ];
      await tester.tap(find.text('Recheck'));
      await tester.pumpAndSettle();
      expect(find.text('Not available on this device'), findsNothing);

      speech.dispose();
      authCtrl.dispose();
      authRepo.dispose();
    });

    test('PrivacyCopy includes plain-language sentence about device/browser speech engine', () {
      final allText = PrivacyCopy.sections.map((s) => s.body).join(' ');
      expect(
        allText,
        contains(
          "Pronunciation audio is produced by your device's or browser's built-in speech engine, and depending on the browser the text may be processed by its provider.",
        ),
      );
    });
  });
}
