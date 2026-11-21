import 'package:material_ui/material_ui.dart';

/// Category domain entity representing a thematic phrase group.
///
/// Tolerates missing new fields (`group`, `priority`) with sensible slug-based
/// defaults so the app works against both old and new Firestore documents.
class Category {
  static const String groupEveryday = 'everyday';
  static const String groupTravel = 'travel';
  static const String groupSafety = 'safety';

  static const List<String> groupOrder = [
    groupEveryday,
    groupTravel,
    groupSafety,
  ];

  static const String priorityEssential = 'essential';
  static const String priorityCritical = 'critical';
  static const String priorityHigh = 'high';

  final String id;
  final int sortOrder;
  final String iconKey;
  final String group;
  final String priority;
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
    String? group,
    String? priority,
    this.isActive = true,
    this.names = const {},
    String? title,
    String? description,
    IconData? icon,
    this.phraseCount = 0,
    this.progress = 0.0,
  })  : group = group ?? '',
        priority = priority ?? '',
        _legacyTitle = title,
        _legacyDescription = description,
        _legacyIcon = icon;

  /// Effective group (`everyday`, `travel`, or `safety`), falling back when unset.
  String get effectiveGroup =>
      groupOrder.contains(group) ? group : defaultGroupFor(id);

  /// Effective priority (`essential`, `critical`, or `high`), falling back when unset.
  String get effectivePriority =>
      (priority == priorityEssential ||
              priority == priorityCritical ||
              priority == priorityHigh)
          ? priority
          : defaultPriorityFor(id);

  bool get isCritical => effectivePriority == priorityCritical;
  bool get isEssential => effectivePriority == priorityEssential;

  static String groupTitleFor(String group) {
    switch (group) {
      case groupEveryday:
        return 'Everyday Conversations';
      case groupTravel:
        return 'Travel & Navigation';
      case groupSafety:
        return 'Safety & Essential Needs';
      default:
        return 'Everyday Conversations';
    }
  }

  static String defaultGroupFor(String slug) {
    switch (slug.toLowerCase()) {
      case 'directions':
      case 'travel':
      case 'transportation':
      case 'airport-immigration':
      case 'accommodation':
      case 'restrooms':
      case 'sightseeing':
      case 'money-payments':
      case 'weather':
        return groupTravel;
      case 'emergencies':
      case 'emergency':
      case 'police-safety':
      case 'health-pharmacy':
      case 'lost-found':
        return groupSafety;
      case 'greetings':
      case 'food':
      case 'social-conversations':
      case 'shopping':
      case 'time-dates-numbers':
      case 'communication-help':
      case 'family-relationships':
      default:
        return groupEveryday;
    }
  }

  static String defaultPriorityFor(String slug) {
    switch (slug.toLowerCase()) {
      case 'emergencies':
      case 'emergency':
      case 'police-safety':
      case 'health-pharmacy':
        return priorityCritical;
      case 'social-conversations':
      case 'shopping':
      case 'family-relationships':
      case 'sightseeing':
      case 'weather':
      case 'lost-found':
        return priorityHigh;
      case 'greetings':
      case 'food':
      case 'directions':
      case 'travel':
      case 'time-dates-numbers':
      case 'communication-help':
      case 'transportation':
      case 'airport-immigration':
      case 'accommodation':
      case 'restrooms':
      case 'money-payments':
      default:
        return priorityEssential;
    }
  }

  /// Filters active categories in [targetGroup], sorted by [sortOrder].
  static List<Category> activeInGroup(
    Iterable<Category> categories,
    String targetGroup,
  ) {
    final list = categories
        .where((c) => c.isActive && c.effectiveGroup == targetGroup)
        .toList();
    list.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return list;
  }

  /// Selects at most [maxCount] (default 6) active categories for the Home screen:
  /// `essential` priority first, then ordered by group (`everyday` -> `travel` -> `safety`)
  /// and `sortOrder`.
  static List<Category> selectForHome(
    Iterable<Category> categories, {
    int maxCount = 6,
  }) {
    final active = categories.where((c) => c.isActive).toList();
    active.sort((a, b) {
      final aEss = a.isEssential ? 0 : 1;
      final bEss = b.isEssential ? 0 : 1;
      if (aEss != bEss) return aEss.compareTo(bEss);

      final aGroupIdx = groupOrder.indexOf(a.effectiveGroup);
      final bGroupIdx = groupOrder.indexOf(b.effectiveGroup);
      if (aGroupIdx != bGroupIdx) return aGroupIdx.compareTo(bGroupIdx);

      return a.sortOrder.compareTo(b.sortOrder);
    });
    return active.take(maxCount).toList();
  }

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

  /// Resolves standard iconKeys to Material icons across all 20 categories.
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
      case 'social-conversations':
        return Icons.forum_outlined;
      case 'shopping':
        return Icons.shopping_bag_outlined;
      case 'time-dates-numbers':
        return Icons.schedule_outlined;
      case 'communication-help':
        return Icons.record_voice_over_outlined;
      case 'family-relationships':
        return Icons.group_outlined;
      case 'transportation':
        return Icons.directions_transit_outlined;
      case 'airport-immigration':
        return Icons.flight_takeoff_rounded;
      case 'accommodation':
        return Icons.hotel_outlined;
      case 'restrooms':
        return Icons.wc_rounded;
      case 'sightseeing':
        return Icons.photo_camera_outlined;
      case 'money-payments':
        return Icons.payments_outlined;
      case 'weather':
        return Icons.wb_sunny_outlined;
      case 'police-safety':
        return Icons.local_police_outlined;
      case 'health-pharmacy':
        return Icons.medication_outlined;
      case 'lost-found':
        return Icons.find_in_page_outlined;
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

    final iconKey = (map['iconKey'] as String?)?.trim() ?? id;
    final rawGroup = (map['group'] as String?)?.trim();
    final rawPriority = (map['priority'] as String?)?.trim();

    return Category(
      id: id,
      sortOrder: (map['sortOrder'] as num?)?.toInt() ?? 0,
      iconKey: iconKey,
      group: (rawGroup != null && rawGroup.isNotEmpty)
          ? rawGroup
          : defaultGroupFor(id),
      priority: (rawPriority != null && rawPriority.isNotEmpty)
          ? rawPriority
          : defaultPriorityFor(id),
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
      'group': effectiveGroup,
      'priority': effectivePriority,
      'isActive': isActive,
      'names': names,
    };
  }

  Category copyWith({
    String? id,
    int? sortOrder,
    String? iconKey,
    String? group,
    String? priority,
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
      group: group ?? this.group,
      priority: priority ?? this.priority,
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
  String toString() => 'Category($id: "$title", group: $effectiveGroup, priority: $effectivePriority)';
}
