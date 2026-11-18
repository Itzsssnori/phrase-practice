import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import '../models/phrase.dart';
import '../services/mock_data_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/app_empty_state.dart';
import '../widgets/phrase_card.dart';

/// Screen listing user's bookmarked favorite phrases.
class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  late List<Phrase> _favorites;

  @override
  void initState() {
    super.initState();
    _favorites = MockDataService.samplePhrases
        .where((p) => p.isFavorite)
        .toList();
  }

  void _removeFavorite(Phrase phrase) {
    setState(() {
      _favorites.removeWhere((p) => p.id == phrase.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Phrases'),
      ),
      body: SafeArea(
        child: _favorites.isEmpty
            ? AppEmptyState(
                icon: Icons.star_outline_rounded,
                title: 'No saved phrases yet',
                message: 'Tap the star icon on any phrase card to save it for quick review.',
                actionLabel: 'Browse Topics',
                onAction: () => context.go('/categories'),
              )
            : ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                children: [
                  Text(
                    '${_favorites.length} Starred Phrases',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkText : AppColors.lightText,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Review and cement expressions you want to keep handy.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _favorites.length,
                    separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
                    itemBuilder: (context, index) {
                      final phrase = _favorites[index];
                      return PhraseCard(
                        phrase: phrase,
                        onTap: () => context.push('/phrase-study'),
                        onFavoriteToggle: (_) => _removeFavorite(phrase),
                      );
                    },
                  ),
                ],
              ),
      ),
    );
  }
}
