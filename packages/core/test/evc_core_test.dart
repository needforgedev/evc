import 'package:flutter_test/flutter_test.dart';
import 'package:evc_core/evc_core.dart';

void main() {
  test('EvcApp carries display names and taglines', () {
    expect(EvcApp.rider.displayName, 'EVC Rider');
    expect(EvcApp.driver.displayName, 'EVC Driver');
    expect(EvcApp.admin.displayName, 'EVC Admin');
    expect(EvcApp.values, hasLength(3));
  });
}