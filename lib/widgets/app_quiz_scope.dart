import 'package:flutter/widgets.dart';
import '../services/quiz_controller.dart';

/// InheritedNotifier scope providing app-wide access to [QuizController].
class AppQuizScope extends InheritedNotifier<QuizController> {
  const AppQuizScope({
    super.key,
    required QuizController controller,
    required super.child,
  }) : super(notifier: controller);

  static QuizController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppQuizScope>();
    assert(scope != null, 'No AppQuizScope found in context');
    return scope!.notifier!;
  }

  static QuizController? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AppQuizScope>()?.notifier;
  }
}
