import 'package:docsy/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Docsy home renders core interface', (tester) async {
    await tester.pumpWidget(const DocsyApp());
    await tester.pumpAndSettle();

    expect(find.text('docsy'), findsOneWidget);
    expect(find.text('BETA'), findsOneWidget);
  });
}
