import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import '../models/category.dart';
import '../models/language.dart';
import '../services/browse_data_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/app_empty_state.dart';
import '../widgets/app_error_message.dart';
import '../widgets/app_loading_indicator.dart';
import '../widgets/app_settings_scope.dart';
import '../widgets/category_card.dart';
import '../widgets/language_chip.dart';
import '../widgets/language_picker_bottom_sheet.dart';

/// Categories directory screen displaying curated thematic collections of phrases.
class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final _browseService = BrowseDataService.instance;

  bool _isLoading = true;
  String? _errorMessage;
  List<Category> _categories = [];
  List<Language> _languages = [];
  String? _lastLoadedNativeCode;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final settings = AppSettingsScope.maybeOf(context);
    final currentNative = settings?.nativeLanguageCode ?? 'en';

    if (_lastLoadedNativeCode != currentNative) {
      _loadCategories();
    }
  }

  Future<void> _loadCategories({bool forceRefresh = false}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final settings = AppSettingsScope.maybeOf(context);
    final nativeCode = settings?.nativeLanguageCode ?? 'en';
    _lastLoadedNativeCode = nativeCode;

    // Load active languages for the header chip
    final langResult = await _browseService.getLanguages(forceRefresh: forceRefresh);
    if (langResult.isSuccess && langResult.dataOrNull != null) {
      _languages = langResult.dataOrNull!;
    }

    final result = await _browseService.getCategories(nativeCode, forceRefresh: forceRefresh);

    if (mounted) {
      if (result.isError) {
        setState(() {
          _isLoading = false;
          _errorMessage = result.errorMessageOrNull ?? 'Failed to load categories.';
        });
      } else {
        setState(() {
          _categories = result.dataOrNull ?? [];
          _isLoading = false;
        });
      }
    }
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
        title: const Text('Phrase Categories'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            tooltip: 'Search phrases',
            onPressed: () => context.push('/search'),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _loadCategories(forceRefresh: true),
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
            title: 'Unable to Load Categories',
            message: _errorMessage!,
            retryLabel: 'Try Again',
            onRetry: () => _loadCategories(forceRefresh: true),
          ),
        ),
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      children: [
        // Top row: Language switch chip accessible from Categories
        Row(
          children: [
            LanguagePairChip(
              nativeLanguage: nativeLang,
              targetLanguage: targetLang,
              onTap: () => LanguagePickerBottomSheet.showPairPicker(context),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),

        Text(
          'Browse by Topic',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.darkText : AppColors.lightText,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Phrases organized by everyday travel, dining, and social scenarios.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Grid of Category Cards
        if (_categories.isEmpty)
          const AppEmptyState(
            icon: Icons.folder_open_rounded,
            title: 'No Categories Available',
            message: 'No categories were found. Pull down to refresh.',
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 600;

              if (isWide) {
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: AppSpacing.md,
                    mainAxisSpacing: AppSpacing.md,
                    childAspectRatio: 1.6,
                  ),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final cat = _categories[index];
                    return CategoryCard(
                      category: cat,
                      onTap: () => context.push('/categories/${cat.id}'),
                    );
                  },
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _categories.length,
                separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  return CategoryCard(
                    category: cat,
                    onTap: () => context.push('/categories/${cat.id}'),
                  );
                },
              );
            },
          ),
        const SizedBox(height: AppSpacing.xxl),
      ],
    );
  }
}
