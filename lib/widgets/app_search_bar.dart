import 'package:material_ui/material_ui.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Clean, minimal search input with subtle borders and clear icon.
class AppSearchBar extends StatelessWidget {
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final VoidCallback? onFilterTap;
  final String hintText;
  final bool autofocus;

  const AppSearchBar({
    super.key,
    this.controller,
    this.onChanged,
    this.onClear,
    this.onFilterTap,
    this.hintText = 'Search phrases, translations...',
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ConstrainedBox(
      constraints: const BoxConstraints(
        minHeight: AppSpacing.minTouchTarget,
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        autofocus: autofocus,
        style: theme.textTheme.bodyMedium,
        decoration: InputDecoration(
          filled: true,
          fillColor: theme.colorScheme.surface,
          hintText: hintText,
          prefixIcon: Icon(
            Icons.search_rounded,
            size: AppSpacing.iconMd,
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (controller != null && controller!.text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: AppSpacing.iconSm),
                  onPressed: () {
                    controller?.clear();
                    onClear?.call();
                  },
                ),
              if (onFilterTap != null)
                IconButton(
                  icon: const Icon(Icons.tune_rounded, size: AppSpacing.iconSm),
                  tooltip: 'Filter options',
                  onPressed: onFilterTap,
                ),
            ],
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
            borderSide: BorderSide(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              width: 1,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
            borderSide: BorderSide(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
            borderSide: BorderSide(
              color: theme.colorScheme.primary,
              width: 1.6,
            ),
          ),
        ),
      ),
    );
  }
}
