import 'dart:async';
import 'package:material_ui/material_ui.dart';
import '../services/speech_service.dart';
import '../theme/app_spacing.dart';
import 'app_speech_scope.dart';

/// Visual state of [AppAudioButton].
enum AudioButtonVisualState {
  checking,
  idle,
  playing,
  unavailable,
  error,
}

/// Interactive Text-to-Speech pronunciation button with checking, idle,
/// playing, unavailable, and error states.
///
/// Always maintains at least a 48x48 px touch target ([AppSpacing.minTouchTarget]),
/// speaks only on explicit user tap (never autoplay), and stops active playback
/// when disposed.
class AppAudioButton extends StatefulWidget {
  /// Target-language text to speak when tapped.
  final String text;

  /// Target language code (e.g. 'es', 'fil', 'fr').
  final String languageCode;

  /// Optional human-readable language name (e.g. 'Spanish'). If omitted, derived
  /// from [languageCode].
  final String? languageName;

  /// Optional unique identifier for this button's utterance. If omitted,
  /// defaults to `'$languageCode::$text'`.
  final String? utteranceId;

  /// Whether to render a slightly smaller icon for secondary contexts such as
  /// example sentences, while preserving the 48x48 px minimum touch target.
  final bool isCompact;

  /// Optional custom action label prefix (defaults to `'Play pronunciation'`).
  final String actionPrefix;

  const AppAudioButton({
    super.key,
    this.text = '',
    this.languageCode = 'es',
    this.languageName,
    this.utteranceId,
    this.isCompact = false,
    this.actionPrefix = 'Play pronunciation',
  });

  /// Canonical human-readable language name for tooltips and accessibility labels.
  static String languageNameFor(String code, {String? explicitName}) {
    if (explicitName != null && explicitName.trim().isNotEmpty) {
      return explicitName.trim();
    }
    switch (code.trim().toLowerCase()) {
      case 'en':
        return 'English';
      case 'es':
        return 'Spanish';
      case 'fil':
        return 'Filipino';
      case 'fr':
        return 'French';
      case 'ru':
        return 'Russian';
      case 'ja':
        return 'Japanese';
      case 'ko':
        return 'Korean';
      case 'zh':
        return 'Chinese (Mandarin, Simplified)';
      default:
        return code.toUpperCase();
    }
  }

  @override
  State<AppAudioButton> createState() => _AppAudioButtonState();
}

class _AppAudioButtonState extends State<AppAudioButton> {
  SpeechService? _speechService;

  String get _resolvedUtteranceId =>
      widget.utteranceId ??
      '${widget.languageCode.trim().toLowerCase()}::${widget.text.trim()}';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final service = AppSpeechScope.maybeOf(context);
    if (!identical(_speechService, service)) {
      _speechService = service;
      _triggerLazyCheck();
    }
  }

  @override
  void didUpdateWidget(covariant AppAudioButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.languageCode != widget.languageCode) {
      _triggerLazyCheck();
    }
  }

  void _triggerLazyCheck() {
    final service = _speechService;
    if (service == null || widget.languageCode.trim().isEmpty) return;
    // Schedule after build so notifyListeners never fires mid-build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(service.ensureLanguageChecked(widget.languageCode));
    });
  }

  @override
  void dispose() {
    final service = _speechService;
    final utteranceId = _resolvedUtteranceId;
    if (service != null) {
      // Defer stop until after unmount so notifyListeners never fires while
      // the widget tree is locked.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(service.stopIfPlayingUtterance(utteranceId));
      });
    }
    super.dispose();
  }

  void _showAudioErrorSnackBar() {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      const SnackBar(
        content: Text("Couldn't play audio"),
        duration: Duration(seconds: 3),
      ),
    );
  }

  Future<void> _handleTap() async {
    final service = _speechService;
    if (service == null || widget.text.trim().isEmpty) return;

    await service.speak(
      text: widget.text,
      languageCode: widget.languageCode,
      utteranceId: _resolvedUtteranceId,
      onError: _showAudioErrorSnackBar,
    );
  }

  AudioButtonVisualState _resolveVisualState(SpeechService? service) {
    if (service == null || widget.text.trim().isEmpty) {
      return AudioButtonVisualState.unavailable;
    }
    final availability = service.availabilityFor(widget.languageCode);
    switch (availability) {
      case VoiceAvailability.checking:
        return AudioButtonVisualState.checking;
      case VoiceAvailability.unavailable:
        return AudioButtonVisualState.unavailable;
      case VoiceAvailability.available:
        if (service.isPlayingUtterance(_resolvedUtteranceId)) {
          return AudioButtonVisualState.playing;
        }
        if (service.hasErrorForUtterance(_resolvedUtteranceId)) {
          return AudioButtonVisualState.error;
        }
        return AudioButtonVisualState.idle;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final service = AppSpeechScope.maybeOf(context);
    final visualState = _resolveVisualState(service);
    final langName = AppAudioButton.languageNameFor(
      widget.languageCode,
      explicitName: widget.languageName,
    );

    final double iconSize =
        widget.isCompact ? AppSpacing.iconSm : AppSpacing.iconMd;

    late final String label;
    late final Widget iconWidget;
    late final VoidCallback? onPressed;

    switch (visualState) {
      case AudioButtonVisualState.checking:
        label = 'Checking voice for $langName';
        onPressed = null;
        iconWidget = SizedBox(
          width: iconSize - 4,
          height: iconSize - 4,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
          ),
        );
        break;
      case AudioButtonVisualState.unavailable:
        label = 'No voice for $langName on this device';
        onPressed = null;
        iconWidget = Icon(
          Icons.volume_off_outlined,
          size: iconSize,
          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.35),
        );
        break;
      case AudioButtonVisualState.playing:
        label = 'Stop';
        onPressed = _handleTap;
        iconWidget = Icon(
          Icons.stop_circle_outlined,
          size: iconSize,
          color: theme.colorScheme.primary,
        );
        break;
      case AudioButtonVisualState.error:
      case AudioButtonVisualState.idle:
        label = '${widget.actionPrefix} in $langName';
        onPressed = _handleTap;
        iconWidget = Icon(
          Icons.volume_up_outlined,
          size: iconSize,
          color: theme.colorScheme.primary,
        );
        break;
    }

    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: label,
      excludeSemantics: true,
      child: Tooltip(
        message: label,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: AppSpacing.minTouchTarget,
            minHeight: AppSpacing.minTouchTarget,
          ),
          child: IconButton(
            onPressed: onPressed,
            icon: iconWidget,
          ),
        ),
      ),
    );
  }
}
