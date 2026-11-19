import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import '../models/phrase.dart';
import '../services/browse_data_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/app_auth_scope.dart';
import '../widgets/app_empty_state.dart';
import '../widgets/app_error_message.dart';
import '../widgets/app_loading_indicator.dart';
import '../widgets/app_primary_button.dart';
import '../widgets/app_secondary_button.dart';
import '../widgets/app_settings_scope.dart';
import '../widgets/app_user_phrase_scope.dart';
import '../widgets/phrase_card.dart';

/// Screen listing the signed-in user's bookmarked favorite phrases,
/// or prompting guests to sign in.
class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final _browseService = BrowseDataService.instance;
  List<Phrase>? _allPhrases;
  bool _isLoadingPhrases = false;
  String? _phraseLoadError;

  @override
  void initState() {
    super.initState();
    _loadAllPhrases();
  }

  Future<void> _loadAllPhrases({bool forceRefresh = false}) async {
    setState(() {
      _isLoadingPhrases = true;
      _phraseLoadError = null;
    });

    final result = await _browseService.getAllPhrases(forceRefresh: forceRefresh);
    if (!mounted) return;

    if (result.isSuccess && result.dataOrNull != null) {
      setState(() {
        _allPhrases = result.dataOrNull;
        _isLoadingPhrases = false;
      });
    } else {
      setState(() {
        _phraseLoadError = result.errorMessageOrNull ?? 'Failed to load phrases.';
        _isLoadingPhrases = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final auth = AppAuthScope.maybeOf(context);
    final settings = AppSettingsScope.of(context);

    // 1. Guest State
    if (auth == null || !auth.isSignedIn) {
      return Scaffold(
        appBar: AppBar(title: const Text('Favorites')),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.xxl,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkPrimaryContainer
                          : AppColors.lightPrimaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.favorite_rounded,
                      color: theme.colorScheme.primary,
                      size: AppSpacing.iconLg,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    'Save Your Favorite Phrases',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkText : AppColors.lightText,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Sign in or create an account to bookmark phrases and review them anytime across all your devices.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      height: 1.45,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  SizedBox(
                    width: double.infinity,
                    child: AppPrimaryButton(
                      label: 'Sign In',
                      onPressed: () => context.push('/login'),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    width: double.infinity,
                    child: AppSecondaryButton(
                      label: 'Create Account',
                      onPressed: () => context.push('/register'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // 2. Signed-in state
    final userPhraseCtrl = AppUserPhraseScope.of(context);

    if (userPhraseCtrl.isLoading || _isLoadingPhrases) {
      return Scaffold(
        appBar: AppBar(title: const Text('Favorites')),
        body: const Center(child: AppLoadingIndicator()),
      );
    }

    if (userPhraseCtrl.errorMessage != null || _phraseLoadError != null) {
      final errorMsg = userPhraseCtrl.errorMessage ?? _phraseLoadError!;
      return Scaffold(
        appBar: AppBar(title: const Text('Favorites')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: AppErrorMessage(
              title: 'Unable to Load Favorites',
              message: errorMsg,
              retryLabel: 'Try Again',
              onRetry: () {
                _loadAllPhrases(forceRefresh: true);
                if (auth.user != null) {
                  userPhraseCtrl.loadForUser(auth.user!.uid);
                }
              },
            ),
          ),
        ),
      );
    }

    // Resolve phrase objects for favorite IDs, preserving order (newest first)
    final favIds = userPhraseCtrl.favoritePhraseIds;
    final allPhrasesMap = {
      for (final p in (_allPhrases ?? <Phrase>[]))
        if (p.isActive) p.id: p,
    };

    final favoritePhrases = <Phrase>[];
    for (final id in favIds) {
      final p = allPhrasesMap[id];
      if (p != null) {
        favoritePhrases.add(p);
      }
      // Silently ignore inactive or removed IDs
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorites'),
      ),
      body: SafeArea(
        child: favoritePhrases.isEmpty
            ? AppEmptyState(
                icon: Icons.favorite_border_rounded,
                title: 'No saved phrases yet',
                message: 'Tap the heart icon on any phrase card to save it for quick review.',
                actionLabel: 'Browse Topics',
                onAction: () => context.go('/categories'),
              )
            : RefreshIndicator(
                onRefresh: () async {
                  await Future.wait([
                    _loadAllPhrases(forceRefresh: true),
                    if (auth.user != null) userPhraseCtrl.loadForUser(auth.user!.uid),
                  ]);
                },
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  children: [
                    Text(
                      '${favoritePhrases.length} Starred Phrases',
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
                      itemCount: favoritePhrases.length,
                      separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
                      itemBuilder: (context, index) {
                        final phrase = favoritePhrases[index];
                        return PhraseCard(
                          phrase: phrase,
                          targetLanguageCode: settings.targetLanguageCode,
                          nativeLanguageCode: settings.nativeLanguageCode,
                          onTap: () => context.push(
                            '/phrase-study/${phrase.id}?category=${phrase.categoryId}',
                          ),
                          onFavoriteToggle: (_) async {
                            final res = await userPhraseCtrl.toggleFavorite(phrase.id);
                            if (!context.mounted) return;
                            if (res.isError) {
                              ScaffoldMessenger.of(context).hideCurrentSnackBar();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(res.errorMessageOrNull ?? 'Could not update favorite.'),
                                  backgroundColor: Theme.of(context).colorScheme.error,
                                ),
                              );
                            } else if (res.isSuccess) {
                              ScaffoldMessenger.of(context).hideCurrentSnackBar();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('Removed from favorites'),
                                  action: SnackBarAction(
                                    label: 'Undo',
                                    onPressed: () => userPhraseCtrl.toggleFavorite(phrase.id),
                                  ),
                                ),
                              );
                            }
                          },
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
