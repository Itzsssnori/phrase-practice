import 'package:material_ui/material_ui.dart';
import '../services/translator_controller.dart';

/// InheritedNotifier exposing [TranslatorController] throughout the widget tree.
class AppTranslatorScope extends InheritedNotifier<TranslatorController> {
  const AppTranslatorScope({
    super.key,
    required TranslatorController controller,
    required super.child,
  }) : super(notifier: controller);

  static TranslatorController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppTranslatorScope>();
    assert(scope != null, 'No AppTranslatorScope found in widget tree');
    return scope!.notifier!;
  }

  static TranslatorController? maybeOf(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppTranslatorScope>();
    return scope?.notifier;
  }
}
