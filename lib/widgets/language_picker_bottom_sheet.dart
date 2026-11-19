import 'package:material_ui/material_ui.dart';
import '../models/language.dart';
import '../services/browse_data_service.dart';
import '../services/language_settings_controller.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'app_settings_scope.dart';

/// Bottom sheet dialog allowing the user to select their study or native language.
class LanguagePickerBottomSheet extends StatefulWidget {
  final Language selectedLanguage;
  final String title;
  final List<Language>? availableLanguages;

  const LanguagePickerBottomSheet({
    super.key,
    required this.selectedLanguage,
    this.title = 'Select Language',
    this.availableLanguages,
  });

  /// Opens the language selector bottom sheet for a single language selection.
  static Future<Language?> show(
    BuildContext context, {
    required Language selectedLanguage,
    String title = 'Select Language',
    List<Language>? availableLanguages,
  }) async {
    List<Language> languages = availableLanguages ?? [];
    if (languages.isEmpty) {
      final result = await BrowseDataService.instance.getLanguages();
      languages = result.dataOrNull ?? [
        const Language(code: 'en', name: 'English', nativeName: 'English'),
        const Language(code: 'es', name: 'Spanish', nativeName: 'Español'),
        const Language(code: 'fil', name: 'Filipino', nativeName: 'Filipino'),
      ];
    }

    if (!context.mounted) return null;

    return showModalBottomSheet<Language>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusCard)),
      ),
      builder: (context) => LanguagePickerBottomSheet(
        selectedLanguage: selectedLanguage,
        title: title,
        availableLanguages: languages,
      ),
    );
  }

  /// Opens a comprehensive language pair management sheet (I speak + I'm learning + Swap).
  static Future<void> showPairPicker(BuildContext context) async {
    final settings = AppSettingsScope.of(context);
    final langResult = await BrowseDataService.instance.getLanguages();
    final languages = langResult.dataOrNull ?? [
      const Language(code: 'en', name: 'English', nativeName: 'English'),
      const Language(code: 'es', name: 'Spanish', nativeName: 'Español'),
      const Language(code: 'fil', name: 'Filipino', nativeName: 'Filipino'),
    ];

    if (!context.mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusCard)),
      ),
      builder: (context) => _LanguagePairModalContent(
        settings: settings,
        languages: languages,
      ),
    );
  }

  @override
  State<LanguagePickerBottomSheet> createState() =>
      _LanguagePickerBottomSheetState();
}

class _LanguagePickerBottomSheetState extends State<LanguagePickerBottomSheet> {
  late String _query;
  late List<Language> _languages;

  @override
  void initState() {
    super.initState();
    _query = '';
    _languages = widget.availableLanguages ?? [];
    if (_languages.isEmpty) {
      _loadLanguages();
    }
  }

