import 'package:material_ui/material_ui.dart';
import '../services/language_settings_controller.dart';

/// InheritedNotifier providing [LanguageSettingsController] to all child widgets.
///
/// Calling `AppSettingsScope.of(context)` registers the caller to rebuild whenever
/// language preferences change.
class AppSettingsScope extends InheritedNotifier<LanguageSettingsController> {
  const AppSettingsScope({
    super.key,
    required LanguageSettingsController controller,
    required super.child,
  }) : super(notifier: controller);

  /// Accesses the nearest [LanguageSettingsController] in the widget tree,
  /// registering the build context for automatic updates.
  static LanguageSettingsController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppSettingsScope>();
    assert(scope != null, 'No AppSettingsScope found in widget tree context');
    return scope!.notifier!;
  }

  /// Accesses the nearest [LanguageSettingsController] without asserting.
  static LanguageSettingsController? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AppSettingsScope>()?.notifier;
  }
}
