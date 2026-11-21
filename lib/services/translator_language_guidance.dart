import '../models/language.dart';

/// Per-language translation register, script, and pronunciation guidance for the AI translator.
class TranslatorLanguageGuidance {
  TranslatorLanguageGuidance._();

  /// Map of ISO language code to register and dialect instruction used by the prompt builder.
  static const Map<String, String> guidanceByCode = {
    'en': 'Use neutral international English.',
    'es': 'Use neutral Latin American Spanish with polite "usted"/"ustedes" forms (avoid Peninsular "vosotros").',
    'fil': 'Use natural conversational Filipino with "po" for polite phrases.',
    'fr': 'Use standard French with polite "vous" forms.',
    'ru': 'Use standard Russian in Cyrillic script with polite "вы" forms.',
    'ja': 'Use polite Japanese (です/ます style) in standard Japanese script (kanji and kana).',
    'ko': 'Use polite Korean (해요체 style) in Hangul.',
    'zh': 'Use Mandarin in Simplified Chinese characters (简体字), using 请 and 您 where natural.',
  };

  /// Detailed pronunciation format guidance for each pronunciation system.
  static String pronunciationInstructionFor(Language targetLanguage) {
    final sys = targetLanguage.effectivePronunciationSystem;
    switch (sys) {
      case 'Pinyin':
        return 'Provide Hanyu Pinyin with tone marks (e.g. "Qǐngwèn") in "pronunciation".';
      case 'Romaji':
        return 'Provide Hepburn romaji (e.g. "Sumimasen") in "pronunciation".';
      case 'Revised Romanization':
        return 'Provide Revised Romanization of Korean (e.g. "Annyeonghaseyo") in "pronunciation".';
      case 'Latin transliteration':
        return 'Provide a clear Latin transliteration for Russian (e.g. "Izvinite") in "pronunciation".';
      case 'Respelling':
      default:
        return 'Provide a simple readable phonetic respelling for an English speaker (e.g. "OH-lah") in "pronunciation", or an empty string if the target language is English.';
    }
  }

  /// Returns the register guidance for [languageCode], falling back to a polite travel register.
  static String guidanceFor(String languageCode) {
    return guidanceByCode[languageCode.toLowerCase()] ??
        'Use a natural, polite register suitable for travelers.';
  }
}
