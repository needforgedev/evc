import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evcdriver/main.dart';

void main() {
  testWidgets('EVC Driver boots to the branded welcome screen', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: EvcDriverApp()));
    expect(find.text('Sign in to drive'), findsOneWidget);
  });
}