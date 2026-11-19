import 'package:flutter/foundation.dart' hide Category;
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import '../models/category.dart';
import '../models/language.dart';
import '../models/phrase.dart';
import '../models/result.dart';
import '../services/category_repository.dart';
import '../services/language_repository.dart';
import '../services/phrase_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/app_loading_indicator.dart';

/// Temporary debug inspection screen verifying Firestore data repository connections.
/// Accessible ONLY when kDebugMode is true at route `/debug/data`.
class DebugDataScreen extends StatefulWidget {
  const DebugDataScreen({super.key});

  @override
  State<DebugDataScreen> createState() => _DebugDataScreenState();
}

class _DebugDataScreenState extends State<DebugDataScreen> {
  final LanguageRepository _languageRepo = FirestoreLanguageRepository();
  final CategoryRepository _categoryRepo = FirestoreCategoryRepository();
  final PhraseRepository _phraseRepo = FirestorePhraseRepository();

  bool _isLoading = true;
  String? _errorMessage;

  List<Language> _languages = [];
  List<Category> _categories = [];
  List<Phrase> _phrases = [];

  String _selectedLanguageCode = 'es';
  String? _selectedCategorySlug;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // 1. Fetch active languages
    final langResult = await _languageRepo.getActiveLanguages();
    if (langResult is ErrorResult<List<Language>>) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Languages Error: ${langResult.message}';
      });
      return;
    }

    _languages = langResult.dataOrNull ?? [];
    if (_languages.isNotEmpty && !_languages.any((l) => l.code == _selectedLanguageCode)) {
      _selectedLanguageCode = _languages.first.code;
    }

    await _loadCategoriesAndPhrases();
  }

  Future<void> _loadCategoriesAndPhrases() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // 2. Fetch categories for chosen language
    final catResult = await _categoryRepo.getCategories(_selectedLanguageCode);
    if (catResult is ErrorResult<List<Category>>) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Categories Error: ${catResult.message}';
      });
      return;
    }

    _categories = catResult.dataOrNull ?? [];
    if (_categories.isNotEmpty) {
      if (_selectedCategorySlug == null ||
          !_categories.any((c) => c.id == _selectedCategorySlug)) {
        _selectedCategorySlug = _categories.first.id;
      }
    } else {
      _selectedCategorySlug = null;
    }

    // 3. Fetch phrases for chosen category
    if (_selectedCategorySlug != null) {
      final phraseResult = await _phraseRepo.getPhrasesByCategory(_selectedCategorySlug!);
      if (phraseResult is ErrorResult<List<Phrase>>) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Phrases Error: ${phraseResult.message}';
        });
        return;
      }
      final allCategoryPhrases = phraseResult.dataOrNull ?? [];
      // Take first 5 phrases as specified in requirements
      _phrases = allCategoryPhrases.take(5).toList();
    } else {
      _phrases = [];
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Defense in depth: if accessed in release mode, redirect out
    if (!kDebugMode) {
      return Scaffold(
        body: Center(
          child: Text(
            'Debug route is disabled in release mode.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug: Data Foundation'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reload Firestore Data',
            onPressed: _loadInitialData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: AppLoadingIndicator(message: 'Querying Firestore collections...'))
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.warning_amber_rounded, size: 48, color: theme.colorScheme.error),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'Firestore Query Failed',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.error,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        FilledButton(
                          onPressed: _loadInitialData,
                          child: const Text('Retry Connection'),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: [
                    // --- Section 1: Active Languages ---
                    Text(
                      '1. Active Languages (${_languages.length})',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: _languages.map((lang) {
                        final isSelected = lang.code == _selectedLanguageCode;
                        return ChoiceChip(
                          avatar: Text(lang.flag),
                          label: Text('${lang.name} (${lang.code})'),
                          selected: isSelected,
                          onSelected: (val) {
                            if (val && _selectedLanguageCode != lang.code) {
                              setState(() => _selectedLanguageCode = lang.code);
                              _loadCategoriesAndPhrases();
                            }
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // --- Section 2: Categories in chosen language ---
                    Text(
                      '2. Categories for "$_selectedLanguageCode" (${_categories.length})',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    if (_categories.isEmpty)
                      Text(
                        'No categories found in Firestore.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      )
                    else
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: _categories.map((cat) {
                          final isSelected = cat.id == _selectedCategorySlug;
                          final categoryTitle = cat.nameFor(_selectedLanguageCode);
                          return ChoiceChip(
                            avatar: Icon(cat.icon, size: 16),
                            label: Text(categoryTitle),
                            selected: isSelected,
                            onSelected: (val) {
                              if (val && _selectedCategorySlug != cat.id) {
                                setState(() => _selectedCategorySlug = cat.id);
                                _loadCategoriesAndPhrases();
                              }
                            },
                          );
                        }).toList(),
                      ),
                    const SizedBox(height: AppSpacing.xl),

                    // --- Section 3: First 5 Phrases of chosen category ---
                    Text(
                      '3. First 5 Phrases for [${_selectedCategorySlug ?? 'none'}] -> "$_selectedLanguageCode"',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    if (_phrases.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                          border: Border.all(
                            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                          ),
                        ),
                        child: Text(
                          'No phrases found for category "${_selectedCategorySlug ?? ''}". Have you executed the seed script?',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                      )
                    else
                      ..._phrases.asMap().entries.map((entry) {
                        final index = entry.key + 1;
                        final phrase = entry.value;
                        final trans = phrase.translationFor(_selectedLanguageCode);
                        final english = phrase.translationFor('en')?.text ?? phrase.originalText;

                        return Card(
                          margin: const EdgeInsets.only(bottom: AppSpacing.md),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                            side: BorderSide(
                              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? AppColors.darkPrimaryContainer
                                            : AppColors.lightPrimaryContainer,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '#$index • ${phrase.id}',
                                        style: theme.textTheme.labelSmall?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: isDark
                                              ? AppColors.darkOnPrimaryContainer
                                              : AppColors.lightOnPrimaryContainer,
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      'Diff: ${phrase.difficulty}',
                                      style: theme.textTheme.labelSmall?.copyWith(
                                        color: isDark
                                            ? AppColors.darkTextSecondary
                                            : AppColors.lightTextSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  trans?.text ?? '(No translation found for $_selectedLanguageCode)',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? AppColors.darkText : AppColors.lightText,
                                  ),
                                ),
                                if (trans?.pronunciation != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    trans!.pronunciation!,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontStyle: FontStyle.italic,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  'EN: $english',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: isDark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.lightTextSecondary,
                                  ),
                                ),
                                if (trans?.exampleSentence != null) ...[
                                  const SizedBox(height: AppSpacing.xs),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(AppSpacing.sm),
                                    decoration: BoxDecoration(
                                      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                                      borderRadius: BorderRadius.circular(AppSpacing.radiusInput),
                                    ),
                                    child: Text(
                                      'Ex: ${trans!.exampleSentence}',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: isDark
                                            ? AppColors.darkText
                                            : AppColors.lightText,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      }),
                  ],
                ),
    );
  }
}
