import 'dart:async';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import '../models/language.dart';
import '../models/translation_entry.dart';
import '../services/browse_data_service.dart';
import '../services/translator_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/app_auth_scope.dart';
import '../widgets/app_empty_state.dart';
import '../widgets/app_error_message.dart';
import '../widgets/app_loading_indicator.dart';
import '../widgets/app_primary_button.dart';
import '../widgets/app_secondary_button.dart';
import '../widgets/app_settings_scope.dart';
import '../widgets/app_translator_scope.dart';
import '../widgets/language_chip.dart';
import '../widgets/language_picker_bottom_sheet.dart';
import '../widgets/require_sign_in.dart';
import '../widgets/translation_result_card.dart';

/// AI-powered travel phrasebook translator backed by Firebase AI Logic.
class TranslatorScreen extends StatefulWidget {
  final String? initialQuery;

  const TranslatorScreen({
    super.key,
    this.initialQuery,
  });

  @override
  State<TranslatorScreen> createState() => _TranslatorScreenState();
}

class _TranslatorScreenState extends State<TranslatorScreen> {
  final _inputController = TextEditingController();
  List<Language> _languages = const [];
  String? _validationError;
  String? _requestedHistoryUid;
  bool _isCheckingVerification = false;
  String? _verificationFeedback;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null && widget.initialQuery!.trim().isNotEmpty) {
      _inputController.text = widget.initialQuery!.trim();
    }
    _loadLanguages();
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _inputController.dispose();
    super.dispose();
  }

  Future<void> _loadLanguages() async {
    final res = await BrowseDataService.instance.getLanguages();
    if (mounted && res.isSuccess && res.dataOrNull != null) {
      setState(() => _languages = res.dataOrNull!);
    }
  }

  Language _resolveLanguage(String code) {
    for (final lang in _languages) {
      if (lang.code == code) return lang;
    }
    return Language(
      code: code,
      name: code.toUpperCase(),
      nativeName: code.toUpperCase(),
    );
  }

  void _startCooldownTicker() {
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final ctrl = AppTranslatorScope.maybeOf(context);
      if (ctrl == null || !ctrl.isCoolingDown) {
        timer.cancel();
      }
      setState(() {});
    });
  }

  Future<void> _handleTranslate() async {
    final allowed = await requireSignIn(
      context,
      title: 'Sign in to translate phrases',
      message: 'Sign in or create a free account to translate everyday phrases with AI.',
    );
    if (!allowed || !mounted) return;

    final auth = AppAuthScope.of(context);
    if (!auth.isEmailVerified) return;

    final validation = TranslatorInputValidator.validate(_inputController.text);
    if (validation != null) {
      setState(() => _validationError = validation);
      return;
    }

    setState(() => _validationError = null);

    final settings = AppSettingsScope.of(context);
    final translatorCtrl = AppTranslatorScope.of(context);
    final sourceLang = _resolveLanguage(settings.nativeLanguageCode);
    final targetLang = _resolveLanguage(settings.targetLanguageCode);

    await translatorCtrl.translate(
      rawInput: _inputController.text,
      sourceLanguage: sourceLang,
      targetLanguage: targetLang,
    );

    if (mounted && translatorCtrl.isCoolingDown) {
      _startCooldownTicker();
    }
  }

  void _handleClear() {
    _inputController.clear();
    setState(() => _validationError = null);
    AppTranslatorScope.maybeOf(context)?.clearCurrentResult();
  }

  Future<void> _refreshEmailVerification() async {
    if (_isCheckingVerification) return;
    final auth = AppAuthScope.of(context);
    setState(() {
      _isCheckingVerification = true;
      _verificationFeedback = null;
    });

    final res = await auth.reloadEmailVerificationStatus();
    if (!mounted) return;

    setState(() {
      _isCheckingVerification = false;
      if (res.isError) {
        _verificationFeedback =
            res.errorMessageOrNull ?? 'Could not refresh your email status. Please try again.';
      } else if (res.dataOrNull == true) {
        _verificationFeedback = null;
      } else {
        _verificationFeedback =
            'Email is still not verified yet. Open the link in your inbox and try again.';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryText = isDark ? AppColors.darkText : AppColors.lightText;
    final secondaryText = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    final auth = AppAuthScope.of(context);
    final settings = AppSettingsScope.of(context);
    final translatorCtrl = AppTranslatorScope.of(context);

    final sourceLang = _resolveLanguage(settings.nativeLanguageCode);
    final targetLang = _resolveLanguage(settings.targetLanguageCode);

    // Lazy-load history once for signed-in users so history-first lookup works
    if (auth.isSignedIn && auth.user != null && _requestedHistoryUid != auth.user!.uid) {
      final uid = auth.user!.uid;
      _requestedHistoryUid = uid;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          translatorCtrl.ensureHistoryLoaded(uid);
        }
      });
    } else if (!auth.isSignedIn) {
      _requestedHistoryUid = null;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Translator'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'History',
            onPressed: () => context.push('/translator/history'),
          ),
        ],
      ),
      body: SafeArea(
        child: _buildBody(
          context: context,
          theme: theme,
          isDark: isDark,
          primaryText: primaryText,
          secondaryText: secondaryText,
          borderColor: borderColor,
          sourceLang: sourceLang,
          targetLang: targetLang,
        ),
      ),
    );
  }

  Widget _buildBody({
    required BuildContext context,
    required ThemeData theme,
    required bool isDark,
    required Color primaryText,
    required Color secondaryText,
    required Color borderColor,
    required Language sourceLang,
    required Language targetLang,
  }) {
    final auth = AppAuthScope.of(context);
    final translatorCtrl = AppTranslatorScope.of(context);

    if (auth.isLoading) {
      return const Center(child: AppLoadingIndicator());
    }

    // 1. Guest gate
    if (!auth.isSignedIn || auth.user == null) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkPrimaryContainer
                        : AppColors.lightPrimaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.translate_rounded,
                    size: AppSpacing.iconLg,
                    color: isDark
                        ? AppColors.darkOnPrimaryContainer
                        : AppColors.lightOnPrimaryContainer,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Translate Everyday Phrases',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: primaryText,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Type any travel or daily phrase to get a translation, pronunciation hint, and example sentence. Sign in with a verified email to use the translator and save your history.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: secondaryText,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
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
      );
    }

    // 2. App Check / Translator unavailable gate (e.g. release web missing site key)
    if (!translatorCtrl.isAvailable) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: AppEmptyState(
            icon: Icons.cloud_off_rounded,
            title: 'Translator is unavailable',
            message:
                'The AI translator is not available in this build right now. You can still browse phrases, study, and take quizzes.',
          ),
        ),
      );
    }

    final isVerified = auth.isEmailVerified;
    final cooldownSecs = translatorCtrl.cooldownRemainingSeconds;
    final canTapTranslate =
        isVerified && !translatorCtrl.isTranslating && cooldownSecs == 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Unverified email gate card
          if (!isVerified) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                border: Border.all(color: borderColor, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.mark_email_unread_outlined,
                        size: AppSpacing.iconSm,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'Verify your email to use the translator',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: primaryText,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Please confirm your email address in Settings & Profile before translating phrases.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: secondaryText,
                      height: 1.4,
                    ),
                  ),
                  if (_verificationFeedback != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      _verificationFeedback!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      FilledButton(
                        onPressed: () => context.go('/profile'),
                        child: const Text('Go to Verification'),
                      ),
                      OutlinedButton(
                        onPressed: _isCheckingVerification
                            ? null
                            : _refreshEmailVerification,
                        child: Text(
                          _isCheckingVerification ? 'Checking...' : "I've verified",
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],

          // Language Pair Chip
          LanguagePairChip(
            nativeLanguage: sourceLang,
            targetLanguage: targetLang,
            onTap: () => LanguagePickerBottomSheet.showPairPicker(context),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Multiline input with 200-char counter
          Semantics(
            textField: true,
            label: 'Phrase to translate in ${sourceLang.name}',
            child: TextField(
              controller: _inputController,
              maxLines: 4,
              minLines: 3,
              maxLength: TranslatorInputValidator.maxLength,
              enabled: isVerified && !translatorCtrl.isTranslating,
              decoration: InputDecoration(
                labelText: 'Phrase in ${sourceLang.name}',
                hintText: 'Type an everyday phrase or question...',
                errorText: _validationError,
                alignLabelWithHint: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusInput),
                ),
              ),
              onChanged: (_) {
                if (_validationError != null) {
                  setState(() => _validationError = null);
                } else {
                  setState(() {});
                }
              },
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Translate & Clear actions
          Row(
            children: [
              Expanded(
                child: AppPrimaryButton(
                  label: translatorCtrl.isTranslating
                      ? 'Translating...'
                      : (cooldownSecs > 0
                          ? 'Wait ${cooldownSecs}s'
                          : 'Translate'),
                  icon: Icons.translate_rounded,
                  isLoading: translatorCtrl.isTranslating,
                  onPressed: canTapTranslate ? _handleTranslate : null,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Semantics(
                button: true,
                label: 'Clear phrase input',
                child: OutlinedButton(
                  onPressed: translatorCtrl.isTranslating ? null : _handleClear,
                  child: const Text('Clear'),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.xl),

          // Output / Status Area
          _buildOutputSection(
            context: context,
            theme: theme,
            isDark: isDark,
            primaryText: primaryText,
            secondaryText: secondaryText,
            borderColor: borderColor,
          ),

          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildOutputSection({
    required BuildContext context,
    required ThemeData theme,
    required bool isDark,
    required Color primaryText,
    required Color secondaryText,
    required Color borderColor,
  }) {
    final translatorCtrl = AppTranslatorScope.of(context);

    if (translatorCtrl.isTranslating) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: Center(child: AppLoadingIndicator()),
      );
    }

    if (translatorCtrl.errorMessage != null) {
      final isCooldownError =
          translatorCtrl.errorCode == TranslatorErrorMapper.quotaErrorCode;
      final canRetry = !translatorCtrl.isCoolingDown &&
          translatorCtrl.errorCode != TranslatorErrorMapper.unavailableErrorCode;

      return AppErrorMessage(
        title: isCooldownError ? 'Translator Busy' : 'Could Not Translate',
        message: translatorCtrl.errorMessage!,
        retryLabel: 'Try Again',
        onRetry: canRetry ? _handleTranslate : null,
      );
    }

    final result = translatorCtrl.currentResult;
    if (result == null) {
      return const AppEmptyState(
        icon: Icons.translate_rounded,
        title: 'Ready to translate',
        message: 'Enter a phrase above and tap Translate to see the translation, pronunciation, and an example.',
      );
    }

    if (result.status == TranslationStatus.notAPhrase) {
      return const AppEmptyState(
        icon: Icons.help_outline_rounded,
        title: 'Not a translatable phrase',
        message: 'Try entering a short everyday phrase or travel question.',
      );
    }

    if (result.status == TranslationStatus.unsupported) {
      return const AppEmptyState(
        icon: Icons.language_rounded,
        title: 'Language not supported',
        message: 'This language pair could not be translated. Try another pair from the language picker.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TranslationResultCard(result: result),
        if (translatorCtrl.saveFailed) ...[
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusInput),
              border: Border.all(color: borderColor, width: 1),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    "Couldn't save to history",
                    style: theme.textTheme.bodySmall?.copyWith(color: secondaryText),
                  ),
                ),
                TextButton(
                  onPressed: translatorCtrl.isSavingHistory
                      ? null
                      : translatorCtrl.retrySaveCurrentResult,
                  child: Text(translatorCtrl.isSavingHistory ? 'Saving...' : 'Retry'),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
