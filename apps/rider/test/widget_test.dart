import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evcrider/main.dart';

void main() {
  testWidgets('EVC Rider boots to the branded welcome screen', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: EvcRiderApp()));
    await tester.pumpAndSettle(); // localization delegates load asynchronously
    expect(find.text('EVC'), findsOneWidget);
    expect(find.text('Get started'), findsOneWidget);
  });
}