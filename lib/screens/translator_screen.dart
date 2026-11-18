import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import '../models/language.dart';
import '../services/mock_data_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/app_audio_button.dart';
import '../widgets/app_favorite_button.dart';
import '../widgets/app_primary_button.dart';
import '../widgets/app_text_field.dart';
import '../widgets/language_chip.dart';
import '../widgets/language_picker_bottom_sheet.dart';

/// Instant phrase translator tool with clean, minimalist cards.
class TranslatorScreen extends StatefulWidget {
  const TranslatorScreen({super.key});

  @override
  State<TranslatorScreen> createState() => _TranslatorScreenState();
}

class _TranslatorScreenState extends State<TranslatorScreen> {
  final _inputController = TextEditingController();
  Language _sourceLang = MockDataService.sampleLanguages[0]; // English
  Language _targetLang = MockDataService.sampleLanguages[1]; // Spanish
  String? _simulatedTranslation;
  bool _isFavorite = false;

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _swapLanguages() {
    setState(() {
      final temp = _sourceLang;
      _sourceLang = _targetLang;
      _targetLang = temp;
      _simulatedTranslation = null;
    });
  }

  void _translate() {
    if (_inputController.text.trim().isEmpty) return;
    setState(() {
      _simulatedTranslation = '¿Dónde está la estación de tren más cercana?';
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quick Translator'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'Translation History',
            onPressed: () => context.push('/translator/history'),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Language Selector Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  LanguageChip(
                    language: _sourceLang,
                    isSelected: false,
                    onTap: () async {
                      final selected = await LanguagePickerBottomSheet.show(
                        context,
                        selectedLanguage: _sourceLang,
                        title: 'Select Source Language',
                      );
                      if (selected != null) setState(() => _sourceLang = selected);
                    },
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.swap_horiz_rounded,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                    tooltip: 'Swap languages',
                    onPressed: _swapLanguages,
                  ),
                  LanguageChip(
                    language: _targetLang,
                    isSelected: true,
                    onTap: () async {
                      final selected = await LanguagePickerBottomSheet.show(
                        context,
                        selectedLanguage: _targetLang,
                        title: 'Select Target Language',
                      );
                      if (selected != null) setState(() => _targetLang = selected);
                    },
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // Input field
              AppTextField(
                controller: _inputController,
                label: 'Phrase to translate',
                hintText: 'Type an everyday phrase or question...',
                maxLines: 4,
              ),
              const SizedBox(height: AppSpacing.md),

              AppPrimaryButton(
                label: 'Translate',
                icon: Icons.translate_rounded,
                onPressed: _translate,
              ),

              const SizedBox(height: AppSpacing.xl),

              // Translation Result Card
              if (_simulatedTranslation != null) ...[
                Text(
                  'Translation',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkText : AppColors.lightText,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      width: 1,
                    ),
                    boxShadow: isDark
                        ? []
                        : [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.015),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const AppAudioButton(isAvailable: false),
                          const Spacer(),
                          AppFavoriteButton(
                            isFavorite: _isFavorite,
                            onToggle: (val) => setState(() => _isFavorite = val),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        _simulatedTranslation!,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.primary,
                        ),
                        softWrap: true,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusInput),
                        ),
                        child: Text(
                          'Context: Frequently used when asking for public transport directions.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark ? AppColors.darkText : AppColors.lightText,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
