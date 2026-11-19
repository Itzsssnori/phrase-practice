import 'dart:math';

import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import '../models/category.dart';
import '../models/language.dart';
import '../models/phrase.dart';
import '../services/browse_data_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/app_empty_state.dart';
import '../widgets/app_error_message.dart';
import '../widgets/app_loading_indicator.dart';
import '../widgets/app_search_bar.dart';
import '../widgets/app_settings_scope.dart';
import '../widgets/language_chip.dart';
import '../widgets/language_picker_bottom_sheet.dart';

/// Main home screen focusing on daily study focus, search, language context,
/// and categorized phrase browsing.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _browseService = BrowseDataService.instance;

  bool _isLoading = true;
  bool _initialLoadStarted = false;
  String? _errorMessage;
  List<Language> _languages = [];
  List<Category> _categories = [];
  List<Phrase> _allPhrases = [];
  Phrase? _dailyPhrase;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialLoadStarted) {
      _initialLoadStarted = true;
      _loadData();
    }
  }

  Future<void> _loadData({bool forceRefresh = false}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final settings = AppSettingsScope.maybeOf(context);
    final nativeCode = settings?.nativeLanguageCode ?? 'en';

    // 1. Load active languages
    final langResult = await _browseService.getLanguages(forceRefresh: forceRefresh);
    if (langResult.isError) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = langResult.errorMessageOrNull ?? 'Failed to load languages.';
        });
      }
      return;
    }
    _languages = langResult.dataOrNull ?? [];

    // 2. Load categories
    final catResult = await _browseService.getCategories(nativeCode, forceRefresh: forceRefresh);
    if (catResult.isError) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = catResult.errorMessageOrNull ?? 'Failed to load categories.';
        });
      }
      return;
    }
    _categories = catResult.dataOrNull ?? [];

    // 3. Load phrases to select the daily focus phrase
    final phraseResult = await _browseService.getAllPhrases(forceRefresh: forceRefresh);
    if (phraseResult.isSuccess && phraseResult.dataOrNull != null) {
      _allPhrases = phraseResult.dataOrNull!;
      _pickDailyPhrase();
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  /// Deterministically picks a daily phrase from the loaded phrase collection
  /// using the current date as a seed so it remains consistent throughout the day.
  void _pickDailyPhrase() {
    if (_allPhrases.isEmpty) return;
    final now = DateTime.now();
    final daySeed = now.year * 10000 + now.month * 100 + now.day;
    final index = Random(daySeed).nextInt(_allPhrases.length);
    _dailyPhrase = _allPhrases[index];
  }

  Language _findLanguage(String code, String fallback) {
    return _languages.firstWhere(
      (l) => l.code == code,
      orElse: () => _languages.firstWhere(
        (l) => l.code == fallback,
        orElse: () => Language(code: code, name: code, nativeName: code),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final settings = AppSettingsScope.of(context);
    final nativeLang = _findLanguage(settings.nativeLanguageCode, 'en');
    final targetLang = _findLanguage(settings.targetLanguageCode, 'es');

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Phrase Practice',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _loadData(forceRefresh: true),
          child: _buildBody(theme, isDark, nativeLang, targetLang),
        ),
      ),
    );
  }

  Widget _buildBody(
    ThemeData theme,
    bool isDark,
    Language nativeLang,
    Language targetLang,
  ) {
    if (_isLoading) {
      return const Center(child: AppLoadingIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: AppErrorMessage(
            title: 'Unable to Load Data',
            message: _errorMessage!,
            retryLabel: 'Try Again',
            onRetry: () => _loadData(forceRefresh: true),
          ),
        ),
      );
    }

    final nativeCode = nativeLang.code;
    final targetCode = targetLang.code;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Language Pair Chip (I speak -> I'm learning)
          LanguagePairChip(
            nativeLanguage: nativeLang,
            targetLanguage: targetLang,
            onTap: () => LanguagePickerBottomSheet.showPairPicker(context),
          ),
          const SizedBox(height: AppSpacing.lg),

          // 2. Search Bar (navigates to real search screen)
          Semantics(
            button: true,
            label: 'Search phrases in ${targetLang.name} or ${nativeLang.name}',
            child: InkWell(
              onTap: () => context.push('/search'),
              borderRadius: BorderRadius.circular(AppSpacing.radiusInput),
              child: IgnorePointer(
                child: AppSearchBar(
                  hintText: 'Search in ${targetLang.name} or ${nativeLang.name}...',
                  onChanged: (_) {},
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // 3. Featured Daily Phrase (only shown if a real phrase was loaded)
          if (_dailyPhrase != null) ...[
            _buildDailyPhraseCard(theme, isDark, nativeCode, targetCode),
            const SizedBox(height: AppSpacing.xl),
          ],

          // 4. Practice by Category (compact 2-per-row grid of real categories)
          _buildCategorySection(theme, isDark, nativeCode),

          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  // ─── Featured Daily Phrase ────────────────────────────────────────────

  Widget _buildDailyPhraseCard(
    ThemeData theme,
    bool isDark,
    String nativeCode,
    String targetCode,
  ) {
    final phrase = _dailyPhrase!;
    final targetTranslation = phrase.translationFor(targetCode);
    final nativeTranslation = phrase.translationFor(nativeCode);
    final categoryName = _categories
        .where((c) => c.id == phrase.categoryId)
        .map((c) => c.nameFor(nativeCode).toUpperCase())
        .firstOrNull;

    final tint = AppColors.getCategoryTintById(phrase.categoryId, isDark);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'FEATURED DAILY PHRASE',
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Material(
          color: theme.colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
            side: BorderSide(color: theme.dividerColor),
          ),
          child: InkWell(
            onTap: () => context.push(
              '/phrase-study/${phrase.id}?category=${phrase.categoryId}',
            ),
            borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category badge
                  if (categoryName != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: tint.background,
                        borderRadius: BorderRadius.circular(AppSpacing.xs),
                      ),
                      child: Text(
                        categoryName,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: tint.foreground,
                          letterSpacing: 0.5,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],

                  // Target language phrase (large)
                  if (targetTranslation != null)
                    Text(
                      targetTranslation.text,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                        height: 1.3,
                      ),
                    ),
                  if (targetTranslation?.pronunciation != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      targetTranslation!.pronunciation!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.sm),

                  // Native language translation
                  if (nativeTranslation != null)
                    Text(
                      '"${nativeTranslation.text}"',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),

                  // Usage note
                  if (nativeTranslation?.meaningNote != null &&
                      nativeTranslation!.meaningNote!.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      nativeTranslation.meaningNote!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],

                  const SizedBox(height: AppSpacing.md),

                  // "View phrase details" link
                  Text(
                    'View phrase details →',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Compact Category Grid ────────────────────────────────────────────

  Widget _buildCategorySection(ThemeData theme, bool isDark, String nativeCode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                'PRACTICE BY CATEGORY',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            GestureDetector(
              onTap: () => context.go('/categories'),
              child: Text(
                'View all',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        if (_categories.isEmpty)
          const AppEmptyState(
            icon: Icons.folder_open_rounded,
            title: 'No Categories',
            message: 'Check back soon for curated phrase categories.',
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final textScale = MediaQuery.textScalerOf(context).scale(1.0);
              // Single column on extreme text scales to prevent overflow
              final crossAxisCount = textScale >= 1.5 ? 1 : (constraints.maxWidth > 600 ? 3 : 2);
              final spacing = AppSpacing.md;

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: spacing,
                  mainAxisSpacing: spacing,
                  childAspectRatio: crossAxisCount == 1 ? 3.5 : 1.15,
                ),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  return _CompactCategoryTile(
                    category: cat,
                    nativeCode: nativeCode,
                    isDark: isDark,
                    colorIndex: index,
                    onTap: () => context.push('/categories/${cat.id}'),
                  );
                },
              );
            },
          ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Compact category tile for the Home 2×N grid
// ═══════════════════════════════════════════════════════════════════════════

class _CompactCategoryTile extends StatelessWidget {
  final Category category;
  final String nativeCode;
  final bool isDark;
  final int colorIndex;
  final VoidCallback? onTap;

  const _CompactCategoryTile({
    required this.category,
    required this.nativeCode,
    required this.isDark,
    required this.colorIndex,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tint = AppColors.getCategoryTint(colorIndex, isDark);
    final settings = AppSettingsScope.maybeOf(context);
    final effectiveNativeCode = settings?.nativeLanguageCode ?? nativeCode;
    final title = category.nameFor(effectiveNativeCode);

    return Semantics(
      button: true,
      label: '$title, ${category.phraseCount} phrases',
      child: Material(
        color: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          side: BorderSide(color: theme.dividerColor),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: tint.background,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusInput),
                  ),
                  child: Icon(
                    category.icon,
                    color: tint.foreground,
                    size: AppSpacing.iconMd,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  title,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${category.phraseCount} phrases',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
