import 'package:flutter_test/flutter_test.dart';
import 'package:candlelang_app/main.dart';

void main() {
  testWidgets('App launches', (WidgetTester tester) async {
    await tester.pumpWidget(const CandleLangApp());
    expect(find.text('CandleLang'), findsOneWidget);
  });
}
