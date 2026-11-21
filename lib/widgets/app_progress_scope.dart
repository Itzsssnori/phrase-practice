import 'package:material_ui/material_ui.dart';
import '../services/progress_controller.dart';

/// InheritedNotifier exposing [ProgressController] throughout the widget tree.
class AppProgressScope extends InheritedNotifier<ProgressController> {
  const AppProgressScope({
    super.key,
    required ProgressController controller,
    required super.child,
  }) : super(notifier: controller);

  static ProgressController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppProgressScope>();
    assert(scope != null, 'No AppProgressScope found in widget tree');
    return scope!.notifier!;
  }

  static ProgressController? maybeOf(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppProgressScope>();
    return scope?.notifier;
  }
}
