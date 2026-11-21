import 'package:material_ui/material_ui.dart';
import '../content/privacy_copy.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Plain-language Privacy screen explaining what the app stores and how to delete it.
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryText = isDark ? AppColors.darkText : AppColors.lightText;
    final secondaryText = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Scaffold(
      appBar: AppBar(
        title: const Text(PrivacyCopy.screenTitle),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          children: [
            Semantics(
              header: true,
              child: Text(
                PrivacyCopy.introTitle,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: primaryText,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              PrivacyCopy.introBody,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: secondaryText,
                height: 1.45,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            for (final section in PrivacyCopy.sections) ...[
              Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                  border: Border.all(color: borderColor, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        section.title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: primaryText,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      section.body,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: secondaryText,
                        height: 1.45,
                      ),
                    ),
                    if (section.bullets.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.sm),
                      for (final bullet in section.bullets)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Container(
                                  width: 5,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(
                                  bullet,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: primaryText,
                                    height: 1.4,
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
            ],
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}
