import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import '../services/mock_data_service.dart';
import '../theme/app_spacing.dart';
import '../widgets/category_card.dart';

/// Categories directory screen displaying thematic collections of phrases.
class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categories = MockDataService.sampleCategories;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Phrase Categories'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            tooltip: 'Search phrases',
            onPressed: () => context.push('/search'),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Text(
              'Browse by Topic',
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Organized by daily real-world scenarios to help you read fluently.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Responsive grid or list of Category Cards
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 600;
                if (isWide) {
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: AppSpacing.md,
                      mainAxisSpacing: AppSpacing.md,
                      childAspectRatio: 1.6,
                    ),
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final cat = categories[index];
                      return CategoryCard(
                        category: cat,
                        onTap: () => context.push('/categories/${cat.id}'),
                      );
                    },
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: categories.length,
                  separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, index) {
                    final cat = categories[index];
                    return CategoryCard(
                      category: cat,
                      onTap: () => context.push('/categories/${cat.id}'),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
