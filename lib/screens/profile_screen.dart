import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import '../services/mock_data_service.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings & Profile'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            // User Profile Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Text(
                        'JD',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onPrimaryContainer,
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
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'demo@phrasepractice.internal',
                            style: theme.textTheme.bodySmall,
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
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.language_rounded),
                    title: const Text('Target Language'),
                    subtitle: Text('${_selectedLanguage.flag} ${_selectedLanguage.name}'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: _chooseLanguage,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.history_rounded),
                    title: const Text('Translation History'),
                    subtitle: const Text('View recently translated phrases'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push('/translator/history'),
                  ),
                  const Divider(height: 1),
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
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.brightness_medium_rounded),
                    title: const Text('Theme Mode'),
                    subtitle: const Text('System Default (Light & Dark supported)'),
                    trailing: const Chip(
                      label: Text('System'),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    secondary: const Icon(Icons.notifications_none_rounded),
                    title: const Text('Daily Study Reminder'),
                    subtitle: const Text('Coming in next stage'),
                    value: false,
                    onChanged: null, // Disabled per rule: no fake working buttons
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
