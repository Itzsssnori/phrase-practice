import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import '../services/mock_data_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/language_picker_bottom_sheet.dart';

/// Profile and application settings screen.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  var _selectedLanguage = MockDataService.sampleLanguages[1]; // Spanish

  void _chooseLanguage() async {
    final selected = await LanguagePickerBottomSheet.show(
      context,
      selectedLanguage: _selectedLanguage,
      title: 'Primary Learning Language',
    );
    if (selected != null && mounted) {
      setState(() => _selectedLanguage = selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
            // User Profile Card
            Container(
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
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: isDark ? AppColors.darkPrimaryContainer : AppColors.lightPrimaryContainer,
                      child: Text(
                        'JD',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.darkOnPrimaryContainer : AppColors.lightOnPrimaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Demo Learner',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.darkText : AppColors.lightText,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'demo@phrasepractice.internal',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            Text(
              'Learning Preferences',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkText : AppColors.lightText,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.language_rounded),
                    title: const Text('Target Language'),
                    subtitle: Text('${_selectedLanguage.flag} ${_selectedLanguage.name}'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: _chooseLanguage,
                  ),
                  Divider(height: 1, color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
                  ListTile(
                    leading: const Icon(Icons.history_rounded),
                    title: const Text('Translation History'),
                    subtitle: const Text('View recently translated phrases'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push('/translator/history'),
                  ),
                  Divider(height: 1, color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
                  ListTile(
                    leading: const Icon(Icons.wifi_off_rounded),
                    title: const Text('Network Error Test Screen'),
                    subtitle: const Text('Preview offline / error state UI'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push('/error'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            Text(
              'Appearance & Notifications',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkText : AppColors.lightText,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.brightness_medium_rounded),
                    title: const Text('Theme Mode'),
                    subtitle: const Text('System Default (Light & Dark supported)'),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkPrimaryContainer : AppColors.lightPrimaryContainer,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusInput),
                      ),
                      child: Text(
                        'System',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.darkOnPrimaryContainer : AppColors.lightOnPrimaryContainer,
                        ),
                      ),
                    ),
                  ),
                  Divider(height: 1, color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
                  const SwitchListTile(
                    secondary: Icon(Icons.notifications_none_rounded),
                    title: Text('Daily Study Reminder'),
                    subtitle: Text('Coming in next stage'),
                    value: false,
                    onChanged: null,
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xxl),

            OutlinedButton.icon(
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Sign Out'),
              onPressed: () => context.go('/splash'),
            ),
          ],
        ),
      ),
    );
  }
}
