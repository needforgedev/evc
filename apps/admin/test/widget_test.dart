import 'package:flutter_test/flutter_test.dart';
import 'package:evcadmin/main.dart';

void main() {
  testWidgets('EVC Admin boots its branded landing screen', (tester) async {
    await tester.pumpWidget(const EvcAdminApp());
    expect(find.text('EVC Admin'), findsOneWidget);
  });
}