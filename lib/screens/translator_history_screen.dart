import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import '../services/mock_data_service.dart';
import '../theme/app_spacing.dart';

/// Screen displaying past lookup history from the quick translator.
class TranslatorHistoryScreen extends StatelessWidget {
  const TranslatorHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final historyPhrases = MockDataService.samplePhrases;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Translation History'),
        actions: [
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('History clearing is simulated for Stage 1.'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Clear'),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: historyPhrases.length,
          separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
          itemBuilder: (context, index) {
            final phrase = historyPhrases[index];
            return Card(
              child: ListTile(
                contentPadding: const EdgeInsets.all(AppSpacing.md),
                title: Text(
                  phrase.originalText,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      phrase.translatedText,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                onTap: () => context.push('/phrase-study'),
              ),
            );
          },
        ),
      ),
    );
  }
}
