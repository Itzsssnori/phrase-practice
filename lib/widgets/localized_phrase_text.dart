import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';
import '../models/language.dart';

/// Unified multi-script text rendering helper and widget for all 8 languages
/// (`en`, `es`, `fil`, `fr`, `ru`, `ja`, `ko`, `zh`).
///
/// Applies the proper [Locale] (essential for CJK Han unification disambiguation)
/// and a script-prioritized Noto Sans font fallback chain (`Noto Sans SC`,
/// `Noto Sans JP`, `Noto Sans KR`, `Noto Sans` for Cyrillic) while keeping
/// English and Latin-script languages in the app's primary `Inter` font.
class LocalizedPhraseText extends StatelessWidget {
  final String text;
  final String languageCode;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool softWrap;

  const LocalizedPhraseText(
    this.text, {
    super.key,
    required this.languageCode,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap = true,
  });

  /// Resolves the canonical [Locale] for [languageCode] so Flutter's text shaper
  /// selects region-appropriate glyphs (especially for Simplified Chinese vs Japanese kanji).
  static Locale localeFor(String languageCode) {
    switch (languageCode.toLowerCase()) {
      case 'zh':
        return const Locale.fromSubtags(
          languageCode: 'zh',
          scriptCode: 'Hans',
          countryCode: 'CN',
        );
      case 'ja':
        return const Locale('ja', 'JP');
      case 'ko':
        return const Locale('ko', 'KR');
      case 'ru':
        return const Locale('ru', 'RU');
      case 'fr':
        return const Locale('fr', 'FR');
      case 'es':
        return const Locale('es', 'MX');
      case 'fil':
        return const Locale('fil', 'PH');
      case 'en':
      default:
        return const Locale('en', 'US');
    }
  }

  /// Returns the script-prioritized font fallback list for [languageCode],
  /// including Google Fonts registered family names when available.
  static List<String> fontFallbackFor(String languageCode) {
    final code = languageCode.toLowerCase();
    switch (code) {
      case 'zh':
        return const [
          'Noto Sans SC',
          'NotoSansSC_regular',
          'Noto Sans JP',
          'Noto Sans KR',
          'Noto Sans',
          'sans-serif',
        ];
      case 'ja':
        return const [
          'Noto Sans JP',
          'NotoSansJP_regular',
          'Noto Sans SC',
          'Noto Sans KR',
          'Noto Sans',
          'sans-serif',
        ];
      case 'ko':
        return const [
          'Noto Sans KR',
          'NotoSansKR_regular',
          'Noto Sans JP',
          'Noto Sans SC',
          'Noto Sans',
          'sans-serif',
        ];
      case 'ru':
        return const [
          'Inter',
          'Noto Sans',
          'NotoSans_regular',
          'Noto Sans SC',
          'Noto Sans JP',
          'Noto Sans KR',
          'sans-serif',
        ];
      case 'en':
      case 'es':
      case 'fil':
      case 'fr':
      default:
        return const [
          'Inter',
          'Noto Sans',
          'Noto Sans SC',
          'Noto Sans JP',
          'Noto Sans KR',
          'sans-serif',
        ];
    }
  }

  /// Applies the appropriate [Locale] and script-aware font family/fallback list
  /// to [baseStyle] for [languageCode].
  ///
  /// Keeps English and Latin-script languages (`en`, `es`, `fil`, `fr`) in the
  /// existing `Inter` font while configuring Noto Sans CJK/Cyrillic fallbacks.
  static TextStyle styleFor(
    TextStyle? baseStyle,
    String languageCode, {
    bool preloadGoogleFonts = false,
  }) {
    final base = baseStyle ?? const TextStyle();
    final locale = localeFor(languageCode);
    final fallbacks = fontFallbackFor(languageCode);
    final script = Language.defaultScriptFor(languageCode);

    if (preloadGoogleFonts && script != 'Latin') {
      try {
        switch (languageCode.toLowerCase()) {
          case 'zh':
            return GoogleFonts.notoSansSc(textStyle: base).copyWith(
              locale: locale,
              fontFamilyFallback: fallbacks,
            );
          case 'ja':
            return GoogleFonts.notoSansJp(textStyle: base).copyWith(
              locale: locale,
              fontFamilyFallback: fallbacks,
            );
          case 'ko':
            return GoogleFonts.notoSansKr(textStyle: base).copyWith(
              locale: locale,
              fontFamilyFallback: fallbacks,
            );
          case 'ru':
            return GoogleFonts.notoSans(textStyle: base).copyWith(
              locale: locale,
              fontFamilyFallback: fallbacks,
            );
        }
      } catch (_) {
        // Fallback safely when offline or in test environments
      }
    }

    return base.copyWith(
      locale: locale,
      fontFamilyFallback: fallbacks,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      locale: localeFor(languageCode),
      style: styleFor(style, languageCode),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      softWrap: softWrap,
    );
  }
}
