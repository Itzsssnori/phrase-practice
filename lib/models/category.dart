import 'package:material_ui/material_ui.dart';

/// Category model for thematic grouping of phrases.
class Category {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final int phraseCount;
  final double progress; // 0.0 to 1.0

  const Category({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.phraseCount,
    this.progress = 0.0,
  });
}
