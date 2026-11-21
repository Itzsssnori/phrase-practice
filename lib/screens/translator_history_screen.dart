import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import '../models/language.dart';
import '../models/translation_entry.dart';
import '../services/browse_data_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/app_auth_scope.dart';
import '../widgets/app_empty_state.dart';
import '../widgets/app_error_message.dart';
import '../widgets/app_loading_indicator.dart';
import '../widgets/app_primary_button.dart';
import '../widgets/app_secondary_button.dart';
import '../widgets/app_translator_scope.dart';
import '../widgets/localized_phrase_text.dart';
import '../widgets/translation_result_card.dart';

/// Displays a signed-in user's private AI translation history with All/Saved filter,
/// star toggling, delete with Undo, clear all, and full result card inspection.
class TranslatorHistoryScreen extends StatefulWidget {
  const TranslatorHistoryScreen({super.key});

  @override
  State<TranslatorHistoryScreen> createState() => _TranslatorHistoryScreenState();
}

class _TranslatorHistoryScreenState extends State<TranslatorHistoryScreen> {
  bool _savedOnly = false;
  List<Language> _languages = const [];
  String? _requestedUid;

  @override
  void initState() {
    super.initState();
    _loadLanguages();
  }

  Future<void> _loadLanguages() async {
    final res = await BrowseDataService.instance.getLanguages();
    if (mounted && res.isSuccess && res.dataOrNull != null) {
      setState(() => _languages = res.dataOrNull!);
    }
  }

  String _languageName(String code) {
    for (final lang in _languages) {
      if (lang.code == code) return lang.name;
    }
    return code.toUpperCase();
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  void _openDetailSheet(BuildContext context, TranslationHistoryItem item) {
    final result = item.toTranslationResult(
      sourceLanguageName: _languageName(item.sourceLanguageCode),
      targetLanguageName: _languageName(item.targetLanguageCode),
      fromHistory: true,
    );

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusCard)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: DraggableScrollableSheet(
            initialChildSize: 0.72,
            minChildSize: 0.45,
            maxChildSize: 0.92,
            expand: false,
            builder: (ctx, scrollController) {
              return SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Saved Translation',
                            style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          tooltip: 'Close',
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TranslationResultCard(
                      result: result,
                      showInputPhrase: true,
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _toggleSaved(BuildContext context, TranslationHistoryItem item) async {
    final ctrl = AppTranslatorScope.of(context);
    final res = await ctrl.toggleSaved(item.id);
    if (res.isError && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.errorMessageOrNull ?? 'Could not update saved state.'),
        ),
      );
    }
  }

  void _deleteWithUndo(BuildContext context, TranslationHistoryItem item) {
    final ctrl = AppTranslatorScope.of(context);
    final removed = ctrl.removeHistoryItemOptimistically(item.id);
    if (removed == null) return;

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    final controller = messenger.showSnackBar(
      SnackBar(
        content: const Text('Translation deleted.'),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            ctrl.undoRemoveHistoryItem(item.id);
          },
        ),
      ),
    );

