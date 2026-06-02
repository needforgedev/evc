import 'package:flutter_test/flutter_test.dart';
import 'package:evcrider/main.dart';

void main() {
  testWidgets('EVC Rider boots its branded landing screen', (tester) async {
    await tester.pumpWidget(const EvcRiderApp());
    expect(find.text('EVC Rider'), findsOneWidget);
  });
}