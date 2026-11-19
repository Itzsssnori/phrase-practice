/// Language domain entity representing an active or supported language.
class Language {
  final String code;
  final String name;
  final String nativeName;
  final String script;
  final bool isActive;
  final String _customFlag;

  const Language({
    required this.code,
    required this.name,
    required this.nativeName,
    this.script = 'Latin',
    this.isActive = true,
    String? flag,
  }) : _customFlag = flag ?? '';

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
      default:
        return '🌐';
    }
  }

  factory Language.fromMap(String code, Map<String, dynamic> map) {
    return Language(
      code: code,
      name: (map['name'] as String?)?.trim() ?? code,
      nativeName: (map['nativeName'] as String?)?.trim() ?? (map['name'] as String?)?.trim() ?? code,
      script: (map['script'] as String?)?.trim() ?? 'Latin',
      isActive: (map['isActive'] as bool?) ?? true,
      flag: map['flag'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'nativeName': nativeName,
      'script': script,
      'isActive': isActive,
    };
  }

  Language copyWith({
    String? code,
    String? name,
    String? nativeName,
    String? script,
    bool? isActive,
    String? flag,
  }) {
    return Language(
      code: code ?? this.code,
      name: name ?? this.name,
      nativeName: nativeName ?? this.nativeName,
      script: script ?? this.script,
      isActive: isActive ?? this.isActive,
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
