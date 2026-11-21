import 'package:material_ui/material_ui.dart';
import '../services/speech_service.dart';

/// InheritedNotifier scope exposing [SpeechService] across the widget tree.
class AppSpeechScope extends InheritedNotifier<SpeechService> {
  const AppSpeechScope({
    super.key,
    required SpeechService controller,
    required super.child,
  }) : super(notifier: controller);

  /// Retrieves [SpeechService] and registers the calling widget to rebuild on updates.
  static SpeechService of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppSpeechScope>();
    assert(scope != null, 'No AppSpeechScope found in context.');
    return scope!.notifier!;
  }

  /// Retrieves [SpeechService] if present in the widget tree, or `null` otherwise.
  static SpeechService? maybeOf(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppSpeechScope>();
    return scope?.notifier;
  }
}
