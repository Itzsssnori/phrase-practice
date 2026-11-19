import 'package:material_ui/material_ui.dart';
import '../services/user_phrase_controller.dart';

/// InheritedNotifier providing [UserPhraseController] to all descendant widgets.
class AppUserPhraseScope extends InheritedNotifier<UserPhraseController> {
  const AppUserPhraseScope({
    super.key,
    required UserPhraseController controller,
    required super.child,
  }) : super(notifier: controller);

  /// Accesses the nearest [UserPhraseController] in the widget tree,
  /// registering the build context for automatic updates.
  static UserPhraseController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppUserPhraseScope>();
    assert(scope != null, 'No AppUserPhraseScope found in widget tree context');
    return scope!.notifier!;
  }

  /// Accesses the nearest [UserPhraseController] without asserting.
  static UserPhraseController? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AppUserPhraseScope>()?.notifier;
  }
}
