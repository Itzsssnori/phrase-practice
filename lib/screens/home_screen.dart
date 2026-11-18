import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import '../models/phrase.dart';
import '../services/mock_data_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/language_chip.dart';
import '../widgets/language_picker_bottom_sheet.dart';
import '../widgets/phrase_card.dart';

/// Main home screen focusing on daily reading and curated practice.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // PLACEHOLDER: Selected study language
  var _selectedLanguage = MockDataService.sampleLanguages[1]; // Spanish
  late List<Phrase> _phrases;

  @override
  void initState() {
    super.initState();
    _phrases = List.from(MockDataService.samplePhrases);
  }

  void _changeLanguage() async {
    final selected = await LanguagePickerBottomSheet.show(
      context,
      selectedLanguage: _selectedLanguage,
      title: 'Change Study Language',
    );
    if (selected != null && mounted) {
      setState(() => _selectedLanguage = selected);
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
    final featuredPhrase = _phrases.first;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Phrase Practice'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            tooltip: 'Search phrases',
            onPressed: () => context.push('/search'),
          ),
          IconButton(
            icon: const Icon(Icons.star_outline_rounded),
            tooltip: 'Favorites',
            onPressed: () => context.push('/favorites'),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Language Selection Bar
              Row(
                children: [
                  LanguageChip(
                    language: _selectedLanguage,
                    isSelected: true,
                    onTap: _changeLanguage,
                  ),
                  const Spacer(),
                  // Subtle calm streak tag (no loud animations)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.local_fire_department_rounded,
                          size: 16,
                          color: AppColors.lightAccent,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          '${MockDataService.sampleProgress.currentStreakDays} days',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),

              // Section 1: Featured Phrase of the Day
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Phrase of the Day',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.push('/phrase-study'),
                    child: const Text('Study Mode'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),

              PhraseCard(
                phrase: featuredPhrase,
                onTap: () => context.push('/phrase-study'),
                onFavoriteToggle: (_) => _toggleFavorite(featuredPhrase),
              ),

              const SizedBox(height: AppSpacing.xl),

              // Quick action tools
              Row(
                children: [
                  Expanded(
                    child: _QuickActionCard(
                      icon: Icons.g_translate_rounded,
                      title: 'Translator',
                      subtitle: 'Direct context lookup',
                      onTap: () => context.push('/translator'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _QuickActionCard(
                      icon: Icons.quiz_outlined,
                      title: 'Quick Quiz',
                      subtitle: 'Test 5 key phrases',
                      onTap: () => context.push('/quiz/play'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.xl),

              // Section 2: Recent Categories
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Popular Topics',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.go('/categories'),
                    child: const Text('View All'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),

              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 3,
                separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
                itemBuilder: (context, index) {
                  final cat = MockDataService.sampleCategories[index];
                  return Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(AppSpacing.md),
                      leading: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusInput),
                        ),
                        child: Icon(
                          cat.icon,
                          color: theme.colorScheme.onPrimaryContainer,
                          size: AppSpacing.iconMd,
                        ),
                      ),
                      title: Text(
                        cat.title,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        '${cat.phraseCount} phrases • ${(cat.progress * 100).toInt()}% mastered',
                        style: theme.textTheme.bodySmall,
                      ),
                      trailing: const Icon(
                        Icons.chevron_right_rounded,
                        size: AppSpacing.iconMd,
                      ),
                      onTap: () => context.push('/categories/${cat.id}'),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                color: theme.colorScheme.primary,
                size: AppSpacing.iconLg,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
