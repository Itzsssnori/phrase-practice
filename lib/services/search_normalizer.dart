import '../models/language.dart';

/// Per-script Unicode search normalization utility.
///
/// Rules:
/// 1. Always converts to Unicode NFC, lowercases, and trims/collapses whitespace.
/// 2. Strips combining marks and folds accented Latin letters ONLY when the
///    script is `Latin` (covering `en`, `es`, `fil`, `fr`, plus pronunciation
///    strings such as Pinyin with tone marks and Romaji with macrons).
/// 3. For `Cyrillic` (`ru`), folds `ё` to `е` and never folds `й` to `и`.
/// 4. For `Japanese` (`ja`), `Hangul` (`ko`), and `Han (Simplified)` (`zh`),
///    never decomposes or strips anything (so `が` and `か` never match).
class SearchNormalizer {
  SearchNormalizer._();

  // Kana dakuten (\u3099) composition map -> NFC precomposed character
  static const Map<int, int> _dakutenMap = {
    0x304B: 0x304C, // か -> が
    0x304D: 0x304E, // き -> ぎ
    0x304F: 0x3050, // く -> ぐ
    0x3051: 0x3052, // け -> げ
    0x3053: 0x3054, // こ -> ご
    0x3055: 0x3056, // さ -> ざ
    0x3057: 0x3058, // し -> じ
    0x3059: 0x305A, // す -> ず
    0x305B: 0x305C, // せ -> ぜ
    0x305D: 0x305E, // そ -> ぞ
    0x305F: 0x3060, // た -> だ
    0x3061: 0x3062, // ち -> ぢ
    0x3064: 0x3065, // つ -> づ
    0x3066: 0x3067, // て -> で
    0x3068: 0x3069, // と -> ど
    0x306F: 0x3070, // は -> ば
    0x3072: 0x3073, // ひ -> び
    0x3075: 0x3076, // ふ -> ぶ
    0x3078: 0x3079, // へ -> べ
    0x307B: 0x307C, // ほ -> ぼ
    0x3046: 0x3094, // う -> ゔ
    0x30AB: 0x30AC, // カ -> ガ
    0x30AD: 0x30AE, // キ -> ギ
    0x30AF: 0x30B0, // ク -> グ
    0x30B1: 0x30B2, // ケ -> ゲ
    0x30B3: 0x30B4, // コ -> ゴ
    0x30B5: 0x30B6, // サ -> ザ
    0x30B7: 0x30B8, // シ -> ジ
    0x30B9: 0x30BA, // ス -> ズ
    0x30BB: 0x30BC, // セ -> ゼ
    0x30BD: 0x30BE, // ソ -> Зо
    0x30BF: 0x30C0, // タ -> ダ
    0x30C1: 0x30C2, // チ -> ヂ
    0x30C4: 0x30C5, // ツ -> ヅ
    0x30C6: 0x30C7, // テ -> デ
    0x30C8: 0x30C9, // ト -> ド
    0x30CF: 0x30D0, // ハ -> バ
    0x30D2: 0x30D3, // ヒ -> ビ
    0x30D5: 0x30D6, // フ -> ブ
    0x30D8: 0x30D9, // ヘ -> ベ
    0x30DB: 0x30DC, // ホ -> ボ
    0x30A6: 0x30F4, // ウ -> ヴ
  };

  // Kana handakuten (\u309A) composition map -> NFC precomposed character
  static const Map<int, int> _handakutenMap = {
    0x306F: 0x3071, // は -> ぱ
    0x3072: 0x3074, // ひ -> ぴ
    0x3075: 0x3077, // ふ -> ぷ
    0x3078: 0x307A, // へ -> ぺ
    0x307B: 0x307D, // ほ -> ぽ
    0x30CF: 0x30D1, // ハ -> パ
    0x30D2: 0x30D4, // ヒ -> ピ
    0x30D5: 0x30D7, // フ -> プ
    0x30D8: 0x30DA, // ヘ -> ペ
    0x30DB: 0x30DD, // ホ -> ポ
  };

  // Precomposed Latin characters (including Pinyin tone vowels & Romaji macrons) -> ASCII base
  static const Map<String, String> _latinFoldMap = {
    'á': 'a', 'à': 'a', 'ä': 'a', 'â': 'a', 'ã': 'a', 'å': 'a', 'ā': 'a', 'ǎ': 'a', 'ă': 'a', 'ą': 'a',
    'é': 'e', 'è': 'e', 'ë': 'e', 'ê': 'e', 'ē': 'e', 'ě': 'e', 'ĕ': 'e', 'ė': 'e', 'ę': 'e',
    'í': 'i', 'ì': 'i', 'ï': 'i', 'î': 'i', 'ī': 'i', 'ǐ': 'i', 'ĭ': 'i', 'į': 'i',
    'ó': 'o', 'ò': 'o', 'ö': 'o', 'ô': 'o', 'õ': 'o', 'ø': 'o', 'ō': 'o', 'ǒ': 'o', 'ŏ': 'o', 'ő': 'o',
    'ú': 'u', 'ù': 'u', 'ü': 'u', 'û': 'u', 'ū': 'u', 'ǔ': 'u', 'ŭ': 'u', 'ů': 'u', 'ű': 'u', 'ų': 'u',
    'ǖ': 'u', 'ǘ': 'u', 'ǚ': 'u', 'ǜ': 'u',
    'ñ': 'n', 'ń': 'n', 'ň': 'n', 'ņ': 'n',
    'ç': 'c', 'ć': 'c', 'č': 'c',
    'ý': 'y', 'ÿ': 'y', 'ȳ': 'y',
    'ß': 'ss', 'æ': 'ae', 'œ': 'oe',
  };

