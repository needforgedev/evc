import 'package:flutter_test/flutter_test.dart';
import 'package:evcdriver/main.dart';

void main() {
  testWidgets('EVC Driver boots its branded landing screen', (tester) async {
    await tester.pumpWidget(const EvcDriverApp());
    expect(find.text('EVC Driver'), findsOneWidget);
  });
}