    controller.closed.then((reason) async {
      if (reason != SnackBarClosedReason.action) {
        final res = await ctrl.commitRemoveHistoryItem(item.id);
        if (res.isError && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(res.errorMessageOrNull ?? 'Could not delete translation.'),
            ),
          );
        }
      }
    });
  }

  Future<void> _confirmClearAll(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Clear History?'),
        content: const Text(
          'This will permanently delete all of your saved and recent translations.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
              foregroundColor: Theme.of(dialogContext).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final ctrl = AppTranslatorScope.of(context);
      final res = await ctrl.clearHistory();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              res.isSuccess
                  ? 'Translation history cleared.'
                  : (res.errorMessageOrNull ?? 'Could not clear history.'),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryText = isDark ? AppColors.darkText : AppColors.lightText;
    final secondaryText = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    final auth = AppAuthScope.of(context);
    final ctrl = AppTranslatorScope.of(context);

    // Guest state
    if (!auth.isSignedIn || auth.user == null) {
      _requestedUid = null;
      return Scaffold(
        appBar: AppBar(title: const Text('Translation History')),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.history_rounded,
                      size: 48,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Sign in to view history',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: primaryText,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Your AI translations are saved privately to your account when you are signed in.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(color: secondaryText),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    SizedBox(
                      width: double.infinity,
                      child: AppPrimaryButton(
                        label: 'Sign In',
                        onPressed: () => context.push('/login'),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
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
        ),
      );
    }

    final uid = auth.user!.uid;
    if (_requestedUid != uid) {
      _requestedUid = uid;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) ctrl.ensureHistoryLoaded(uid);
      });
    }

    final visibleItems = _savedOnly ? ctrl.savedHistory : ctrl.history;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Translation History'),
        actions: [
          if (ctrl.history.isNotEmpty)
            TextButton(
              onPressed: () => _confirmClearAll(context),
              child: const Text('Clear history'),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Segment selector: All / Saved
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  children: [
                    ChoiceChip(
                      label: const Text('All'),
                      selected: !_savedOnly,
                      onSelected: (_) => setState(() => _savedOnly = false),
                    ),
                    ChoiceChip(
                      label: const Text('Saved'),
                      selected: _savedOnly,
                      onSelected: (_) => setState(() => _savedOnly = true),
                    ),
                  ],
                ),
              ),
            ),

            Expanded(
              child: _buildListBody(
                context: context,
                theme: theme,
                isDark: isDark,
                primaryText: primaryText,
                secondaryText: secondaryText,
                borderColor: borderColor,
                uid: uid,
                visibleItems: visibleItems,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListBody({
    required BuildContext context,
    required ThemeData theme,
    required bool isDark,
    required Color primaryText,
    required Color secondaryText,
    required Color borderColor,
    required String uid,
    required List<TranslationHistoryItem> visibleItems,
  }) {
    final ctrl = AppTranslatorScope.of(context);

    if (ctrl.isLoadingHistory && !ctrl.hasLoadedHistory) {
      return const Center(child: AppLoadingIndicator());
    }

    if (ctrl.historyError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: AppErrorMessage(
            title: 'Could Not Load History',
            message: ctrl.historyError!,
            retryLabel: 'Retry',
            onRetry: () => ctrl.loadHistory(uid, force: true),
          ),
        ),
      );
    }

    if (visibleItems.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: AppEmptyState(
            icon: _savedOnly ? Icons.star_outline_rounded : Icons.history_rounded,
            title: _savedOnly ? 'No saved translations' : 'No translation history yet',
            message: _savedOnly
                ? 'Tap the star on any translation in your history to save it here.'
                : 'Phrases you translate will appear here so you can review them later.',
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      itemCount: visibleItems.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final item = visibleItems[index];
        final langPair =
            '${_languageName(item.sourceLanguageCode)} → ${_languageName(item.targetLanguageCode)}';
        final dateLabel = _formatDate(item.createdAt);

        return Dismissible(
          key: ValueKey(item.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            decoration: BoxDecoration(
              color: theme.colorScheme.error,
              borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
            ),
            child: Icon(
              Icons.delete_outline_rounded,
              color: theme.colorScheme.onError,
            ),
          ),
          onDismissed: (_) => _deleteWithUndo(context, item),
          child: Semantics(
            button: true,
            label:
                '${item.inputText} translated to ${item.translatedText}, $langPair, $dateLabel',
            child: Material(
              color: theme.colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                side: BorderSide(color: borderColor, width: 1),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => _openDetailSheet(context, item),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                LocalizedPhraseText(
                                  item.inputText,
                                  languageCode: item.sourceLanguageCode,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: primaryText,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                LocalizedPhraseText(
                                  item.translatedText,
                                  languageCode: item.targetLanguageCode,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              item.isSaved ? Icons.star_rounded : Icons.star_outline_rounded,
                              color: item.isSaved ? theme.colorScheme.primary : secondaryText,
                            ),
                            tooltip: item.isSaved ? 'Remove from saved' : 'Save translation',
                            onPressed: () => _toggleSaved(context, item),
                          ),
                          PopupMenuButton<String>(
                            tooltip: 'More options',
                            onSelected: (value) {
                              if (value == 'delete') {
                                _deleteWithUndo(context, item);
                              }
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(
                                value: 'delete',
                                child: Text('Delete'),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: 2,
                        children: [
                          Text(
                            langPair,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: secondaryText,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '•',
                            style: theme.textTheme.labelSmall?.copyWith(color: secondaryText),
                          ),
                          Text(
                            dateLabel,
                            style: theme.textTheme.labelSmall?.copyWith(color: secondaryText),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
