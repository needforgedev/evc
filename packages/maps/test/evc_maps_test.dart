import 'package:flutter_test/flutter_test.dart';
import 'package:evc_maps/evc_maps.dart';

void main() {
  test('maps package exposes its current provider', () {
    expect(evcMapsProvider, 'google_maps');
  });
}