  /// Composes NFD sequences (Hangul Jamo, Kana dakuten/handakuten, Cyrillic й/ё) into Unicode NFC.
  static String toNfc(String input) {
    if (input.isEmpty) return '';
    final runes = input.runes.toList();
    final out = <int>[];

    const int sBase = 0xAC00;
    const int lBase = 0x1100;
    const int vBase = 0x1161;
    const int tBase = 0x11A7;
    const int lCount = 19;
    const int vCount = 21;
    const int tCount = 28;
    const int nCount = vCount * tCount; // 588
    const int sCount = lCount * nCount; // 11172

    for (int i = 0; i < runes.length; i++) {
      final r = runes[i];

      // 1. Hangul L + V -> LV
      if (out.isNotEmpty) {
        final prev = out.last;
        final lIndex = prev - lBase;
        if (lIndex >= 0 && lIndex < lCount) {
          final vIndex = r - vBase;
          if (vIndex >= 0 && vIndex < vCount) {
            out[out.length - 1] = sBase + (lIndex * vCount + vIndex) * tCount;
            continue;
          }
        }

        // Hangul LV + T -> LVT
        final sIndex = prev - sBase;
        if (sIndex >= 0 && sIndex < sCount && (sIndex % tCount) == 0) {
          final tIndex = r - tBase;
          if (tIndex > 0 && tIndex < tCount) {
            out[out.length - 1] = prev + tIndex;
            continue;
          }
        }

        // 2. Kana + combining dakuten (\u3099) or standalone dakuten (\u309B)
        if (r == 0x3099) {
          final composed = _dakutenMap[prev];
          if (composed != null) {
            out[out.length - 1] = composed;
            continue;
          }
        }
        if (r == 0x309A) {
          final composed = _handakutenMap[prev];
          if (composed != null) {
            out[out.length - 1] = composed;
            continue;
          }
        }

        // 3. Cyrillic NFD composition: е/Е + \u0308 -> ё/Ё, и/И + \u0306 -> й/Й
        if (r == 0x0308) {
          if (prev == 0x0435) {
            out[out.length - 1] = 0x0451; // ё
            continue;
          } else if (prev == 0x0415) {
            out[out.length - 1] = 0x0401; // Ё
            continue;
          }
        }
        if (r == 0x0306) {
          if (prev == 0x0438) {
            out[out.length - 1] = 0x0439; // й
            continue;
          } else if (prev == 0x0418) {
            out[out.length - 1] = 0x0419; // Й
            continue;
          }
        }
      }

      out.add(r);
    }

    return String.fromCharCodes(out);
  }

  /// Normalizes [input] according to the rules for [languageCode] (or explicit [script]).
  static String normalize(
    String input, {
    String? languageCode,
    String? script,
  }) {
    final resolvedScript = (script != null && script.isNotEmpty)
        ? script
        : (languageCode != null && languageCode.isNotEmpty
            ? Language.defaultScriptFor(languageCode)
            : 'Latin');

    return normalizeForScript(input, resolvedScript);
  }

  /// Normalizes [input] for a specific [script] (`Latin`, `Cyrillic`, `Japanese`, `Hangul`, `Han (Simplified)`).
  static String normalizeForScript(String input, String script) {
    if (input.isEmpty) return '';

    // Step 1: Always NFC and lowercase
    var result = toNfc(input).toLowerCase();

    final scriptLower = script.trim().toLowerCase();
    if (scriptLower == 'latin') {
      final buffer = StringBuffer();
      for (int i = 0; i < result.length; i++) {
        final ch = result[i];
        final code = ch.codeUnitAt(0);
        // Strip combining diacritical marks (U+0300..U+036F) in Latin script
        if (code >= 0x0300 && code <= 0x036F) {
          continue;
        }
        buffer.write(_latinFoldMap[ch] ?? ch);
      }
      result = buffer.toString();
    } else if (scriptLower == 'cyrillic') {
      // Fold Russian ё -> е, never fold й -> и
      result = result.replaceAll('ё', 'е');
    }
    // For Japanese, Hangul, Han (Simplified): keep NFC + lowercase intact!

    return result.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// Normalizes pronunciation strings (always Latin script: Respelling, Pinyin, Romaji, Revised Romanization, Latin transliteration).
  static String normalizePronunciation(String input) {
    return normalizeForScript(input, 'Latin');
  }

  /// Returns true if [text] in [languageCode] matches [query].
  static bool matchesText({
    required String text,
    required String query,
    required String languageCode,
    String? script,
  }) {
    final normQuery = normalize(query, languageCode: languageCode, script: script);
    if (normQuery.isEmpty) return false;
    final normText = normalize(text, languageCode: languageCode, script: script);
    return normText.contains(normQuery);
  }

  /// Returns true if Latin-script [pronunciation] matches [query].
  static bool matchesPronunciation({
    required String pronunciation,
    required String query,
  }) {
    final normQuery = normalizePronunciation(query);
    if (normQuery.isEmpty) return false;
    final normPron = normalizePronunciation(pronunciation);
    return normPron.contains(normQuery);
  }
}
