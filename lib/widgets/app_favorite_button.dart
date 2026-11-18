import 'package:material_ui/material_ui.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Favorite button featuring subtle scale feedback and amber highlight.
class AppFavoriteButton extends StatefulWidget {
  final bool isFavorite;
  final ValueChanged<bool>? onToggle;

  const AppFavoriteButton({
    super.key,
    required this.isFavorite,
    this.onToggle,
  });

  @override
  State<AppFavoriteButton> createState() => _AppFavoriteButtonState();
}

class _AppFavoriteButtonState extends State<AppFavoriteButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() async {
    await _controller.forward();
    await _controller.reverse();
    widget.onToggle?.call(!widget.isFavorite);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final activeColor = isDark ? AppColors.darkAccent : AppColors.lightAccent;

    return Semantics(
      button: true,
      label: widget.isFavorite ? 'Remove from favorites' : 'Add to favorites',
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: AppSpacing.minTouchTarget,
          minHeight: AppSpacing.minTouchTarget,
        ),
        child: InkResponse(
          onTap: widget.onToggle != null ? _handleTap : null,
          radius: AppSpacing.minTouchTarget / 2,
          child: Center(
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Icon(
                widget.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                color: widget.isFavorite
                    ? activeColor
                    : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                size: AppSpacing.iconMd,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
