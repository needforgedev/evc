import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evcadmin/main.dart';

void main() {
  testWidgets('EVC Admin boots to the sign-in screen', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: EvcAdminApp()));
    await tester.pumpAndSettle(); // localization delegates load asynchronously
    expect(find.text('EVC Admin'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
  });
}