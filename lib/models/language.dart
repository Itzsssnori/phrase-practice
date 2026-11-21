/// Language domain entity representing an active or supported language.
///
/// Tolerates missing new fields (`sortOrder`, `ttsLocale`, `pronunciationSystem`)
/// with sensible code-based defaults so the app works against both old and new
/// Firestore documents.
class Language {
  final String code;
  final String name;
  final String nativeName;
  final String script;
  final bool isActive;
  final int sortOrder;
  final String ttsLocale;
  final String pronunciationSystem;
  final String _customFlag;

  const Language({
    required this.code,
    required this.name,
    required this.nativeName,
    String? script,
    this.isActive = true,
    int? sortOrder,
    String? ttsLocale,
    String? pronunciationSystem,
    String? flag,
  })  : script = script ?? 'Latin',
        sortOrder = sortOrder ?? 0,
        ttsLocale = ttsLocale ?? '',
        pronunciationSystem = pronunciationSystem ?? '',
        _customFlag = flag ?? '';

  /// Effective sort order, falling back to canonical order when 0/unset.
  int get effectiveSortOrder => sortOrder > 0 ? sortOrder : defaultSortOrderFor(code);

  /// Effective TTS locale, falling back to canonical BCP-47 locale when unset.
  String get effectiveTtsLocale =>
      ttsLocale.isNotEmpty ? ttsLocale : defaultTtsLocaleFor(code);

  /// Effective pronunciation system label (e.g. "Respelling", "Romaji", "Pinyin").
  String get effectivePronunciationSystem =>
      pronunciationSystem.isNotEmpty
          ? pronunciationSystem
          : defaultPronunciationSystemFor(code);

  /// Returns explicit flag or derives standard emoji from language code.
  String get flag => _customFlag.isNotEmpty ? _customFlag : defaultFlagFor(code);

  static String defaultFlagFor(String code) {
    switch (code.toLowerCase()) {
      case 'en':
        return '🇺🇸';
      case 'es':
        return '🇪🇸';
      case 'fil':
        return '🇵🇭';
      case 'fr':
        return '🇫🇷';
      case 'ru':
        return '🇷🇺';
      case 'ja':
        return '🇯🇵';
      case 'ko':
        return '🇰🇷';
      case 'zh':
        return '🇨🇳';
      default:
        return '🌐';
    }
  }

  static String defaultScriptFor(String code) {
    switch (code.toLowerCase()) {
      case 'ru':
        return 'Cyrillic';
      case 'ja':
        return 'Japanese';
      case 'ko':
        return 'Hangul';
      case 'zh':
        return 'Han (Simplified)';
      case 'en':
      case 'es':
      case 'fil':
      case 'fr':
      default:
        return 'Latin';
    }
  }

  static int defaultSortOrderFor(String code) {
    switch (code.toLowerCase()) {
      case 'en':
        return 1;
      case 'es':
        return 2;
      case 'fil':
        return 3;
      case 'fr':
        return 4;
      case 'ru':
        return 5;
      case 'ja':
        return 6;
      case 'ko':
        return 7;
      case 'zh':
        return 8;
      default:
        return 99;
    }
  }

  static String defaultTtsLocaleFor(String code) {
    switch (code.toLowerCase()) {
      case 'en':
        return 'en-US';
      case 'es':
        return 'es-MX';
      case 'fil':
        return 'fil-PH';
      case 'fr':
        return 'fr-FR';
      case 'ru':
        return 'ru-RU';
      case 'ja':
        return 'ja-JP';
      case 'ko':
        return 'ko-KR';
      case 'zh':
        return 'zh-CN';
      default:
        return code;
    }
  }

  static String defaultPronunciationSystemFor(String code) {
    switch (code.toLowerCase()) {
      case 'ru':
        return 'Latin transliteration';
      case 'ja':
        return 'Romaji';
      case 'ko':
        return 'Revised Romanization';
      case 'zh':
        return 'Pinyin';
      case 'en':
      case 'es':
      case 'fil':
      case 'fr':
      default:
        return 'Respelling';
    }
  }

  factory Language.fromMap(String code, Map<String, dynamic> map) {
    final rawScript = (map['script'] as String?)?.trim();
    final rawTts = (map['ttsLocale'] as String?)?.trim();
    final rawPronSys = (map['pronunciationSystem'] as String?)?.trim();
    final rawSort = (map['sortOrder'] as num?)?.toInt();

    return Language(
      code: code,
      name: (map['name'] as String?)?.trim() ?? code,
      nativeName: (map['nativeName'] as String?)?.trim() ??
          (map['name'] as String?)?.trim() ??
          code,
      script: (rawScript != null && rawScript.isNotEmpty)
          ? rawScript
          : defaultScriptFor(code),
      isActive: (map['isActive'] as bool?) ?? true,
      sortOrder: rawSort ?? defaultSortOrderFor(code),
      ttsLocale: (rawTts != null && rawTts.isNotEmpty)
          ? rawTts
          : defaultTtsLocaleFor(code),
      pronunciationSystem: (rawPronSys != null && rawPronSys.isNotEmpty)
          ? rawPronSys
          : defaultPronunciationSystemFor(code),
      flag: map['flag'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'nativeName': nativeName,
      'script': script,
      'isActive': isActive,
      'sortOrder': effectiveSortOrder,
      'ttsLocale': effectiveTtsLocale,
      'pronunciationSystem': effectivePronunciationSystem,
    };
  }

  Language copyWith({
    String? code,
    String? name,
    String? nativeName,
    String? script,
    bool? isActive,
    int? sortOrder,
    String? ttsLocale,
    String? pronunciationSystem,
    String? flag,
  }) {
    return Language(
      code: code ?? this.code,
      name: name ?? this.name,
      nativeName: nativeName ?? this.nativeName,
      script: script ?? this.script,
      isActive: isActive ?? this.isActive,
      sortOrder: sortOrder ?? this.sortOrder,
      ttsLocale: ttsLocale ?? this.ttsLocale,
      pronunciationSystem: pronunciationSystem ?? this.pronunciationSystem,
      flag: flag ?? _customFlag,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Language && runtimeType == other.runtimeType && code == other.code;

  @override
  int get hashCode => code.hashCode;

  @override
  String toString() => 'Language($code: $name / $nativeName)';
}
