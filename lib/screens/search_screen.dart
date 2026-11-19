import 'dart:async';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import '../models/category.dart';
import '../models/phrase.dart';
import '../services/browse_data_service.dart';
import '../theme/app_spacing.dart';
import '../widgets/app_empty_state.dart';
import '../widgets/app_error_message.dart';
import '../widgets/app_loading_indicator.dart';
import '../widgets/app_search_bar.dart';
import '../widgets/app_settings_scope.dart';
import '../widgets/phrase_card.dart';

/// Full-text search screen with debounce, category filtering, and accent-insensitive matching.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  final _browseService = BrowseDataService.instance;

  Timer? _debounceTimer;
  List<Category> _categories = [];
  String? _selectedCategoryId; // null or 'all' means all categories

  List<Phrase> _results = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _currentQuery = '';

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    final settings = AppSettingsScope.maybeOf(context);
    final nativeCode = settings?.nativeLanguageCode ?? 'en';

    final catResult = await _browseService.getCategories(nativeCode);
    if (mounted && catResult.isSuccess && catResult.dataOrNull != null) {
      setState(() {
        _categories = catResult.dataOrNull!;
      });
    }
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _currentQuery = query.trim();

    if (_currentQuery.isEmpty && (_selectedCategoryId == null || _selectedCategoryId == 'all')) {
      setState(() {
        _results = [];
        _isLoading = false;
        _errorMessage = null;
      });
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 250), () {
      _executeSearch();
    });
  }

  void _onCategorySelected(String? categoryId) {
    setState(() {
      _selectedCategoryId = categoryId;
    });
    _executeSearch();
  }

  Future<void> _executeSearch() async {
    final settings = AppSettingsScope.maybeOf(context);
    final nativeCode = settings?.nativeLanguageCode ?? 'en';
    final targetCode = settings?.targetLanguageCode ?? 'es';

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _browseService.searchPhrases(
      query: _currentQuery,
      categoryId: _selectedCategoryId,
      nativeLang: nativeCode,
      targetLang: targetCode,
    );

    if (!mounted) return;

    if (result.isError) {
      setState(() {
        _isLoading = false;
        _errorMessage = result.errorMessageOrNull ?? 'Search failed.';
        _results = [];
      });
    } else {
      setState(() {
        _isLoading = false;
        _results = result.dataOrNull ?? [];
      });
    }
  }

  void _clearSearch() {
    _searchController.clear();
    _onSearchChanged('');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final settings = AppSettingsScope.of(context);

    final targetCode = settings.targetLanguageCode;
    final nativeCode = settings.nativeLanguageCode;

    final isBlankSearch = _currentQuery.isEmpty &&
        (_selectedCategoryId == null || _selectedCategoryId == 'all');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Phrases'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Search Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: AppSearchBar(
                controller: _searchController,
                autofocus: true,
                hintText: 'Search in $targetCode or $nativeCode...',
                onChanged: _onSearchChanged,
                onClear: _clearSearch,
              ),
            ),

            // 2. Category Filter Chips Carousel
            if (_categories.isNotEmpty)
              SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.xs),
                      child: FilterChip(
                        label: const Text('All'),
                        selected: _selectedCategoryId == null || _selectedCategoryId == 'all',
                        onSelected: (_) => _onCategorySelected('all'),
                        showCheckmark: false,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
                        ),
                      ),
                    ),
                    ..._categories.map((cat) {
                      final isSelected = _selectedCategoryId == cat.id;
                      return Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.xs),
                        child: FilterChip(
                          avatar: Icon(cat.icon, size: 16),
                          label: Text(cat.nameFor(nativeCode)),
                          selected: isSelected,
                          onSelected: (_) => _onCategorySelected(cat.id),
                          showCheckmark: false,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            const SizedBox(height: AppSpacing.sm),

            // 3. Search Results or State Prompts
            Expanded(
              child: _buildResultBody(
                theme: theme,
                isDark: isDark,
                isBlank: isBlankSearch,
                targetLang: targetCode,
                nativeLang: nativeCode,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultBody({
    required ThemeData theme,
    required bool isDark,
    required bool isBlank,
    required String targetLang,
    required String nativeLang,
  }) {
    if (_isLoading) {
      return const Center(child: AppLoadingIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: AppErrorMessage(
            title: 'Search Error',
            message: _errorMessage!,
            retryLabel: 'Retry',
            onRetry: _executeSearch,
          ),
        ),
      );
    }

    if (isBlank) {
      return const Center(
        child: AppEmptyState(
          icon: Icons.search_rounded,
          title: 'Type to search',
          message: 'Type any phrase, translation, or everyday keyword to find instant matches.',
        ),
      );
    }

    if (_results.isEmpty) {
      return Center(
        child: AppEmptyState(
          icon: Icons.search_off_rounded,
          title: 'No phrases found',
          message: 'No phrases matched "$_currentQuery". Try another keyword or category filter.',
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: _results.length,
      separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        final phrase = _results[index];
        return PhraseCard(
          phrase: phrase,
          targetLanguageCode: targetLang,
          nativeLanguageCode: nativeLang,
          onTap: () {
            context.push('/phrase-study/${phrase.id}?category=${phrase.categoryId}');
          },
        );
      },
    );
  }
}
