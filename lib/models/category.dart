import 'package:material_ui/material_ui.dart';

/// Category domain entity representing a thematic phrase group.
class Category {
  final String id;
  final int sortOrder;
  final String iconKey;
  final bool isActive;
  final Map<String, String> names;

  // Backwards compatibility legacy fields for existing UI/mock services
  final String? _legacyTitle;
  final String? _legacyDescription;
  final IconData? _legacyIcon;
  final int phraseCount;
  final double progress; // 0.0 to 1.0

  const Category({
    required this.id,
    this.sortOrder = 0,
    this.iconKey = 'greetings',
    this.isActive = true,
    this.names = const {},
    String? title,
    String? description,
    IconData? icon,
    this.phraseCount = 0,
    this.progress = 0.0,
  })  : _legacyTitle = title,
        _legacyDescription = description,
        _legacyIcon = icon;

  /// Returns the translated name for a specified language code, falling back to English.
  String nameFor(String languageCode) {
    if (names.containsKey(languageCode) && names[languageCode]!.isNotEmpty) {
      return names[languageCode]!;
    }
    if (names.containsKey('en') && names['en']!.isNotEmpty) {
      return names['en']!;
    }
    return title;
  }

  /// Backward-compatible title accessor.
  String get title {
    final legacy = _legacyTitle;
    if (legacy != null && legacy.isNotEmpty) {
      return legacy;
    }
    return names['en'] ?? (names.isNotEmpty ? names.values.first : id);
  }

  /// Backward-compatible description accessor.
  String get description {
    final legacy = _legacyDescription;
    if (legacy != null) {
      return legacy;
    }
    return '$title phrases and conversational vocabulary.';
  }

  /// Backward-compatible icon accessor derived from [iconKey].
  IconData get icon {
    final legacy = _legacyIcon;
    if (legacy != null) {
      return legacy;
    }
    return iconFor(iconKey);
  }

  /// Resolves standard iconKeys to Material Symbols Outlined icons.
  static IconData iconFor(String key) {
    switch (key.toLowerCase()) {
      case 'greetings':
        return Icons.waving_hand_outlined;
      case 'food':
        return Icons.restaurant_outlined;
      case 'directions':
        return Icons.signpost_outlined;
      case 'travel':
        return Icons.luggage_outlined;
      case 'emergencies':
      case 'emergency':
        return Icons.local_hospital_outlined;
      default:
        return Icons.folder_open_outlined;
    }
  }

  factory Category.fromMap(String id, Map<String, dynamic> map, [String? currentLanguageCode]) {
    final rawNames = map['names'] as Map<String, dynamic>? ?? {};
    final parsedNames = <String, String>{};
    rawNames.forEach((key, value) {
      if (value != null) {
        parsedNames[key] = value.toString();
      }
    });

    final iconKey = (map['iconKey'] as String?)?.trim() ?? 'greetings';

    return Category(
      id: id,
      sortOrder: (map['sortOrder'] as num?)?.toInt() ?? 0,
      iconKey: iconKey,
      isActive: (map['isActive'] as bool?) ?? true,
      names: parsedNames,
      title: currentLanguageCode != null ? parsedNames[currentLanguageCode] : null,
      icon: iconFor(iconKey),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sortOrder': sortOrder,
      'iconKey': iconKey,
      'isActive': isActive,
      'names': names,
    };
  }

  Category copyWith({
    String? id,
    int? sortOrder,
    String? iconKey,
    bool? isActive,
    Map<String, String>? names,
    String? title,
    String? description,
    IconData? icon,
    int? phraseCount,
    double? progress,
  }) {
    return Category(
      id: id ?? this.id,
      sortOrder: sortOrder ?? this.sortOrder,
      iconKey: iconKey ?? this.iconKey,
      isActive: isActive ?? this.isActive,
      names: names ?? this.names,
      title: title ?? _legacyTitle,
      description: description ?? _legacyDescription,
      icon: icon ?? _legacyIcon,
      phraseCount: phraseCount ?? this.phraseCount,
      progress: progress ?? this.progress,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Category && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Category($id: "$title", iconKey: $iconKey)';
}
