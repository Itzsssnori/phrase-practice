import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import '../models/category.dart';
import '../models/phrase.dart';
import '../services/mock_data_service.dart';
import '../theme/app_spacing.dart';
import '../widgets/phrase_card.dart';

/// Screen listing all phrases under a selected category.
class CategoryPhrasesScreen extends StatefulWidget {
  final String categoryId;

  const CategoryPhrasesScreen({
    super.key,
    required this.categoryId,
  });

  @override
  State<CategoryPhrasesScreen> createState() => _CategoryPhrasesScreenState();
}

class _CategoryPhrasesScreenState extends State<CategoryPhrasesScreen> {
  late Category _category;
  late List<Phrase> _phrases;

  @override
  void initState() {
    super.initState();
    _category = MockDataService.sampleCategories.firstWhere(
      (c) => c.id == widget.categoryId,
      orElse: () => MockDataService.sampleCategories.first,
    );
    _phrases = MockDataService.samplePhrases
        .where((p) => p.categoryId == _category.id)
        .toList();
    if (_phrases.isEmpty) {
      _phrases = List.from(MockDataService.samplePhrases);
    }
  }

  void _toggleFavorite(Phrase phrase) {
    setState(() {
      final index = _phrases.indexWhere((p) => p.id == phrase.id);
      if (index != -1) {
        _phrases[index] = phrase.copyWith(isFavorite: !phrase.isFavorite);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_category.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.play_circle_outline_rounded),
            tooltip: 'Start Category Study',
            onPressed: () => context.push('/phrase-study'),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            // Category header card
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.15),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _category.icon,
                        color: theme.colorScheme.primary,
                        size: AppSpacing.iconLg,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          _category.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    _category.description,
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    '${_phrases.length} phrases available for study',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            Text(
              'Phrases',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _phrases.length,
              separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) {
                final phrase = _phrases[index];
                return PhraseCard(
                  phrase: phrase,
                  onTap: () => context.push('/phrase-study'),
                  onFavoriteToggle: (_) => _toggleFavorite(phrase),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
