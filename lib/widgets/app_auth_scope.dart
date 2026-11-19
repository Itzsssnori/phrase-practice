import 'package:material_ui/material_ui.dart';
import '../services/auth_controller.dart';

/// InheritedNotifier providing [AuthController] to all child widgets.
///
/// Calling `AppAuthScope.of(context)` registers the caller to rebuild whenever
/// authentication status, user profile, or session state changes.
class AppAuthScope extends InheritedNotifier<AuthController> {
  const AppAuthScope({
    super.key,
    required AuthController controller,
    required super.child,
  }) : super(notifier: controller);

  /// Accesses the nearest [AuthController] in the widget tree,
  /// registering the build context for automatic updates.
  static AuthController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppAuthScope>();
    assert(scope != null, 'No AppAuthScope found in widget tree context');
    return scope!.notifier!;
  }

  /// Accesses the nearest [AuthController] without asserting.
  static AuthController? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AppAuthScope>()?.notifier;
  }
}
