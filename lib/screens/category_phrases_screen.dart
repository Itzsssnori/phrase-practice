import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import '../models/category.dart';
import '../models/phrase.dart';
import '../services/browse_data_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/app_empty_state.dart';
import '../widgets/app_error_message.dart';
import '../widgets/app_loading_indicator.dart';
import '../widgets/app_settings_scope.dart';
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
  final _browseService = BrowseDataService.instance;

  bool _isLoading = true;
  bool _initialLoadStarted = false;
  String? _errorMessage;
  Category? _category;
  List<Phrase> _phrases = [];

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

    // 1. Fetch category metadata
    final catResult = await _browseService.getCategories(nativeCode, forceRefresh: forceRefresh);
    if (catResult.isSuccess && catResult.dataOrNull != null) {
      _category = catResult.dataOrNull!.where((c) => c.id == widget.categoryId).firstOrNull;
    }

    // 2. Fetch phrases for this category
    final phraseResult = await _browseService.getPhrasesByCategory(
      widget.categoryId,
      forceRefresh: forceRefresh,
    );

    if (mounted) {
      if (phraseResult.isError) {
        setState(() {
          _isLoading = false;
          _errorMessage = phraseResult.errorMessageOrNull ?? 'Failed to load phrases.';
        });
      } else {
        setState(() {
          _phrases = phraseResult.dataOrNull ?? [];
          _isLoading = false;
        });
      }
    }
  }

  void _openStudyScreen([String? phraseSlug]) {
    final slug = phraseSlug ?? (_phrases.isNotEmpty ? _phrases.first.id : '');
    if (slug.isNotEmpty) {
      context.push('/phrase-study/$slug?category=${widget.categoryId}');
    } else {
      context.push('/phrase-study?category=${widget.categoryId}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Read language settings directly in build so category names and phrase cards update immediately
    final settings = AppSettingsScope.of(context);
    final nativeCode = settings.nativeLanguageCode;
    final targetCode = settings.targetLanguageCode;

    final title = _category?.nameFor(nativeCode) ??
        widget.categoryId[0].toUpperCase() + widget.categoryId.substring(1);

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (_phrases.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.play_circle_outline_rounded),
              tooltip: 'Start Category Study',
              onPressed: () => _openStudyScreen(),
            ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _loadData(forceRefresh: true),
          child: _buildBody(theme, isDark, targetCode, nativeCode, title),
        ),
      ),
    );
  }

  Widget _buildBody(
    ThemeData theme,
    bool isDark,
    String targetLang,
    String nativeLang,
    String categoryTitle,
  ) {
    if (_isLoading) {
      return const Center(child: AppLoadingIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: AppErrorMessage(
            title: 'Unable to Load Category Phrases',
            message: _errorMessage!,
            retryLabel: 'Try Again',
            onRetry: () => _loadData(forceRefresh: true),
          ),
        ),
      );
    }

    final categoryIcon = _category?.icon ?? Icons.folder_open_outlined;
    final categoryDescription = _category?.description ?? '$categoryTitle essential vocabulary.';

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      children: [
        // Category Header Banner Card
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkPrimaryContainer : AppColors.lightPrimaryContainer,
            borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusInput),
                    ),
                    child: Icon(
                      categoryIcon,
                      color: theme.colorScheme.primary,
                      size: AppSpacing.iconMd,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      categoryTitle,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.darkText : AppColors.lightText,
                      ),
                      softWrap: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                categoryDescription,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
                softWrap: true,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                '${_phrases.length} phrases available for study',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),

        // Phrases Section Header
        Text(
          'Phrases',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.darkText : AppColors.lightText,
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Phrases List
        if (_phrases.isEmpty)
          const AppEmptyState(
            icon: Icons.chat_bubble_outline_rounded,
            title: 'No Phrases Available',
            message: 'No phrases found for this category.',
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _phrases.length,
            separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, index) {
              final phrase = _phrases[index];
              return PhraseCard(
                phrase: phrase,
                targetLanguageCode: targetLang,
                nativeLanguageCode: nativeLang,
                onTap: () => _openStudyScreen(phrase.id),
              );
            },
          ),
        const SizedBox(height: AppSpacing.xxl),
      ],
    );
  }
}
