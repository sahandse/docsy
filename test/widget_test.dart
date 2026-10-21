import 'dart:convert';
import 'dart:io';

import 'package:docsy/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

void seedLibraryFile() {
  // Synchronous I/O only: real async file work never completes inside a
  // testWidgets fake-async zone unless it is wrapped in tester.runAsync.
  final directory = Directory.systemTemp.createTempSync('docsy_test');
  addTearDown(() {
    if (directory.existsSync()) directory.deleteSync(recursive: true);
  });
  final file = File(p.join(directory.path, 'report.pdf'));
  file.writeAsBytesSync(const [0x25, 0x50, 0x44, 0x46]);
  SharedPreferences.setMockInitialValues({
    'docsy_recent_v1': jsonEncode([
      {'path': file.path, 'name': 'report.pdf', 'ext': 'pdf', 'added': 1},
    ]),
  });
}

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

    await tester.tap(find.widgetWithText(ChoiceChip, 'PDF'));
    await tester.pumpAndSettle();
    expect(find.text('هنوز فایلی اینجا نیست'), findsOneWidget);
  });

  test('decodeTextBytes decodes UTF-8 and BOM-marked UTF-16', () {
    expect(decodeTextBytes(utf8.encode('Docsy')), 'Docsy');
    expect(decodeTextBytes([0xEF, 0xBB, 0xBF, ...utf8.encode('Docsy')]), 'Docsy');
    expect(decodeTextBytes([0xFF, 0xFE, 0x33, 0x06, 0x44, 0x06, 0x27, 0x06, 0x45, 0x06]), 'سلام');
    expect(decodeTextBytes([0xFE, 0xFF, 0x06, 0x33, 0x06, 0x44, 0x06, 0x27, 0x06, 0x45]), 'سلام');
    expect(decodeTextBytes([0xC3, 0x28]), isNull);
  });

  testWidgets('Search without matches shows a no-results state', (tester) async {
    seedLibraryFile();
    await tester.pumpWidget(const DocsyApp());
    await tester.pumpAndSettle();

    expect(find.text('report.pdf'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'missing');
    await tester.pumpAndSettle();

    expect(find.text('نتیجه‌ای پیدا نشد'), findsOneWidget);
    expect(find.text('هنوز فایلی اینجا نیست'), findsNothing);
  });

  testWidgets('Removing a document requires confirmation', (tester) async {
    seedLibraryFile();
    await tester.pumpWidget(const DocsyApp());
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('حذف از کتابخانه'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'انصراف'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('report.pdf'), findsOneWidget);
  });
}
