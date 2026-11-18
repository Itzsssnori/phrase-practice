import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phrase_practice/main.dart';

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('App launches with Phrase Practice title', (WidgetTester tester) async {
    await tester.pumpWidget(const PhrasePracticeApp());
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Phrase Practice'), findsWidgets);
  });
}
