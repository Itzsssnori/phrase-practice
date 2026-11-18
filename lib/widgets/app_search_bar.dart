import 'package:material_ui/material_ui.dart';
import '../theme/app_spacing.dart';

/// Clean, minimal search input with clear trigger and optional filter icon.
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
    this.hintText = 'Search phrases, translations, topics...',
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
          hintText: hintText,
          prefixIcon: const Icon(
            Icons.search_rounded,
            size: AppSpacing.iconMd,
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
            borderSide: BorderSide(color: theme.dividerColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
            borderSide: BorderSide(color: theme.dividerColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
            borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
          ),
        ),
      ),
    );
  }
}
