import 'package:material_ui/material_ui.dart';
import '../models/language.dart';
import '../services/mock_data_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Bottom sheet dialog allowing the user to select their study or native language.
class LanguagePickerBottomSheet extends StatefulWidget {
  final Language selectedLanguage;
  final String title;

  const LanguagePickerBottomSheet({
    super.key,
    required this.selectedLanguage,
    this.title = 'Select Language',
  });

  static Future<Language?> show(
    BuildContext context, {
    required Language selectedLanguage,
    String title = 'Select Language',
  }) {
    return showModalBottomSheet<Language>(
      context: context,
      isScrollControlled: true,
      builder: (context) => LanguagePickerBottomSheet(
        selectedLanguage: selectedLanguage,
        title: title,
      ),
    );
  }

  @override
  State<LanguagePickerBottomSheet> createState() =>
      _LanguagePickerBottomSheetState();
}

class _LanguagePickerBottomSheetState extends State<LanguagePickerBottomSheet> {
  late String _query;

  @override
  void initState() {
    super.initState();
    _query = '';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final languages = MockDataService.sampleLanguages.where((lang) {
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      return lang.name.toLowerCase().contains(q) ||
          lang.nativeName.toLowerCase().contains(q);
    }).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.85,
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
                  itemCount: languages.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
                  ),
                  itemBuilder: (context, index) {
                    final lang = languages[index];
                    final isCurrent = lang.code == widget.selectedLanguage.code;

                    return Container(
                      decoration: BoxDecoration(
                        color: isCurrent
                            ? (isDark ? AppColors.darkSecondary : AppColors.lightSecondary)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusInput),
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
