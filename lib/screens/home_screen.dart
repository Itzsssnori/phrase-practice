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
import '../widgets/app_search_bar.dart';
import '../widgets/app_settings_scope.dart';
import '../widgets/category_card.dart';
import '../widgets/language_chip.dart';
import '../widgets/language_picker_bottom_sheet.dart';

/// Main home screen focusing on language context, search, and categorized browsing.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _browseService = BrowseDataService.instance;

  bool _isLoading = true;
  String? _errorMessage;

  List<Language> _languages = [];
  List<Category> _categories = [];
  String? _lastLoadedNativeCode;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final settings = AppSettingsScope.maybeOf(context);
    final currentNative = settings?.nativeLanguageCode ?? 'en';

    if (_lastLoadedNativeCode != currentNative) {
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
    _lastLoadedNativeCode = nativeCode;

    // Load active languages
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

    // Load categories translated in the native language
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

    if (mounted) {
      setState(() {
        _categories = catResult.dataOrNull ?? [];
        _isLoading = false;
      });
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
        title: Text(
          'Phrase Practice',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
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
            title: 'Unable to Load Categories',
            message: _errorMessage!,
            retryLabel: 'Try Again',
            onRetry: () => _loadData(forceRefresh: true),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Language Pair Chip (Tapping opens Language Settings Sheet)
          LanguagePairChip(
            nativeLanguage: nativeLang,
            targetLanguage: targetLang,
            onTap: () => LanguagePickerBottomSheet.showPairPicker(context),
          ),
          const SizedBox(height: AppSpacing.lg),

          // 2. Search Bar (Navigates directly to Search screen)
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

          // 3. Categories Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Categories',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkText : AppColors.lightText,
                ),
              ),
              Text(
                '${_categories.length} Topics',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // 4. Real Categories Grid
          if (_categories.isEmpty)
            const AppEmptyState(
              icon: Icons.folder_open_rounded,
              title: 'No Categories Available',
              message: 'Check back soon for curated phrase categories.',
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 600;
                final crossAxisCount = isWide ? 3 : 2;

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: AppSpacing.md,
                    mainAxisSpacing: AppSpacing.md,
                    childAspectRatio: 1.25,
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
              },
            ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}