  Future<void> _loadLanguages() async {
    final result = await BrowseDataService.instance.getLanguages();
    if (mounted && result.isSuccess && result.dataOrNull != null) {
      setState(() {
        _languages = result.dataOrNull!;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final filteredLanguages = _languages.where((lang) {
      if (_query.isEmpty) return true;
      final q = BrowseDataService.normalize(_query);
      return BrowseDataService.normalize(lang.name).contains(q) ||
          BrowseDataService.normalize(lang.nativeName).contains(q) ||
          BrowseDataService.normalize(lang.code).contains(q);
    }).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.35,
      maxChildSize: 0.90,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Subtle handle bar
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title
              Text(
                widget.title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkText : AppColors.lightText,
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Filter textfield
              TextField(
                onChanged: (val) => setState(() => _query = val),
                decoration: const InputDecoration(
                  hintText: 'Search language...',
                  prefixIcon: Icon(Icons.search_rounded, size: AppSpacing.iconSm),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Language list
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  itemCount: filteredLanguages.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
                  ),
                  itemBuilder: (context, index) {
                    final lang = filteredLanguages[index];
                    final isCurrent = lang.code == widget.selectedLanguage.code;

                    return Container(
                      decoration: BoxDecoration(
                        color: isCurrent
                            ? (isDark ? AppColors.darkPrimaryContainer : AppColors.lightPrimaryContainer)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusInput),
                        border: isCurrent
                            ? Border.all(color: theme.colorScheme.primary, width: 1)
                            : null,
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: 2,
                        ),
                        leading: Text(
                          lang.flag,
                          style: const TextStyle(fontSize: 22),
                        ),
                        title: Text(
                          lang.name,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                            color: isCurrent ? theme.colorScheme.primary : null,
                          ),
                        ),
                        subtitle: Text(
                          lang.nativeName,
                          style: theme.textTheme.bodySmall,
                        ),
                        trailing: isCurrent
                            ? Icon(
                                Icons.check_rounded,
                                color: theme.colorScheme.primary,
                                size: AppSpacing.iconMd,
                              )
                            : null,
                        onTap: () => Navigator.of(context).pop(lang),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Fully scrollable interactive modal for managing both "I speak" and "I'm learning" languages.
class _LanguagePairModalContent extends StatelessWidget {
  final LanguageSettingsController settings;
  final List<Language> languages;

  const _LanguagePairModalContent({
    required this.settings,
    required this.languages,
  });

  Language _findLang(String code, String fallbackCode) {
    return languages.firstWhere(
      (l) => l.code == code,
      orElse: () => languages.firstWhere(
        (l) => l.code == fallbackCode,
        orElse: () => Language(code: code, name: code, nativeName: code),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        final nativeLang = _findLang(settings.nativeLanguageCode, 'en');
        final targetLang = _findLang(settings.targetLanguageCode, 'es');

        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.xl,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Language Settings',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      tooltip: 'Close',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),

                // Pair Swap Card (Responsive layout: Wrap / Row with Flexible)
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                    border: Border.all(
                      color: theme.dividerColor,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      // "I speak" column
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'I speak',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(nativeLang.flag, style: const TextStyle(fontSize: 18)),
                                const SizedBox(width: AppSpacing.xs),
                                Flexible(
                                  child: Text(
                                    nativeLang.name,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Swap Button
                      Semantics(
                        label: 'Swap native and target languages',
                        button: true,
                        child: IconButton.filledTonal(
                          icon: const Icon(Icons.swap_horiz_rounded),
                          tooltip: 'Swap languages',
                          onPressed: () => settings.swapLanguages(),
                        ),
                      ),

                      // "I'm learning" column
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "I'm learning",
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Flexible(
                                  child: Text(
                                    targetLang.name,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: theme.colorScheme.primary,
                                    ),
                                    textAlign: TextAlign.end,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Text(targetLang.flag, style: const TextStyle(fontSize: 18)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // Select Target Language Header
                Text(
                  "Choose What I'm Learning",
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),

                // Language selection list
                ...languages.map((lang) {
                  final isTarget = lang.code == targetLang.code;
                  final isNative = lang.code == nativeLang.code;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: Material(
                      color: isTarget
                          ? (isDark ? AppColors.darkPrimaryContainer : AppColors.lightPrimaryContainer)
                          : Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusInput),
                        side: isTarget
                            ? BorderSide(color: theme.colorScheme.primary, width: 1)
                            : BorderSide(color: theme.dividerColor.withValues(alpha: 0.5), width: 1),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: 0,
                        ),
                        leading: Text(lang.flag, style: const TextStyle(fontSize: 20)),
                        title: Text(
                          lang.name,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: isTarget ? FontWeight.w700 : FontWeight.w500,
                            color: isTarget ? theme.colorScheme.primary : null,
                          ),
                        ),
                        subtitle: Text(
                          isNative ? 'Current: I speak (${lang.nativeName})' : lang.nativeName,
                          style: theme.textTheme.bodySmall,
                        ),
                        trailing: isTarget
                            ? Icon(Icons.check_rounded, color: theme.colorScheme.primary)
                            : null,
                        onTap: () {
                          settings.setTargetLanguage(lang.code);
                        },
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}
