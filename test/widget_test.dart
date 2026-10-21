import 'package:docsy/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Docsy home renders the core interface', (tester) async {
    await tester.pumpWidget(const DocsyApp());
    await tester.pumpAndSettle();

    expect(find.text('docsy'), findsOneWidget);
    expect(find.text('هنوز فایلی اینجا نیست'), findsOneWidget);
    expect(find.text('BETA'), findsNothing);
    expect(find.byTooltip('تغییر تم'), findsOneWidget);
    expect(find.text('همه اسنادت،\nیک‌جا و مرتب.'), findsOneWidget);
  });

  testWidgets('Language toggle switches the home copy to English', (tester) async {
    await tester.pumpWidget(const DocsyApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('تغییر زبان'));
    await tester.pumpAndSettle();

    expect(find.text('Every document,\nin one place.'), findsOneWidget);
    expect(find.byTooltip('Change language'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('docsy_language_fa_v1'), isFalse);
  });

  testWidgets('Theme toggle remains available in both languages', (tester) async {
    await tester.pumpWidget(const DocsyApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('تغییر تم'));
    await tester.pumpAndSettle();

    expect(find.byTooltip('تغییر تم'), findsOneWidget);
    expect(find.text('docsy'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('docsy_dark_theme_v1'), isTrue);
  });
  testWidgets('Search field and file type filters remain usable on empty library', (tester) async {
    await tester.pumpWidget(const DocsyApp());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'report');
    await tester.pumpAndSettle();

    expect(find.text('report'), findsOneWidget);
    expect(find.text('هنوز فایلی اینجا نیست'), findsOneWidget);

    await tester.tap(find.text('PDF'));
    await tester.pumpAndSettle();
    expect(find.text('هنوز فایلی اینجا نیست'), findsOneWidget);
  });

}
