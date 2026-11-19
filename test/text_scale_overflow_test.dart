import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:phrase_practice/models/category.dart';
import 'package:phrase_practice/models/phrase.dart';
import 'package:phrase_practice/models/phrase_translation.dart';
import 'package:phrase_practice/services/language_settings_controller.dart';
import 'package:phrase_practice/theme/app_theme.dart';
import 'package:phrase_practice/widgets/app_settings_scope.dart';
import 'package:phrase_practice/widgets/category_card.dart';
import 'package:phrase_practice/widgets/phrase_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  final testCategories = [
    const Category(
      id: 'emergencies',
      sortOrder: 1,
      iconKey: 'emergencies',
      names: {'en': 'Emergencies', 'es': 'Emergencias', 'fil': 'Mga Emergency'},
      phraseCount: 10,
    ),
  ];

  final testPhrases = [
    const Phrase(
      id: 'i-am-allergic-to-peanuts',
      categoryId: 'food',
      sortOrder: 1,
      translations: {
        'en': PhraseTranslation(
          text: 'I am allergic to peanuts, please make sure there are no traces of nuts in the food.',
          exampleSentence: 'Please tell the chef that I have a severe allergic reaction to peanuts and tree nuts.',
        ),
        'es': PhraseTranslation(
          text: 'Soy alérgico al maní, por favor asegúrese de que no haya rastros en los ingredientes.',
          pronunciation: 'soy ah-LEHR-hee-koh ahl mah-NEE pohr fah-VOHR ah-seh-GOO-reh-seh',
          meaningNote: 'En México y Centroamérica se dice cacahuate en vez de maní.',
          exampleSentence: 'Por favor tenga muchísimo cuidado al preparar el plato, soy alérgico al maní.',
        ),
        'fil': PhraseTranslation(
          text: 'May allergy po ako sa mani, pakisigurado po na walang kahit anong bakas ng mani sa pagkain.',
          pronunciation: 'my AH-lehr-jee poh ah-KOH sah mah-NEE pah-kee-see-GOO-rah-doh poh',
          meaningNote: 'Mahalagang sabihin kaagad sa naghahain bago simulan ang pagluluto ng pagkain.',
          exampleSentence: 'Pakisabihan po ang kusina na may matinding allergy po ako sa lahat ng uri ng mani.',
        ),
      },
    ),
  ];

  Widget wrapWithTheme({
    required Widget child,
    required bool isDark,
    required LanguageSettingsController controller,
    double textScale = 1.5,
  }) {
    return AppSettingsScope(
      controller: controller,
      child: MediaQuery(
        data: MediaQueryData(
          size: const Size(390, 844),
          textScaler: TextScaler.linear(textScale),
        ),
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
          home: child,
        ),
      ),
    );
  }

  testWidgets('CategoryCard renders without overflow at 1.5x scale in light and dark mode', (tester) async {
    for (final isDark in [false, true]) {
      final controller = LanguageSettingsController();
      await controller.load();

      await tester.pumpWidget(
        wrapWithTheme(
          isDark: isDark,
          controller: controller,
          textScale: 1.5,
          child: Scaffold(
            body: Center(
              child: SizedBox(
                width: 320,
                child: CategoryCard(
                  category: testCategories.first,
                  onTap: () {},
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('PhraseCard renders long translations without overflow at 1.5x scale', (tester) async {
    for (final isDark in [false, true]) {
      final controller = LanguageSettingsController();
      await controller.load();

      await tester.pumpWidget(
        wrapWithTheme(
          isDark: isDark,
          controller: controller,
          textScale: 1.5,
          child: Scaffold(
            body: SingleChildScrollView(
              child: PhraseCard(
                phrase: testPhrases.first,
                targetLanguageCode: 'fil',
                nativeLanguageCode: 'en',
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });
}
