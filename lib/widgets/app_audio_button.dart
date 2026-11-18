import 'package:material_ui/material_ui.dart';
import '../theme/app_spacing.dart';

/// Audio pronunciation button currently presented in disabled state (audio engine coming in later stage).
class AppAudioButton extends StatelessWidget {
  final VoidCallback? onPlay;
  final bool isAvailable;

  const AppAudioButton({
    super.key,
    this.onPlay,
    this.isAvailable = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Tooltip(
      message: isAvailable ? 'Listen to pronunciation' : 'Audio coming soon',
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: AppSpacing.minTouchTarget,
          minHeight: AppSpacing.minTouchTarget,
        ),
        child: IconButton(
          onPressed: isAvailable ? onPlay : null,
          icon: Icon(
            Icons.volume_up_outlined,
            size: AppSpacing.iconMd,
            color: isAvailable
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.35),
          ),
        ),
      ),
    );
  }
}
