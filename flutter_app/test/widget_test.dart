import 'package:flutter_test/flutter_test.dart';
import 'package:candlelang_app/main.dart';
import 'package:candlelang_app/injection_container.dart' as di;

void main() {
  setUp(() async {
    await di.init();
  });

  testWidgets('App launches', (WidgetTester tester) async {
    await tester.pumpWidget(const CandleLangApp());
    await tester.pump();
    expect(find.text('CandleLang'), findsWidgets);
  });
}
