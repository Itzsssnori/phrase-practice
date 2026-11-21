import 'package:flutter_tts/flutter_tts.dart' show SpeechRateValidRange;

/// User-selectable speech playback speed.
enum SpeechSpeed {
  normal,
  slow,
}

/// Represents a platform-reported TTS voice with a name and BCP-47 locale tag.
class TtsVoice {
  final String name;
  final String locale;

  const TtsVoice({
    required this.name,
    required this.locale,
  });

  Map<String, String> toMap() => {
        'name': name,
        'locale': locale,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TtsVoice &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          locale == other.locale;

  @override
  int get hashCode => Object.hash(name, locale);

  @override
  String toString() => 'TtsVoice(name: $name, locale: $locale)';
}

/// Result of matching a target language against platform-reported voices and locales.
class TtsVoiceMatch {
  /// Specific voice matched, if the platform reported a voice list.
  final TtsVoice? voice;

  /// Concrete locale tag selected (e.g. "es-MX", "tl-PH", "fr-FR").
  final String locale;

  const TtsVoiceMatch({
    this.voice,
    required this.locale,
  });

  @override
  String toString() => 'TtsVoiceMatch(locale: $locale, voice: $voice)';
}

/// Configuration and pure selection/rate-mapping functions for Text-to-Speech.
class TtsVoiceSelector {
  TtsVoiceSelector._();

  /// Preferred locale fallback chains keyed by language code.
  ///
  /// Starts with each language's canonical `ttsLocale` and then falls back
  /// in priority order:
  /// - `en`: `en-US`, then any `en-*`
  /// - `es`: `es-MX`, `es-419`, `es-US`, then any `es-*` (neutral Latin American Spanish)
  /// - `fil`: `fil-PH`, `fil`, `tl-PH`, `tl`, then any `fil-*` or `tl-*`
  /// - `fr`: `fr-FR`, then any `fr-*`
  /// - `ru`: `ru-RU`, then any `ru-*`
  /// - `ja`: `ja-JP`, then any `ja-*`
  /// - `ko`: `ko-KR`, then any `ko-*`
  /// - `zh`: `zh-CN`, then any `zh-*`
  static const Map<String, List<String>> preferredLocalesByLanguage = {
    'en': ['en-US', 'en-*', 'en'],
    'es': ['es-MX', 'es-419', 'es-US', 'es-*', 'es'],
    'fil': ['fil-PH', 'fil', 'tl-PH', 'tl', 'fil-*', 'tl-*'],
    'fr': ['fr-FR', 'fr-*', 'fr'],
    'ru': ['ru-RU', 'ru-*', 'ru'],
    'ja': ['ja-JP', 'ja-*', 'ja'],
    'ko': ['ko-KR', 'ko-*', 'ko'],
    'zh': ['zh-CN', 'zh-Hans-CN', 'zh-Hans', 'zh-*', 'zh'],
  };

  /// Returns the preferred locale patterns for [languageCode], optionally
  /// prepending a custom [ttsLocale] from the [Language] model if not already first.
  static List<String> preferredLocalesFor(
    String languageCode, {
    String? ttsLocale,
  }) {
    final code = languageCode.trim().toLowerCase();
    final defaults = preferredLocalesByLanguage[code] ?? [code, '$code-*'];
    if (ttsLocale == null || ttsLocale.trim().isEmpty) {
      return defaults;
    }
    final normalizedTts = normalizeLocale(ttsLocale);
    final result = <String>[ttsLocale.trim()];
    for (final pattern in defaults) {
      if (normalizeLocale(pattern) != normalizedTts) {
        result.add(pattern);
      }
    }
    return result;
  }

  /// Normalizes a locale tag by trimming, lowercasing, and replacing `_` with `-`.
  static String normalizeLocale(String raw) {
    return raw.trim().toLowerCase().replaceAll('_', '-');
  }

  /// Checks whether [candidateLocale] matches [pattern] (case-insensitive,
  /// treating `_` and `-` as identical).
  ///
  /// Supports:
  /// - Exact match: `"es-MX"` matches `"es-mx"` or `"es_MX"`.
  /// - Prefix wildcard: `"es-*"` matches `"es-ES"`, `"es-AR"`, or `"es"`.
  static bool localeMatchesPattern(String candidateLocale, String pattern) {
    final candidate = normalizeLocale(candidateLocale);
    final normPattern = normalizeLocale(pattern);
    if (candidate.isEmpty || normPattern.isEmpty) return false;

    if (normPattern.endsWith('-*')) {
      final prefix = normPattern.substring(0, normPattern.length - 2);
      return candidate == prefix || candidate.startsWith('$prefix-');
    }
    return candidate == normPattern;
  }

  /// Pure function that selects the best matching voice or locale for [languageCode]
  /// given platform-reported [voices], [availableLocales], and an optional
  /// [preferredLocales] override list.
  ///
  /// Returns `null` when no reported voice or locale matches any preference for
  /// [languageCode].
  static TtsVoiceMatch? selectVoice({
    required String languageCode,
    List<TtsVoice> voices = const [],
    List<String> availableLocales = const [],
    List<String>? preferredLocales,
  }) {
    final preferences =
        preferredLocales ?? preferredLocalesFor(languageCode);

    for (final pattern in preferences) {
      // 1. Check reported voices first for this priority pattern.
      for (final voice in voices) {
        if (localeMatchesPattern(voice.locale, pattern)) {
          return TtsVoiceMatch(
            voice: voice,
            locale: voice.locale,
          );
        }
      }

      // 2. Check reported language/locale strings for this priority pattern.
      for (final rawLocale in availableLocales) {
        if (localeMatchesPattern(rawLocale, pattern)) {
          return TtsVoiceMatch(
            voice: null,
            locale: rawLocale,
          );
        }
      }
    }

    return null;
  }

  /// Pure function mapping [SpeechSpeed] (`normal` or `slow`) to the platform's
  /// speech rate range.
  ///
  /// - On Web (or when [validRange] is unavailable): uses `1.0` for Normal and
  ///   `0.6` for Slow.
  /// - When [validRange] is provided by the platform:
  ///   - Normal uses `validRange.normal` clamped within `[validRange.min, validRange.max]`.
  ///   - Slow is 60% of `validRange.normal`, clamped so it is never below
  ///     `validRange.min` (and if `validRange.min <= 0`, at least `0.05`).
  static double mapSpeechRate({
    required SpeechSpeed speed,
    SpeechRateValidRange? validRange,
    bool isWeb = false,
  }) {
    if (isWeb || validRange == null) {
      return speed == SpeechSpeed.slow ? 0.6 : 1.0;
    }

    final minRate = validRange.min;
    final maxRate = validRange.max >= minRate ? validRange.max : minRate;
    final normalRate = validRange.normal.clamp(minRate, maxRate);

    if (speed == SpeechSpeed.normal) {
      return normalRate;
    }

    final rawSlow = normalRate * 0.6;
    final effectiveFloor = minRate > 0.0 ? minRate : 0.05;
    final clampedSlow = rawSlow < effectiveFloor ? effectiveFloor : rawSlow;
    return clampedSlow.clamp(minRate, maxRate);
  }
}
