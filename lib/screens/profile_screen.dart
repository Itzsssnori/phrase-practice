import 'dart:async';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import '../models/language.dart';
import '../services/auth_controller.dart';
import '../services/browse_data_service.dart';
import '../services/speech_service.dart';
import '../services/tts_voice_selector.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/app_auth_scope.dart';
import '../widgets/app_primary_button.dart';
import '../widgets/app_progress_scope.dart';
import '../widgets/app_quiz_scope.dart';
import '../widgets/app_secondary_button.dart';
import '../widgets/app_settings_scope.dart';
import '../widgets/app_speech_scope.dart';
import '../widgets/app_translator_scope.dart';
import '../widgets/app_user_phrase_scope.dart';
import '../widgets/language_picker_bottom_sheet.dart';

/// Profile and application settings screen.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  List<Language> _languages = const [];
  bool _isSendingVerification = false;
  bool _isCheckingVerification = false;
  String? _verificationFeedback;
  bool _verificationFeedbackIsError = false;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    _loadLanguages();
    _ensureVoicesChecked(_effectiveActiveLanguages);
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadLanguages() async {
    final res = await BrowseDataService.instance.getLanguages();
    if (mounted && res.isSuccess && res.dataOrNull != null) {
      final loaded = res.dataOrNull!;
      setState(() => _languages = loaded);
      _ensureVoicesChecked(loaded);
    }
  }

  List<Language> get _effectiveActiveLanguages {
    final active = _languages.where((l) => l.isActive).toList();
    if (active.isNotEmpty) return active;
    return const [
      Language(code: 'en', name: 'English', nativeName: 'English', sortOrder: 1),
      Language(code: 'es', name: 'Spanish', nativeName: 'Español', sortOrder: 2),
      Language(code: 'fil', name: 'Filipino', nativeName: 'Filipino', sortOrder: 3),
    ];
  }

  void _ensureVoicesChecked(List<Language> langs) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final speech = AppSpeechScope.maybeOf(context);
      if (speech == null) return;
      for (final lang in langs.where((l) => l.isActive)) {
        unawaited(
          speech.ensureLanguageChecked(
            lang.code,
            ttsLocale: lang.effectiveTtsLocale,
          ),
        );
      }
    });
  }

  String _languageName(String code) {
    for (final lang in _languages) {
      if (lang.code == code) return lang.name;
    }
    return code.toUpperCase();
  }

  void _startCooldownTicker() {
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final auth = AppAuthScope.maybeOf(context);
      if (auth == null || auth.verificationCooldownRemaining == Duration.zero) {
        timer.cancel();
      }
      setState(() {});
    });
  }

  Future<void> _chooseLanguage({required bool isNative}) async {
    final settings = AppSettingsScope.of(context);
    var languages = _languages;
    if (languages.isEmpty) {
      final res = await BrowseDataService.instance.getLanguages();
      if (!mounted || res.isError) return;
      languages = res.dataOrNull ?? [];
      if (languages.isNotEmpty) {
        setState(() => _languages = languages);
      }
    }
    if (!mounted || languages.isEmpty) return;

    final currentCode =
        isNative ? settings.nativeLanguageCode : settings.targetLanguageCode;
    final currentLang = languages.firstWhere(
      (l) => l.code == currentCode,
      orElse: () => languages.first,
    );

    final selected = await LanguagePickerBottomSheet.show(
      context,
      selectedLanguage: currentLang,
      title: isNative ? 'I Speak' : "I'm Learning",
      availableLanguages: languages,
    );

    if (selected != null && mounted) {
      if (isNative) {
        await settings.setNativeLanguage(selected.code);
      } else {
        await settings.setTargetLanguage(selected.code);
      }
    }
  }

  Future<void> _sendVerificationEmail() async {
    if (_isSendingVerification) return;
    final auth = AppAuthScope.of(context);

    setState(() {
      _isSendingVerification = true;
      _verificationFeedback = null;
      _verificationFeedbackIsError = false;
    });

    final result = await auth.sendEmailVerification();
    if (!mounted) return;

    setState(() {
      _isSendingVerification = false;
      if (result.isSuccess) {
        _verificationFeedback = 'Verification email sent. Please check your inbox.';
        _verificationFeedbackIsError = false;
        _startCooldownTicker();
      } else {
        _verificationFeedback = result.errorMessageOrNull ??
            'Could not send verification email. Please try again.';
        _verificationFeedbackIsError = true;
      }
    });
  }

  Future<void> _checkEmailVerified() async {
    if (_isCheckingVerification) return;
    final auth = AppAuthScope.of(context);

    setState(() {
      _isCheckingVerification = true;
      _verificationFeedback = null;
      _verificationFeedbackIsError = false;
    });

    final result = await auth.reloadEmailVerificationStatus();
    if (!mounted) return;

    setState(() {
      _isCheckingVerification = false;
      if (result.isError) {
        _verificationFeedback = result.errorMessageOrNull ??
            'Could not check your email status. Please try again.';
        _verificationFeedbackIsError = true;
      } else if (result.dataOrNull == true) {
        _verificationFeedback = null;
        _verificationFeedbackIsError = false;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Your email is now verified.')),
        );
      } else {
        _verificationFeedback =
            'Email is still not verified yet. Tap the link in your inbox and try again.';
        _verificationFeedbackIsError = false;
      }
    });
  }

  Future<void> _showEditDisplayNameDialog(BuildContext context) async {
    final auth = AppAuthScope.of(context);
    final controller = TextEditingController(text: auth.displayName ?? '');
    String? errorText;
    bool isSaving = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return AlertDialog(
            title: const Text('Edit Display Name'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: controller,
                    autofocus: true,
                    enabled: !isSaving,
                    maxLength: AuthController.maxDisplayNameLength,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      labelText: 'Display name',
                      errorText: errorText,
                    ),
                    onChanged: (_) {
                      if (errorText != null) {
                        setDialogState(() => errorText = null);
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: isSaving
                    ? null
                    : () async {
                        final validation =
                            AuthController.validateDisplayName(controller.text);
                        if (validation != null) {
                          setDialogState(() => errorText = validation);
                          return;
                        }

                        setDialogState(() {
                          isSaving = true;
                          errorText = null;
                        });

                        final res = await auth.updateDisplayName(controller.text);
                        if (!dialogContext.mounted) return;

                        if (res.isSuccess) {
                          Navigator.of(dialogContext).pop();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Display name updated.')),
                            );
                          }
                        } else {
                          setDialogState(() {
                            isSaving = false;
                            errorText = res.errorMessageOrNull ??
                                'Could not update display name. Please try again.';
                          });
                        }
                      },
                child: isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save'),
              ),
            ],
          );
        },
      ),
    );

    controller.dispose();
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out of your account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final auth = AppAuthScope.of(context);
      await auth.signOut();
    }
  }

  /// Multi-step account deletion flow:
  /// 1. Clear warning listing everything that will be deleted
  /// 2. Re-enter password
  /// 3. Final confirmation + execution with progress & retry on failure
  Future<void> _startDeleteAccountFlow(BuildContext context) async {
    final auth = AppAuthScope.of(context);
    if (auth.isDeletingAccount) return;

    // Step 1: Warning dialog
    final acknowledgedWarning = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Account?'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Deleting your account permanently removes all of the following:',
              ),
              SizedBox(height: AppSpacing.sm),
              Text('• Your account login, email, and display name'),
              Text('• Your saved language preferences'),
              Text('• All bookmarked favorites'),
              Text('• All learned phrases and recently studied phrases'),
              Text('• All saved quiz attempts and scores'),
              SizedBox(height: AppSpacing.sm),
              Text(
                'This action cannot be undone.',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
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
            child: const Text('Continue'),
          ),
        ],
      ),
    );

    if (acknowledgedWarning != true || !context.mounted) return;

    // Step 2: Re-enter password dialog
    final password = await _promptForPassword(context);
    if (password == null || !context.mounted) return;

    // Step 3: Final confirmation & execution dialog (supports retry on failure)
    await _showFinalDeleteDialog(context, password: password);
  }

  Future<String?> _promptForPassword(BuildContext context) async {
    final controller = TextEditingController();
    String? errorText;

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Confirm Your Password'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'For your security, please enter your password to continue.',
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: controller,
                  autofocus: true,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    errorText: errorText,
                  ),
                  onChanged: (_) {
                    if (errorText != null) {
                      setDialogState(() => errorText = null);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(null),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (controller.text.isEmpty) {
                  setDialogState(() => errorText = 'Please enter your password.');
                  return;
                }
                Navigator.of(dialogContext).pop(controller.text);
              },
              child: const Text('Verify'),
            ),
          ],
        ),
      ),
    );

    controller.dispose();
    return result;
  }

  Future<void> _showFinalDeleteDialog(
    BuildContext context, {
    required String password,
  }) async {
    final auth = AppAuthScope.of(context);
    final userPhrases = AppUserPhraseScope.maybeOf(context);
    final quizCtrl = AppQuizScope.maybeOf(context);
    final progressCtrl = AppProgressScope.maybeOf(context);
    final translatorCtrl = AppTranslatorScope.maybeOf(context);

    bool isDeleting = false;
    String? errorMessage;

    final deleted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          Future<void> runDelete() async {
            if (isDeleting) return;
            setDialogState(() {
              isDeleting = true;
              errorMessage = null;
            });

            final res = await auth.deleteAccount(
              password: password,
              onDeleted: () {
                userPhrases?.clear();
                quizCtrl?.clear();
                progressCtrl?.clear();
                translatorCtrl?.clear();
              },
            );

            if (!dialogContext.mounted) return;

            if (res.isSuccess) {
              Navigator.of(dialogContext).pop(true);
            } else {
              setDialogState(() {
                isDeleting = false;
                errorMessage = res.errorMessageOrNull ??
                    'Could not delete your account. Please try again.';
              });
            }
          }

          return AlertDialog(
            title: const Text('Final Confirmation'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Are you sure you want to permanently delete your account and all saved data?',
                  ),
                  if (isDeleting) ...[
                    const SizedBox(height: AppSpacing.lg),
                    const Row(
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        ),
                        SizedBox(width: AppSpacing.md),
                        Expanded(child: Text('Deleting your account and data...')),
                      ],
                    ),
                  ],
                  if (errorMessage != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      errorMessage!,
                      style: TextStyle(
                        color: Theme.of(dialogContext).colorScheme.error,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isDeleting ? null : () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(dialogContext).colorScheme.error,
                  foregroundColor: Theme.of(dialogContext).colorScheme.onError,
                ),
                onPressed: isDeleting ? null : runDelete,
                child: Text(errorMessage != null ? 'Retry Delete' : 'Delete Permanently'),
              ),
            ],
          );
        },
      ),
    );

    if (deleted == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your account has been deleted.')),
      );
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryText = isDark ? AppColors.darkText : AppColors.lightText;
    final secondaryText = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final dividerColor = isDark ? AppColors.darkDivider : AppColors.lightDivider;

    final auth = AppAuthScope.of(context);
    final settings = AppSettingsScope.of(context);

    final isSignedIn = auth.isSignedIn;
    final displayName =
        auth.displayName ?? (auth.email != null ? auth.email!.split('@').first : 'Learner');
    final email = auth.email ?? '';
    final isEmailVerified = auth.isEmailVerified;

    String initials = 'G';
    if (isSignedIn && displayName.isNotEmpty) {
      final parts = displayName.trim().split(RegExp(r'\s+'));
      if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
        initials = '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      } else {
        initials = displayName[0].toUpperCase();
      }
    }

    final cooldownRemaining = auth.verificationCooldownRemaining;
    final cooldownSeconds = cooldownRemaining.inSeconds +
        (cooldownRemaining.inMilliseconds % 1000 > 0 ? 1 : 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings & Profile'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          children: [
            // --- Account Header Card: Signed In vs Guest ---
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                border: Border.all(color: borderColor, width: 1),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: isSignedIn
                    ? Row(
                        children: [
                          CircleAvatar(
                            radius: 26,
                            backgroundColor: isDark
                                ? AppColors.darkPrimaryContainer
                                : AppColors.lightPrimaryContainer,
                            child: Text(
                              initials,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? AppColors.darkOnPrimaryContainer
                                    : AppColors.lightOnPrimaryContainer,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  displayName,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: primaryText,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  email,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: secondaryText,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Semantics(
                                  label: isEmailVerified
                                      ? 'Email verified'
                                      : 'Email not verified',
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isEmailVerified
                                            ? Icons.verified_rounded
                                            : Icons.info_outline_rounded,
                                        size: 14,
                                        color: isEmailVerified
                                            ? (isDark
                                                ? AppColors.darkSuccess
                                                : AppColors.lightSuccess)
                                            : secondaryText,
                                      ),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          isEmailVerified
                                              ? 'Email verified'
                                              : 'Email not verified',
                                          style: theme.textTheme.labelSmall?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: isEmailVerified
                                                ? (isDark
                                                    ? AppColors.darkSuccess
                                                    : AppColors.lightSuccess)
                                                : secondaryText,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.logout_rounded),
                            tooltip: 'Sign Out',
                            onPressed: () => _confirmSignOut(context),
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: isDark
                                    ? AppColors.darkPrimaryContainer
                                    : AppColors.lightPrimaryContainer,
                                child: Icon(
                                  Icons.person_outline_rounded,
                                  color: theme.colorScheme.primary,
                                  size: AppSpacing.iconMd,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Guest Explorer',
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: primaryText,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Sign in to save favorites and track progress.',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: secondaryText,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Wrap(
                            spacing: AppSpacing.md,
                            runSpacing: AppSpacing.sm,
                            children: [
                              AppPrimaryButton(
                                label: 'Sign In',
                                onPressed: () => context.push('/login'),
                              ),
                              AppSecondaryButton(
                                label: 'Create Account',
                                onPressed: () => context.push('/register'),
                              ),
                            ],
                          ),
                        ],
                      ),
              ),
            ),

            // --- Verify Your Email Card (Signed in & unverified only) ---
            if (isSignedIn && !isEmailVerified) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
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
                            'Verify your email',
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
                      'Confirm your email address so we can help you recover your account if needed.',
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
                          color: _verificationFeedbackIsError
                              ? theme.colorScheme.error
                              : theme.colorScheme.primary,
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
                          onPressed: (_isSendingVerification || cooldownSeconds > 0)
                              ? null
                              : _sendVerificationEmail,
                          child: Text(
                            _isSendingVerification
                                ? 'Sending...'
                                : (cooldownSeconds > 0
                                    ? 'Resend in ${cooldownSeconds}s'
                                    : 'Send verification email'),
                          ),
                        ),
                        OutlinedButton(
                          onPressed:
                              _isCheckingVerification ? null : _checkEmailVerified,
                          child: Text(
                            _isCheckingVerification ? 'Checking...' : "I've verified",
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],

            // --- Account Section (Signed in only) ---
            if (isSignedIn) ...[
              const SizedBox(height: AppSpacing.xl),
              _SectionHeading(title: 'Account'),
              const SizedBox(height: AppSpacing.sm),
              _SettingsCard(
                borderColor: borderColor,
                children: [
                  ListTile(
                    leading: const Icon(Icons.badge_outlined),
                    title: const Text('Display Name'),
                    subtitle: Text(displayName),
                    trailing: const Icon(Icons.edit_outlined),
                    onTap: () => _showEditDisplayNameDialog(context),
                  ),
                ],
              ),
            ],

            // --- Language Section ---
            const SizedBox(height: AppSpacing.xl),
            _SectionHeading(title: 'Language'),
            const SizedBox(height: AppSpacing.sm),
            _SettingsCard(
              borderColor: borderColor,
              children: [
                ListTile(
                  leading: const Icon(Icons.translate_rounded),
                  title: const Text('I speak'),
                  subtitle: Text(_languageName(settings.nativeLanguageCode)),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _chooseLanguage(isNative: true),
                ),
                Divider(height: 1, color: dividerColor),
                ListTile(
                  leading: const Icon(Icons.language_rounded),
                  title: const Text("I'm learning"),
                  subtitle: Text(_languageName(settings.targetLanguageCode)),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _chooseLanguage(isNative: false),
                ),
              ],
            ),

            // --- Appearance Section ---
            const SizedBox(height: AppSpacing.xl),
            _SectionHeading(title: 'Appearance'),
            const SizedBox(height: AppSpacing.sm),
            _SettingsCard(
              borderColor: borderColor,
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Theme Mode',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: primaryText,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.xs,
                        children: [
                          ChoiceChip(
                            label: const Text('System'),
                            selected: settings.themeMode == ThemeMode.system,
                            onSelected: (_) => settings.setThemeMode(ThemeMode.system),
                          ),
                          ChoiceChip(
                            label: const Text('Light'),
                            selected: settings.themeMode == ThemeMode.light,
                            onSelected: (_) => settings.setThemeMode(ThemeMode.light),
                          ),
                          ChoiceChip(
                            label: const Text('Dark'),
                            selected: settings.themeMode == ThemeMode.dark,
                            onSelected: (_) => settings.setThemeMode(ThemeMode.dark),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // --- Reading Section (shared source of truth with Phrase Study) ---
            const SizedBox(height: AppSpacing.xl),
            _SectionHeading(title: 'Reading'),
            const SizedBox(height: AppSpacing.sm),
            _SettingsCard(
              borderColor: borderColor,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.md,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Study Text Size',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: primaryText,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.xs,
                        children: [
                          ChoiceChip(
                            label: const Text('Default'),
                            selected: settings.studyTextSizeIndex == 0,
                            onSelected: (_) => settings.setStudyTextSizeIndex(0),
                          ),
                          ChoiceChip(
                            label: const Text('Large'),
                            selected: settings.studyTextSizeIndex == 1,
                            onSelected: (_) => settings.setStudyTextSizeIndex(1),
                          ),
                          ChoiceChip(
                            label: const Text('Extra Large'),
                            selected: settings.studyTextSizeIndex == 2,
                            onSelected: (_) => settings.setStudyTextSizeIndex(2),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: dividerColor),
                SwitchListTile(
                  secondary: const Icon(Icons.visibility_off_outlined),
                  title: const Text('Recall Mode'),
                  subtitle: const Text('Hide translations until tapped while studying'),
                  value: settings.studyRecallMode,
                  onChanged: (value) => settings.setStudyRecallMode(value),
                ),
                Divider(height: 1, color: dividerColor),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.lg,
                    AppSpacing.lg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Speech Speed',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: primaryText,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.xs,
                        children: [
                          ChoiceChip(
                            label: const Text('Normal'),
                            selected: settings.speechSpeed == SpeechSpeed.normal,
                            onSelected: (_) =>
                                settings.setSpeechSpeed(SpeechSpeed.normal),
                          ),
                          ChoiceChip(
                            label: const Text('Slow'),
                            selected: settings.speechSpeed == SpeechSpeed.slow,
                            onSelected: (_) =>
                                settings.setSpeechSpeed(SpeechSpeed.slow),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // --- Audio Voices Section ---
            const SizedBox(height: AppSpacing.xl),
            _SectionHeading(title: 'Audio voices'),
            const SizedBox(height: AppSpacing.sm),
            _buildAudioVoicesCard(
              context,
              theme: theme,
              isDark: isDark,
              primaryText: primaryText,
              secondaryText: secondaryText,
              borderColor: borderColor,
              dividerColor: dividerColor,
            ),

            // --- Privacy & Account Data Section ---
            const SizedBox(height: AppSpacing.xl),
            _SectionHeading(title: 'Privacy & Data'),
            const SizedBox(height: AppSpacing.sm),
            _SettingsCard(
              borderColor: borderColor,
              children: [
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: const Text('Privacy'),
                  subtitle: const Text('What we store and how to delete it'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('/privacy'),
                ),
                if (isSignedIn) ...[
                  Divider(height: 1, color: dividerColor),
                  ListTile(
                    leading: Icon(
                      Icons.delete_forever_outlined,
                      color: theme.colorScheme.error,
                    ),
                    title: Text(
                      'Delete Account',
                      style: TextStyle(
                        color: theme.colorScheme.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: const Text('Permanently remove your account and data'),
                    enabled: !auth.isDeletingAccount,
                    onTap: () => _startDeleteAccountFlow(context),
                  ),
                ],
              ],
            ),

            if (isSignedIn) ...[
              const SizedBox(height: AppSpacing.xxl),
              OutlinedButton.icon(
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Sign Out'),
                onPressed: () => _confirmSignOut(context),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  Widget _buildAudioVoicesCard(
    BuildContext context, {
    required ThemeData theme,
    required bool isDark,
    required Color primaryText,
    required Color secondaryText,
    required Color borderColor,
    required Color dividerColor,
  }) {
    final speech = AppSpeechScope.maybeOf(context);
    final activeLangs = _effectiveActiveLanguages;

    final bool anyChecking = speech != null &&
        activeLangs.any(
          (l) => speech.availabilityFor(l.code) == VoiceAvailability.checking,
        );

    return _SettingsCard(
      borderColor: borderColor,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    'Availability depends on the device or browser.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: secondaryText,
                      height: 1.4,
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: (speech == null || anyChecking)
                        ? null
                        : () {
                            unawaited(
                              speech.recheckLanguages(
                                activeLangs.map((l) => l.code),
                              ),
                            );
                          },
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('Recheck'),
                  ),
                ],
              ),
            ],
          ),
        ),
        for (int i = 0; i < activeLangs.length; i++) ...[
          Divider(height: 1, color: dividerColor),
          Builder(
            builder: (context) {
              final lang = activeLangs[i];
              final status = speech != null
                  ? speech.availabilityFor(lang.code)
                  : VoiceAvailability.unavailable;

              late final String statusText;
              late final Color statusColor;
              switch (status) {
                case VoiceAvailability.checking:
                  statusText = 'Checking...';
                  statusColor = secondaryText;
                  break;
                case VoiceAvailability.available:
                  statusText = 'Available';
                  statusColor =
                      isDark ? AppColors.darkSuccess : AppColors.lightSuccess;
                  break;
                case VoiceAvailability.unavailable:
                  statusText = 'Not available on this device';
                  statusColor = secondaryText;
                  break;
              }

              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                child: Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: 4,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      lang.name,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: primaryText,
                      ),
                    ),
                    Text(
                      statusText,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: status == VoiceAvailability.available
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ],
    );
  }
}

class _SectionHeading extends StatelessWidget {
  final String title;

  const _SectionHeading({required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Semantics(
      header: true,
      child: Text(
        title,
        style: theme.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: isDark ? AppColors.darkText : AppColors.lightText,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final Color borderColor;
  final List<Widget> children;

  const _SettingsCard({
    required this.borderColor,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        side: BorderSide(color: borderColor, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}
